import 'dart:math';
import '../models/daily_health_data.dart';
import '../repositories/wellness_repository.dart';

/// Abstraction over a source of health metrics. A [SampleHealthDataSource]
/// backs the emulator / no-permission path; [HealthConnectDataSource]
/// (Phase D) reads real device data.
abstract class HealthDataSource {
  /// Requests any runtime permissions. Returns true if granted (always true
  /// for the sample source).
  Future<bool> requestPermissions();

  /// Fetches one [DailyHealthData] per day for the last [days] days
  /// (inclusive of today), oldest first. Used to backfill history so 7-day
  /// averages and streaks aren't empty on first run.
  Future<List<DailyHealthData>> fetchRange({int days = 7});
}

/// Deterministic synthetic data, mirroring the original prototype's sample
/// figures: today tracks a little below the trailing baseline.
class SampleHealthDataSource implements HealthDataSource {
  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<DailyHealthData>> fetchRange({int days = 7}) async {
    final rnd = Random(42);
    final today = DateTime.now();
    final out = <DailyHealthData>[];

    for (int i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final date = WellnessRepository.dateKey(day);
      if (i == 0) {
        // Today — matches the prototype's "below baseline" sample.
        out.add(DailyHealthData(
          date: date,
          sleepDurationMinutes: 378,
          steps: 4321,
          activeMinutes: 28,
          restingHeartRate: 71,
        ));
      } else {
        out.add(DailyHealthData(
          date: date,
          sleepDurationMinutes: 420 + rnd.nextInt(50) - 25,
          steps: 6100 + rnd.nextInt(1200) - 600,
          activeMinutes: 35 + rnd.nextInt(20) - 10,
          restingHeartRate: 68 + rnd.nextInt(4) - 2,
        ));
      }
    }
    return out;
  }
}
