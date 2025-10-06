import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import 'widgets/action_buttons_widget.dart';
import 'widgets/confetti_widget.dart';
import 'widgets/progress_indicator_widget.dart';
import 'widgets/score_breakdown_widget.dart';
import 'widgets/star_rating_widget.dart';

class LevelCompleteScreen extends StatefulWidget {
  final Map<String, dynamic> levelData;
  final VoidCallback? onNextLevel;
  final VoidCallback? onReplayLevel;
  final VoidCallback? onWatchAd;
  final VoidCallback? onShareScore;

  const LevelCompleteScreen({
    super.key,
    required this.levelData,
    this.onNextLevel,
    this.onReplayLevel,
    this.onWatchAd,
    this.onShareScore,
  });

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlideAnimation;
  Timer? _confettiTimer;
  bool _isConfettiActive = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startConfettiTimer();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..forward();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _contentOpacity = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeIn,
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOutCubic,
      ),
    );

    _contentController.forward();
  }

  void _startConfettiTimer() {
    _confettiTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isConfettiActive = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiTimer?.cancel();
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.levelData.isEmpty) {
      return _buildMissingLevelDataFallback(context);
    }

    final colorScheme = Theme.of(context).colorScheme;

    final level = _readInt('level', defaultValue: 1);
    final levelTitle =
        _readString('levelTitle', defaultValue: 'Level $level Complete');
    final completionTime =
        _readString('completionTime', defaultValue: 'Just now');
    final difficulty =
        _readString('difficulty', defaultValue: 'Standard Difficulty');
    final starsEarned = _readInt('starsEarned', defaultValue: 3).clamp(0, 3);
    final basePoints = _readInt('basePoints', defaultValue: 0);
    final timeBonus = _readInt('timeBonus', defaultValue: 0);
    final moveEfficiency = _readInt('moveEfficiency', defaultValue: 0);
    final totalScore = _readInt('totalScore', defaultValue: 0);
    final progressToNextLevel =
        _readDouble('progressToNext', defaultValue: 0.4).clamp(0.0, 1.0);
    final nextMilestone =
        _readString('nextMilestone', defaultValue: 'Level ${level + 1}');
    final bestMoves = _readInt('bestMoves', defaultValue: 0);
    final coinsEarned = _readInt('coinsEarned', defaultValue: 0);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _backgroundController,
          _contentController,
        ]),
        builder: (context, child) {
          final backgroundValue = _backgroundController.value;
          final gradientStart = Color.lerp(
            colorScheme.surface,
            colorScheme.primary.withOpacity(0.8),
            0.25 + (backgroundValue * 0.3),
          )!;
          final gradientEnd = Color.lerp(
            colorScheme.surface,
            colorScheme.secondary.withOpacity(0.7),
            0.1 + (backgroundValue * 0.25),
          )!;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [gradientStart, gradientEnd],
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.35),
                  ),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _contentOpacity,
                  child: SlideTransition(
                    position: _contentSlideAnimation,
                    child: _buildContent(
                      context: context,
                      levelTitle: levelTitle,
                      difficulty: difficulty,
                      completionTime: completionTime,
                      starsEarned: starsEarned,
                      level: level,
                      progressToNextLevel: progressToNextLevel,
                      nextMilestone: nextMilestone,
                      basePoints: basePoints,
                      timeBonus: timeBonus,
                      moveEfficiency: moveEfficiency,
                      totalScore: totalScore,
                      bestMoves: bestMoves,
                      coinsEarned: coinsEarned,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiWidget(isActive: _isConfettiActive),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required String levelTitle,
    required String difficulty,
    required String completionTime,
    required int starsEarned,
    required int level,
    required double progressToNextLevel,
    required String nextMilestone,
    required int basePoints,
    required int timeBonus,
    required int moveEfficiency,
    required int totalScore,
    required int bestMoves,
    required int coinsEarned,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 2.h),
          Text(
            levelTitle,
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '$difficulty • Completed $completionTime',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          StarRatingWidget(
            starCount: starsEarned,
            onAnimationComplete: () {
              if (!_isConfettiActive) {
                setState(() {
                  _isConfettiActive = true;
                });
              }
            },
          ),
          SizedBox(height: 4.h),
          _buildQuickStatsRow(
            context,
            level: level,
            bestMoves: bestMoves,
            coinsEarned: coinsEarned,
          ),
          SizedBox(height: 4.h),
          ProgressIndicatorWidget(
            currentLevel: level,
            progressToNext: progressToNextLevel,
            nextMilestone: nextMilestone,
          ),
          SizedBox(height: 4.h),
          ScoreBreakdownWidget(
            basePoints: basePoints,
            timeBonus: timeBonus,
            moveEfficiency: moveEfficiency,
            totalScore: totalScore,
            onAnimationComplete: () {
              if (!_isConfettiActive) {
                setState(() {
                  _isConfettiActive = true;
                });
              }
            },
          ),
          SizedBox(height: 4.h),
          ActionButtonsWidget(
            onNextLevel: _handleNextLevel,
            onReplayLevel: _handleReplayLevel,
            onShareScore: _handleShareScore,
            onWatchAd: widget.onWatchAd,
            showAdButton: widget.onWatchAd != null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(
    BuildContext context, {
    required int level,
    required int bestMoves,
    required int coinsEarned,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = AppTheme.lightTheme.textTheme;

    Widget buildStat({
      required String label,
      required String value,
      required IconData icon,
    }) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
          margin: EdgeInsets.symmetric(horizontal: 1.5.w),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(3.w),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.primary, size: 20.sp),
              SizedBox(height: 1.5.h),
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        buildStat(
          label: 'Current Level',
          value: '$level',
          icon: Icons.flag,
        ),
        buildStat(
          label: 'Best Moves',
          value: bestMoves > 0 ? '$bestMoves' : '—',
          icon: Icons.leaderboard,
        ),
        buildStat(
          label: 'Coins Earned',
          value: coinsEarned > 0 ? '+$coinsEarned' : '+0',
          icon: Icons.monetization_on,
        ),
      ],
    );
  }

  void _handleNextLevel() {
    if (widget.onNextLevel != null) {
      widget.onNextLevel!();
      return;
    }

    Navigator.of(context).maybePop({'action': 'nextLevel'});
  }

  void _handleReplayLevel() {
    if (widget.onReplayLevel != null) {
      widget.onReplayLevel!();
      return;
    }

    Navigator.of(context).maybePop({'action': 'replayLevel'});
  }

  void _handleShareScore() {
    widget.onShareScore?.call();

    final level = _readInt('level', defaultValue: 1);
    final totalScore = _readInt('totalScore', defaultValue: 0);
    final stars = _readInt('starsEarned', defaultValue: 0);
    final message =
        'I just completed level $level in SortBliss with $stars ⭐ and a score of $totalScore!';

    unawaited(Share.share(message));
  }

  Widget _buildMissingLevelDataFallback(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied_outlined,
                size: 24.w,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 3.h),
              Text(
                'We couldn\'t load your level summary',
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Return to the previous screen and try completing the level again to see your stats.',
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _readInt(String key, {required int defaultValue}) {
    final value = widget.levelData[key];
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  double _readDouble(String key, {required double defaultValue}) {
    final value = widget.levelData[key];
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  String _readString(String key, {required String defaultValue}) {
    final value = widget.levelData[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return defaultValue;
  }
}
