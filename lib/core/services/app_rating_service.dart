import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/analytics_logger.dart';

/// Intelligent app rating service for maximizing positive reviews
///
/// Features:
/// - Smart timing (only ask when user is happy)
/// - Trigger conditions (positive moments only)
/// - Rate limiting (don't spam users)
/// - Platform-specific integration (iOS App Store, Google Play)
/// - Analytics tracking
///
/// Trigger Conditions (all must be met):
/// - Minimum sessions: 5
/// - Minimum levels completed: 10
/// - Minimum days since install: 3
/// - Recent 3-star level completion (positive moment)
/// - Not asked in last 30 days
/// - Never rated (or not yet)
/// - No recent negative feedback
///
/// Usage:
/// ```dart
/// await AppRatingService.instance.initialize();
///
/// // Check if should prompt
/// if (AppRatingService.instance.shouldPromptForRating()) {
///   await AppRatingService.instance.promptForRating(context);
/// }
/// ```
///
/// TODO: Integrate with in_app_review package for native rating prompts
class AppRatingService {
  static final AppRatingService instance = AppRatingService._();
  AppRatingService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  static const String _keyFirstLaunchDate = 'app_first_launch_date';
  static const String _keySessionCount = 'app_session_count';
  static const String _keyLevelsCompleted = 'app_levels_for_rating';
  static const String _keyLastRatingPromptDate = 'app_last_rating_prompt';
  static const String _keyUserRated = 'app_user_rated';
  static const String _keyUserDeclinedRating = 'app_user_declined_rating';
  static const String _keyPromptCount = 'app_rating_prompt_count';
  static const String _keyLastNegativeFeedback = 'app_last_negative_feedback';

  // Thresholds
  static const int _minSessions = 5;
  static const int _minLevels = 10;
  static const int _minDaysSinceInstall = 3;
  static const int _minDaysBetweenPrompts = 30;
  static const int _maxPromptCount = 3; // Don't ask more than 3 times

  /// Initialize app rating service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Record first launch if not set
    final firstLaunch = _prefs?.getString(_keyFirstLaunchDate);
    if (firstLaunch == null) {
      await _prefs?.setString(
        _keyFirstLaunchDate,
        DateTime.now().toIso8601String(),
      );
    }

    // Increment session count
    await _incrementSessionCount();

    _initialized = true;

    debugPrint('✅ App Rating Service initialized');
  }

  /// Check if should prompt for rating
  bool shouldPromptForRating() {
    if (!_initialized) return false;

    // Check if user already rated
    if (_prefs?.getBool(_keyUserRated) ?? false) {
      return false;
    }

    // Check prompt count
    final promptCount = _prefs?.getInt(_keyPromptCount) ?? 0;
    if (promptCount >= _maxPromptCount) {
      return false;
    }

    // Check minimum sessions
    final sessionCount = _prefs?.getInt(_keySessionCount) ?? 0;
    if (sessionCount < _minSessions) {
      return false;
    }

    // Check minimum levels
    final levelsCompleted = _prefs?.getInt(_keyLevelsCompleted) ?? 0;
    if (levelsCompleted < _minLevels) {
      return false;
    }

    // Check days since install
    final firstLaunchStr = _prefs?.getString(_keyFirstLaunchDate);
    if (firstLaunchStr != null) {
      final firstLaunch = DateTime.parse(firstLaunchStr);
      final daysSinceInstall = DateTime.now().difference(firstLaunch).inDays;
      if (daysSinceInstall < _minDaysSinceInstall) {
        return false;
      }
    }

    // Check days since last prompt
    final lastPromptStr = _prefs?.getString(_keyLastRatingPromptDate);
    if (lastPromptStr != null) {
      final lastPrompt = DateTime.parse(lastPromptStr);
      final daysSincePrompt = DateTime.now().difference(lastPrompt).inDays;
      if (daysSincePrompt < _minDaysBetweenPrompts) {
        return false;
      }
    }

    // Check for recent negative feedback (don't ask if user had issues recently)
    final lastNegativeStr = _prefs?.getString(_keyLastNegativeFeedback);
    if (lastNegativeStr != null) {
      final lastNegative = DateTime.parse(lastNegativeStr);
      final daysSinceNegative = DateTime.now().difference(lastNegative).inDays;
      if (daysSinceNegative < 7) {
        // Don't ask within a week of negative feedback
        return false;
      }
    }

    return true;
  }

  /// Prompt user for rating
  ///
  /// TODO: Replace with actual in_app_review package
  /// ```dart
  /// final InAppReview inAppReview = InAppReview.instance;
  /// if (await inAppReview.isAvailable()) {
  ///   await inAppReview.requestReview();
  /// }
  /// ```
  Future<void> promptForRating(dynamic context) async {
    if (!shouldPromptForRating()) return;

    // Record prompt
    await _recordPrompt();

    // Log analytics
    AnalyticsLogger.logEvent('rating_prompt_shown');

    // Show native rating dialog (mock)
    debugPrint('📱 Showing rating prompt...');

    // TODO: Show actual native prompt
    // For now, this is a placeholder
    // The actual implementation would use in_app_review package

    // Mock: Assume user will rate
    // In real implementation, this would be handled by callbacks
  }

  /// Record that user rated the app
  Future<void> recordUserRated() async {
    await _prefs?.setBool(_keyUserRated, true);

    AnalyticsLogger.logEvent('app_rated');

    debugPrint('⭐ User rated the app!');
  }

  /// Record that user declined to rate
  Future<void> recordUserDeclined() async {
    await _prefs?.setBool(_keyUserDeclinedRating, true);

    AnalyticsLogger.logEvent('rating_declined');

    debugPrint('❌ User declined to rate');
  }

  /// Record that user wants to rate later
  Future<void> recordRemindLater() async {
    // Just record the prompt, will ask again after cooldown period
    AnalyticsLogger.logEvent('rating_remind_later');

    debugPrint('⏰ User wants to rate later');
  }

  /// Record level completion for rating threshold
  Future<void> recordLevelCompleted() async {
    final current = _prefs?.getInt(_keyLevelsCompleted) ?? 0;
    await _prefs?.setInt(_keyLevelsCompleted, current + 1);
  }

  /// Record negative feedback (delays rating prompt)
  Future<void> recordNegativeFeedback() async {
    await _prefs?.setString(
      _keyLastNegativeFeedback,
      DateTime.now().toIso8601String(),
    );

    AnalyticsLogger.logEvent('negative_feedback_recorded');
  }

  /// Trigger rating prompt at optimal moment (after 3-star level)
  Future<void> triggerAfterPositiveMoment(
    dynamic context, {
    required int stars,
  }) async {
    // Only trigger after high-quality completion
    if (stars < 3) return;

    if (shouldPromptForRating()) {
      // Slight delay for better UX (don't interrupt celebration)
      await Future.delayed(const Duration(seconds: 2));
      await promptForRating(context);
    }
  }

  /// Get rating statistics
  RatingStatistics getStatistics() {
    return RatingStatistics(
      sessionCount: _prefs?.getInt(_keySessionCount) ?? 0,
      levelsCompleted: _prefs?.getInt(_keyLevelsCompleted) ?? 0,
      promptCount: _prefs?.getInt(_keyPromptCount) ?? 0,
      userRated: _prefs?.getBool(_keyUserRated) ?? false,
      userDeclined: _prefs?.getBool(_keyUserDeclinedRating) ?? false,
      daysSinceInstall: _getDaysSinceInstall(),
      shouldPrompt: shouldPromptForRating(),
    );
  }

  /// Increment session count
  Future<void> _incrementSessionCount() async {
    final current = _prefs?.getInt(_keySessionCount) ?? 0;
    await _prefs?.setInt(_keySessionCount, current + 1);
  }

  /// Record rating prompt shown
  Future<void> _recordPrompt() async {
    final current = _prefs?.getInt(_keyPromptCount) ?? 0;
    await _prefs?.setInt(_keyPromptCount, current + 1);
    await _prefs?.setString(
      _keyLastRatingPromptDate,
      DateTime.now().toIso8601String(),
    );
  }

  /// Get days since install
  int _getDaysSinceInstall() {
    final firstLaunchStr = _prefs?.getString(_keyFirstLaunchDate);
    if (firstLaunchStr == null) return 0;

    final firstLaunch = DateTime.parse(firstLaunchStr);
    return DateTime.now().difference(firstLaunch).inDays;
  }

  /// Reset all rating data (for testing)
  Future<void> resetAll() async {
    await _prefs?.remove(_keySessionCount);
    await _prefs?.remove(_keyLevelsCompleted);
    await _prefs?.remove(_keyLastRatingPromptDate);
    await _prefs?.remove(_keyUserRated);
    await _prefs?.remove(_keyUserDeclinedRating);
    await _prefs?.remove(_keyPromptCount);
    await _prefs?.remove(_keyLastNegativeFeedback);

    debugPrint('🔄 Rating service reset');
  }
}

/// Rating statistics data class
class RatingStatistics {
  final int sessionCount;
  final int levelsCompleted;
  final int promptCount;
  final bool userRated;
  final bool userDeclined;
  final int daysSinceInstall;
  final bool shouldPrompt;

  RatingStatistics({
    required this.sessionCount,
    required this.levelsCompleted,
    required this.promptCount,
    required this.userRated,
    required this.userDeclined,
    required this.daysSinceInstall,
    required this.shouldPrompt,
  });

  @override
  String toString() {
    return 'RatingStatistics(\n'
        '  sessions: $sessionCount,\n'
        '  levels: $levelsCompleted,\n'
        '  prompts: $promptCount,\n'
        '  rated: $userRated,\n'
        '  declined: $userDeclined,\n'
        '  days: $daysSinceInstall,\n'
        '  shouldPrompt: $shouldPrompt\n'
        ')';
  }
}

/// Custom rating dialog widget (fallback if in_app_review not available)
///
/// This provides a custom dialog that can:
/// 1. Show initial sentiment check ("Are you enjoying SortBliss?")
/// 2. If yes -> Direct to app store rating
/// 3. If no -> Collect feedback instead of rating
class CustomRatingDialog {
  /// Show rating dialog with sentiment check
  static Future<void> show(dynamic context) async {
    // TODO: Implement custom dialog
    // This would be a fallback if in_app_review package is not available
    // or for additional customization

    debugPrint('🎯 Custom rating dialog (to be implemented)');

    // Example structure:
    // Step 1: "Are you enjoying SortBliss?" (Yes/No)
    // If Yes: "Would you mind rating us?" -> App Store
    // If No: "We'd love your feedback!" -> Feedback form
  }
}

/// Best practices for app ratings:
///
/// 1. Timing is everything:
///    - Ask after positive moments (3-star level, achievement unlock)
///    - Never interrupt gameplay
///    - Wait a few days after install
///
/// 2. Don't spam:
///    - Maximum 3 prompts ever
///    - Wait at least 30 days between prompts
///    - Respect user's decision
///
/// 3. Sentiment check:
///    - Ask if they like the app first
///    - If no, collect feedback instead
///    - If yes, then ask for rating
///
/// 4. Make it easy:
///    - Use native prompts (in_app_review)
///    - Single tap to rate
///    - Clear "Not now" option
///
/// 5. Track everything:
///    - Log prompt impressions
///    - Track conversion rate
///    - Analyze optimal timing
///    - Monitor for issues before prompting
