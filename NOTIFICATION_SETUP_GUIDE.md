# Push Notification Setup Guide

**Estimated time:** 30-40 minutes
**Prerequisites:** Firebase project configured (P0.5), APNs certificates (iOS)

---

## Overview

This guide walks through setting up push notifications and local notifications for SortBliss using:
- **Firebase Cloud Messaging (FCM)** - Push notifications
- **Flutter Local Notifications** - Scheduled local reminders
- **APNs** (iOS) - Apple Push Notification service

**Features enabled:**
- Daily reward reminders (scheduled local notifications)
- Level progression reminders (after 24-48 hours of inactivity)
- Event announcements (push notifications from Firebase Console)
- Quiet hours (respects user sleep schedule: 10 PM - 8 AM default)
- Notification channels (Android) for user control

---

## Part 1: Firebase Cloud Messaging Setup

### Step 1.1: Enable FCM in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your SortBliss project
3. Navigate to **Build** → **Cloud Messaging**
4. Click **Get Started** (if not already enabled)

### Step 1.2: Android Configuration

FCM is automatically enabled for Android after Firebase setup (P0.5). No additional configuration needed.

**Verify:**
```bash
# Check that google-services.json exists
ls android/app/google-services.json
```

### Step 1.3: iOS Configuration (APNs)

**Prerequisites:**
- Apple Developer account ($99/year)
- Enrolled in Apple Developer Program

**Generate APNs Authentication Key:**

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Click **+** to create a new key
3. Enable **Apple Push Notifications service (APNs)**
4. Download the `.p8` key file (save securely - can only download once)
5. Note the **Key ID** and **Team ID**

**Upload APNs Key to Firebase:**

1. In Firebase Console, go to **Project Settings** → **Cloud Messaging**
2. Under **Apple app configuration**, click **Upload**
3. Upload your `.p8` file
4. Enter your **Key ID** and **Team ID**
5. Click **Save**

---

## Part 2: Code Activation

### Step 2.1: Uncomment Dependencies

**File:** `pubspec.yaml`

```yaml
# BEFORE:
  # firebase_messaging: ^14.7.9
  # flutter_local_notifications: ^16.3.0
  # timezone: ^0.9.2

# AFTER:
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
  timezone: ^0.9.2
```

**Install dependencies:**
```bash
flutter pub get
```

### Step 2.2: Uncomment Notification Service

**File:** `lib/core/services/notification_service.dart`

Search for `// TODO: Uncomment after Firebase setup (P0.5)` and uncomment all sections:

1. Import statements (lines 4-6)
2. `_initializeLocalNotifications()` method
3. `_createNotificationChannels()` method
4. `_initializePushNotifications()` method
5. `_setupNotificationHandlers()` method
6. `_showLocalNotification()` method
7. `_onNotificationTapped()` method
8. All logic inside `requestPermission()` method
9. All logic inside `scheduleDailyRewardReminder()` method
10. All logic inside `scheduleLevelReminder()` method

**Quick find/replace:**
```bash
# Remove all TODO comment blocks
# Manual approach: Remove 15 TODO sections in notification_service.dart
```

### Step 2.3: Update Main.dart

**File:** `lib/main.dart`

Add notification service initialization:

```dart
import 'core/services/notification_service.dart';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service (add this)
  await NotificationService.instance.initialize();

  // ... rest of initialization
}
```

### Step 2.4: iOS Info.plist Configuration

**File:** `ios/Runner/Info.plist`

Add notification permissions:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

**File:** `ios/Runner/AppDelegate.swift`

Update to handle notifications:

```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // Request notification permission
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

### Step 2.5: Android Notification Icon

**Create notification icons:**

1. Generate notification icons (must be white/transparent PNG):
   - Use [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/icons-notification.html)
   - Upload your logo
   - Download generated icon set

2. Place icons in `android/app/src/main/res/`:
   ```
   drawable-mdpi/ic_notification.png (24x24)
   drawable-hdpi/ic_notification.png (36x36)
   drawable-xhdpi/ic_notification.png (48x48)
   drawable-xxhdpi/ic_notification.png (72x72)
   drawable-xxxhdpi/ic_notification.png (96x96)
   ```

3. Update `notification_service.dart`:
   ```dart
   const androidSettings = AndroidInitializationSettings('@mipmap/ic_notification');
   ```

### Step 2.6: Android Manifest Permissions

**File:** `android/app/src/main/AndroidManifest.xml`

Add permissions (likely already present from Firebase setup):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />

    <application ...>
        <!-- FCM default notification channel (optional but recommended) -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="sortbliss_general" />
    </application>
</manifest>
```

---

## Part 3: Integrate Notifications into App Flow

### Step 3.1: Request Permission on First Launch

**File:** `lib/presentation/onboarding/onboarding_screen.dart` (or similar)

```dart
import 'package:sortbliss/core/services/notification_service.dart';

Future<void> _completeOnboarding() async {
  // Request notification permission
  final permissionGranted = await NotificationService.instance.requestPermission();

  if (permissionGranted) {
    // Schedule daily reward reminder for 10 AM
    await NotificationService.instance.scheduleDailyRewardReminder(hour: 10);
  }

  // Continue with onboarding completion...
}
```

### Step 3.2: Schedule Notifications After Daily Reward Claim

**File:** `lib/presentation/daily_rewards/daily_rewards_screen.dart`

```dart
Future<void> _claimReward() async {
  final reward = await _rewardsService.claimReward();

  if (reward != null) {
    // Reschedule daily reminder for tomorrow
    await NotificationService.instance.scheduleDailyRewardReminder(hour: 10);
  }
}
```

### Step 3.3: Schedule Level Reminders on App Background

**File:** `lib/main.dart`

```dart
import 'package:flutter/services.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App going to background - schedule level reminder
      NotificationService.instance.scheduleLevelReminder(
        delay: const Duration(hours: 24),
        currentLevel: PlayerProfileService.instance.getCurrentLevel(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(...);
  }
}
```

### Step 3.4: Add Notification Settings to Settings Screen

**File:** `lib/presentation/settings/settings_screen.dart`

```dart
import '../../core/services/notification_service.dart';

_SettingsSection(
  title: 'Notifications',
  children: [
    SwitchListTile(
      title: const Text('Daily Reward Reminders'),
      subtitle: const Text('Get notified when rewards are available'),
      value: NotificationService.instance.isDailyRewardReminderEnabled(),
      onChanged: (value) {
        setState(() {
          NotificationService.instance.setDailyRewardReminderEnabled(value);
          if (value) {
            NotificationService.instance.scheduleDailyRewardReminder(hour: 10);
          }
        });
      },
    ),
    SwitchListTile(
      title: const Text('Level Reminders'),
      subtitle: const Text('Reminders to continue your progress'),
      value: NotificationService.instance.isLevelReminderEnabled(),
      onChanged: (value) {
        setState(() {
          NotificationService.instance.setLevelReminderEnabled(value);
        });
      },
    ),
    ListTile(
      title: const Text('Quiet Hours'),
      subtitle: Text(
        '${NotificationService.instance.getQuietHoursStart()}:00 - '
        '${NotificationService.instance.getQuietHoursEnd()}:00',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Show quiet hours picker dialog
        _showQuietHoursPicker();
      },
    ),
  ],
),
```

---

## Part 4: Testing

### Test 4.1: Permission Request

1. Uninstall app from device
2. Install fresh build: `flutter run`
3. Complete onboarding
4. Verify permission dialog appears
5. Grant permission
6. Check logs for FCM token:
   ```
   [analytics] fcm_token_obtained -> {token_length: 163}
   ```

### Test 4.2: Local Notification (Daily Reward Reminder)

**Immediate test (bypass scheduling):**

```dart
// Add to notification_service.dart temporarily
Future<void> testNotification() async {
  await _showLocalNotification(
    title: 'Test Notification',
    body: 'This is a test of local notifications',
    payload: 'test',
  );
}

// Call from a button in the app
NotificationService.instance.testNotification();
```

**Scheduled test:**
1. Schedule notification for 1 minute in future
2. Close app (don't force quit)
3. Wait 1 minute
4. Notification should appear

### Test 4.3: Push Notification

**Send test from Firebase Console:**

1. Go to Firebase Console → **Cloud Messaging**
2. Click **Send your first message**
3. Enter notification title and text
4. Click **Send test message**
5. Enter FCM token (from app logs)
6. Click **Test**

**Verify:**
- Notification appears when app is in background
- Notification appears when app is in foreground (as local notification)
- Tapping notification opens app

### Test 4.4: Background Message Handler

**File:** `lib/main.dart`

Add background message handler:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

// Top-level function (must be outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('Handling background message: ${message.messageId}');

  // Don't call setState or Navigator here
  // Just log or save to local storage
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeApp();
  runApp(const MyApp());
}
```

---

## Part 5: Production Optimization

### 5.1: Notification Topics (Segmentation)

Subscribe users to topics for targeted messaging:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

// Subscribe to topics
await FirebaseMessaging.instance.subscribeToTopic('all_users');
await FirebaseMessaging.instance.subscribeToTopic('daily_players');
await FirebaseMessaging.instance.subscribeToTopic('premium_users');

// Unsubscribe when no longer relevant
await FirebaseMessaging.instance.unsubscribeFromTopic('daily_players');
```

**Send to topic from Firebase Console:**
1. Go to Cloud Messaging → **New campaign**
2. Select **Topic**
3. Enter topic name (e.g., `daily_players`)

### 5.2: Notification Analytics

Track notification effectiveness:

```dart
// In notification tap handler
void _onNotificationTapped(NotificationResponse response) {
  AnalyticsLogger.logEvent('notification_tapped', parameters: {
    'payload': response.payload ?? 'none',
    'source': 'local', // or 'push'
  });

  // Track conversion (did user complete action?)
  if (response.payload == 'daily_rewards') {
    // Later, when reward is claimed:
    AnalyticsLogger.logEvent('notification_conversion', parameters: {
      'type': 'daily_rewards',
      'time_to_conversion_seconds': 120,
    });
  }
}
```

### 5.3: A/B Test Notification Copy

Test different notification messages:

```dart
Future<void> scheduleDailyRewardReminder({required int hour}) async {
  // Randomly assign variant
  final variant = Random().nextBool() ? 'A' : 'B';

  final title = variant == 'A'
    ? 'Daily Reward Available!'
    : 'Don\'t miss your daily coins!';

  final body = variant == 'A'
    ? 'Claim your daily coins and continue your streak 🔥'
    : 'Your streak is waiting! Claim now and keep it going 🎁';

  // Log variant assignment
  AnalyticsLogger.logEvent('notification_variant_assigned', parameters: {
    'variant': variant,
    'type': 'daily_reward',
  });

  // Schedule with assigned copy
  await _scheduleNotification(title: title, body: body);
}
```

### 5.4: Opt-out Rate Monitoring

Monitor notification opt-out to improve messaging:

```dart
Future<void> setNotificationsEnabled(bool enabled) async {
  await _prefs.setBool(_keyNotificationsEnabled, enabled);

  AnalyticsLogger.logEvent('notifications_toggled', parameters: {
    'enabled': enabled,
    'days_since_install': _getDaysSinceInstall(),
    'total_notifications_received': getTotalNotificationsReceived(),
  });
}
```

---

## Part 6: Troubleshooting

### Issue 6.1: "FCM token not generated" (iOS)

**Symptoms:** No FCM token in logs

**Solutions:**
1. Verify APNs certificate uploaded to Firebase
2. Check Info.plist has `UIBackgroundModes` with `remote-notification`
3. Verify app capabilities: Xcode → Target → Signing & Capabilities → **+ Capability** → Push Notifications
4. Clean and rebuild: `flutter clean && flutter pub get && flutter run`

### Issue 6.2: "Notifications not appearing" (Android)

**Symptoms:** Notifications scheduled but not showing

**Solutions:**
1. Check notification channels created: `adb shell dumpsys notification_listener`
2. Verify notification permission granted: Settings → Apps → SortBliss → Notifications
3. Check battery optimization: Settings → Battery → Battery optimization → SortBliss → Don't optimize
4. Test on physical device (not emulator)

### Issue 6.3: "Notifications work in debug, not in release"

**Symptoms:** Works in debug mode, fails in release

**Solutions:**
1. iOS: Verify distribution APNs certificate uploaded (not development)
2. Android: Ensure ProGuard rules added:
   ```
   # Firebase
   -keep class com.google.firebase.** { *; }
   -keep class com.google.android.gms.** { *; }
   ```

### Issue 6.4: "Background notifications not received" (iOS)

**Symptoms:** Foreground works, background doesn't

**Solutions:**
1. Verify `content_available: true` in FCM payload
2. Check background fetch enabled: Xcode → Capabilities → Background Modes → Remote notifications
3. Test on physical device (background notifications don't work in simulator)

---

## Cost Analysis

**Firebase Cloud Messaging:**
- Free tier: Unlimited messages
- No additional costs

**Firebase Analytics (notification tracking):**
- Free tier: Unlimited events
- No additional costs

**Total monthly cost:** $0 (within free tier)

---

## Timeline

| Task | Duration |
|------|----------|
| Firebase Cloud Messaging setup | 10 min |
| iOS APNs configuration | 15 min |
| Code activation & dependencies | 10 min |
| Testing notifications | 10 min |
| Integration into app flow | 15 min |
| **Total** | **60 min** |

---

## Success Metrics

After activation, monitor these KPIs:

1. **Permission Grant Rate:** Target 60-70% (industry average: 50%)
2. **Notification Open Rate:** Target 15-25% (industry average: 10-15%)
3. **D1 Retention Impact:** Expected +5-10% (notifications improve retention)
4. **Opt-out Rate:** Target <5% monthly

Track in Firebase Analytics:
```dart
AnalyticsLogger.logEvent('notification_permission_result', parameters: {
  'granted': true,
});
AnalyticsLogger.logEvent('notification_tapped', parameters: {
  'type': 'daily_rewards',
});
```

---

## Next Steps

After completing notification setup:

1. ✅ **P1.6 Complete** - Notification infrastructure ready
2. → **Test thoroughly** - Verify on iOS and Android devices
3. → **Monitor analytics** - Track permission grant rate and open rate
4. → **Iterate messaging** - A/B test notification copy for best engagement
5. → **Expand use cases** - Add notifications for achievements, events, limited-time offers

**Estimated valuation impact:** +$25K-50K (improved retention from smart notifications)

---

## Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications Package](https://pub.dev/packages/flutter_local_notifications)
- [APNs Overview](https://developer.apple.com/documentation/usernotifications)
- [Android Notification Channels](https://developer.android.com/training/notify-user/channels)
- [Notification Best Practices](https://firebase.google.com/docs/cloud-messaging/best-practices)
