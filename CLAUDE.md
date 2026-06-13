# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All commands run from `/Users/andy/Desktop/project flutter/arcova-well/`.

```bash
flutter run                    # Run on connected device/emulator (Android device needed for Health Connect)
flutter analyze                # Lint check
flutter pub get                # Install dependencies
flutter clean                  # Clean build artifacts
flutter test                   # Run unit tests (BriefingGenerator logic)

# Regenerate Hive type adapters (run after modifying @HiveType models)
flutter pub run build_runner build --delete-conflicting-outputs

# Regenerate app icons and splash screen (after replacing assets/icon/*)
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create

# Release builds
flutter build apk --release
```

## Product

**Arcova Well** — an AI wellness companion. It reads sleep / steps / active minutes /
resting heart-rate (via Android Health Connect) plus a daily mood check-in, and produces a
personalized **daily briefing**. Offline-first (Hive), with optional cloud backup (Firestore)
behind a premium paywall. The Dart package is now named `arcova_well` (renamed from `one_place`);
the user-facing identity, `applicationId` (`com.arcova.well`), and theme are all Arcova Well.

> This app was migrated in place from a Korean link-saver ("한곳에 / OnePlace"). Some docs
> under `docs/` still describe the old product and are stale.

## Architecture (Clean-ish + Riverpod)

```
lib/
├── main.dart                  # Bootstrap: Firebase, Hive (4 adapters), 'settings' box, ProviderScope
├── app.dart                   # ArcovaWellApp: theme watcher, home = RootScreen
├── core/
│   ├── services/              # auth_service, sync_service, payment_service, premium_service
│   ├── theme/                 # AppTheme (Material 3, navy/sage/gold, Pretendard)
│   └── providers/             # themeModeProvider
└── features/wellness/
    ├── data/
    │   ├── models/            # UserProfile(0), DailyHealthData(1), MoodCheckIn(2), DailyBriefing(3) — Hive
    │   ├── repositories/      # WellnessRepository — all Hive CRUD + 7-day avg / streak / weekly aggregation
    │   └── services/          # health_data_source (Sample), health_connect_data_source,
    │                          #   briefing_generator (on-device), gemini_briefing_service, briefing_service
    ├── providers/             # wellness_providers — repo override, WellnessController, derived providers
    └── presentation/
        ├── screens/           # root, welcome, sign_in, onboarding, health_permission, main_shell,
        │                      #   dashboard, briefing, mood_check_in, settings, weekly_summary, medical_disclaimer
        └── widgets/           # health_stat_card
```

### Data flow

- **Source of truth**: Hive (offline-first). Firestore is a backup layer, synced only when
  signed-in **and** premium (`WellnessController._maybeSync`).
- **Health metrics**: `healthDataSourceProvider` → `HealthConnectDataSource` on Android
  (falls back to `SampleHealthDataSource` when permission denied / no data), Sample elsewhere.
  `connectHealth()` backfills a date *range* so 7-day averages and streaks aren't empty.
- **Briefing**: `BriefingService` tries `GeminiBriefingService` (Gemini via **Firebase AI
  Logic** — no raw key in the app) and falls back to the on-device `BriefingGenerator` on any
  error. Result cached to Hive + Firestore with a `source` field (`gemini` | `local`).

### Firestore schema (uid-scoped; existing `users/{userId}/{document=**}` owner-only rule covers it)

```
users/{uid}/
  (doc): name, email, timezone, premiumStatus, lastLoginAt
  healthData/{yyyy-MM-dd}, moodCheckIns/{yyyy-MM-dd}, briefings/{yyyy-MM-dd}
```

### Key providers (Riverpod)

| Provider | Type | Purpose |
|---|---|---|
| `wellnessControllerProvider` | StateNotifier<WellnessState> | profile, health snapshot, mood, briefing + all mutations |
| `wellnessRepositoryProvider` | Provider (overridden in main) | Hive repository |
| `healthDataSourceProvider` | Provider | Health Connect / sample selection |
| `briefingServiceProvider` | Provider | Gemini + on-device fallback |
| `onboardingProvider` | StateNotifier<OnboardingState> | hasOnboarded / healthConnected (in 'settings' box) |
| `weeklySummaryProvider`, `checkInStreakProvider`, `bottomTabProvider` | derived | dashboard/weekly |
| `premiumStatusProvider`, `currentUserProvider`, `themeModeProvider` | core | reused |

## In-App Purchase

Product ID: `arcova_premium_unlock` (`payment_service.dart`). Gates cloud sync.

## Critical pre-release flag

`settings_screen.dart` top: `const bool kTestMode = false;` — set correctly. Do not change back.

## External setup required before a real build/run

1. **Android** — `android/app/google-services.json` is already registered for `com.arcova.well`.
2. **iOS Firebase** — `ios/Runner/GoogleService-Info.plist` is **stale** (still targets
   `com.oneplace.onePlace` and has no `CLIENT_ID`/`REVERSED_CLIENT_ID`). Must be replaced:
   - Register `com.arcova.well` as an iOS app in the Firebase console.
   - Download the new `GoogleService-Info.plist` and replace the committed file.
   - Add the `REVERSED_CLIENT_ID` value from that file as a URL scheme in `ios/Runner/Info.plist`
     under `CFBundleURLSchemes` (required for Google Sign-In redirect on iOS).
   - Until this is done, Firebase Auth and Google Sign-In **will not function on iOS**.
3. Enable Firebase **AI Logic** (Gemini) on the **Blaze** plan for live briefings.
4. Replace `assets/icon/app_icon.png` + splash with Arcova artwork, then regenerate icons/splash.
5. Native build/run requires a **real Android device** (Health Connect isn't on most emulators).

## Android JVM targets

All Android modules are pinned to **Java 17** (`android/build.gradle.kts` `subprojects` +
`android/app/build.gradle.kts`) because Flutter plugins ship mixed Java targets (health=11,
device_info_plus=17) and AGP rejects per-module Java/Kotlin mismatches.
