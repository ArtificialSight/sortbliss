# Firebase Setup Guide for SortBliss

This guide explains how to set up Firebase for SortBliss, which is required for:
- **Crashlytics:** Crash reporting and stability monitoring
- **Analytics:** User behavior tracking and conversion metrics
- **Performance Monitoring:** App performance insights
- **Remote Config:** Feature flags and A/B testing

**Status:** 🚨 REQUIRED - App will not launch without Firebase configuration files

---

## Prerequisites

- Google account
- Access to [Firebase Console](https://console.firebase.google.com/)
- Project ownership in Google Cloud (if billing required)

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" (or "Add project")
3. **Project name:** `SortBliss` (or your preferred name)
4. **Google Analytics:** Enable (recommended for tracking metrics)
5. Select or create Analytics account
6. Click "Create project" and wait for provisioning (~1 minute)

---

## Step 2: Add Android App to Firebase

### 2.1 Register App

1. In Firebase Console, select your project
2. Click the Android icon to add Android app
3. **Android package name:** `com.sortbliss.app`
   - ⚠️ Must match exactly with `android/app/build.gradle` applicationId
4. **App nickname (optional):** "SortBliss Android"
5. **Debug signing certificate SHA-1 (optional):** Leave blank for now
   - You can add this later for advanced features
6. Click "Register app"

### 2.2 Download google-services.json

1. Click "Download google-services.json"
2. Move the file to `/home/user/sortbliss/android/app/`

```bash
# From your downloads folder
mv ~/Downloads/google-services.json /home/user/sortbliss/android/app/
```

3. Verify placement:

```bash
ls /home/user/sortbliss/android/app/google-services.json
```

**Expected:** File exists at this exact path

### 2.3 Add Firebase SDK

Firebase dependencies are already configured in the project. Verify in `android/app/build.gradle`:

```gradle
// Firebase already added
// No action needed - dependencies configured
```

### 2.4 Test Android Configuration

```bash
cd /home/user/sortbliss
flutter run --release
```

Check logs for Firebase initialization:
```
[Firebase] Initialized successfully
```

---

## Step 3: Add iOS App to Firebase

### 3.1 Register App

1. In Firebase Console, click "Add app" > iOS
2. **iOS bundle ID:** `com.sortbliss.app`
   - ⚠️ Must match `ios/Runner/Info.plist` CFBundleIdentifier
3. **App nickname (optional):** "SortBliss iOS"
4. **App Store ID (optional):** Leave blank (add after App Store submission)
5. Click "Register app"

### 3.2 Download GoogleService-Info.plist

1. Click "Download GoogleService-Info.plist"
2. Move the file to `/home/user/sortbliss/ios/Runner/`

```bash
# From your downloads folder
mv ~/Downloads/GoogleService-Info.plist /home/user/sortbliss/ios/Runner/
```

3. Verify placement:

```bash
ls /home/user/sortbliss/ios/Runner/GoogleService-Info.plist
```

**Expected:** File exists at this exact path

### 3.3 Add to Xcode (Important!)

1. Open Xcode:

```bash
open ios/Runner.xcworkspace
```

2. In Xcode, drag `GoogleService-Info.plist` from Finder into the `Runner` folder
3. **Check:** "Copy items if needed"
4. **Add to targets:** Select "Runner"
5. Verify file is in Project Navigator under `Runner/Runner/GoogleService-Info.plist`

### 3.4 Test iOS Configuration

```bash
flutter run --release
```

Check logs for Firebase initialization:
```
[Firebase] Initialized successfully
```

---

## Step 4: Enable Firebase Services

### 4.1 Enable Crashlytics

1. In Firebase Console > Build > Crashlytics
2. Click "Enable Crashlytics"
3. Follow on-screen instructions
4. Click "Finish setup"

**Verification:**
- Force a test crash (in app, press hidden button 5x)
- Check Crashlytics dashboard for crash report within 5 minutes

### 4.2 Enable Analytics

1. In Firebase Console > Build > Analytics
2. Click "Enable Google Analytics"
3. Select Analytics account
4. Click "Enable Analytics"

**Verification:**
- Run app for 2 minutes
- Navigate to Analytics > Events
- Check for `app_open`, `screen_view` events

### 4.3 Enable Performance Monitoring

1. In Firebase Console > Build > Performance
2. Click "Enable Performance Monitoring"

**Verification:**
- Run app and complete a level
- Check Performance dashboard for traces

### 4.4 Enable Remote Config (Optional)

1. In Firebase Console > Build > Remote Config
2. Click "Get started"
3. Add default config values if needed

**Use Case:** Feature flags, A/B testing, kill switches

---

## Step 5: Add Firebase Dependencies to Project

### 5.1 Update pubspec.yaml

```bash
cd /home/user/sortbliss
```

Edit `pubspec.yaml` and add:

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_crashlytics: ^4.1.3
  firebase_analytics: ^11.3.3
  firebase_performance: ^0.10.0+8
  # firebase_remote_config: ^5.1.3  # Optional
```

### 5.2 Install Dependencies

```bash
flutter pub get
```

### 5.3 Verify Installation

```bash
flutter pub outdated | grep firebase
```

**Expected:** All firebase packages listed with latest versions

---

## Step 6: Initialize Firebase in App

**Good News:** Firebase initialization is already added to `main.dart`!

Verify in `/home/user/sortbliss/lib/main.dart`:

```dart
// Already implemented:
await Firebase.initializeApp();
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
```

---

## Step 7: Test Complete Integration

### 7.1 Android Test

```bash
flutter run --release
```

**Check for:**
- ✅ No Firebase errors in logs
- ✅ App opens successfully
- ✅ Firebase initialization message

### 7.2 iOS Test

```bash
flutter run --release
```

**Check for:**
- ✅ No Firebase errors in logs
- ✅ App opens successfully
- ✅ Firebase initialization message

### 7.3 Trigger Test Crash

```bash
# In app, press a hidden button or call:
throw Exception('Test crash');
```

Wait 5 minutes, then check Crashlytics dashboard for crash report.

### 7.4 Check Analytics

1. Use app for 2 minutes (navigate screens, play levels)
2. Go to Firebase Console > Analytics > Events
3. Verify events: `app_open`, `level_complete`, `purchase`, etc.

---

## Troubleshooting

### Android: "google-services.json not found"

**Solution:**
```bash
ls android/app/google-services.json
```

If missing, re-download from Firebase Console and place in `android/app/`

### iOS: "GoogleService-Info.plist not found"

**Solution:**
```bash
ls ios/Runner/GoogleService-Info.plist
```

If missing, re-download and add to Xcode (Step 3.3)

### "Firebase initialization failed"

**Solution:**
1. Verify package name matches Firebase registration exactly
2. Check `google-services.json` and `GoogleService-Info.plist` are valid JSON/plist
3. Rebuild app: `flutter clean && flutter pub get && flutter run`

### Crashlytics not receiving crashes

**Solution:**
1. Ensure Crashlytics enabled in Firebase Console
2. Wait up to 15 minutes for first crash to appear
3. Verify device has internet connection
4. Check crash logs: `adb logcat | grep Crashlytics` (Android)

### Analytics events not showing

**Solution:**
1. Wait 24 hours (Analytics has delay)
2. Use DebugView for real-time testing:
   - iOS: Run with `--dart-define=FIREBASE_ANALYTICS_DEBUG_MODE=true`
   - Android: `adb shell setprop debug.firebase.analytics.app com.sortbliss.app`

---

## Security Best Practices

1. ✅ **Never commit** Firebase config files to public repositories
   - Files are already gitignored
2. ✅ Enable App Check to prevent abuse
3. ✅ Set up Firebase Security Rules for database access
4. ✅ Rotate API keys if exposed

---

## Next Steps After Setup

1. **Configure Alerts:**
   - Set up Crashlytics alerts for crash rate > 1%
   - Set up Performance alerts for slow screens

2. **Create Custom Events:**
   - Track key business metrics (revenue, retention, engagement)

3. **Set up BigQuery Export:**
   - Export raw Analytics data for advanced analysis

4. **Enable Firebase App Distribution:**
   - Distribute beta builds to testers

---

## Firebase Console URLs

- **Main Dashboard:** https://console.firebase.google.com/u/0/project/YOUR_PROJECT_ID
- **Crashlytics:** https://console.firebase.google.com/u/0/project/YOUR_PROJECT_ID/crashlytics
- **Analytics:** https://console.firebase.google.com/u/0/project/YOUR_PROJECT_ID/analytics
- **Performance:** https://console.firebase.google.com/u/0/project/YOUR_PROJECT_ID/performance

Replace `YOUR_PROJECT_ID` with your actual Firebase project ID.

---

## Cost Estimates

Firebase has generous free tiers:

- **Crashlytics:** Free unlimited
- **Analytics:** Free unlimited
- **Performance:** Free up to 10K traces/day
- **Remote Config:** Free up to 1M requests/month
- **App Check:** Free up to 10K checks/day

**Expected Monthly Cost:** $0 for apps under 100K DAU

---

## Summary

After completing this guide, you will have:
- ✅ Firebase project created
- ✅ Android app registered with `google-services.json`
- ✅ iOS app registered with `GoogleService-Info.plist`
- ✅ Crashlytics, Analytics, Performance enabled
- ✅ Firebase SDK integrated and tested

**Estimated Time:** 30-45 minutes (first-time setup)

**Status Check:**
```bash
# Verify both config files exist
ls android/app/google-services.json
ls ios/Runner/GoogleService-Info.plist

# If both exist, Firebase setup is complete!
```

---

**Questions?** Check [Firebase Documentation](https://firebase.google.com/docs/flutter/setup) or Firebase Console Support.
