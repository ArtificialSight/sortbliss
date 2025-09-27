import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/confetti_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/score_breakdown_widget.dart';
import './widgets/star_rating_widget.dart';

class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({Key? key}) : super(key: key);

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  late AnimationController _autoAdvanceController;
  late Animation<double> _autoAdvanceAnimation;

  bool _showConfetti = false;
  bool _showScoreBreakdown = false;
  bool _showProgressIndicator = false;
  bool _showActionButtons = false;
  bool _isAutoAdvanceActive = false;

  // Mock level data
  final Map<String, dynamic> levelData = {
    "levelNumber": 15,
    "difficulty": "Medium",
    "starCount": 3,
    "basePoints": 1250,
    "timeBonus": 350,
    "moveEfficiency": 200,
    "totalScore": 1800,
    "progressToNext": 0.75,
    "nextMilestone": "Level 20 Unlock",
    "isLastLevel": false,
    "coinsEarned": 45,
    "achievementUnlocked": null,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCelebrationSequence();
    _triggerHapticFeedback();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _autoAdvanceController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _autoAdvanceAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _autoAdvanceController, curve: Curves.linear),
    );
  }

  void _triggerHapticFeedback() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      HapticFeedback.lightImpact();
    });
  }

  void _startCelebrationSequence() async {
    _backgroundController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _showConfetti = true;
      });
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        _showScoreBreakdown = true;
      });
    }
  }

  void _onStarAnimationComplete() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _showProgressIndicator = true;
      });
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _showActionButtons = true;
      });
      _startAutoAdvanceTimer();
    }
  }

  void _onScoreAnimationComplete() {
    // Additional celebration effects can be added here
    HapticFeedback.selectionClick();
  }

  void _startAutoAdvanceTimer() {
    setState(() {
      _isAutoAdvanceActive = true;
    });
    _autoAdvanceController.forward().then((_) {
      if (mounted && _isAutoAdvanceActive) {
        _navigateToNextLevel();
      }
    });
  }

  void _stopAutoAdvanceTimer() {
    setState(() {
      _isAutoAdvanceActive = false;
    });
    _autoAdvanceController.stop();
  }

  void _navigateToNextLevel() {
    HapticFeedback.selectionClick();
    Navigator.pushReplacementNamed(context, '/gameplay-screen');
  }

  void _replayLevel() {
    HapticFeedback.selectionClick();
    _stopAutoAdvanceTimer();
    Navigator.pushReplacementNamed(context, '/gameplay-screen');
  }

  void _shareScore() {
    HapticFeedback.selectionClick();
    _stopAutoAdvanceTimer();

    // Mock share functionality
    final shareText =
        'Just completed Level ${levelData["levelNumber"]} in SortBliss with ${levelData["totalScore"]} points! 🌟';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Score shared: $shareText'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _watchAdForCoins() {
    HapticFeedback.selectionClick();
    _stopAutoAdvanceTimer();

    // Mock ad watching functionality
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Watching Ad...',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(height: 2.h),
            Text(
              'Please wait while the ad loads',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Simulate ad completion
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Earned ${levelData["coinsEarned"] * 2} coins! 🪙'),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _navigateToMainMenu() {
    HapticFeedback.selectionClick();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/main-menu',
      (route) => false,
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _autoAdvanceController.dispose();
    super.dispose();
  }

  Widget _buildLevelInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level ${levelData["levelNumber"]}',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                levelData["difficulty"],
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _navigateToMainMenu,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: CustomIconWidget(
                iconName: 'close',
                color: Colors.white,
                size: 5.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoAdvanceIndicator() {
    return _isAutoAdvanceActive
        ? Positioned(
            top: 15.h,
            left: 4.w,
            right: 4.w,
            child: AnimatedBuilder(
              animation: _autoAdvanceAnimation,
              builder: (context, child) {
                return Container(
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(0.5.h),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _autoAdvanceAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(0.5.h),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToMainMenu();
        return false;
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.lightTheme.colorScheme.primary.withOpacity(0.8 + (_backgroundAnimation.value * 0.2),
                    ),
                    AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6 + (_backgroundAnimation.value * 0.4),
                    ),
                  ],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Background blur effect
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),

                    // Confetti animation
                    ConfettiWidget(isActive: _showConfetti),

                    // Auto advance indicator
                    _buildAutoAdvanceIndicator(),

                    // Main content
                    Column(
                      children: [
                        _buildLevelInfo(),

                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Column(
                              children: [
                                SizedBox(height: 4.h),

                                // Celebration title
                                Text(
                                  levelData["isLastLevel"]
                                      ? 'Game Complete!'
                                      : 'Level Complete!',
                                  style: AppTheme
                                      .lightTheme.textTheme.displaySmall
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: 3.h),

                                // Star rating
                                StarRatingWidget(
                                  starCount: levelData["starCount"],
                                  onAnimationComplete: _onStarAnimationComplete,
                                ),

                                SizedBox(height: 4.h),

                                // Score breakdown
                                if (_showScoreBreakdown)
                                  ScoreBreakdownWidget(
                                    basePoints: levelData["basePoints"],
                                    timeBonus: levelData["timeBonus"],
                                    moveEfficiency: levelData["moveEfficiency"],
                                    totalScore: levelData["totalScore"],
                                    onAnimationComplete:
                                        _onScoreAnimationComplete,
                                  ),

                                SizedBox(height: 3.h),

                                // Progress indicator
                                if (_showProgressIndicator &&
                                    !levelData["isLastLevel"])
                                  ProgressIndicatorWidget(
                                    currentLevel: levelData["levelNumber"],
                                    progressToNext: levelData["progressToNext"],
                                    nextMilestone: levelData["nextMilestone"],
                                  ),

                                SizedBox(height: 4.h),

                                // Achievement notification
                                if (levelData["achievementUnlocked"] != null)
                                  Container(
                                    padding: EdgeInsets.all(3.w),
                                    decoration: BoxDecoration(
                                      color: AppTheme
                                          .lightTheme.colorScheme.tertiary
                                          .withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(3.w),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        CustomIconWidget(
                                          iconName: 'emoji_events',
                                          color: Colors.white,
                                          size: 6.w,
                                        ),
                                        SizedBox(width: 3.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Achievement Unlocked!',
                                                style: AppTheme.lightTheme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                levelData[
                                                    "achievementUnlocked"],
                                                style: AppTheme.lightTheme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                SizedBox(height: 2.h),
                              ],
                            ),
                          ),
                        ),

                        // Action buttons
                        if (_showActionButtons)
                          ActionButtonsWidget(
                            onNextLevel: _navigateToNextLevel,
                            onReplayLevel: _replayLevel,
                            onShareScore: _shareScore,
                            onWatchAd: _watchAdForCoins,
                            showAdButton: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
