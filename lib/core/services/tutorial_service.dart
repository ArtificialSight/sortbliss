import 'package:shared_preferences/shared_preferences.dart';
import '../utils/analytics_logger.dart';

/// Manages tutorial system with progressive hints and contextual tips
///
/// Tutorial stages:
/// 1. First level - Basic drag and drop
/// 2. Sorting mechanics - How to sort colors
/// 3. Stars system - Earning stars for efficiency
/// 4. Power-ups - Using power-ups effectively
/// 5. Combos - Building combo chains
/// 6. Daily rewards - Claiming daily rewards
///
/// Features:
/// - Progressive disclosure (show tips at right time)
/// - Context-sensitive hints
/// - Skip option for experienced players
/// - Track completion for each tutorial stage
class TutorialService {
  static final TutorialService instance = TutorialService._();
  TutorialService._();

  static const String _keyTutorialComplete = 'tutorial_complete';
  static const String _keyStage1Complete = 'tutorial_stage1_complete';
  static const String _keyStage2Complete = 'tutorial_stage2_complete';
  static const String _keyStage3Complete = 'tutorial_stage3_complete';
  static const String _keyStage4Complete = 'tutorial_stage4_complete';
  static const String _keyStage5Complete = 'tutorial_stage5_complete';
  static const String _keyStage6Complete = 'tutorial_stage6_complete';
  static const String _keyTutorialSkipped = 'tutorial_skipped';

  SharedPreferences? _prefs;

  /// Initialize tutorial service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    AnalyticsLogger.logEvent('tutorial_service_initialized', parameters: {
      'tutorial_complete': isTutorialComplete(),
      'completed_stages': getCompletedStages().length,
    });
  }

  /// Check if tutorial is complete
  bool isTutorialComplete() {
    return _prefs?.getBool(_keyTutorialComplete) ?? false;
  }

  /// Mark tutorial as complete
  Future<void> completeTutorial() async {
    await _prefs?.setBool(_keyTutorialComplete, true);

    AnalyticsLogger.logEvent('tutorial_completed', parameters: {
      'stages_completed': getCompletedStages().length,
    });
  }

  /// Skip tutorial
  Future<void> skipTutorial() async {
    await _prefs?.setBool(_keyTutorialSkipped, true);
    await _prefs?.setBool(_keyTutorialComplete, true);

    AnalyticsLogger.logEvent('tutorial_skipped');
  }

  /// Check if tutorial was skipped
  bool wasTutorialSkipped() {
    return _prefs?.getBool(_keyTutorialSkipped) ?? false;
  }

  // ========== Tutorial Stages ==========

  /// Stage 1: Basic drag and drop
  bool isStage1Complete() {
    return _prefs?.getBool(_keyStage1Complete) ?? false;
  }

  Future<void> completeStage1() async {
    await _prefs?.setBool(_keyStage1Complete, true);
    _logStageComplete(1, 'basic_movement');
  }

  /// Stage 2: Sorting mechanics
  bool isStage2Complete() {
    return _prefs?.getBool(_keyStage2Complete) ?? false;
  }

  Future<void> completeStage2() async {
    await _prefs?.setBool(_keyStage2Complete, true);
    _logStageComplete(2, 'sorting_mechanics');
  }

  /// Stage 3: Stars system
  bool isStage3Complete() {
    return _prefs?.getBool(_keyStage3Complete) ?? false;
  }

  Future<void> completeStage3() async {
    await _prefs?.setBool(_keyStage3Complete, true);
    _logStageComplete(3, 'stars_system');
  }

  /// Stage 4: Power-ups
  bool isStage4Complete() {
    return _prefs?.getBool(_keyStage4Complete) ?? false;
  }

  Future<void> completeStage4() async {
    await _prefs?.setBool(_keyStage4Complete, true);
    _logStageComplete(4, 'powerups');
  }

  /// Stage 5: Combos
  bool isStage5Complete() {
    return _prefs?.getBool(_keyStage5Complete) ?? false;
  }

  Future<void> completeStage5() async {
    await _prefs?.setBool(_keyStage5Complete, true);
    _logStageComplete(5, 'combos');
  }

  /// Stage 6: Daily rewards
  bool isStage6Complete() {
    return _prefs?.getBool(_keyStage6Complete) ?? false;
  }

  Future<void> completeStage6() async {
    await _prefs?.setBool(_keyStage6Complete, true);
    _logStageComplete(6, 'daily_rewards');

    // Complete tutorial after all stages
    if (_allStagesComplete()) {
      await completeTutorial();
    }
  }

  /// Check if all stages are complete
  bool _allStagesComplete() {
    return isStage1Complete() &&
        isStage2Complete() &&
        isStage3Complete() &&
        isStage4Complete() &&
        isStage5Complete() &&
        isStage6Complete();
  }

  /// Get list of completed stages
  List<int> getCompletedStages() {
    final stages = <int>[];
    if (isStage1Complete()) stages.add(1);
    if (isStage2Complete()) stages.add(2);
    if (isStage3Complete()) stages.add(3);
    if (isStage4Complete()) stages.add(4);
    if (isStage5Complete()) stages.add(5);
    if (isStage6Complete()) stages.add(6);
    return stages;
  }

  /// Get current tutorial stage (1-6, or 7 if complete)
  int getCurrentStage() {
    if (isStage6Complete()) return 7; // Complete
    if (isStage5Complete()) return 6;
    if (isStage4Complete()) return 5;
    if (isStage3Complete()) return 4;
    if (isStage2Complete()) return 3;
    if (isStage1Complete()) return 2;
    return 1;
  }

  /// Get tutorial progress (0.0 to 1.0)
  double getTutorialProgress() {
    return getCompletedStages().length / 6.0;
  }

  /// Should show tutorial for current stage
  bool shouldShowTutorial(int stage) {
    if (isTutorialComplete()) return false;
    if (wasTutorialSkipped()) return false;
    return getCurrentStage() == stage;
  }

  /// Get tutorial content for stage
  TutorialContent getTutorialContent(int stage) {
    switch (stage) {
      case 1:
        return TutorialContent(
          title: 'Welcome to SortBliss!',
          description: 'Tap and drag a piece to move it to an empty space.',
          icon: 'assets/tutorial/drag.png',
          actionText: 'Try it now!',
        );

      case 2:
        return TutorialContent(
          title: 'Sort by Color',
          description:
              'Group same-colored pieces together. When 3 or more match, they disappear!',
          icon: 'assets/tutorial/sort.png',
          actionText: 'Got it!',
        );

      case 3:
        return TutorialContent(
          title: 'Earn Stars',
          description:
              'Complete levels efficiently to earn up to 3 stars. Stars unlock new tiers!',
          icon: 'assets/tutorial/stars.png',
          actionText: 'Awesome!',
        );

      case 4:
        return TutorialContent(
          title: 'Use Power-Ups',
          description:
              'Get stuck? Use power-ups like Undo and Hint to help you solve puzzles.',
          icon: 'assets/tutorial/powerups.png',
          actionText: 'Show me',
        );

      case 5:
        return TutorialContent(
          title: 'Build Combos',
          description:
              'Make consecutive successful moves to build combos and multiply your score!',
          icon: 'assets/tutorial/combo.png',
          actionText: 'Cool!',
        );

      case 6:
        return TutorialContent(
          title: 'Daily Rewards',
          description:
              'Come back every day to claim rewards and build your streak for bonus coins!',
          icon: 'assets/tutorial/daily.png',
          actionText: 'Let\'s go!',
        );

      default:
        return TutorialContent(
          title: 'Tutorial',
          description: 'Learn the basics',
          icon: '',
          actionText: 'OK',
        );
    }
  }

  /// Get contextual tip based on game state
  String? getContextualTip({
    int? movesLeft,
    int? currentCombo,
    bool? hasAvailableMoves,
    int? coins,
  }) {
    // Low moves warning
    if (movesLeft != null && movesLeft <= 3 && movesLeft > 0) {
      return 'Only $movesLeft moves left! Plan carefully or use Extra Moves power-up.';
    }

    // Combo encouragement
    if (currentCombo != null && currentCombo >= 5) {
      return 'Amazing! ${currentCombo}x combo! Keep it going for bonus coins!';
    }

    // Stuck detection
    if (hasAvailableMoves != null && !hasAvailableMoves) {
      return 'No moves available? Try using the Shuffle power-up to rearrange pieces.';
    }

    // Low coins
    if (coins != null && coins < 10) {
      return 'Running low on coins? Complete levels with more stars to earn bonus coins!';
    }

    return null;
  }

  /// Reset tutorial (for testing)
  Future<void> resetTutorial() async {
    await _prefs?.setBool(_keyTutorialComplete, false);
    await _prefs?.setBool(_keyStage1Complete, false);
    await _prefs?.setBool(_keyStage2Complete, false);
    await _prefs?.setBool(_keyStage3Complete, false);
    await _prefs?.setBool(_keyStage4Complete, false);
    await _prefs?.setBool(_keyStage5Complete, false);
    await _prefs?.setBool(_keyStage6Complete, false);
    await _prefs?.setBool(_keyTutorialSkipped, false);

    AnalyticsLogger.logEvent('tutorial_reset');
  }

  void _logStageComplete(int stage, String stageName) {
    AnalyticsLogger.logEvent('tutorial_stage_completed', parameters: {
      'stage': stage,
      'stage_name': stageName,
      'progress': getTutorialProgress(),
    });
  }
}

/// Tutorial content data class
class TutorialContent {
  final String title;
  final String description;
  final String icon;
  final String actionText;

  const TutorialContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.actionText,
  });
}
