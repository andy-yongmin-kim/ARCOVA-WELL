import '../models/daily_health_data.dart';
import '../models/mood_check_in.dart';
import '../models/daily_briefing.dart';

/// On-device, rule-based briefing generator. Ported from the original Kotlin
/// `WellnessRepositoryImpl.generateBriefingState`. Used offline and as the
/// fallback when the Gemini API is unavailable.
class BriefingGenerator {
  static DailyBriefing generate(HealthSnapshot snapshot, MoodCheckIn? mood) {
    final data = snapshot.today;
    final insights = <String>[];
    final recommendations = <String>[];

    // 1. Sleep insight
    if (data.sleepDurationMinutes < snapshot.sleepSevenDayAverage) {
      final diff = snapshot.sleepSevenDayAverage - data.sleepDurationMinutes;
      final diffString = diff >= 60 ? '${diff ~/ 60}h ${diff % 60}m' : '${diff}m';
      insights.add('Your sleep was lower than your 7-day average by $diffString.');
    } else {
      insights.add(
          'Your sleep was at or above your 7-day average. Consistent sleep supports daily focus.');
    }

    // 2. Activity insight
    if (data.steps < snapshot.stepsSevenDayAverage) {
      insights.add(
          'Your step count is currently tracking below your average of ${snapshot.stepsSevenDayAverage} steps.');
    } else {
      insights.add(
          'You are maintaining steady activity, tracking at or above your 7-day step average.');
    }

    // 3. Resting HR insight
    if (data.restingHeartRate > snapshot.restingHrSevenDayAverage + 2) {
      insights.add(
          'Your resting heart rate (${data.restingHeartRate} bpm) is slightly above your recent baseline.');
    } else if (data.restingHeartRate < snapshot.restingHrSevenDayAverage - 2) {
      insights.add(
          'Your resting heart rate (${data.restingHeartRate} bpm) is tracking below your recent baseline.');
    } else {
      insights.add('Your resting heart rate is stable and matching your 7-day average.');
    }

    // 4. Mood insight
    if (mood != null) {
      insights.add(
          'You reported a mood score of ${mood.moodScore}/10 and energy of ${mood.energyScore}/10.');
      if (mood.stressScore >= 7) {
        insights.add(
            'Your check-in indicates higher stress today. Moderating demanding tasks may be beneficial.');
      }
    }

    // Recommendations (3 practical actions)
    if (data.sleepDurationMinutes < snapshot.sleepSevenDayAverage ||
        (mood != null && mood.energyScore <= 4)) {
      recommendations.add('Consider an earlier bedtime tonight to re-align with your baseline.');
      recommendations
          .add('Opt for light movement, like stretching or a gentle walk, over intense workouts.');
    } else {
      recommendations.add('Consider adding a 20-minute brisk walk to keep your activity levels up.');
      recommendations.add(
          "Your metrics are stable. It's a good day to focus on your primary lifestyle rhythms.");
    }

    if (data.restingHeartRate > snapshot.restingHrSevenDayAverage + 2 ||
        (mood != null && mood.stressScore >= 7)) {
      recommendations.add('Try a 5-minute boxed breathing exercise to encourage relaxation.');
    } else {
      recommendations
          .add('Aim to drink a glass of water with each meal to maintain consistent hydration.');
    }

    while (recommendations.length > 3) {
      recommendations.removeLast();
    }
    if (recommendations.length < 3) {
      recommendations.add('Take a brief screen break every hour.');
    }

    return DailyBriefing(
      date: data.date,
      summary:
          'Your wellness data has been processed. Based on your 7-day trends, here are your personalized insights and actions for the day.',
      insights: insights,
      recommendations: recommendations,
      source: 'local',
    );
  }
}
