import 'package:hive/hive.dart';

part 'daily_briefing.g.dart';

/// The generated daily wellness briefing, keyed by [date] (yyyy-MM-dd).
/// [source] records whether it came from the Gemini API ('gemini') or the
/// on-device fallback algorithm ('local').
@HiveType(typeId: 3)
class DailyBriefing extends HiveObject {
  @HiveField(0)
  final String date; // yyyy-MM-dd

  @HiveField(1)
  String summary;

  @HiveField(2)
  List<String> insights;

  @HiveField(3)
  List<String> recommendations;

  @HiveField(4)
  String source; // 'gemini' | 'local'

  @HiveField(5)
  DateTime createdAt;

  DailyBriefing({
    required this.date,
    required this.summary,
    required this.insights,
    required this.recommendations,
    this.source = 'local',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
