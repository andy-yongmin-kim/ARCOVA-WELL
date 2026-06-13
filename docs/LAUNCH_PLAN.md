# Arcova Well Launch Plan

## Goal
Ship an iOS-first Arcova Well release that is honest about current capabilities, connected to Firebase, and safe for production.

## Product Scope
- iOS v1: mood check-ins, daily AI briefing, local Hive storage, Google sign-in, Firestore backup/restore, premium unlock
- Android follow-up: Health Connect integration and production signing
- Deferred: Apple Health / HealthKit parity, deeper health analytics, platform-specific polish

## Work Plan

### 1. iOS-first product cleanup
- Remove Android-only health claims from iOS-facing UX
- Make onboarding and settings copy reflect mood + AI first
- Ensure the app does not imply real iOS health ingestion before HealthKit exists

### 2. Firebase / GCP completion
- Refresh FlutterFire configuration for the current iOS bundle ID
- Replace stale `GoogleService-Info.plist`
- Add iOS Google Sign-In URL scheme configuration
- Verify Firebase Auth, Firestore, and Gemini fallback on iPhone

### 3. Release safety
- Disable premium test bypass
- Verify purchase, restore, and premium gating flows
- Confirm backup and restore only work when intended

### 4. Compliance and trust
- Add working Privacy Policy link
- Add working Terms of Use link
- Add clear in-app data-use disclosure for health, mood, and cloud backup data
- Add account/data deletion path or clear deletion request flow

### 5. Naming and project cleanup
- Remove stale `OnePlace` references from iOS/project files and docs
- Align bundle identifiers, app display names, and Firebase metadata

### 6. Android follow-up
- Keep Health Connect Android-only
- Configure production signing
- Recheck Android Firebase / Google sign-in setup

### 7. Verification
- Run `flutter analyze`
- Run `flutter test`
- Run the smoke test
- Manually validate the iOS onboarding, sign-in, check-in, briefing, and backup flow

## Definition of Done
- iOS build is truthful, stable, and launch-ready
- Firebase auth and cloud sync work end-to-end
- Premium access is not bypassed in production
- Compliance surfaces are present and functional
- Smoke tests pass
