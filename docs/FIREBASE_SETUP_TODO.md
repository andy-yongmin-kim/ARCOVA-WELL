# Firebase Setup Checklist for Arcova Well

Complete these steps to enable Google Sign-In, cloud sync, and AI briefings.

## ☐ Step 1: Register Android App in Firebase

- [ ] Go to [Firebase Console](https://console.firebase.google.com)
- [ ] Select your project (or create "Arcova Well" project if new)
- [ ] Click **Project Settings** (gear icon) → **Your apps** tab
- [ ] Click **Add app** → **Android**
- [ ] Fill in:
  - **Package name**: `com.arcova.well`
  - **App nickname**: `Arcova Well Android`
  - **Debug signing certificate SHA-1**: 
    ```bash
    cd /Users/andy/Desktop/project\ flutter/arcova-well/android
    ./gradlew signingReport
    # Copy the SHA-1 fingerprint from "debug" variant
    ```
- [ ] Complete the wizard
- [ ] **Download** `google-services.json`
- [ ] **Replace** `android/app/google-services.json` with the downloaded file

## ☐ Step 2: Enable Google Sign-In

- [ ] Firebase Console → **Authentication** → **Sign-in method** tab
- [ ] Click **Google** provider
- [ ] Toggle **Enable**
- [ ] Set:
  - **Public-facing name**: `Arcova Well`
  - **Support email**: (your email)
- [ ] **Save**

## ☐ Step 3: Create Firestore Database

- [ ] Firebase Console → **Firestore Database** → **Create database**
- [ ] Choose:
  - **Mode**: Production
  - **Region**: `us-central1` (or closest to your users; `asia-northeast1` for Asia)
- [ ] After creation, go to **Rules** tab
- [ ] Replace the default rules with this uid-scoped rule:
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
- [ ] Click **Publish**

## ☐ Step 4 (Optional): Enable Firebase AI Logic for Gemini Briefings

- [ ] Firebase Console → **Build** → **AI Logic** (or search "Firebase AI")
- [ ] Check that your project is on **Blaze plan** (pay-as-you-go)
  - If on Spark (free), you must upgrade
- [ ] Enable **Google AI** backend
- [ ] The app uses `gemini-2.5-flash` model — no additional config needed; Firebase AI Logic handles auth

## ✅ Testing After Firebase Setup

Once all steps are complete, test in the app:

```bash
cd /Users/andy/Desktop/project\ flutter/arcova-well
flutter run -d emulator-5554
```

Then:
1. Tap **Settings** (bottom right)
2. Tap **Sign in with Google** → should show login screen
3. Sign in with a test Google account
4. After sign-in, your name should appear at the top of Settings
5. Tap **Check-In** → enter mood scores → should save without Firestore errors
6. Tap **View Daily Briefing** → should show either:
   - Live Gemini briefing (if AI Logic enabled) — requires `gemini_api_key` fallback
   - On-device generated briefing (always works as fallback)

---

**Stuck?** Check the app logs:
```bash
adb logcat flutter:V *:S
```

Look for:
- ✅ No "Null check operator used on a null value" errors
- ✅ Firebase auth successful if signed in
- ℹ️ Firestore sync errors are okay if not premium/signed-in (expected)
