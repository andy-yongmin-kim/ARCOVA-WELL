import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/daily_health_data.dart';
import '../models/mood_check_in.dart';
import '../models/daily_briefing.dart';

/// Local (Hive) source of truth for all wellness data.
/// Computes rolling 7-day averages, the check-in streak, and weekly
/// aggregates from stored history — none of which the prototype persisted.
class WellnessRepository {
  static const String _profileBoxName = 'profile';
  static const String _healthBoxName = 'health_data';
  static const String _moodBoxName = 'mood_check_ins';
  static const String _briefingBoxName = 'briefings';
  static const String _profileKey = 'me';

  late Box<UserProfile> _profileBox;
  late Box<DailyHealthData> _healthBox;
  late Box<MoodCheckIn> _moodBox;
  late Box<DailyBriefing> _briefingBox;

  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  /// Date key (yyyy-MM-dd) for a given day, defaulting to today.
  static String dateKey([DateTime? day]) => _fmt.format(day ?? DateTime.now());

  Future<void> init() async {
    _profileBox = await Hive.openBox<UserProfile>(_profileBoxName);
    _healthBox = await Hive.openBox<DailyHealthData>(_healthBoxName);
    _moodBox = await Hive.openBox<MoodCheckIn>(_moodBoxName);
    _briefingBox = await Hive.openBox<DailyBriefing>(_briefingBoxName);
  }

  // ---- Profile -------------------------------------------------------------

  UserProfile getProfile() {
    return _profileBox.get(_profileKey) ?? UserProfile(id: _profileKey);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _profileBox.put(_profileKey, profile);
  }

  // ---- Health data ---------------------------------------------------------

  Future<void> saveHealthData(DailyHealthData data) async {
    data.updatedAt = DateTime.now();
    await _healthBox.put(data.date, data);
  }

  DailyHealthData? getHealthData(String date) => _healthBox.get(date);

  /// All stored health records, newest first.
  List<DailyHealthData> getAllHealthData() {
    final list = _healthBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Today's metrics + rolling 7-day averages (computed from the 7 days
  /// strictly before [date]). Falls back to a zeroed record / today's own
  /// value when there is no prior history, so comparisons stay neutral.
  /// Body metrics (weight/BMI/body fat) are point-in-time values from the
  /// most recent record that carries them.
  HealthSnapshot snapshotFor([String? date]) {
    final key = date ?? dateKey();
    final today = _healthBox.get(key) ?? DailyHealthData(date: key);

    final prior = _healthBox.values
        .where((d) => d.date.compareTo(key) < 0)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final window = prior.take(7).toList();

    int avg(int Function(DailyHealthData) sel, int fallback) {
      if (window.isEmpty) return fallback;
      final total = window.fold<int>(0, (s, d) => s + sel(d));
      return (total / window.length).round();
    }

    // Surface the latest non-null body metric from today or any prior record.
    final allRecords = [today, ...prior];
    double? latestValue<T>(double? Function(DailyHealthData) sel) {
      for (final r in allRecords) {
        final v = sel(r);
        if (v != null) return v;
      }
      return null;
    }

    return HealthSnapshot(
      today: today,
      sleepSevenDayAverage: avg((d) => d.sleepDurationMinutes, today.sleepDurationMinutes),
      stepsSevenDayAverage: avg((d) => d.steps, today.steps),
      restingHrSevenDayAverage: avg((d) => d.restingHeartRate, today.restingHeartRate),
      latestWeight: latestValue((d) => d.weight),
      latestBmi: latestValue((d) => d.bodyMassIndex),
      latestBodyFat: latestValue((d) => d.bodyFatPercentage),
    );
  }

  // ---- Mood ----------------------------------------------------------------

  Future<void> saveMood(MoodCheckIn mood) async {
    await _moodBox.put(mood.date, mood);
  }

  MoodCheckIn? getMood(String date) => _moodBox.get(date);

  Iterable<String> allMoodDates() => _moodBox.keys.cast<String>();

  /// Consecutive days (ending today) that have a mood check-in.
  int checkInStreak() {
    int streak = 0;
    var day = DateTime.now();
    while (_moodBox.get(dateKey(day)) != null) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---- Briefing ------------------------------------------------------------

  Future<void> saveBriefing(DailyBriefing briefing) async {
    await _briefingBox.put(briefing.date, briefing);
  }

  DailyBriefing? getBriefing(String date) => _briefingBox.get(date);

  Iterable<String> allBriefingDates() => _briefingBox.keys.cast<String>();

  // ---- Weekly summary ------------------------------------------------------

  /// Aggregates the last 7 days of stored history.
  WeeklySummary weeklySummary() {
    final today = DateTime.now();
    final keys = List.generate(7, (i) => dateKey(today.subtract(Duration(days: i))));

    final health = keys.map((k) => _healthBox.get(k)).whereType<DailyHealthData>().toList();
    final moods = keys.map((k) => _moodBox.get(k)).whereType<MoodCheckIn>().toList();

    int avgInt(Iterable<int> xs) {
      final l = xs.toList();
      if (l.isEmpty) return 0;
      return (l.reduce((a, b) => a + b) / l.length).round();
    }

    double avgDouble(Iterable<int> xs) {
      final l = xs.toList();
      if (l.isEmpty) return 0;
      return l.reduce((a, b) => a + b) / l.length;
    }

    // Best day = highest mood score; tie-break to most steps.
    String? bestDay;
    int bestScore = -1;
    for (final m in moods) {
      if (m.moodScore > bestScore) {
        bestScore = m.moodScore;
        bestDay = m.date;
      }
    }
    if (bestDay == null && health.isNotEmpty) {
      health.sort((a, b) => b.steps.compareTo(a.steps));
      bestDay = health.first.date;
    }

    return WeeklySummary(
      averageSleepMinutes: avgInt(health.map((d) => d.sleepDurationMinutes)),
      averageSteps: avgInt(health.map((d) => d.steps)),
      averageMood: avgDouble(moods.map((m) => m.moodScore)),
      bestDayLabel: bestDay == null ? '—' : DateFormat('EEEE').format(DateTime.parse(bestDay)),
      daysLogged: {...health.map((d) => d.date), ...moods.map((m) => m.date)}.length,
    );
  }

  // ---- Reset ---------------------------------------------------------------

  Future<void> wipeLocalData() async {
    await _healthBox.clear();
    await _moodBox.clear();
    await _briefingBox.clear();
    await _profileBox.clear();
  }
}

/// Computed weekly aggregate for the Weekly Summary screen.
class WeeklySummary {
  final int averageSleepMinutes;
  final int averageSteps;
  final double averageMood;
  final String bestDayLabel;
  final int daysLogged;

  const WeeklySummary({
    required this.averageSleepMinutes,
    required this.averageSteps,
    required this.averageMood,
    required this.bestDayLabel,
    required this.daysLogged,
  });
}
