import 'package:hive/hive.dart';

part 'mood_check_in.g.dart';

/// A daily mood check-in, keyed by [date] (yyyy-MM-dd).
@HiveType(typeId: 2)
class MoodCheckIn extends HiveObject {
  @HiveField(0)
  final String date; // yyyy-MM-dd

  @HiveField(1)
  int moodScore; // 1..10

  @HiveField(2)
  int energyScore; // 1..10

  @HiveField(3)
  int stressScore; // 1..10

  @HiveField(4)
  String note;

  @HiveField(5)
  DateTime createdAt;

  MoodCheckIn({
    required this.date,
    required this.moodScore,
    required this.energyScore,
    required this.stressScore,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
