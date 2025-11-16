import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_logger.dart';

/// Service for managing app rating prompts with smart timing
/// Prompts users to rate the app after positive engagement signals
class RateAppService {
  RateAppService._();
  static final RateAppService instance = RateAppService._();

  final InAppReview _inAppReview = InAppReview.instance;

  static const String _keyLevelsCompleted = 'rate_app_levels_completed';
  static const String _keyPromptShown = 'rate_app_prompt_shown';
  static const String _keyLastPromptDate = 'rate_app_last_prompt';
  static const String _keyUserRated = 'rate_app_user_rated';

  static const int _levelsBeforePrompt = 5;
  static const int _daysBetweenPrompts = 30;

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();
  }

  /// Call this after every level completion
  Future<void> onLevelCompleted() async {
    if (!_initialized) await initialize();

    // Don't prompt if user already rated
    if (_hasUserRated()) return;

    // Increment level completion counter
    final levelsCompleted = _getLevelsCompleted() + 1;
    await _prefs.setInt(_keyLevelsCompleted, levelsCompleted);

    AnalyticsLogger.logEvent('rate_app_level_completed', parameters: {
      'levels_completed': levelsCompleted,
    });

    // Check if we should show the prompt
    if (levelsCompleted >= _levelsBeforePrompt && _shouldShowPrompt()) {
      await _showRatingPrompt();
    }
  }

  /// Manually trigger the rating prompt (e.g., from settings)
  Future<void> requestReview() async {
    if (!_initialized) await initialize();

    AnalyticsLogger.logEvent('rate_app_manual_trigger');

    await _showRatingPrompt();
  }

  Future<void> _showRatingPrompt() async {
    try {
      // Check if in-app review is available
      if (await _inAppReview.isAvailable()) {
        AnalyticsLogger.logEvent('rate_app_prompt_shown');

        // Update last prompt date
        await _prefs.setString(
          _keyLastPromptDate,
          DateTime.now().toIso8601String(),
        );
        await _prefs.setBool(_keyPromptShown, true);

        // Request the review (OS decides whether to show native dialog)
        await _inAppReview.requestReview();

        // Note: We can't know if user actually rated, so we don't set _keyUserRated
        // The OS handles this silently
      } else {
        AnalyticsLogger.logEvent('rate_app_not_available');

        // Fallback: Open app store page
        await _openStoreListing();
      }
    } catch (e) {
      AnalyticsLogger.logEvent('rate_app_error', parameters: {
        'error': e.toString(),
      });
    }
  }

  Future<void> _openStoreListing() async {
    try {
      // Opens the app's store listing for manual rating
      await _inAppReview.openStoreListing(
        // Optional: specify the app ID for each platform
        // appStoreId: 'your_app_store_id',
        // microsoftStoreId: 'your_microsoft_store_id',
      );

      AnalyticsLogger.logEvent('rate_app_store_opened');

      // Mark as prompted
      await _prefs.setBool(_keyUserRated, true);
    } catch (e) {
      AnalyticsLogger.logEvent('rate_app_store_open_failed', parameters: {
        'error': e.toString(),
      });
    }
  }

  bool _shouldShowPrompt() {
    // Don't show if already prompted recently
    final lastPromptDate = _getLastPromptDate();
    if (lastPromptDate != null) {
      final daysSincePrompt = DateTime.now().difference(lastPromptDate).inDays;
      if (daysSincePrompt < _daysBetweenPrompts) {
        return false;
      }
    }

    return true;
  }

  int _getLevelsCompleted() {
    return _prefs.getInt(_keyLevelsCompleted) ?? 0;
  }

  DateTime? _getLastPromptDate() {
    final dateString = _prefs.getString(_keyLastPromptDate);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  bool _hasUserRated() {
    return _prefs.getBool(_keyUserRated) ?? false;
  }

  /// Mark user as having rated (call this if you have external confirmation)
  Future<void> markUserAsRated() async {
    await _prefs.setBool(_keyUserRated, true);
    AnalyticsLogger.logEvent('rate_app_user_rated');
  }

  /// Reset the rating prompt state (for testing)
  Future<void> resetForTesting() async {
    await _prefs.remove(_keyLevelsCompleted);
    await _prefs.remove(_keyPromptShown);
    await _prefs.remove(_keyLastPromptDate);
    await _prefs.remove(_keyUserRated);
  }
}
