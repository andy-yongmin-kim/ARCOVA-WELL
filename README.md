# Arcova Well — Your Personal AI Wellness Companion

An intelligent health and wellness app that combines daily health metrics (sleep, steps, heart rate) with mood tracking and AI-powered personalized briefings.

## Features

- **Health Metrics**: Reads sleep duration, steps, active minutes, and resting heart rate via Android Health Connect
- **Daily Mood Check-in**: Track your emotional state with scores for mood, energy, and stress
- **AI-Powered Briefing**: Get personalized daily wellness insights powered by Google Gemini, with on-device fallback
- **Offline-First**: All data stored locally in Hive; cloud backup via Firestore for premium users
- **Premium Features**: Cloud sync and backup behind a paywall (in-app purchase)

## Build & Run

### Prerequisites
- Flutter 3.10+
- Android SDK 26+ (for Health Connect on real devices)
- Emulator: SDK API 30+ recommended

### Commands

```bash
# Install dependencies
flutter pub get

# Run on Android emulator
flutter run -d emulator-5554

# Static analysis
flutter analyze

# Run unit tests
flutter test

# Build release APK
flutter build apk --release
```

## Architecture

```
lib/
├── main.dart                    # Bootstrap: Firebase, Hive, providers
├── app.dart                     # ArcovaWellApp theme and navigation
├── core/
│   ├── services/                # Auth, sync, payment, premium logic
│   ├── theme/                   # Material 3 theme (navy/sage/gold)
│   └── providers/               # Core Riverpod providers
└── features/wellness/
    ├── data/
    │   ├── models/              # UserProfile, DailyHealthData, etc. (Hive)
    │   ├── repositories/        # WellnessRepository (Hive CRUD + logic)
    │   └── services/            # HealthConnect, Firestore sync, Gemini
    ├── providers/               # Riverpod wellness state
    └── presentation/
        ├── screens/             # Dashboard, briefing, mood, settings, etc.
        └── widgets/             # Reusable UI components
```

### Data Flow
1. **Local Storage**: All data persists in Hive (offline-first)
2. **Health Metrics**: HealthConnectDataSource on Android; sample data on iOS/web
3. **Briefing Generation**: Tries Firebase AI Logic (Gemini) → falls back to on-device generator
4. **Cloud Sync**: WellnessController syncs to Firestore when signed-in + premium

## External Setup Required

These steps must be completed before the app can run with full features:

### 1. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create or select project (e.g., "Arcova Well")
3. Project Settings → Your Apps → **Add app** → Android
   - Package name: `com.arcova.well`
   - Get debug SHA-1: Run `cd android && ./gradlew signingReport`
4. Download `google-services.json` → replace `android/app/google-services.json`
5. Enable **Firebase Auth** (Google sign-in)
6. Create **Firestore Database** (production mode):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```
7. (Optional) Enable **AI Logic** for live Gemini briefings (Blaze plan required)

### 2. Android Health Connect

- On a real Android 14+ device, Health Connect is built-in
- The app requests permission to read health data on first launch
- On emulators without Health Connect, sample data is used

### 3. Icons & Splash

Replace `assets/icon/app_icon.png` with Arcova logo, then:
```bash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

### 4. Pre-Release Checks

- **`kTestMode` flag**: Set to `false` in `lib/features/wellness/presentation/screens/settings_screen.dart` before release
- **Privacy policy**: Required for Health Connect and Play Store submission

## Testing

```bash
# Unit tests (BriefingGenerator logic, no Firebase/Hive)
flutter test

# Smoke test (Dashboard renders over a temp Hive store)
flutter test test/smoke_test.dart

# Hot reload during development
r  # in the running flutter console
```

## Package Structure

- **Package name (internal)**: `arcova_well` (Dart/pubspec)
- **Application ID (Android)**: `com.arcova.well`
- **User-facing brand**: Arcova Well

## Notes

- This app was migrated from a Korean link-saver project ("한곳에 / OnePlace"); some legacy docs may still reference the old architecture
- Firestore schema is uid-scoped at `users/{userId}/...` for privacy
- In-app purchase product ID: `arcova_premium_unlock`

## Support & Feedback

For issues or feature requests, refer to the CLAUDE.md file for detailed architecture notes and common troubleshooting steps.
