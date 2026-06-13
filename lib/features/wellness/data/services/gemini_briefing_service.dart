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
        'diagnose or give medical advice. Base everything on the provided trends. '
        'Keep insights factual and recommendations small, practical, and achievable.',
      ),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'summary': Schema.string(
                description: 'One or two encouraging sentences summarizing the day.'),
            'insights': Schema.array(
              items: Schema.string(),
              description: '3-5 short factual observations about the trends.',
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

  Future<DailyBriefing> generate(HealthSnapshot s, MoodCheckIn? mood) async {
    final t = s.today;
    final moodLine = mood == null
        ? 'No mood check-in today.'
        : 'Mood ${mood.moodScore}/10, energy ${mood.energyScore}/10, '
            'stress ${mood.stressScore}/10. Note: "${mood.note}".';

    final prompt = '''
Today's wellness data (compare each metric to its 7-day average):
- Sleep: ${fmtMinutes(t.sleepDurationMinutes)} (avg ${fmtMinutes(s.sleepSevenDayAverage)})
- Steps: ${t.steps} (avg ${s.stepsSevenDayAverage})
- Active minutes: ${t.activeMinutes}
- Resting heart rate: ${t.restingHeartRate} bpm (avg ${s.restingHrSevenDayAverage} bpm)
- $moodLine

Return a JSON briefing with "summary", "insights", and exactly 3 "recommendations".
''';

    final response = await _build().generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw StateError('Empty Gemini response');
    }

    final json = jsonDecode(text) as Map<String, dynamic>;
    final insights = List<String>.from(json['insights'] ?? const []);
    final recommendations = List<String>.from(json['recommendations'] ?? const []);
    if (insights.isEmpty || recommendations.isEmpty) {
      throw StateError('Incomplete Gemini briefing');
    }

    return DailyBriefing(
      date: t.date,
      summary: (json['summary'] ?? '').toString(),
      insights: insights,
      recommendations: recommendations,
      source: 'gemini',
    );
  }
}
