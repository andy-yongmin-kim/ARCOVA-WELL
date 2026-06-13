import '../models/daily_health_data.dart';
import '../models/mood_check_in.dart';
import '../models/daily_briefing.dart';
import 'briefing_generator.dart';

/// Produces the daily briefing. Tries a remote generator (Gemini via Firebase
/// AI Logic — wired in Phase E) and falls back to the on-device
/// [BriefingGenerator] when it is unavailable or errors.
class BriefingService {
  /// Optional remote generator. When null, only the on-device algorithm runs.
  final Future<DailyBriefing> Function(HealthSnapshot, MoodCheckIn?)? remote;

  const BriefingService({this.remote});

  Future<DailyBriefing> generate(HealthSnapshot snapshot, MoodCheckIn? mood) async {
    final r = remote;
    if (r != null) {
      try {
        return await r(snapshot, mood);
      } catch (_) {
        // fall through to local
      }
    }
    return BriefingGenerator.generate(snapshot, mood);
  }
}
