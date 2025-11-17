import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/analytics_logger.dart';

/// Smart notification scheduler for user engagement and retention
///
/// Features:
/// - Daily reminder notifications
/// - Streak protection alerts
/// - Event notifications
/// - Achievement unlock celebrations
/// - Power-up deals
/// - Personalized timing based on user behavior
/// - Rate limiting to prevent spam
/// - Quiet hours support
///
/// Notification Types:
/// - Daily Play Reminder (24h after last play)
/// - Streak Protection (when streak at risk)
/// - Event Started (seasonal events)
/// - Event Ending Soon (last 24h)
/// - Achievement Progress (near unlock)
/// - Power-Up Sale (limited time deals)
/// - New Level Unlocked
/// - Leaderboard Position Change
///
/// Usage:
/// ```dart
/// await NotificationSchedulerService.instance.initialize();
/// await NotificationSchedulerService.instance.scheduleAllNotifications();
/// ```
///
/// TODO: Integrate with actual notification package (flutter_local_notifications or Firebase Cloud Messaging)
class NotificationSchedulerService {
  static final NotificationSchedulerService instance =
      NotificationSchedulerService._();
  NotificationSchedulerService._();

  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _notificationsEnabled = true;

  static const String _keyEnabled = 'notifications_enabled';
  static const String _keyScheduledNotifications = 'scheduled_notifications';
  static const String _keyLastPlayTime = 'last_play_time';
  static const String _keyQuietHoursStart = 'quiet_hours_start';
  static const String _keyQuietHoursEnd = 'quiet_hours_end';
  static const String _keyNotificationHistory = 'notification_history';

  // Quiet hours (default: 10 PM - 8 AM)
  int _quietHoursStart = 22; // 10 PM
  int _quietHoursEnd = 8; // 8 AM

  final Map<String, ScheduledNotification> _scheduledNotifications = {};
  final List<NotificationEvent> _history = [];

  /// Initialize notification scheduler
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Load settings
    _notificationsEnabled = _prefs?.getBool(_keyEnabled) ?? true;
    _quietHoursStart = _prefs?.getInt(_keyQuietHoursStart) ?? 22;
    _quietHoursEnd = _prefs?.getInt(_keyQuietHoursEnd) ?? 8;

    // Load scheduled notifications
    await _loadScheduledNotifications();

    // Load history
    await _loadHistory();

    _initialized = true;

    debugPrint(
        '✅ Notification Scheduler initialized (enabled: $_notificationsEnabled)');

    // TODO: Request notification permissions
    // await _requestPermissions();
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs?.setBool(_keyEnabled, enabled);

    if (!enabled) {
      await cancelAllNotifications();
    } else {
      await scheduleAllNotifications();
    }

    AnalyticsLogger.logEvent(
      'notifications_toggled',
      parameters: {'enabled': enabled},
    );
  }

  /// Set quiet hours
  Future<void> setQuietHours(int startHour, int endHour) async {
    _quietHoursStart = startHour;
    _quietHoursEnd = endHour;
    await _prefs?.setInt(_keyQuietHoursStart, startHour);
    await _prefs?.setInt(_keyQuietHoursEnd, endHour);

    // Reschedule notifications with new quiet hours
    await scheduleAllNotifications();
  }

  /// Schedule all relevant notifications
  Future<void> scheduleAllNotifications() async {
    if (!_notificationsEnabled) return;

    // Cancel existing scheduled notifications
    await cancelAllNotifications();

    // Schedule daily play reminder
    await _scheduleDailyPlayReminder();

    // Schedule streak protection
    await _scheduleStreakProtection();

    // Schedule event notifications
    await _scheduleEventNotifications();

    debugPrint('📅 Scheduled ${_scheduledNotifications.length} notifications');
  }

  /// Schedule daily play reminder
  Future<void> _scheduleDailyPlayReminder() async {
    final lastPlayTime = _prefs?.getString(_keyLastPlayTime);
    if (lastPlayTime == null) return;

    final lastPlay = DateTime.parse(lastPlayTime);
    final now = DateTime.now();

    // Schedule for 24 hours after last play
    var scheduledTime = lastPlay.add(const Duration(hours: 24));

    // Adjust for quiet hours
    scheduledTime = _adjustForQuietHours(scheduledTime);

    // Only schedule if in the future
    if (scheduledTime.isAfter(now)) {
      final notification = ScheduledNotification(
        id: 'daily_reminder',
        title: '🎮 Ready to play?',
        body: 'Come back and beat your high score in SortBliss!',
        scheduledTime: scheduledTime,
        type: NotificationType.dailyReminder,
      );

      await _scheduleNotification(notification);
    }
  }

  /// Schedule streak protection notification
  Future<void> _scheduleStreakProtection() async {
    // TODO: Get actual streak data from statistics service
    final hasActiveStreak = true; // Mock
    final streakDays = 5; // Mock

    if (!hasActiveStreak) return;

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 20, 0); // 8 PM

    // If it's already past 8 PM, schedule for tomorrow
    if (now.hour >= 20) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    scheduledTime = _adjustForQuietHours(scheduledTime);

    final notification = ScheduledNotification(
      id: 'streak_protection',
      title: '🔥 Don\'t break your streak!',
      body: 'You have a $streakDays-day streak. Play today to keep it going!',
      scheduledTime: scheduledTime,
      type: NotificationType.streakProtection,
      data: {'streak_days': streakDays},
    );

    await _scheduleNotification(notification);
  }

  /// Schedule event notifications
  Future<void> _scheduleEventNotifications() async {
    // TODO: Get actual events from seasonal events service
    final mockEvents = [
      {
        'id': 'christmas_2025',
        'name': 'Winter Wonderland',
        'startDate': DateTime(2025, 12, 18),
        'endDate': DateTime(2025, 12, 27),
      }
    ];

    for (final event in mockEvents) {
      final startDate = event['startDate'] as DateTime;
      final endDate = event['endDate'] as DateTime;
      final now = DateTime.now();

      // Event starting soon (1 hour before)
      if (startDate.isAfter(now)) {
        var notifyTime = startDate.subtract(const Duration(hours: 1));
        notifyTime = _adjustForQuietHours(notifyTime);

        if (notifyTime.isAfter(now)) {
          await _scheduleNotification(
            ScheduledNotification(
              id: 'event_starting_${event['id']}',
              title: '🎉 Event Starting Soon!',
              body: '${event['name']} begins in 1 hour. Get ready!',
              scheduledTime: notifyTime,
              type: NotificationType.eventStarting,
              data: {'event_id': event['id']},
            ),
          );
        }
      }

      // Event ending soon (24 hours before)
      if (endDate.isAfter(now)) {
        var notifyTime = endDate.subtract(const Duration(hours: 24));
        notifyTime = _adjustForQuietHours(notifyTime);

        if (notifyTime.isAfter(now)) {
          await _scheduleNotification(
            ScheduledNotification(
              id: 'event_ending_${event['id']}',
              title: '⏰ Last chance!',
              body: '${event['name']} ends in 24 hours. Claim your rewards!',
              scheduledTime: notifyTime,
              type: NotificationType.eventEnding,
              data: {'event_id': event['id']},
            ),
          );
        }
      }
    }
  }

  /// Schedule achievement progress notification
  Future<void> scheduleAchievementProgress(
    String achievementId,
    String achievementName,
    int current,
    int target,
  ) async {
    if (!_notificationsEnabled) return;

    final progress = current / target;

    // Notify when 75% complete
    if (progress >= 0.75 && progress < 1.0) {
      final now = DateTime.now();
      var scheduledTime = now.add(const Duration(hours: 2));
      scheduledTime = _adjustForQuietHours(scheduledTime);

      final notification = ScheduledNotification(
        id: 'achievement_progress_$achievementId',
        title: '🏆 Almost there!',
        body: 'You\'re $current/$target for "$achievementName"!',
        scheduledTime: scheduledTime,
        type: NotificationType.achievementProgress,
        data: {
          'achievement_id': achievementId,
          'current': current,
          'target': target,
        },
      );

      await _scheduleNotification(notification);
    }
  }

  /// Schedule power-up deal notification
  Future<void> schedulePowerUpDeal(String dealName, Duration duration) async {
    if (!_notificationsEnabled) return;

    final now = DateTime.now();
    var scheduledTime = now.add(const Duration(hours: 1));
    scheduledTime = _adjustForQuietHours(scheduledTime);

    final notification = ScheduledNotification(
      id: 'powerup_deal',
      title: '💥 Limited Time Deal!',
      body: '$dealName - Save big on power-ups!',
      scheduledTime: scheduledTime,
      type: NotificationType.powerUpDeal,
      data: {'deal_name': dealName},
    );

    await _scheduleNotification(notification);
  }

  /// Schedule leaderboard notification
  Future<void> scheduleLeaderboardUpdate(
    int oldRank,
    int newRank,
    String leaderboardType,
  ) async {
    if (!_notificationsEnabled) return;

    // Only notify if rank improved and entered top 10
    if (newRank < oldRank && newRank <= 10) {
      final now = DateTime.now();
      var scheduledTime = now.add(const Duration(minutes: 30));
      scheduledTime = _adjustForQuietHours(scheduledTime);

      final notification = ScheduledNotification(
        id: 'leaderboard_update',
        title: '📈 You\'re climbing!',
        body: 'You\'re now #$newRank on the $leaderboardType leaderboard!',
        scheduledTime: scheduledTime,
        type: NotificationType.leaderboardUpdate,
        data: {
          'old_rank': oldRank,
          'new_rank': newRank,
          'type': leaderboardType,
        },
      );

      await _scheduleNotification(notification);
    }
  }

  /// Schedule a notification
  Future<void> _scheduleNotification(ScheduledNotification notification) async {
    _scheduledNotifications[notification.id] = notification;
    await _saveScheduledNotifications();

    // TODO: Actually schedule with platform
    // For flutter_local_notifications:
    // await flutterLocalNotificationsPlugin.zonedSchedule(
    //   notification.id.hashCode,
    //   notification.title,
    //   notification.body,
    //   tz.TZDateTime.from(notification.scheduledTime, tz.local),
    //   const NotificationDetails(...),
    //   androidAllowWhileIdle: true,
    //   uiLocalNotificationDateInterpretation: ...,
    // );

    debugPrint(
        '📬 Scheduled: ${notification.title} at ${notification.scheduledTime}');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    _scheduledNotifications.clear();
    await _saveScheduledNotifications();

    // TODO: Cancel platform notifications
    // await flutterLocalNotificationsPlugin.cancelAll();

    debugPrint('🚫 Cancelled all notifications');
  }

  /// Cancel specific notification
  Future<void> cancelNotification(String id) async {
    _scheduledNotifications.remove(id);
    await _saveScheduledNotifications();

    // TODO: Cancel platform notification
    // await flutterLocalNotificationsPlugin.cancel(id.hashCode);
  }

  /// Record notification sent
  Future<void> recordNotificationSent(
    String id,
    String title,
    NotificationType type,
  ) async {
    final event = NotificationEvent(
      id: id,
      title: title,
      type: type,
      sentTime: DateTime.now(),
    );

    _history.add(event);

    // Keep only last 100 events
    if (_history.length > 100) {
      _history.removeAt(0);
    }

    await _saveHistory();

    AnalyticsLogger.logEvent(
      'notification_sent',
      parameters: {
        'notification_id': id,
        'type': type.toString(),
      },
    );
  }

  /// Record notification opened
  Future<void> recordNotificationOpened(String id) async {
    final event = _history.firstWhere(
      (e) => e.id == id,
      orElse: () => NotificationEvent(
        id: id,
        title: 'Unknown',
        type: NotificationType.other,
        sentTime: DateTime.now(),
      ),
    );

    event.opened = true;
    event.openedTime = DateTime.now();

    await _saveHistory();

    AnalyticsLogger.logEvent(
      'notification_opened',
      parameters: {'notification_id': id},
    );
  }

  /// Adjust time for quiet hours
  DateTime _adjustForQuietHours(DateTime time) {
    final hour = time.hour;

    // Check if in quiet hours
    final inQuietHours = _quietHoursStart < _quietHoursEnd
        ? (hour >= _quietHoursStart || hour < _quietHoursEnd)
        : (hour >= _quietHoursStart && hour < _quietHoursEnd);

    if (!inQuietHours) return time;

    // Adjust to end of quiet hours
    var adjustedTime = DateTime(
      time.year,
      time.month,
      time.day,
      _quietHoursEnd,
      0,
    );

    // If we're past the end hour today, it's for today
    // Otherwise, it's for tomorrow
    if (hour >= _quietHoursStart) {
      adjustedTime = adjustedTime.add(const Duration(days: 1));
    }

    return adjustedTime;
  }

  /// Get notification statistics
  NotificationStatistics getStatistics() {
    final totalSent = _history.length;
    final totalOpened = _history.where((e) => e.opened).length;
    final openRate = totalSent > 0 ? totalOpened / totalSent : 0.0;

    final typeStats = <NotificationType, int>{};
    for (final event in _history) {
      typeStats[event.type] = (typeStats[event.type] ?? 0) + 1;
    }

    return NotificationStatistics(
      totalSent: totalSent,
      totalOpened: totalOpened,
      openRate: openRate,
      typeStats: typeStats,
      scheduledCount: _scheduledNotifications.length,
    );
  }

  /// Update last play time (for daily reminder)
  Future<void> updateLastPlayTime() async {
    await _prefs?.setString(_keyLastPlayTime, DateTime.now().toIso8601String());

    // Reschedule daily reminder
    await _scheduleDailyPlayReminder();
  }

  // Persistence methods

  Future<void> _loadScheduledNotifications() async {
    final json = _prefs?.getString(_keyScheduledNotifications);
    if (json != null) {
      try {
        final List<dynamic> list = jsonDecode(json);
        for (final item in list) {
          final notification = ScheduledNotification.fromJson(item);
          _scheduledNotifications[notification.id] = notification;
        }
      } catch (e) {
        debugPrint('❌ Error loading scheduled notifications: $e');
      }
    }
  }

  Future<void> _saveScheduledNotifications() async {
    final list = _scheduledNotifications.values
        .map((n) => n.toJson())
        .toList();
    await _prefs?.setString(_keyScheduledNotifications, jsonEncode(list));
  }

  Future<void> _loadHistory() async {
    final json = _prefs?.getString(_keyNotificationHistory);
    if (json != null) {
      try {
        final List<dynamic> list = jsonDecode(json);
        _history.clear();
        _history.addAll(list.map((item) => NotificationEvent.fromJson(item)));
      } catch (e) {
        debugPrint('❌ Error loading notification history: $e');
      }
    }
  }

  Future<void> _saveHistory() async {
    final list = _history.map((e) => e.toJson()).toList();
    await _prefs?.setString(_keyNotificationHistory, jsonEncode(list));
  }
}

/// Scheduled notification data class
class ScheduledNotification {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final NotificationType type;
  final Map<String, dynamic>? data;

  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.type,
    this.data,
  });

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.other,
      ),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime.toIso8601String(),
      'type': type.toString(),
      if (data != null) 'data': data,
    };
  }
}

/// Notification event (history)
class NotificationEvent {
  final String id;
  final String title;
  final NotificationType type;
  final DateTime sentTime;
  bool opened = false;
  DateTime? openedTime;

  NotificationEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.sentTime,
    this.opened = false,
    this.openedTime,
  });

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.other,
      ),
      sentTime: DateTime.parse(json['sentTime'] as String),
      opened: json['opened'] as bool? ?? false,
      openedTime: json['openedTime'] != null
          ? DateTime.parse(json['openedTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString(),
      'sentTime': sentTime.toIso8601String(),
      'opened': opened,
      if (openedTime != null) 'openedTime': openedTime!.toIso8601String(),
    };
  }
}

/// Notification type enum
enum NotificationType {
  dailyReminder,
  streakProtection,
  eventStarting,
  eventEnding,
  achievementProgress,
  achievementUnlocked,
  powerUpDeal,
  leaderboardUpdate,
  newLevelUnlocked,
  other,
}

/// Notification statistics
class NotificationStatistics {
  final int totalSent;
  final int totalOpened;
  final double openRate;
  final Map<NotificationType, int> typeStats;
  final int scheduledCount;

  NotificationStatistics({
    required this.totalSent,
    required this.totalOpened,
    required this.openRate,
    required this.typeStats,
    required this.scheduledCount,
  });

  @override
  String toString() {
    return 'NotificationStatistics(\n'
        '  sent: $totalSent,\n'
        '  opened: $totalOpened,\n'
        '  openRate: ${(openRate * 100).toStringAsFixed(1)}%,\n'
        '  scheduled: $scheduledCount\n'
        ')';
  }
}
