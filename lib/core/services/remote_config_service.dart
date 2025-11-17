import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/analytics_logger.dart';

/// Remote configuration service for live updates without app updates
///
/// Features:
/// - Feature flags (enable/disable features remotely)
/// - Dynamic values (pricing, limits, messages)
/// - A/B test parameters
/// - Emergency controls (kill switch)
/// - Caching with expiration
/// - Fallback to defaults
///
/// Usage:
/// ```dart
/// await RemoteConfigService.instance.initialize();
///
/// // Get values
/// final bool isEnabled = RemoteConfigService.instance.getBool('feature_x_enabled');
/// final int price = RemoteConfigService.instance.getInt('coin_pack_price');
/// final String message = RemoteConfigService.instance.getString('welcome_message');
///
/// // Force refresh
/// await RemoteConfigService.instance.fetchAndActivate();
/// ```
///
/// TODO: Replace mock fetch with actual Firebase Remote Config or custom backend
class RemoteConfigService {
  static final RemoteConfigService instance = RemoteConfigService._();
  RemoteConfigService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  final Map<String, dynamic> _config = {};
  final Map<String, dynamic> _defaults = {};

  DateTime? _lastFetchTime;
  static const Duration _cacheExpiration = Duration(hours: 12);

  static const String _keyConfig = 'remote_config_data';
  static const String _keyLastFetch = 'remote_config_last_fetch';

  /// Initialize remote config
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Set default values
    _setDefaults();

    // Load cached config
    await _loadCachedConfig();

    // Fetch fresh config if cache expired
    if (_isCacheExpired()) {
      await fetchAndActivate();
    }

    _initialized = true;

    debugPrint('✅ Remote Config Service initialized');
  }

  /// Fetch and activate new config
  Future<bool> fetchAndActivate() async {
    if (!_initialized) await initialize();

    try {
      debugPrint('🔄 Fetching remote config...');

      // Fetch from server
      final newConfig = await _fetchFromServer();

      // Merge with existing config
      _config.addAll(newConfig);

      // Save to cache
      await _saveCachedConfig();

      // Update last fetch time
      _lastFetchTime = DateTime.now();
      await _prefs?.setString(
        _keyLastFetch,
        _lastFetchTime!.toIso8601String(),
      );

      debugPrint('✅ Remote config fetched and activated');

      // Log to analytics
      AnalyticsLogger.logEvent(
        'remote_config_fetched',
        parameters: {'keys_count': newConfig.length},
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error fetching remote config: $e');
      return false;
    }
  }

  /// Get boolean value
  bool getBool(String key, {bool defaultValue = false}) {
    final value = _config[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return _defaults[key] as bool? ?? defaultValue;
  }

  /// Get integer value
  int getInt(String key, {int defaultValue = 0}) {
    final value = _config[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return _defaults[key] as int? ?? defaultValue;
  }

  /// Get double value
  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = _config[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return _defaults[key] as double? ?? defaultValue;
  }

  /// Get string value
  String getString(String key, {String defaultValue = ''}) {
    final value = _config[key];
    if (value is String) return value;
    return _defaults[key] as String? ?? defaultValue;
  }

  /// Get JSON value
  Map<String, dynamic>? getJson(String key) {
    final value = _config[key];
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      try {
        return jsonDecode(value) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('❌ Error parsing JSON for key $key: $e');
        return null;
      }
    }
    return _defaults[key] as Map<String, dynamic>?;
  }

  /// Get all config values
  Map<String, dynamic> getAll() {
    return Map.unmodifiable(_config);
  }

  /// Check if cache is expired
  bool _isCacheExpired() {
    if (_lastFetchTime == null) return true;
    final now = DateTime.now();
    return now.difference(_lastFetchTime!) > _cacheExpiration;
  }

  /// Set default values
  void _setDefaults() {
    _defaults.addAll({
      // Feature flags
      'achievements_enabled': true,
      'leaderboards_enabled': true,
      'events_enabled': true,
      'powerups_enabled': true,
      'social_share_enabled': true,
      'ads_enabled': true,
      'iap_enabled': true,

      // Gameplay settings
      'max_moves_multiplier': 1.0,
      'coin_reward_multiplier': 1.0,
      'star_threshold_easy': 0.7,
      'star_threshold_medium': 0.85,
      'star_threshold_hard': 0.95,

      // Monetization
      'ad_frequency_minutes': 3,
      'rewarded_ad_coin_reward': 50,
      'coin_pack_small_price': 0.99,
      'coin_pack_medium_price': 1.99,
      'coin_pack_large_price': 4.99,

      // Power-ups
      'powerup_undo_coins': 3,
      'powerup_hint_coins': 5,
      'powerup_shuffle_coins': 10,
      'powerup_autosort_coins': 15,
      'powerup_extramoves_coins': 20,

      // Social
      'referral_reward_coins': 100,
      'share_reward_coins': 10,
      'daily_streak_bonus': 50,

      // UI/UX
      'show_tutorial': true,
      'tutorial_max_stages': 6,
      'onboarding_pages': 5,
      'welcome_message': 'Welcome to SortBliss!',
      'update_message': '',

      // Emergency controls
      'maintenance_mode': false,
      'force_update_required': false,
      'min_app_version': '1.0.0',

      // Events
      'event_christmas_enabled': true,
      'event_newyear_enabled': true,
      'event_halloween_enabled': true,
      'event_valentine_enabled': true,

      // Limits
      'max_daily_ad_views': 20,
      'max_hourly_ad_views': 4,
      'max_level': 1000,
      'max_coins': 999999,
    });

    _config.addAll(_defaults);
  }

  /// Load cached config from storage
  Future<void> _loadCachedConfig() async {
    final configJson = _prefs?.getString(_keyConfig);
    if (configJson != null) {
      try {
        final Map<String, dynamic> cached = jsonDecode(configJson);
        _config.addAll(cached);
        debugPrint('📦 Loaded cached config (${cached.length} keys)');
      } catch (e) {
        debugPrint('❌ Error loading cached config: $e');
      }
    }

    final lastFetchStr = _prefs?.getString(_keyLastFetch);
    if (lastFetchStr != null) {
      try {
        _lastFetchTime = DateTime.parse(lastFetchStr);
      } catch (e) {
        debugPrint('❌ Error parsing last fetch time: $e');
      }
    }
  }

  /// Save config to cache
  Future<void> _saveCachedConfig() async {
    final configJson = jsonEncode(_config);
    await _prefs?.setString(_keyConfig, configJson);
  }

  /// Fetch config from server (mock implementation)
  ///
  /// TODO: Replace with actual backend call
  /// For Firebase Remote Config:
  /// ```dart
  /// final remoteConfig = FirebaseRemoteConfig.instance;
  /// await remoteConfig.setConfigSettings(RemoteConfigSettings(
  ///   fetchTimeout: const Duration(seconds: 10),
  ///   minimumFetchInterval: const Duration(hours: 1),
  /// ));
  /// await remoteConfig.fetchAndActivate();
  /// return remoteConfig.getAll().map((key, value) => MapEntry(key, value.asString()));
  /// ```
  Future<Map<String, dynamic>> _fetchFromServer() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock server response
    // In production, this would be an HTTP request to your backend
    // or Firebase Remote Config fetch
    final mockResponse = <String, dynamic>{
      // Example: Enable new feature for testing
      'achievements_enabled': true,
      'leaderboards_enabled': true,

      // Example: Adjust monetization
      'coin_reward_multiplier': 1.2, // 20% more coins
      'ad_frequency_minutes': 4, // Less frequent ads

      // Example: Seasonal event
      'event_christmas_enabled': _isChristmasSeason(),

      // Example: Emergency message
      'update_message': '',

      // Add timestamp for debugging
      '_fetched_at': DateTime.now().toIso8601String(),
    };

    return mockResponse;
  }

  /// Check if it's Christmas season (example of dynamic config)
  bool _isChristmasSeason() {
    final now = DateTime.now();
    return now.month == 12 && now.day >= 18 && now.day <= 27;
  }

  /// Force refresh (bypass cache)
  Future<bool> forceRefresh() async {
    _lastFetchTime = null;
    return await fetchAndActivate();
  }

  /// Reset to defaults (for testing)
  Future<void> resetToDefaults() async {
    _config.clear();
    _config.addAll(_defaults);
    await _prefs?.remove(_keyConfig);
    await _prefs?.remove(_keyLastFetch);
    _lastFetchTime = null;

    debugPrint('🔄 Remote config reset to defaults');
  }
}

/// Remote config keys (for type safety)
class RemoteConfigKeys {
  // Feature flags
  static const String achievementsEnabled = 'achievements_enabled';
  static const String leaderboardsEnabled = 'leaderboards_enabled';
  static const String eventsEnabled = 'events_enabled';
  static const String powerupsEnabled = 'powerups_enabled';
  static const String socialShareEnabled = 'social_share_enabled';
  static const String adsEnabled = 'ads_enabled';
  static const String iapEnabled = 'iap_enabled';

  // Gameplay
  static const String maxMovesMultiplier = 'max_moves_multiplier';
  static const String coinRewardMultiplier = 'coin_reward_multiplier';
  static const String starThresholdEasy = 'star_threshold_easy';
  static const String starThresholdMedium = 'star_threshold_medium';
  static const String starThresholdHard = 'star_threshold_hard';

  // Monetization
  static const String adFrequencyMinutes = 'ad_frequency_minutes';
  static const String rewardedAdCoinReward = 'rewarded_ad_coin_reward';
  static const String coinPackSmallPrice = 'coin_pack_small_price';
  static const String coinPackMediumPrice = 'coin_pack_medium_price';
  static const String coinPackLargePrice = 'coin_pack_large_price';

  // Power-ups
  static const String powerupUndoCoins = 'powerup_undo_coins';
  static const String powerupHintCoins = 'powerup_hint_coins';
  static const String powerupShuffleCoins = 'powerup_shuffle_coins';
  static const String powerupAutosortCoins = 'powerup_autosort_coins';
  static const String powerupExtramovesCoins = 'powerup_extramoves_coins';

  // Social
  static const String referralRewardCoins = 'referral_reward_coins';
  static const String shareRewardCoins = 'share_reward_coins';
  static const String dailyStreakBonus = 'daily_streak_bonus';

  // UI/UX
  static const String showTutorial = 'show_tutorial';
  static const String tutorialMaxStages = 'tutorial_max_stages';
  static const String onboardingPages = 'onboarding_pages';
  static const String welcomeMessage = 'welcome_message';
  static const String updateMessage = 'update_message';

  // Emergency
  static const String maintenanceMode = 'maintenance_mode';
  static const String forceUpdateRequired = 'force_update_required';
  static const String minAppVersion = 'min_app_version';

  // Limits
  static const String maxDailyAdViews = 'max_daily_ad_views';
  static const String maxHourlyAdViews = 'max_hourly_ad_views';
  static const String maxLevel = 'max_level';
  static const String maxCoins = 'max_coins';
}

/// Helper extension for easy access
extension RemoteConfigExtension on RemoteConfigService {
  // Feature flags
  bool get achievementsEnabled =>
      getBool(RemoteConfigKeys.achievementsEnabled, defaultValue: true);
  bool get leaderboardsEnabled =>
      getBool(RemoteConfigKeys.leaderboardsEnabled, defaultValue: true);
  bool get eventsEnabled =>
      getBool(RemoteConfigKeys.eventsEnabled, defaultValue: true);
  bool get powerupsEnabled =>
      getBool(RemoteConfigKeys.powerupsEnabled, defaultValue: true);
  bool get socialShareEnabled =>
      getBool(RemoteConfigKeys.socialShareEnabled, defaultValue: true);
  bool get adsEnabled =>
      getBool(RemoteConfigKeys.adsEnabled, defaultValue: true);
  bool get iapEnabled =>
      getBool(RemoteConfigKeys.iapEnabled, defaultValue: true);

  // Gameplay
  double get coinRewardMultiplier =>
      getDouble(RemoteConfigKeys.coinRewardMultiplier, defaultValue: 1.0);
  double get maxMovesMultiplier =>
      getDouble(RemoteConfigKeys.maxMovesMultiplier, defaultValue: 1.0);

  // Monetization
  int get adFrequencyMinutes =>
      getInt(RemoteConfigKeys.adFrequencyMinutes, defaultValue: 3);
  int get rewardedAdCoinReward =>
      getInt(RemoteConfigKeys.rewardedAdCoinReward, defaultValue: 50);

  // Power-ups
  int get powerupUndoCoins =>
      getInt(RemoteConfigKeys.powerupUndoCoins, defaultValue: 3);
  int get powerupHintCoins =>
      getInt(RemoteConfigKeys.powerupHintCoins, defaultValue: 5);

  // Social
  int get referralRewardCoins =>
      getInt(RemoteConfigKeys.referralRewardCoins, defaultValue: 100);
  int get shareRewardCoins =>
      getInt(RemoteConfigKeys.shareRewardCoins, defaultValue: 10);

  // Emergency
  bool get maintenanceMode =>
      getBool(RemoteConfigKeys.maintenanceMode, defaultValue: false);
  bool get forceUpdateRequired =>
      getBool(RemoteConfigKeys.forceUpdateRequired, defaultValue: false);
  String get updateMessage =>
      getString(RemoteConfigKeys.updateMessage, defaultValue: '');
}
