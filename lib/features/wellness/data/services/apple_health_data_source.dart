import 'package:health/health.dart';
import '../models/daily_health_data.dart';
import '../repositories/wellness_repository.dart';
import 'health_data_source.dart';

/// Reads real device metrics from Apple HealthKit via the `health` plugin.
/// Falls back to [SampleHealthDataSource] when permission is denied or reads
/// return no data (e.g. on the simulator with an empty Health store).
class AppleHealthDataSource implements HealthDataSource {
  final Health _health = Health();
  final SampleHealthDataSource _fallback = SampleHealthDataSource();

  // Core metrics — always requested.
  static const List<HealthDataType> _coreTypes = [
    HealthDataType.SLEEP_ASLEEP, // iOS sleep (not SLEEP_SESSION which is Android)
    HealthDataType.STEPS,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE,
  ];

  // Optional body metrics — requested but gracefully absent.
  static const List<HealthDataType> _bodyTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.BODY_FAT_PERCENTAGE,
  ];

  static List<HealthDataType> get _allTypes => [..._coreTypes, ..._bodyTypes];

  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      final permissions = _allTypes.map((_) => HealthDataAccess.READ).toList();
      return await _health.requestAuthorization(_allTypes, permissions: permissions);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<DailyHealthData>> fetchRange({int days = 7}) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final out = <DailyHealthData>[];

      for (int i = days - 1; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final start = DateTime(day.year, day.month, day.day);
        final end = start.add(const Duration(days: 1));

        final points = await _health.getHealthDataFromTypes(
          types: _allTypes,
          startTime: start,
          endTime: end,
        );

        final steps = await _health.getTotalStepsInInterval(start, end) ??
            _sumInt(points, HealthDataType.STEPS);
        final sleepMinutes = _sumDurationMinutes(points, HealthDataType.SLEEP_ASLEEP);
        final activeMinutes = _sumInt(points, HealthDataType.EXERCISE_TIME);
        final restingHr = _avgInt(points, HealthDataType.RESTING_HEART_RATE) ??
            _avgInt(points, HealthDataType.HEART_RATE) ??
            0;

        // Body metrics: use the latest reading within the window (point-in-time).
        final weight = _latestDouble(points, HealthDataType.WEIGHT);
        final bmi = _latestDouble(points, HealthDataType.BODY_MASS_INDEX);
        final bodyFat = _latestDouble(points, HealthDataType.BODY_FAT_PERCENTAGE);

        out.add(DailyHealthData(
          date: WellnessRepository.dateKey(day),
          sleepDurationMinutes: sleepMinutes,
          steps: steps,
          activeMinutes: activeMinutes,
          restingHeartRate: restingHr,
          weight: weight,
          bodyMassIndex: bmi,
          bodyFatPercentage: bodyFat,
        ));
      }

      // Fall back to sample data when HealthKit returned nothing meaningful
      // (typical on simulator with an empty Health store).
      final hasAny = out.any((d) =>
          d.steps > 0 || d.sleepDurationMinutes > 0 || d.restingHeartRate > 0);
      return hasAny ? out : _fallback.fetchRange(days: days);
    } catch (_) {
      return _fallback.fetchRange(days: days);
    }
  }

  double _numeric(HealthDataPoint p) {
    final v = p.value;
    if (v is NumericHealthValue) return v.numericValue.toDouble();
    return 0;
  }

  int _sumInt(List<HealthDataPoint> points, HealthDataType type) {
    final relevant = points.where((p) => p.type == type);
    if (relevant.isEmpty) return 0;
    return relevant.fold<double>(0, (s, p) => s + _numeric(p)).round();
  }

  int _sumDurationMinutes(List<HealthDataPoint> points, HealthDataType type) {
    final relevant = points.where((p) => p.type == type);
    var minutes = 0.0;
    for (final p in relevant) {
      minutes += p.dateTo.difference(p.dateFrom).inMinutes;
    }
    return minutes.round();
  }

  int? _avgInt(List<HealthDataPoint> points, HealthDataType type) {
    final relevant = points.where((p) => p.type == type).toList();
    if (relevant.isEmpty) return null;
    final total = relevant.fold<double>(0, (s, p) => s + _numeric(p));
    return (total / relevant.length).round();
  }

  double? _latestDouble(List<HealthDataPoint> points, HealthDataType type) {
    final relevant = points.where((p) => p.type == type).toList();
    if (relevant.isEmpty) return null;
    relevant.sort((a, b) => b.dateTo.compareTo(a.dateTo));
    final v = _numeric(relevant.first);
    return v == 0 ? null : v;
  }
}
