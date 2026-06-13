// Unit tests for the on-device briefing generator (pure logic, no Hive/Firebase).

import 'package:flutter_test/flutter_test.dart';
import 'package:arcova_well/features/wellness/data/models/daily_health_data.dart';
import 'package:arcova_well/features/wellness/data/models/mood_check_in.dart';
import 'package:arcova_well/features/wellness/data/services/briefing_generator.dart';

void main() {
  group('BriefingGenerator', () {
    HealthSnapshot snapshot({
      required int sleep,
      required int sleepAvg,
      required int steps,
      required int stepsAvg,
      required int rhr,
      required int rhrAvg,
    }) {
      return HealthSnapshot(
        today: DailyHealthData(
          date: '2026-06-07',
          sleepDurationMinutes: sleep,
          steps: steps,
          activeMinutes: 30,
          restingHeartRate: rhr,
        ),
        sleepSevenDayAverage: sleepAvg,
        stepsSevenDayAverage: stepsAvg,
        restingHrSevenDayAverage: rhrAvg,
      );
    }

    test('always produces exactly 3 recommendations', () {
      final b = BriefingGenerator.generate(
        snapshot(sleep: 378, sleepAvg: 420, steps: 4321, stepsAvg: 6100, rhr: 71, rhrAvg: 68),
        null,
      );
      expect(b.recommendations.length, 3);
      expect(b.source, 'local');
    });

    test('flags below-average sleep', () {
      final b = BriefingGenerator.generate(
        snapshot(sleep: 360, sleepAvg: 420, steps: 6200, stepsAvg: 6100, rhr: 68, rhrAvg: 68),
        null,
      );
      expect(b.insights.any((i) => i.contains('lower than your 7-day average')), isTrue);
    });

    test('includes a mood insight and high-stress note when stress is high', () {
      final b = BriefingGenerator.generate(
        snapshot(sleep: 430, sleepAvg: 420, steps: 6200, stepsAvg: 6100, rhr: 68, rhrAvg: 68),
        MoodCheckIn(date: '2026-06-07', moodScore: 5, energyScore: 4, stressScore: 8, note: ''),
      );
      expect(b.insights.any((i) => i.contains('mood score')), isTrue);
      expect(b.insights.any((i) => i.contains('higher stress')), isTrue);
    });
  });
}
