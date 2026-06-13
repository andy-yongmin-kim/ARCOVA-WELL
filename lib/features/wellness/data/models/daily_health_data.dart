import 'package:hive/hive.dart';

part 'daily_health_data.g.dart';

/// A single day's raw health metrics, keyed by [date] (yyyy-MM-dd).
/// Rolling 7-day averages are computed from history in the repository,
/// not stored here.
@HiveType(typeId: 1)
class DailyHealthData extends HiveObject {
  @HiveField(0)
  final String date; // yyyy-MM-dd

  @HiveField(1)
  int sleepDurationMinutes;

  @HiveField(2)
  int steps;

  @HiveField(3)
  int activeMinutes;

  @HiveField(4)
  int restingHeartRate;

  @HiveField(5)
  DateTime updatedAt;

  DailyHealthData({
    required this.date,
    this.sleepDurationMinutes = 0,
    this.steps = 0,
    this.activeMinutes = 0,
    this.restingHeartRate = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
}

/// A computed view: today's metrics alongside the rolling 7-day averages.
/// Consumed by the dashboard and the briefing generator.
class HealthSnapshot {
  final DailyHealthData today;
  final int sleepSevenDayAverage;
  final int stepsSevenDayAverage;
  final int restingHrSevenDayAverage;

  const HealthSnapshot({
    required this.today,
    required this.sleepSevenDayAverage,
    required this.stepsSevenDayAverage,
    required this.restingHrSevenDayAverage,
  });
}
