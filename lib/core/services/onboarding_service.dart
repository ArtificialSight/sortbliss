import 'package:shared_preferences/shared_preferences.dart';
import '../utils/analytics_logger.dart';

/// Manages onboarding flow and first-time user experience
///
/// Tracks:
/// - Onboarding completion status
/// - Which onboarding steps user has seen
/// - Permission grant status
/// - Tutorial completion
/// - First game played
class OnboardingService {
  static final OnboardingService instance = OnboardingService._();
  OnboardingService._();

  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyWelcomeSeen = 'welcome_seen';
  static const String _keyFeaturesSeen = 'features_seen';
  static const String _keyPermissionsSeen = 'permissions_seen';
  static const String _keyTutorialComplete = 'tutorial_complete';
  static const String _keyFirstGamePlayed = 'first_game_played';
  static const String _keyOnboardingVersion = 'onboarding_version';

  static const int currentOnboardingVersion = 1;

  SharedPreferences? _prefs;

  /// Initialize onboarding service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    AnalyticsLogger.logEvent('onboarding_service_initialized', parameters: {
      'onboarding_complete': isOnboardingComplete(),
      'version': getOnboardingVersion(),
    });
  }

  /// Check if user has completed onboarding
  bool isOnboardingComplete() {
    return _prefs?.getBool(_keyOnboardingComplete) ?? false;
  }

  /// Check if onboarding version is current (for showing new features)
  bool isOnboardingVersionCurrent() {
    final version = getOnboardingVersion();
    return version >= currentOnboardingVersion;
  }

  /// Get onboarding version
  int getOnboardingVersion() {
    return _prefs?.getInt(_keyOnboardingVersion) ?? 0;
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    await _prefs?.setBool(_keyOnboardingComplete, true);
    await _prefs?.setInt(_keyOnboardingVersion, currentOnboardingVersion);

    AnalyticsLogger.logEvent('onboarding_completed', parameters: {
      'version': currentOnboardingVersion,
    });
  }

  /// Mark welcome screen as seen
  Future<void> markWelcomeSeen() async {
    await _prefs?.setBool(_keyWelcomeSeen, true);

    AnalyticsLogger.logEvent('onboarding_welcome_seen');
  }

  /// Check if welcome screen has been seen
  bool hasSeenWelcome() {
    return _prefs?.getBool(_keyWelcomeSeen) ?? false;
  }

  /// Mark features screen as seen
  Future<void> markFeaturesSeen() async {
    await _prefs?.setBool(_keyFeaturesSeen, true);

    AnalyticsLogger.logEvent('onboarding_features_seen');
  }

  /// Check if features screen has been seen
  bool hasSeenFeatures() {
    return _prefs?.getBool(_keyFeaturesSeen) ?? false;
  }

  /// Mark permissions screen as seen
  Future<void> markPermissionsSeen() async {
    await _prefs?.setBool(_keyPermissionsSeen, true);

    AnalyticsLogger.logEvent('onboarding_permissions_seen');
  }

  /// Check if permissions screen has been seen
  bool hasSeenPermissions() {
    return _prefs?.getBool(_keyPermissionsSeen) ?? false;
  }

  /// Mark tutorial as complete
  Future<void> completeTutorial() async {
    await _prefs?.setBool(_keyTutorialComplete, true);

    AnalyticsLogger.logEvent('onboarding_tutorial_completed');
  }

  /// Check if tutorial has been completed
  bool hasTutorialCompleted() {
    return _prefs?.getBool(_keyTutorialComplete) ?? false;
  }

  /// Mark first game as played
  Future<void> markFirstGamePlayed() async {
    await _prefs?.setBool(_keyFirstGamePlayed, true);

    AnalyticsLogger.logEvent('onboarding_first_game_played');
  }

  /// Check if first game has been played
  bool hasPlayedFirstGame() {
    return _prefs?.getBool(_keyFirstGamePlayed) ?? false;
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    await _prefs?.setBool(_keyOnboardingComplete, false);
    await _prefs?.setBool(_keyWelcomeSeen, false);
    await _prefs?.setBool(_keyFeaturesSeen, false);
    await _prefs?.setBool(_keyPermissionsSeen, false);
    await _prefs?.setBool(_keyTutorialComplete, false);
    await _prefs?.setBool(_keyFirstGamePlayed, false);
    await _prefs?.setInt(_keyOnboardingVersion, 0);

    AnalyticsLogger.logEvent('onboarding_reset');
  }

  /// Get onboarding progress (0.0 to 1.0)
  double getOnboardingProgress() {
    int completed = 0;
    const int total = 5;

    if (hasSeenWelcome()) completed++;
    if (hasSeenFeatures()) completed++;
    if (hasSeenPermissions()) completed++;
    if (hasTutorialCompleted()) completed++;
    if (hasPlayedFirstGame()) completed++;

    return completed / total;
  }

  /// Get onboarding step names for analytics
  List<String> getCompletedSteps() {
    final steps = <String>[];

    if (hasSeenWelcome()) steps.add('welcome');
    if (hasSeenFeatures()) steps.add('features');
    if (hasSeenPermissions()) steps.add('permissions');
    if (hasTutorialCompleted()) steps.add('tutorial');
    if (hasPlayedFirstGame()) steps.add('first_game');

    return steps;
  }

  /// Log onboarding event with current progress
  void logOnboardingEvent(String eventName, [Map<String, dynamic>? extra]) {
    AnalyticsLogger.logEvent(eventName, parameters: {
      'progress': getOnboardingProgress(),
      'completed_steps': getCompletedSteps().join(','),
      ...?extra,
    });
  }
}
