import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/daily_health_data.dart';
import '../models/mood_check_in.dart';
import '../models/daily_briefing.dart';
import 'format_minutes.dart';

/// Generates the daily briefing with Gemini via **Firebase AI Logic**
/// (the Google AI backend). No raw API key ships in the app — requests are
/// authenticated through Firebase (and App Check, when enabled).
///
/// Requires the Firebase project to be on the Blaze plan with the AI Logic /
/// Gemini API enabled. Any failure (not enabled, offline, parse error) throws,
/// and [BriefingService] falls back to the on-device generator.
class GeminiBriefingService {
  static const String _model = 'gemini-2.5-flash';

  GenerativeModel _build() {
    return FirebaseAI.googleAI().generativeModel(
      model: _model,
      systemInstruction: Content.text(
        'You are a supportive wellness coach. You are NOT a doctor and must not '
        'diagnose or give medical advice. Use only the provided data. '
        'Handle missing metrics briefly and without speculation. '
        'Keep insights factual and recommendations small, practical, and achievable.',
      ),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'summary': Schema.string(
                description: 'Exactly one encouraging sentence summarizing the day.'),
            'insights': Schema.array(
              items: Schema.string(),
              description: 'Exactly 3 short factual observations about the trends.',
            ),
            'recommendations': Schema.array(
              items: Schema.string(),
              description: 'Exactly 3 small, practical actions for today.',
            ),
          },
          propertyOrdering: ['summary', 'insights', 'recommendations'],
        ),
      ),
    );
  }

  /// Builds a structured JSON payload string from the snapshot and mood.
  String _buildPayload(HealthSnapshot s, MoodCheckIn? mood) {
    final t = s.today;
    final data = <String, dynamic>{
      'today': {
        'sleep_minutes': t.sleepDurationMinutes,
        'steps': t.steps,
        'active_minutes': t.activeMinutes,
        'resting_heart_rate_bpm': t.restingHeartRate,
      },
      'seven_day_averages': {
        'sleep_minutes': s.sleepSevenDayAverage,
        'steps': s.stepsSevenDayAverage,
        'resting_heart_rate_bpm': s.restingHrSevenDayAverage,
      },
      'mood': mood == null
          ? null
          : {
              'mood_score': mood.moodScore,
              'energy_score': mood.energyScore,
              'stress_score': mood.stressScore,
              'note': mood.note,
            },
      'missing_data': {
        'sleep': t.sleepDurationMinutes == 0,
        'steps': t.steps == 0,
        'active_minutes': t.activeMinutes == 0,
        'heart_rate': t.restingHeartRate == 0,
        'mood': mood == null,
      },
    };

    // Include optional body metrics only when available.
    final body = <String, dynamic>{};
    if (s.latestWeight != null) body['weight_kg'] = s.latestWeight;
    if (s.latestBmi != null) body['bmi'] = s.latestBmi;
    if (s.latestBodyFat != null) body['body_fat_percent'] = s.latestBodyFat;
    if (body.isNotEmpty) data['body_metrics'] = body;

    return jsonEncode(data);
  }

  Future<DailyBriefing> generate(HealthSnapshot s, MoodCheckIn? mood) async {
    final payload = _buildPayload(s, mood);

    final prompt = '''
Wellness data payload (JSON):
$payload

Formatted for readability:
- Sleep: ${fmtMinutes(s.today.sleepDurationMinutes)} (7-day avg ${fmtMinutes(s.sleepSevenDayAverage)})
- Steps: ${s.today.steps} (avg ${s.stepsSevenDayAverage})
- Active minutes: ${s.today.activeMinutes}
- Resting HR: ${s.today.restingHeartRate} bpm (avg ${s.restingHrSevenDayAverage} bpm)
${mood == null ? '- Mood: not logged today' : '- Mood ${mood.moodScore}/10, energy ${mood.energyScore}/10, stress ${mood.stressScore}/10'}

Return a briefing with exactly 1 summary sentence, exactly 3 insights, and exactly 3 recommendations.
''';

    final response = await _build().generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw StateError('Empty Gemini response');
    }

    final json = jsonDecode(text) as Map<String, dynamic>;
    final rawInsights = List<String>.from(json['insights'] ?? const []);
    final rawRecs = List<String>.from(json['recommendations'] ?? const []);

    if (rawInsights.isEmpty || rawRecs.isEmpty) {
      throw StateError('Incomplete Gemini briefing');
    }

    // Truncate to exactly 3 if the model returned more (avoids throw for minor overcount).
    final insights = rawInsights.take(3).toList();
    final recommendations = rawRecs.take(3).toList();

    return DailyBriefing(
      date: s.today.date,
      summary: (json['summary'] ?? '').toString(),
      insights: insights,
      recommendations: recommendations,
      source: 'gemini',
    );
  }
}
