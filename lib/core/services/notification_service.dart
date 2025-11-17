import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// TODO: Uncomment after Firebase setup (P0.5)
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../analytics/analytics_logger.dart';

/// Comprehensive notification service for push and local notifications
/// Handles:
/// - Push notifications via Firebase Cloud Messaging
/// - Local notifications for daily rewards, level reminders
/// - Notification permissions and channel configuration
/// - Smart notification timing (respects user preferences and quiet hours)
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // TODO: Uncomment after Firebase setup (P0.5)
  // final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  // final FlutterLocalNotificationsPlugin _localNotifications =
  //     FlutterLocalNotificationsPlugin();

  late SharedPreferences _prefs;
  bool _initialized = false;
  bool _permissionGranted = false;

  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyDailyRewardReminder = 'daily_reward_reminder_enabled';
  static const String _keyLevelReminderEnabled = 'level_reminder_enabled';
  static const String _keyQuietHoursStart = 'quiet_hours_start'; // 22 (10 PM)
  static const String _keyQuietHoursEnd = 'quiet_hours_end'; // 8 (8 AM)
  static const String _keyFcmToken = 'fcm_token';

  // Notification channel IDs (Android)
  static const String _channelIdGeneral = 'sortbliss_general';
  static const String _channelIdRewards = 'sortbliss_rewards';
  static const String _channelIdReminders = 'sortbliss_reminders';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();

    // TODO: Uncomment after Firebase setup (P0.5) - Step 1 of 5
    // await _initializeLocalNotifications();

    // TODO: Uncomment after Firebase setup (P0.5) - Step 2 of 5
    // await _initializePushNotifications();

    // TODO: Uncomment after Firebase setup (P0.5) - Step 3 of 5
    // await _setupNotificationHandlers();

    AnalyticsLogger.logEvent('notification_service_initialized');
  }

  // TODO: Uncomment after Firebase setup (P0.5) - Local Notifications Setup
  // Future<void> _initializeLocalNotifications() async {
  //   const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  //   const iosSettings = DarwinInitializationSettings(
  //     requestAlertPermission: false,
  //     requestBadgePermission: false,
  //     requestSoundPermission: false,
  //   );
  //
  //   const initSettings = InitializationSettings(
  //     android: androidSettings,
  //     iOS: iosSettings,
  //   );
  //
  //   await _localNotifications.initialize(
  //     initSettings,
  //     onDidReceiveNotificationResponse: _onNotificationTapped,
  //   );
  //
  //   // Create notification channels (Android 8.0+)
  //   if (Platform.isAndroid) {
  //     await _createNotificationChannels();
  //   }
  // }

  // TODO: Uncomment after Firebase setup (P0.5) - Create Android Channels
  // Future<void> _createNotificationChannels() async {
  //   final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
  //       AndroidFlutterLocalNotificationsPlugin>();
  //
  //   if (androidPlugin == null) return;
  //
  //   // General notifications
  //   await androidPlugin.createNotificationChannel(
  //     const AndroidNotificationChannel(
  //       _channelIdGeneral,
  //       'General Notifications',
  //       description: 'Updates, events, and announcements',
  //       importance: Importance.defaultImportance,
  //     ),
  //   );
  //
  //   // Daily rewards
  //   await androidPlugin.createNotificationChannel(
  //     const AndroidNotificationChannel(
  //       _channelIdRewards,
  //       'Daily Rewards',
  //       description: 'Notifications about daily login rewards',
  //       importance: Importance.high,
  //       playSound: true,
  //     ),
  //   );
  //
  //   // Level reminders
  //   await androidPlugin.createNotificationChannel(
  //     const AndroidNotificationChannel(
  //       _channelIdReminders,
  //       'Level Reminders',
  //       description: 'Reminders to continue your progress',
  //       importance: Importance.defaultImportance,
  //     ),
  //   );
  // }

  // TODO: Uncomment after Firebase setup (P0.5) - Push Notifications Setup
  // Future<void> _initializePushNotifications() async {
  //   // Request permission
  //   final settings = await _fcm.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //     provisional: false,
  //   );
  //
  //   _permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
  //       settings.authorizationStatus == AuthorizationStatus.provisional;
  //
  //   AnalyticsLogger.logEvent('notification_permission_result', parameters: {
  //     'granted': _permissionGranted,
  //     'status': settings.authorizationStatus.toString(),
  //   });
  //
  //   if (_permissionGranted) {
  //     // Get FCM token for this device
  //     final token = await _fcm.getToken();
  //     if (token != null) {
  //       await _saveFcmToken(token);
  //       AnalyticsLogger.logEvent('fcm_token_obtained', parameters: {
  //         'token_length': token.length,
  //       });
  //     }
  //
  //     // Listen for token refresh
  //     _fcm.onTokenRefresh.listen(_saveFcmToken);
  //   }
  // }

  // TODO: Uncomment after Firebase setup (P0.5) - Notification Handlers
  // Future<void> _setupNotificationHandlers() async {
  //   // Handle foreground messages
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     AnalyticsLogger.logEvent('notification_received_foreground', parameters: {
  //       'title': message.notification?.title ?? '',
  //       'has_data': message.data.isNotEmpty,
  //     });
  //
  //     // Show local notification when app is in foreground
  //     if (message.notification != null) {
  //       _showLocalNotification(
  //         title: message.notification!.title ?? 'SortBliss',
  //         body: message.notification!.body ?? '',
  //         payload: message.data['action'],
  //       );
  //     }
  //   });
  //
  //   // Handle background message tap
  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     AnalyticsLogger.logEvent('notification_tapped_background', parameters: {
  //       'action': message.data['action'],
  //     });
  //     _handleNotificationAction(message.data['action']);
  //   });
  //
  //   // Check if app was opened from a terminated state notification
  //   final initialMessage = await _fcm.getInitialMessage();
  //   if (initialMessage != null) {
  //     AnalyticsLogger.logEvent('notification_tapped_terminated', parameters: {
  //       'action': initialMessage.data['action'],
  //     });
  //     _handleNotificationAction(initialMessage.data['action']);
  //   }
  // }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    if (!_initialized) await initialize();

    // TODO: Uncomment after Firebase setup (P0.5)
    // try {
    //   final settings = await _fcm.requestPermission(
    //     alert: true,
    //     badge: true,
    //     sound: true,
    //   );
    //
    //   _permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
    //       settings.authorizationStatus == AuthorizationStatus.provisional;
    //
    //   await _prefs.setBool(_keyNotificationsEnabled, _permissionGranted);
    //
    //   AnalyticsLogger.logEvent('notification_permission_requested', parameters: {
    //     'granted': _permissionGranted,
    //   });
    //
    //   return _permissionGranted;
    // } catch (e) {
    //   debugPrint('Error requesting notification permission: $e');
    //   return false;
    // }

    // TEMPORARY: Return false until Firebase configured
    debugPrint('WARNING: Notification permissions disabled - Firebase not configured');
    return false;
  }

  /// Schedule daily reward reminder notification
  Future<void> scheduleDailyRewardReminder({
    required int hour, // 0-23
  }) async {
    if (!_initialized) await initialize();
    if (!areNotificationsEnabled()) return;
    if (!isDailyRewardReminderEnabled()) return;

    // Check quiet hours
    if (_isQuietHour(hour)) {
      debugPrint('Skipping daily reward reminder - quiet hours');
      return;
    }

    // TODO: Uncomment after Firebase setup (P0.5)
    // try {
    //   // Schedule for next occurrence of the specified hour
    //   final now = DateTime.now();
    //   var scheduledDate = DateTime(now.year, now.month, now.day, hour);
    //   if (scheduledDate.isBefore(now)) {
    //     scheduledDate = scheduledDate.add(const Duration(days: 1));
    //   }
    //
    //   await _localNotifications.zonedSchedule(
    //     1, // Notification ID
    //     'Daily Reward Available!',
    //     'Claim your daily coins and continue your streak 🔥',
    //     tz.TZDateTime.from(scheduledDate, tz.local),
    //     NotificationDetails(
    //       android: AndroidNotificationDetails(
    //         _channelIdRewards,
    //         'Daily Rewards',
    //         channelDescription: 'Notifications about daily login rewards',
    //         importance: Importance.high,
    //         priority: Priority.high,
    //       ),
    //       iOS: const DarwinNotificationDetails(
    //         presentAlert: true,
    //         presentBadge: true,
    //         presentSound: true,
    //       ),
    //     ),
    //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    //     uiLocalNotificationDateInterpretation:
    //         UILocalNotificationDateInterpretation.absoluteTime,
    //     matchDateTimeComponents: DateTimeComponents.time,
    //     payload: 'daily_rewards',
    //   );
    //
    //   AnalyticsLogger.logEvent('daily_reward_reminder_scheduled', parameters: {
    //     'hour': hour,
    //   });
    // } catch (e) {
    //   debugPrint('Error scheduling daily reward reminder: $e');
    // }

    AnalyticsLogger.logEvent('daily_reward_reminder_scheduled_placeholder', parameters: {
      'hour': hour,
    });
  }

  /// Schedule level reminder notification
  Future<void> scheduleLevelReminder({
    required Duration delay,
    required int currentLevel,
  }) async {
    if (!_initialized) await initialize();
    if (!areNotificationsEnabled()) return;
    if (!isLevelReminderEnabled()) return;

    // TODO: Uncomment after Firebase setup (P0.5)
    // try {
    //   final scheduledDate = DateTime.now().add(delay);
    //
    //   // Check quiet hours
    //   if (_isQuietHour(scheduledDate.hour)) {
    //     debugPrint('Skipping level reminder - quiet hours');
    //     return;
    //   }
    //
    //   await _localNotifications.zonedSchedule(
    //     2, // Notification ID
    //     'Ready for level ${currentLevel + 1}?',
    //     'Continue your sorting journey and earn more rewards!',
    //     tz.TZDateTime.from(scheduledDate, tz.local),
    //     NotificationDetails(
    //       android: AndroidNotificationDetails(
    //         _channelIdReminders,
    //         'Level Reminders',
    //         channelDescription: 'Reminders to continue your progress',
    //         importance: Importance.defaultImportance,
    //       ),
    //       iOS: const DarwinNotificationDetails(
    //         presentAlert: true,
    //         presentBadge: true,
    //         presentSound: true,
    //       ),
    //     ),
    //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    //     uiLocalNotificationDateInterpretation:
    //         UILocalNotificationDateInterpretation.absoluteTime,
    //     payload: 'level_progress',
    //   );
    //
    //   AnalyticsLogger.logEvent('level_reminder_scheduled', parameters: {
    //     'current_level': currentLevel,
    //     'delay_hours': delay.inHours,
    //   });
    // } catch (e) {
    //   debugPrint('Error scheduling level reminder: $e');
    // }

    AnalyticsLogger.logEvent('level_reminder_scheduled_placeholder', parameters: {
      'current_level': currentLevel,
      'delay_hours': delay.inHours,
    });
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    // TODO: Uncomment after Firebase setup (P0.5)
    // await _localNotifications.cancelAll();

    AnalyticsLogger.logEvent('all_notifications_cancelled');
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    // TODO: Uncomment after Firebase setup (P0.5)
    // await _localNotifications.cancel(id);

    AnalyticsLogger.logEvent('notification_cancelled', parameters: {'id': id});
  }

  // TODO: Uncomment after Firebase setup (P0.5) - Show Local Notification
  // Future<void> _showLocalNotification({
  //   required String title,
  //   required String body,
  //   String? payload,
  // }) async {
  //   await _localNotifications.show(
  //     DateTime.now().millisecondsSinceEpoch.remainder(100000),
  //     title,
  //     body,
  //     NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         _channelIdGeneral,
  //         'General Notifications',
  //         channelDescription: 'Updates, events, and announcements',
  //         importance: Importance.high,
  //         priority: Priority.high,
  //       ),
  //       iOS: const DarwinNotificationDetails(
  //         presentAlert: true,
  //         presentBadge: true,
  //         presentSound: true,
  //       ),
  //     ),
  //     payload: payload,
  //   );
  // }

  // TODO: Uncomment after Firebase setup (P0.5) - Handle Notification Tap
  // void _onNotificationTapped(NotificationResponse response) {
  //   AnalyticsLogger.logEvent('notification_tapped', parameters: {
  //     'payload': response.payload ?? 'none',
  //   });
  //
  //   if (response.payload != null) {
  //     _handleNotificationAction(response.payload!);
  //   }
  // }

  void _handleNotificationAction(String? action) {
    if (action == null) return;

    AnalyticsLogger.logEvent('notification_action_handled', parameters: {
      'action': action,
    });

    // Handle different notification actions
    // This would typically navigate to different screens
    switch (action) {
      case 'daily_rewards':
        // Navigate to daily rewards screen
        debugPrint('Navigate to daily rewards');
        break;
      case 'level_progress':
        // Navigate to level select
        debugPrint('Navigate to level select');
        break;
      case 'achievements':
        // Navigate to achievements
        debugPrint('Navigate to achievements');
        break;
      default:
        debugPrint('Unknown notification action: $action');
    }
  }

  Future<void> _saveFcmToken(String token) async {
    await _prefs.setString(_keyFcmToken, token);

    // TODO: Send token to your backend server for targeted push notifications
    debugPrint('FCM Token: $token');

    AnalyticsLogger.logEvent('fcm_token_saved');
  }

  /// Check if currently in quiet hours
  bool _isQuietHour(int hour) {
    final quietStart = _prefs.getInt(_keyQuietHoursStart) ?? 22; // 10 PM
    final quietEnd = _prefs.getInt(_keyQuietHoursEnd) ?? 8; // 8 AM

    if (quietStart < quietEnd) {
      // Normal case: e.g., 22-8 means quiet from 10 PM to 8 AM next day
      return hour >= quietStart || hour < quietEnd;
    } else {
      // Spans midnight: e.g., 8-22 means quiet from 8 AM to 10 PM
      return hour >= quietStart && hour < quietEnd;
    }
  }

  // Getters for notification settings
  bool areNotificationsEnabled() {
    return _prefs.getBool(_keyNotificationsEnabled) ?? false;
  }

  bool isDailyRewardReminderEnabled() {
    return _prefs.getBool(_keyDailyRewardReminder) ?? true;
  }

  bool isLevelReminderEnabled() {
    return _prefs.getBool(_keyLevelReminderEnabled) ?? true;
  }

  int getQuietHoursStart() {
    return _prefs.getInt(_keyQuietHoursStart) ?? 22;
  }

  int getQuietHoursEnd() {
    return _prefs.getInt(_keyQuietHoursEnd) ?? 8;
  }

  String? getFcmToken() {
    return _prefs.getString(_keyFcmToken);
  }

  bool isPermissionGranted() => _permissionGranted;

  // Setters for notification settings
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
    AnalyticsLogger.logEvent('notifications_toggled', parameters: {'enabled': enabled});

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  Future<void> setDailyRewardReminderEnabled(bool enabled) async {
    await _prefs.setBool(_keyDailyRewardReminder, enabled);
    AnalyticsLogger.logEvent('daily_reward_reminder_toggled', parameters: {'enabled': enabled});
  }

  Future<void> setLevelReminderEnabled(bool enabled) async {
    await _prefs.setBool(_keyLevelReminderEnabled, enabled);
    AnalyticsLogger.logEvent('level_reminder_toggled', parameters: {'enabled': enabled});
  }

  Future<void> setQuietHours({required int start, required int end}) async {
    await _prefs.setInt(_keyQuietHoursStart, start.clamp(0, 23));
    await _prefs.setInt(_keyQuietHoursEnd, end.clamp(0, 23));

    AnalyticsLogger.logEvent('quiet_hours_updated', parameters: {
      'start': start,
      'end': end,
    });
  }

  /// Reset notification settings for testing
  Future<void> resetForTesting() async {
    await _prefs.remove(_keyNotificationsEnabled);
    await _prefs.remove(_keyDailyRewardReminder);
    await _prefs.remove(_keyLevelReminderEnabled);
    await _prefs.remove(_keyQuietHoursStart);
    await _prefs.remove(_keyQuietHoursEnd);
    await _prefs.remove(_keyFcmToken);
    await cancelAllNotifications();
  }
}
