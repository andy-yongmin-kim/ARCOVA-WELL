import 'package:health/health.dart';
import '../models/daily_health_data.dart';
import '../repositories/wellness_repository.dart';
import 'health_data_source.dart';

/// Reads real device metrics via Android Health Connect (health 13.x).
/// Falls back to [SampleHealthDataSource] when permission is denied, the
/// platform is unsupported, or a read fails — so the app always has data.
class HealthConnectDataSource implements HealthDataSource {
  final Health _health = Health();
  final SampleHealthDataSource _fallback = SampleHealthDataSource();

  static const List<HealthDataType> _types = [
    // Health Connect stores sleep as SLEEP_SESSION; SLEEP_ASLEEP is the
    // Apple Health equivalent. Request both for cross-platform coverage.
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.EXERCISE_TIME,
  ];

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
      final permissions = _types.map((_) => HealthDataAccess.READ).toList();
      return await _health.requestAuthorization(_types, permissions: permissions);
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
          types: _types,
          startTime: start,
          endTime: end,
        );

        final steps = await _health.getTotalStepsInInterval(start, end) ??
            _sumInt(points, HealthDataType.STEPS);
        // Prefer SLEEP_SESSION (Health Connect); fall back to SLEEP_ASLEEP.
        final sessionSleep = _sumDurationMinutes(points, HealthDataType.SLEEP_SESSION);
        final sleepMinutes = sessionSleep > 0
            ? sessionSleep
            : _sumDurationMinutes(points, HealthDataType.SLEEP_ASLEEP);
        final activeMinutes = _sumInt(points, HealthDataType.EXERCISE_TIME);
        final restingHr = _avgInt(points, HealthDataType.RESTING_HEART_RATE) ??
            _avgInt(points, HealthDataType.HEART_RATE) ??
            0;

        out.add(DailyHealthData(
          date: WellnessRepository.dateKey(day),
          sleepDurationMinutes: sleepMinutes,
          steps: steps,
          activeMinutes: activeMinutes,
          restingHeartRate: restingHr,
        ));
      }

      // If Health Connect returned nothing for the whole window, use sample data
      // so the dashboard and averages aren't blank.
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
}
