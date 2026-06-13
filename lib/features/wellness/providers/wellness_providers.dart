import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/premium_service.dart';
import '../data/models/user_profile.dart';
import '../data/models/daily_health_data.dart';
import '../data/models/mood_check_in.dart';
import '../data/models/daily_briefing.dart';
import '../data/repositories/wellness_repository.dart';
import '../data/services/health_data_source.dart';
import '../data/services/health_connect_data_source.dart';
import '../data/services/briefing_service.dart';
import '../data/services/gemini_briefing_service.dart';

/// Firebase availability — set in `main()` based on init result.
final firebaseAvailableProvider = Provider<bool>((_) => true);

/// Local repository — overridden in `main()` with an initialized instance.
final wellnessRepositoryProvider = Provider<WellnessRepository>((ref) {
  throw UnimplementedError('wellnessRepositoryProvider must be overridden');
});

/// Source of health metrics: real Health Connect on Android (which itself
/// falls back to sample data when permission is denied), sample everywhere else.
final healthDataSourceProvider = Provider<HealthDataSource>((ref) {
  if (!kIsWeb && Platform.isAndroid) {
    return HealthConnectDataSource();
  }
  return SampleHealthDataSource();
});

/// Briefing service: tries Gemini (Firebase AI Logic) and falls back to the
/// on-device generator on any error (not enabled, offline, parse failure).
final briefingServiceProvider = Provider<BriefingService>((ref) {
  final gemini = GeminiBriefingService();
  return BriefingService(remote: gemini.generate);
});

// ---- Onboarding flags (persisted in the shared 'settings' box) ------------

class OnboardingState {
  final bool hasOnboarded;
  final bool healthConnected;
  const OnboardingState({required this.hasOnboarded, required this.healthConnected});

  OnboardingState copyWith({bool? hasOnboarded, bool? healthConnected}) =>
      OnboardingState(
        hasOnboarded: hasOnboarded ?? this.hasOnboarded,
        healthConnected: healthConnected ?? this.healthConnected,
      );
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Box _box;
  OnboardingNotifier(this._box)
      : super(OnboardingState(
          hasOnboarded: _box.get('hasOnboarded', defaultValue: false) as bool,
          healthConnected: _box.get('healthConnected', defaultValue: false) as bool,
        ));

  void completeOnboarding() {
    _box.put('hasOnboarded', true);
    state = state.copyWith(hasOnboarded: true);
  }

  void setHealthConnected(bool v) {
    _box.put('healthConnected', v);
    state = state.copyWith(healthConnected: v);
  }

  void reset() {
    _box.put('hasOnboarded', false);
    _box.put('healthConnected', false);
    state = const OnboardingState(hasOnboarded: false, healthConnected: false);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(Hive.box('settings'));
});

// ---- Wellness controller --------------------------------------------------

class WellnessState {
  final UserProfile profile;
  final HealthSnapshot snapshot;
  final MoodCheckIn? mood;
  final DailyBriefing? briefing;
  final bool isConnectingHealth;
  final bool isGeneratingBriefing;

  const WellnessState({
    required this.profile,
    required this.snapshot,
    this.mood,
    this.briefing,
    this.isConnectingHealth = false,
    this.isGeneratingBriefing = false,
  });

  WellnessState copyWith({
    UserProfile? profile,
    HealthSnapshot? snapshot,
    MoodCheckIn? mood,
    DailyBriefing? briefing,
    bool? isConnectingHealth,
    bool? isGeneratingBriefing,
  }) {
    return WellnessState(
      profile: profile ?? this.profile,
      snapshot: snapshot ?? this.snapshot,
      mood: mood ?? this.mood,
      briefing: briefing ?? this.briefing,
      isConnectingHealth: isConnectingHealth ?? this.isConnectingHealth,
      isGeneratingBriefing: isGeneratingBriefing ?? this.isGeneratingBriefing,
    );
  }
}

class WellnessController extends StateNotifier<WellnessState> {
  final Ref ref;

  WellnessController(this.ref)
      : super(_initial(ref.read(wellnessRepositoryProvider))) {
    refreshFromLocal();
  }

  WellnessRepository get _repo => ref.read(wellnessRepositoryProvider);

  static WellnessState _initial(WellnessRepository repo) {
    final today = WellnessRepository.dateKey();
    return WellnessState(
      profile: repo.getProfile(),
      snapshot: repo.snapshotFor(today),
      mood: repo.getMood(today),
      briefing: repo.getBriefing(today),
    );
  }

  /// Re-reads today's data from Hive into state (after a cloud download, etc.).
  void refreshFromLocal() {
    final today = WellnessRepository.dateKey();
    state = state.copyWith(
      profile: _repo.getProfile(),
      snapshot: _repo.snapshotFor(today),
      mood: _repo.getMood(today),
      briefing: _repo.getBriefing(today),
    );
  }

  /// Mirrors the signed-in Firebase user into the local profile.
  Future<void> adoptAuthUser({required String name, required String email}) async {
    final p = _repo.getProfile().copyWith(name: name, email: email);
    await _repo.saveProfile(p);
    state = state.copyWith(profile: p);
  }

  Future<void> updateProfile(String name, String email) async {
    final p = _repo.getProfile().copyWith(name: name, email: email);
    await _repo.saveProfile(p);
    state = state.copyWith(profile: p);
    _maybeSync((s) => s.saveUserProfile());
  }

  /// Pulls metrics from the active [HealthDataSource] and backfills history.
  /// Returns whether permission was granted.
  Future<bool> connectHealth({int days = 14, bool sampleFallback = false}) async {
    state = state.copyWith(isConnectingHealth: true);
    final source =
        sampleFallback ? SampleHealthDataSource() : ref.read(healthDataSourceProvider);
    final granted = await source.requestPermissions();
    final range = await source.fetchRange(days: days);
    for (final d in range) {
      await _repo.saveHealthData(d);
      _maybeSync((s) => s.uploadHealthData(d));
    }
    refreshFromLocal();
    state = state.copyWith(isConnectingHealth: false);
    return granted;
  }

  Future<void> submitMood(int mood, int energy, int stress, String note) async {
    final today = WellnessRepository.dateKey();
    final m = MoodCheckIn(
      date: today,
      moodScore: mood,
      energyScore: energy,
      stressScore: stress,
      note: note,
    );
    await _repo.saveMood(m);
    state = state.copyWith(mood: m);
    _maybeSync((s) => s.uploadMood(m));
    await generateBriefing();
  }

  Future<void> generateBriefing() async {
    state = state.copyWith(isGeneratingBriefing: true);
    final service = ref.read(briefingServiceProvider);
    final briefing = await service.generate(state.snapshot, state.mood);
    await _repo.saveBriefing(briefing);
    state = state.copyWith(briefing: briefing, isGeneratingBriefing: false);
    _maybeSync((s) => s.uploadBriefing(briefing));
  }

  Future<void> wipeLocalData() async {
    await _repo.wipeLocalData();
    refreshFromLocal();
  }

  /// Pushes a single-record sync only when signed in AND premium.
  void _maybeSync(Future<void> Function(SyncService) op) {
    final loggedIn = ref.read(authServiceProvider).isLoggedIn;
    final premium = ref.read(premiumStatusProvider);
    if (loggedIn && premium) {
      // fire-and-forget; errors are non-fatal for the local-first flow.
      op(ref.read(syncServiceProvider)).catchError((_) {});
    }
  }
}

final wellnessControllerProvider =
    StateNotifierProvider<WellnessController, WellnessState>((ref) {
  return WellnessController(ref);
});

// ---- Derived providers ----------------------------------------------------

final weeklySummaryProvider = Provider<WeeklySummary>((ref) {
  ref.watch(wellnessControllerProvider); // recompute on data change
  return ref.read(wellnessRepositoryProvider).weeklySummary();
});

final checkInStreakProvider = Provider<int>((ref) {
  ref.watch(wellnessControllerProvider);
  return ref.read(wellnessRepositoryProvider).checkInStreak();
});

/// Selected bottom-nav tab (0=Home, 1=Briefing, 2=Check-In, 3=Settings).
final bottomTabProvider = StateProvider<int>((ref) => 0);
