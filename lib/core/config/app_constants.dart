/// App-wide constants and configuration
///
/// Centralized location for all magic numbers, strings, and configuration.
/// Makes it easy to adjust values and maintain consistency.

class AppConstants {
  // App Info
  static const String appName = 'SortBliss';
  static const String appTagline = 'Organize Your Mind';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  // URLs
  static const String privacyPolicyUrl = 'https://sortbliss.com/privacy';
  static const String termsOfServiceUrl = 'https://sortbliss.com/terms';
  static const String supportEmail = 'support@sortbliss.com';
  static const String feedbackEmail = 'feedback@sortbliss.com';
  static const String websiteUrl = 'https://sortbliss.com';

  // Deep Links
  static const String deepLinkScheme = 'sortbliss';
  static const String deepLinkHost = 'app';

  // Gameplay Constants
  static const int maxLevel = 1000;
  static const int tutorialLevels = 5;
  static const double starThreshold3 = 1.0; // Perfect
  static const double starThreshold2 = 0.85;
  static const double starThreshold1 = 0.70;

  // Coin Economy
  static const int starterCoins = 100;
  static const int levelCompletionCoinsBase = 10;
  static const int levelCompletionCoinsPerStar = 10;
  static const int perfectLevelBonus = 20;
  static const int dailyRewardDay1 = 10;
  static const int dailyRewardDay7 = 100;
  static const int referralReward = 100;
  static const int shareReward = 10;
  static const int achievementRewardBronze = 50;
  static const int achievementRewardSilver = 100;
  static const int achievementRewardGold = 250;
  static const int achievementRewardPlatinum = 500;

  // Power-Up Costs
  static const int powerUpUndoCost = 3;
  static const int powerUpHintCost = 5;
  static const int powerUpShuffleCost = 10;
  static const int powerUpAutoSortCost = 15;
  static const int powerUpExtraMovesCost = 20;

  // IAP Product IDs
  static const String iapCoinsSmall = 'com.sortbliss.coins.small';
  static const String iapCoinsMedium = 'com.sortbliss.coins.medium';
  static const String iapCoinsLarge = 'com.sortbliss.coins.large';
  static const String iapPowerUpStarter = 'com.sortbliss.powerup.starter';
  static const String iapPowerUpPro = 'com.sortbliss.powerup.pro';
  static const String iapPowerUpUltimate = 'com.sortbliss.powerup.ultimate';
  static const String iapRemoveAds = 'com.sortbliss.removeads';

  // IAP Prices (default, overridden by dynamic pricing)
  static const double iapPriceCoinsSmall = 0.99;
  static const double iapPriceCoinsMedium = 1.99;
  static const double iapPriceCoinsLarge = 4.99;
  static const double iapPricePowerUpStarter = 2.99;
  static const double iapPricePowerUpPro = 6.99;
  static const double iapPricePowerUpUltimate = 12.99;
  static const double iapPriceRemoveAds = 4.99;

  // Ad Configuration
  static const int maxDailyAdViews = 20;
  static const int maxHourlyAdViews = 4;
  static const int adFrequencyMinutes = 3;
  static const int rewardedAdCoinReward = 50;
  static const int interstitialAdMinInterval = 180; // seconds

  // AdMob Ad Unit IDs (TEST IDS - replace with real ones)
  static const String adMobAppId = 'ca-app-pub-3940256099942544~3347511713'; // TEST
  static const String adMobBannerId = 'ca-app-pub-3940256099942544/6300978111'; // TEST
  static const String adMobInterstitialId = 'ca-app-pub-3940256099942544/1033173712'; // TEST
  static const String adMobRewardedId = 'ca-app-pub-3940256099942544/5224354917'; // TEST

  // Analytics Events
  static const String eventLevelStarted = 'level_started';
  static const String eventLevelCompleted = 'level_completed';
  static const String eventLevelFailed = 'level_failed';
  static const String eventAchievementUnlocked = 'achievement_unlocked';
  static const String eventPowerUpPurchased = 'powerup_purchased';
  static const String eventPowerUpUsed = 'powerup_used';
  static const String eventCoinsPurchased = 'coins_purchased';
  static const String eventCoinsEarned = 'coins_earned';
  static const String eventCoinsSpent = 'coins_spent';
  static const String eventDailyRewardClaimed = 'daily_reward_claimed';
  static const String eventRatingPromptShown = 'rating_prompt_shown';
  static const String eventRatingCompleted = 'rating_completed';
  static const String eventShareCompleted = 'share_completed';
  static const String eventReferralUsed = 'referral_used';

  // Notification Channels
  static const String notificationChannelIdDefault = 'default';
  static const String notificationChannelIdDaily = 'daily_rewards';
  static const String notificationChannelIdEvents = 'events';
  static const String notificationChannelIdAchievements = 'achievements';

  // Notification IDs
  static const int notificationIdDailyReward = 1;
  static const int notificationIdStreakProtection = 2;
  static const int notificationIdEventStarting = 3;
  static const int notificationIdEventEnding = 4;
  static const int notificationIdAchievementProgress = 5;

  // Rating Service
  static const int ratingMinSessions = 5;
  static const int ratingMinLevels = 10;
  static const int ratingMinDays = 3;
  static const int ratingPromptCooldown = 30; // days
  static const int ratingMaxPrompts = 3;

  // Social Sharing
  static const String shareMessageLevel = 'I just completed level {level} in SortBliss with {stars}⭐ and a score of {score}!';
  static const String shareMessageAchievement = 'I unlocked the "{achievement}" achievement in SortBliss! 🏆';
  static const String shareMessageReferral = 'Join me on SortBliss! Use my code {code} for bonus coins. Download: {url}';

  // Achievements
  static const int totalAchievements = 26;
  static const int achievementBronzeTier = 4;
  static const int achievementSilverTier = 8;
  static const int achievementGoldTier = 12;
  static const int achievementPlatinumTier = 2;

  // Leaderboards
  static const int leaderboardTopCount = 100;
  static const int leaderboardRefreshInterval = 300; // seconds

  // Events
  static const int totalEvents = 7;
  static const int eventRewardCoinsMin = 100;
  static const int eventRewardCoinsMax = 1000;

  // Tutorial
  static const int totalTutorialSteps = 6;
  static const bool tutorialDefaultEnabled = true;

  // Onboarding
  static const int totalOnboardingPages = 5;
  static const bool onboardingSkippable = true;

  // Performance
  static const int targetFps = 60;
  static const double jankThreshold = 16.67; // ms
  static const int maxFrameTimeSamples = 100;

  // Cache
  static const int maxAnalyticsQueueSize = 1000;
  static const int maxTransactionHistorySize = 100;
  static const int maxNotificationHistorySize = 100;
  static const Duration remoteconfigCacheExpiration = Duration(hours: 12);

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration apiTimeout = Duration(seconds: 30);

  // Quiet Hours (notifications)
  static const int quietHoursStart = 22; // 10 PM
  static const int quietHoursEnd = 8; // 8 AM

  // UI Constants
  static const Duration splashMinDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Combo System
  static const int comboTier1 = 3; // 1.5x multiplier
  static const int comboTier2 = 5; // 2x multiplier
  static const int comboTier3 = 10; // 3x multiplier
  static const int comboTier4 = 15; // 4x multiplier
  static const int comboTier5 = 20; // 5x multiplier
  static const double comboMultiplier1 = 1.5;
  static const double comboMultiplier2 = 2.0;
  static const double comboMultiplier3 = 3.0;
  static const double comboMultiplier4 = 4.0;
  static const double comboMultiplier5 = 5.0;
  static const int comboTimeout = 5; // seconds

  // Haptic Feedback Types
  static const bool hapticDefaultEnabled = true;
  static const bool soundDefaultEnabled = true;
  static const bool musicDefaultEnabled = true;
  static const double soundDefaultVolume = 0.7;
  static const double musicDefaultVolume = 0.5;

  // Debug
  static const bool debugMenuEnabled = true; // Set to false in production!
  static const bool debugLoggingEnabled = true;
  static const bool debugPerformanceOverlay = false;
}

/// Color palette
class AppColors {
  // Primary colors
  static const int primaryColor = 0xFF6200EE;
  static const int primaryVariant = 0xFF3700B3;
  static const int secondary = 0xFF03DAC6;

  // Game colors (for sorting items)
  static const int color0 = 0xFFE53935; // Red
  static const int color1 = 0xFF1E88E5; // Blue
  static const int color2 = 0xFF43A047; // Green
  static const int color3 = 0xFFFB8C00; // Orange
  static const int color4 = 0xFF8E24AA; // Purple
  static const int color5 = 0xFFFFEB3B; // Yellow
  static const int color6 = 0xFF00ACC1; // Cyan
  static const int color7 = 0xFFE91E63; // Pink

  // Achievement tiers
  static const int tierBronze = 0xFF8D6E63;
  static const int tierSilver = 0xFF757575;
  static const int tierGold = 0xFFFFB300;
  static const int tierPlatinum = 0xFF1976D2;
}

/// Asset paths
class AppAssets {
  // Images
  static const String logoPath = 'assets/images/logo.png';
  static const String iconPath = 'assets/images/icon.png';

  // Sounds (if implemented)
  static const String soundTap = 'assets/sounds/tap.mp3';
  static const String soundSuccess = 'assets/sounds/success.mp3';
  static const String soundError = 'assets/sounds/error.mp3';
  static const String soundLevelComplete = 'assets/sounds/level_complete.mp3';
  static const String soundAchievement = 'assets/sounds/achievement.mp3';
  static const String soundCoin = 'assets/sounds/coin.mp3';
  static const String musicBackground = 'assets/music/background.mp3';

  // Animations (if implemented)
  static const String animConfetti = 'assets/animations/confetti.json';
}

/// Environment configuration
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment current = Environment.development;

  static bool get isDevelopment => current == Environment.development;
  static bool get isStaging => current == Environment.staging;
  static bool get isProduction => current == Environment.production;

  static String get apiBaseUrl {
    switch (current) {
      case Environment.development:
        return 'https://dev-api.sortbliss.com';
      case Environment.staging:
        return 'https://staging-api.sortbliss.com';
      case Environment.production:
        return 'https://api.sortbliss.com';
    }
  }
}
