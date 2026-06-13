# Google OAuth Setup Documentation

This folder contains all documentation and credentials related to Google OAuth setup for the Arcova Well app.

---

## 📋 Quick Navigation

### For First-Time Setup
👉 **Start here**: [SETUP_CHECKLIST.md](./SETUP_CHECKLIST.md)
- Step-by-step guide with checkboxes
- Organized by phase (Android, Firebase, iOS, code, compliance)
- Estimated time per phase

### For Understanding the Architecture
👉 **Read this**: [SETUP_GUIDE.md](./SETUP_GUIDE.md)
- Complete technical explanation of OAuth flow
- Current implementation status
- Security notes and troubleshooting

### For Audit Summary
👉 **Review this**: [AUDIT_SUMMARY.md](./AUDIT_SUMMARY.md)
- What's been verified ✅
- What's missing ❌
- Detailed findings and recommendations
- Security assessment

---

## 📁 Files in This Folder

| File | Purpose | Audience |
|------|---------|----------|
| `README.md` | This file — navigation guide | Everyone |
| `SETUP_GUIDE.md` | Technical documentation | Developers, DevOps |
| `SETUP_CHECKLIST.md` | Actionable setup steps | DevOps, Project Manager |
| `AUDIT_SUMMARY.md` | Audit findings & status | Technical Lead, Manager |
| `App/` | Android OAuth credentials | Developers (secure) |
| `Web/` | Web OAuth credentials | Admin (secure) |

---

## 🔑 Credentials

### Secure Storage Notice ⚠️

**Do NOT commit credentials to git.** This folder is in `.gitignore`.

| Credential | Location | Security Level | Used By |
|-----------|----------|-----------------|---------|
| `google-services.json` | `android/app/` | 🔒 Public IDs only | Android app build |
| `GoogleService-Info.plist` | `ios/Runner/` (needs download) | 🔒 Public IDs only | iOS app build |
| `App/client_secret_[ID].json` | `docs/Google OAuth/App/` | 🔐 Keep private | Reference only |
| `Web/client_secret_[ID].json` | `docs/Google OAuth/Web/` | 🔐 Keep VERY private | Reference only |

---

## 🚀 Current Status

| Component | Status | Effort to Complete |
|-----------|--------|-------------------|
| Android setup | ✅ Complete | — |
| Android testing | ✅ Tested on emulator | — |
| Firebase Console config | ❌ Incomplete | 15 min |
| iOS setup | ❌ Incomplete | 20 min |
| Pre-release config | ❌ Incomplete | 30 min |
| **Total Remaining** | — | **~65 minutes** |

---

## 📊 OAuth Configuration

### Firebase Project
- **Project ID**: `oneplace-1b557`
- **Project Number**: `724852226968`
- **Region**: `us-central1`

### Client IDs
- **Android**: `724852226968-thhg9kn1uu56tvfjthtfi2gbnltu5kif.apps.googleusercontent.com`
- **Web/Server**: `724852226968-geru9evdjcd9dbhoovngav9q1etpr75f.apps.googleusercontent.com`
- **Web/Browser**: `724852226968-p7atl75i719mu2trh8j3g6et51io51tu.apps.googleusercontent.com`

### App Details
- **Package Name**: `com.arcova.well`
- **SHA-1 Fingerprint**: `f16add6e88605d619612b816ec1debf9552aac45`
- **API Key**: `AIzaSyAsJoQR0ChNnHPOe-PHwv8Z--Y1APoYQzE`

---

## 🛠️ Quick Commands

### Verify Android Configuration
```bash
cd /Users/andy/Desktop/project\ flutter/arcova-well
flutter doctor                      # Check environment
cat android/app/google-services.json | jq '.client[0].oauth_client'  # View OAuth clients
```

### Test OAuth Flow
```bash
flutter run -d emulator-5554        # Run on Android emulator
# Tap "Continue with Google" to test OAuth
```

### Rebuild After Changes
```bash
flutter clean
flutter pub get
flutter run -d emulator-5554
```

---

## ✅ Verification Checklist

Before moving to the next phase, verify:

- [ ] You can read and understand SETUP_GUIDE.md
- [ ] You have access to Firebase Console (project `oneplace-1b557`)
- [ ] You have access to Google Cloud Console (same project)
- [ ] Android app builds successfully: `flutter run -d emulator-5554`
- [ ] Sign-in screen appears without crashes
- [ ] All credential files are in this folder or `.gitignore`'d

---

## 🔒 Security Reminders

1. **Never commit credentials to git** — All files with `client_secret` in filename must stay in `.gitignore`
2. **Keep Web client secret private** — Unlike Client IDs, the secret should be stored securely
3. **Disable test mode before release** — `kTestMode = true` in settings_screen.dart must become `false`
4. **Restrict API keys** — In Firebase Console, restrict to Android package + SHA-1
5. **Use HTTPS** — Privacy policy and any OAuth redirect URLs must be HTTPS-only

---

## 📞 Getting Help

| Issue | Resource |
|-------|----------|
| OAuth flow questions | [SETUP_GUIDE.md](./SETUP_GUIDE.md#oauth-architecture) |
| Step-by-step setup | [SETUP_CHECKLIST.md](./SETUP_CHECKLIST.md) |
| Troubleshooting | [SETUP_GUIDE.md#troubleshooting](./SETUP_GUIDE.md#troubleshooting) |
| Security best practices | [SETUP_GUIDE.md#security-notes](./SETUP_GUIDE.md#security-notes) |
| Audit findings | [AUDIT_SUMMARY.md](./AUDIT_SUMMARY.md) |

---

## 📅 Timeline Estimate

- **Phase 1 (Android)**: ✅ Already complete
- **Phase 2 (Firebase Console)**: 15 min
- **Phase 3 (iOS)**: 20 min
- **Phase 4 (Code config)**: 5 min
- **Phase 5 (Privacy & compliance)**: 30 min
- **Phase 6 (Testing)**: 30 min

**Total for production release**: ~100 minutes of work

---

## 🎯 Next Steps

1. **Read**: Open [SETUP_CHECKLIST.md](./SETUP_CHECKLIST.md)
2. **Verify**: Confirm you have Firebase Console access
3. **Execute**: Follow Phase 2 (Firebase Console setup) — takes 15 minutes
4. **Test**: Run `flutter run` and test sign-in on Android emulator
5. **Continue**: Complete Phase 3–5 as needed

---

**Last Updated**: June 8, 2026  
**Maintained By**: Arcova Well Development Team
