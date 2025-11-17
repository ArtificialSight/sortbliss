import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_logger.dart';

/// Ad frequency optimization service to maximize ARPDAU while preventing ad fatigue
/// Implements frequency capping, adaptive intervals, and engagement-based scaling
class AdFrequencyOptimizer {
  AdFrequencyOptimizer._();
  static final AdFrequencyOptimizer instance = AdFrequencyOptimizer._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Frequency caps
  static const int _maxInterstitialsPerHour = 4;
  static const int _maxInterstitialsPerDay = 20;
  static const int _minSecondsBetweenInterstitials = 180; // 3 minutes
  static const int _minSecondsBetweenRewarded = 60; // 1 minute

  // Keys
  static const String _keyInterstitialHistory = 'ad_interstitial_history';
  static const String _keyRewardedHistory = 'ad_rewarded_history';
  static const String _keyLastInterstitialTime = 'ad_last_interstitial';
  static const String _keyLastRewardedTime = 'ad_last_rewarded';
  static const String _keySessionStart = 'ad_session_start';
  static const String _keyDaysActive = 'ad_days_active';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();

    // Track session start
    await _prefs.setString(_keySessionStart, DateTime.now().toIso8601String());
  }

  /// Check if interstitial ad can be shown
  Future<bool> canShowInterstitial() async {
    if (!_initialized) await initialize();

    // Check minimum time since last ad
    final lastShown = _getLastInterstitialTime();
    if (lastShown != null) {
      final secondsSince = DateTime.now().difference(lastShown).inSeconds;
      if (secondsSince < _minSecondsBetweenInterstitials) {
        AnalyticsLogger.logEvent('ad_blocked_cooldown', parameters: {
          'type': 'interstitial',
          'seconds_since_last': secondsSince,
          'required_seconds': _minSecondsBetweenInterstitials,
        });
        return false;
      }
    }

    // Check hourly cap
    final hourCount = _getInterstitialsInLastHour();
    if (hourCount >= _maxInterstitialsPerHour) {
      AnalyticsLogger.logEvent('ad_blocked_hourly_cap', parameters: {
        'type': 'interstitial',
        'count': hourCount,
        'max': _maxInterstitialsPerHour,
      });
      return false;
    }

    // Check daily cap
    final dayCount = _getInterstitialsInLastDay();
    if (dayCount >= _maxInterstitialsPerDay) {
      AnalyticsLogger.logEvent('ad_blocked_daily_cap', parameters: {
        'type': 'interstitial',
        'count': dayCount,
        'max': _maxInterstitialsPerDay,
      });
      return false;
    }

    return true;
  }

  /// Check if rewarded ad can be shown
  Future<bool> canShowRewarded() async {
    if (!_initialized) await initialize();

    // Rewarded ads have more lenient frequency (user initiated)
    final lastShown = _getLastRewardedTime();
    if (lastShown != null) {
      final secondsSince = DateTime.now().difference(lastShown).inSeconds;
      if (secondsSince < _minSecondsBetweenRewarded) {
        AnalyticsLogger.logEvent('ad_blocked_cooldown', parameters: {
          'type': 'rewarded',
          'seconds_since_last': secondsSince,
          'required_seconds': _minSecondsBetweenRewarded,
        });
        return false;
      }
    }

    return true;
  }

  /// Record interstitial ad shown
  Future<void> recordInterstitialShown() async {
    final now = DateTime.now();

    // Update last shown time
    await _prefs.setString(_keyLastInterstitialTime, now.toIso8601String());

    // Add to history
    final history = _getAdHistory(_keyInterstitialHistory);
    history.add(now);
    await _saveAdHistory(_keyInterstitialHistory, history);

    AnalyticsLogger.logEvent('ad_shown', parameters: {
      'type': 'interstitial',
      'hour_count': _getInterstitialsInLastHour(),
      'day_count': _getInterstitialsInLastDay(),
    });
  }

  /// Record rewarded ad shown
  Future<void> recordRewardedShown() async {
    final now = DateTime.now();

    // Update last shown time
    await _prefs.setString(_keyLastRewardedTime, now.toIso8601String());

    // Add to history
    final history = _getAdHistory(_keyRewardedHistory);
    history.add(now);
    await _saveAdHistory(_keyRewardedHistory, history);

    AnalyticsLogger.logEvent('ad_shown', parameters: {
      'type': 'rewarded',
    });
  }

  /// Get optimal level interval for interstitial ads based on session duration
  int getOptimalLevelInterval() {
    final sessionDuration = _getSessionDuration();

    // Short sessions (< 5 min): Show less frequently
    if (sessionDuration < 5) return 5; // Every 5 levels

    // Medium sessions (5-15 min): Normal frequency
    if (sessionDuration < 15) return 3; // Every 3 levels

    // Long sessions (15+ min): More frequent (engaged users)
    return 2; // Every 2 levels
  }

  /// Get ad frequency multiplier based on user engagement
  double getFrequencyMultiplier() {
    final daysActive = _getDaysActive();

    // New users: Fewer ads (onboarding)
    if (daysActive < 3) return 0.5; // 50% normal frequency

    // Early retention: Slightly fewer ads
    if (daysActive < 7) return 0.75; // 75% normal frequency

    // Established users: Normal frequency
    if (daysActive < 30) return 1.0;

    // Power users: Can handle more ads
    return 1.25; // 125% normal frequency
  }

  /// Calculate session duration in minutes
  double _getSessionDuration() {
    final startString = _prefs.getString(_keySessionStart);
    if (startString == null) return 0;

    final start = DateTime.tryParse(startString);
    if (start == null) return 0;

    final duration = DateTime.now().difference(start);
    return duration.inSeconds / 60.0;
  }

  /// Get days active count
  int _getDaysActive() {
    return _prefs.getInt(_keyDaysActive) ?? 1;
  }

  /// Increment days active
  Future<void> incrementDaysActive() async {
    final current = _getDaysActive();
    await _prefs.setInt(_keyDaysActive, current + 1);
  }

  /// Get interstitials shown in last hour
  int _getInterstitialsInLastHour() {
    final history = _getAdHistory(_keyInterstitialHistory);
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

    return history.where((time) => time.isAfter(oneHourAgo)).length;
  }

  /// Get interstitials shown in last day
  int _getInterstitialsInLastDay() {
    final history = _getAdHistory(_keyInterstitialHistory);
    final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));

    return history.where((time) => time.isAfter(oneDayAgo)).length;
  }

  /// Get last interstitial time
  DateTime? _getLastInterstitialTime() {
    final timeString = _prefs.getString(_keyLastInterstitialTime);
    if (timeString == null) return null;
    return DateTime.tryParse(timeString);
  }

  /// Get last rewarded time
  DateTime? _getLastRewardedTime() {
    final timeString = _prefs.getString(_keyLastRewardedTime);
    if (timeString == null) return null;
    return DateTime.tryParse(timeString);
  }

  /// Get ad history
  List<DateTime> _getAdHistory(String key) {
    final historyString = _prefs.getString(key);
    if (historyString == null) return [];

    try {
      final timestamps = historyString.split(',');
      return timestamps
          .map((s) => DateTime.tryParse(s))
          .whereType<DateTime>()
          .toList();
    } catch (e) {
      debugPrint('Error parsing ad history: $e');
      return [];
    }
  }

  /// Save ad history
  Future<void> _saveAdHistory(String key, List<DateTime> history) async {
    // Keep only last 24 hours of history
    final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
    final filtered = history.where((time) => time.isAfter(oneDayAgo)).toList();

    final historyString = filtered.map((time) => time.toIso8601String()).join(',');
    await _prefs.setString(key, historyString);
  }

  /// Get ad statistics
  AdFrequencyStats getStats() {
    return AdFrequencyStats(
      interstitialsLastHour: _getInterstitialsInLastHour(),
      interstitialsLastDay: _getInterstitialsInLastDay(),
      sessionDuration: _getSessionDuration(),
      daysActive: _getDaysActive(),
      optimalLevelInterval: getOptimalLevelInterval(),
      frequencyMultiplier: getFrequencyMultiplier(),
    );
  }

  /// Reset for testing
  Future<void> resetForTesting() async {
    await _prefs.remove(_keyInterstitialHistory);
    await _prefs.remove(_keyRewardedHistory);
    await _prefs.remove(_keyLastInterstitialTime);
    await _prefs.remove(_keyLastRewardedTime);
    await _prefs.remove(_keySessionStart);
    await _prefs.remove(_keyDaysActive);

    await _prefs.setString(_keySessionStart, DateTime.now().toIso8601String());
  }
}

/// Ad frequency statistics
class AdFrequencyStats {
  const AdFrequencyStats({
    required this.interstitialsLastHour,
    required this.interstitialsLastDay,
    required this.sessionDuration,
    required this.daysActive,
    required this.optimalLevelInterval,
    required this.frequencyMultiplier,
  });

  final int interstitialsLastHour;
  final int interstitialsLastDay;
  final double sessionDuration;
  final int daysActive;
  final int optimalLevelInterval;
  final double frequencyMultiplier;

  Map<String, dynamic> toJson() {
    return {
      'interstitials_last_hour': interstitialsLastHour,
      'interstitials_last_day': interstitialsLastDay,
      'session_duration_minutes': sessionDuration,
      'days_active': daysActive,
      'optimal_level_interval': optimalLevelInterval,
      'frequency_multiplier': frequencyMultiplier,
    };
  }
}
