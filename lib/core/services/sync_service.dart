import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import '../../features/wellness/data/models/daily_health_data.dart';
import '../../features/wellness/data/models/mood_check_in.dart';
import '../../features/wellness/data/models/daily_briefing.dart';
import '../../features/wellness/data/repositories/wellness_repository.dart';
import '../../features/wellness/providers/wellness_providers.dart';

/// Firestore sync for Arcova Well.
///
/// Schema (uid-scoped):
/// ```
/// users/{uid}/
///   (doc): name, email, timezone, premiumStatus, lastLoginAt
///   healthData/{yyyy-MM-dd}
///   moodCheckIns/{yyyy-MM-dd}
///   briefings/{yyyy-MM-dd}
/// ```
/// Conflict resolution mirrors the original `updatedAt`/`createdAt` pattern:
/// local writes win when newer than the cloud copy.
class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;

  SyncService(this._ref);

  String? get _userId => _ref.read(authServiceProvider).userId;
  WellnessRepository get _repo => _ref.read(wellnessRepositoryProvider);

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  // ---- Upload --------------------------------------------------------------

  /// Pushes all locally stored wellness data to Firestore.
  /// Returns the number of documents written.
  Future<int> uploadAll() async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Sign-in required');

    final batch = _firestore.batch();
    int writes = 0;

    for (final h in _repo.getAllHealthData()) {
      batch.set(userDoc.collection('healthData').doc(h.date), _healthToMap(h),
          SetOptions(merge: true));
      writes++;
    }

    // Mood + briefings: iterate stored keys via the repository's boxes.
    for (final date in _repo.allMoodDates()) {
      final m = _repo.getMood(date);
      if (m != null) {
        batch.set(userDoc.collection('moodCheckIns').doc(date), _moodToMap(m),
            SetOptions(merge: true));
        writes++;
      }
    }
    for (final date in _repo.allBriefingDates()) {
      final b = _repo.getBriefing(date);
      if (b != null) {
        batch.set(userDoc.collection('briefings').doc(date), _briefingToMap(b),
            SetOptions(merge: true));
        writes++;
      }
    }

    await batch.commit();
    return writes;
  }

  /// Single-record upserts (called after each local write).
  Future<void> uploadHealthData(DailyHealthData h) async {
    await _userDoc?.collection('healthData').doc(h.date).set(_healthToMap(h),
        SetOptions(merge: true));
  }

  Future<void> uploadMood(MoodCheckIn m) async {
    await _userDoc?.collection('moodCheckIns').doc(m.date).set(_moodToMap(m),
        SetOptions(merge: true));
  }

  Future<void> uploadBriefing(DailyBriefing b) async {
    await _userDoc?.collection('briefings').doc(b.date).set(_briefingToMap(b),
        SetOptions(merge: true));
  }

  // ---- Delete --------------------------------------------------------------

  /// Deletes all cloud wellness data for the current user (health, mood,
  /// briefings, and the user profile document).
  Future<void> deleteAll() async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Sign-in required');

    final batch = _firestore.batch();

    final health = await userDoc.collection('healthData').get();
    for (final doc in health.docs) {
      batch.delete(doc.reference);
    }
    final moods = await userDoc.collection('moodCheckIns').get();
    for (final doc in moods.docs) {
      batch.delete(doc.reference);
    }
    final briefings = await userDoc.collection('briefings').get();
    for (final doc in briefings.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    await userDoc.delete();
  }

  // ---- Download ------------------------------------------------------------

  /// Pulls all cloud wellness data into local Hive. Returns documents restored.
  Future<int> downloadAll() async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Sign-in required');

    int count = 0;

    final health = await userDoc.collection('healthData').get();
    for (final doc in health.docs) {
      await _repo.saveHealthData(_mapToHealth(doc.id, doc.data()));
      count++;
    }

    final moods = await userDoc.collection('moodCheckIns').get();
    for (final doc in moods.docs) {
      await _repo.saveMood(_mapToMood(doc.id, doc.data()));
      count++;
    }

    final briefings = await userDoc.collection('briefings').get();
    for (final doc in briefings.docs) {
      await _repo.saveBriefing(_mapToBriefing(doc.id, doc.data()));
      count++;
    }

    return count;
  }

  /// Saves/updates the user profile document.
  Future<void> saveUserProfile() async {
    final uid = _userId;
    if (uid == null) return;
    final user = _ref.read(authServiceProvider).currentUser;
    final profile = _repo.getProfile();

    await _firestore.collection('users').doc(uid).set({
      'name': user?.displayName ?? profile.name,
      'email': user?.email ?? profile.email,
      'timezone': profile.timezone,
      'premiumStatus': profile.premiumStatus,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---- Mappers -------------------------------------------------------------

  Map<String, dynamic> _healthToMap(DailyHealthData h) => {
        'sleepDurationMinutes': h.sleepDurationMinutes,
        'steps': h.steps,
        'activeMinutes': h.activeMinutes,
        'restingHeartRate': h.restingHeartRate,
        'updatedAt': Timestamp.fromDate(h.updatedAt),
        if (h.weight != null) 'weight': h.weight,
        if (h.bodyMassIndex != null) 'bodyMassIndex': h.bodyMassIndex,
        if (h.bodyFatPercentage != null) 'bodyFatPercentage': h.bodyFatPercentage,
      };

  DailyHealthData _mapToHealth(String date, Map<String, dynamic> m) => DailyHealthData(
        date: date,
        sleepDurationMinutes: (m['sleepDurationMinutes'] ?? 0) as int,
        steps: (m['steps'] ?? 0) as int,
        activeMinutes: (m['activeMinutes'] ?? 0) as int,
        restingHeartRate: (m['restingHeartRate'] ?? 0) as int,
        updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        weight: (m['weight'] as num?)?.toDouble(),
        bodyMassIndex: (m['bodyMassIndex'] as num?)?.toDouble(),
        bodyFatPercentage: (m['bodyFatPercentage'] as num?)?.toDouble(),
      );

  Map<String, dynamic> _moodToMap(MoodCheckIn m) => {
        'moodScore': m.moodScore,
        'energyScore': m.energyScore,
        'stressScore': m.stressScore,
        'note': m.note,
        'createdAt': Timestamp.fromDate(m.createdAt),
      };

  MoodCheckIn _mapToMood(String date, Map<String, dynamic> m) => MoodCheckIn(
        date: date,
        moodScore: (m['moodScore'] ?? 5) as int,
        energyScore: (m['energyScore'] ?? 5) as int,
        stressScore: (m['stressScore'] ?? 5) as int,
        note: (m['note'] ?? '') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> _briefingToMap(DailyBriefing b) => {
        'summary': b.summary,
        'insights': b.insights,
        'recommendations': b.recommendations,
        'source': b.source,
        'createdAt': Timestamp.fromDate(b.createdAt),
      };

  DailyBriefing _mapToBriefing(String date, Map<String, dynamic> m) => DailyBriefing(
        date: date,
        summary: (m['summary'] ?? '') as String,
        insights: List<String>.from(m['insights'] ?? const []),
        recommendations: List<String>.from(m['recommendations'] ?? const []),
        source: (m['source'] ?? 'local') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

enum SyncStatus { idle, syncing, success, error }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);
