import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import 'package:sortbliss/presentation/level_complete_screen/widgets/action_buttons_widget.dart';
import 'package:sortbliss/presentation/level_complete_screen/widgets/confetti_widget.dart';
import 'package:sortbliss/presentation/level_complete_screen/widgets/progress_indicator_widget.dart';
import 'package:sortbliss/presentation/level_complete_screen/widgets/score_breakdown_widget.dart';
import 'package:sortbliss/presentation/level_complete_screen/widgets/star_rating_widget.dart';

class LevelCompleteScreen extends StatefulWidget {
  final Map<String, dynamic> levelData;
  final VoidCallback? onNextLevel;
  final VoidCallback? onRestart;

  const LevelCompleteScreen({
    Key? key,
    required this.levelData,
    this.onNextLevel,
    this.onRestart,
  }) : super(key: key);

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late Animation<double> _backgroundOpacity;
  late Animation<double> _contentScale;
  late Animation<Offset> _contentSlide;

  bool _showActionButtons = false;
  bool _showConfetti = false;
  Timer? _confettiTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _contentScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
  }

  Future<void> _startAnimationSequence() async {
    await _backgroundController.forward();

    if (mounted) {
      setState(() {
        _showConfetti = true;
      });
    }

    await _contentController.forward();

    if (mounted) {
      setState(() {
        _showActionButtons = true;
      });
    }

    _confettiTimer?.cancel();
    _confettiTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showConfetti = false;
        });
      }
    });
  }

  int _readInt(String key, {int defaultValue = 0}) {
    final value = widget.levelData[key];
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  double _readDouble(String key, {double defaultValue = 0.0}) {
    final value = widget.levelData[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  String _readString(String key, {String defaultValue = ''}) {
    final value = widget.levelData[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return defaultValue;
  }

  void _showActionFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 10.h, left: 4.w, right: 4.w),
      ),
    );
  }

  void _handleNextLevel() {
    widget.onNextLevel?.call();
    if (widget.onNextLevel == null) {
      Navigator.of(context).pop();
    }
    _showActionFeedback('Loading the next challenge!');
  }

  void _handleRestartLevel() {
    widget.onRestart?.call();
    if (widget.onRestart == null) {
      Navigator.of(context).pop();
    }
    _showActionFeedback('Restarting level...');
  }

  void _handleShareScore() {
    final level = _readInt('level', defaultValue: 1);
    final totalScore = _readInt('totalScore', defaultValue: 0);
    final stars = _readInt('starsEarned', defaultValue: 0);
    final message =
        'I just completed level $level in SortBliss with $stars ⭐ and a score of $totalScore!';

    Share.share(message);
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
    final colorScheme = Theme.of(context).colorScheme;
    final level = _readInt('level', defaultValue: 1);
    final levelTitle = _readString('levelTitle', defaultValue: 'Level $level Complete');
    final completionTime = _readString('completionTime', defaultValue: 'Just now');
    final difficulty = _readString('difficulty', defaultValue: 'Standard');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _backgroundController,
          _contentController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withOpacity(_backgroundOpacity.value * 0.25),
                      colorScheme.secondary.withOpacity(_backgroundOpacity.value * 0.35),
                      colorScheme.surface,
                    ],
                  ),
                ),
              ),
              if (_showConfetti)
                IgnorePointer(
                  ignoring: true,
                  child: ConfettiWidget(isActive: _showConfetti),
                ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                  child: SlideTransition(
                    position: _contentSlide,
                    child: ScaleTransition(
                      scale: _contentScale,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 2.h),
                          _LevelHeader(
                            title: levelTitle,
                            level: level,
                            difficulty: difficulty,
                            completionTime: completionTime,
                          ),
                          SizedBox(height: 3.h),
                          StarRatingWidget(
                            starCount:
                                _readInt('starsEarned', defaultValue: 3).clamp(0, 3),
                            onAnimationComplete: () => _showActionFeedback('Amazing performance!'),
                          ),
                          SizedBox(height: 4.h),
                          ScoreBreakdownWidget(
                            basePoints: _readInt('basePoints', defaultValue: 250),
                            timeBonus: _readInt('timeBonus', defaultValue: 120),
                            moveEfficiency: _readInt('moveEfficiency', defaultValue: 80),
                            totalScore: _readInt('totalScore', defaultValue: 450),
                            onAnimationComplete: () => _showActionFeedback('Final score tallied!'),
                          ),
                          SizedBox(height: 4.h),
                          ProgressIndicatorWidget(
                            currentLevel: level,
                            progressToNext:
                                _readDouble('progressToNextLevel', defaultValue: 0.6).clamp(0.0, 1.0),
                            nextMilestone: _readString(
                              'nextMilestone',
                              defaultValue: 'Next reward at level ${level + 1}',
                            ),
                          ),
                          SizedBox(height: 4.h),
                          if (_showActionButtons)
                            ActionButtonsWidget(
                              onNextLevel: _handleNextLevel,
                              onReplayLevel: _handleRestartLevel,
                              onShareScore: _handleShareScore,
                              showAdButton: false,
                            ),
                          if (!_showActionButtons)
                            SizedBox(
                              height: 6.h,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.title,
    required this.level,
    required this.difficulty,
    required this.completionTime,
  });

  final String title;
  final int level;
  final String difficulty;
  final String completionTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.5.h),
          Wrap(
            spacing: 3.w,
            runSpacing: 1.h,
            alignment: WrapAlignment.center,
            children: [
              _InfoChip(
                icon: Icons.videogame_asset,
                label: 'Level $level',
              ),
              _InfoChip(
                icon: Icons.whatshot,
                label: difficulty,
              ),
              _InfoChip(
                icon: Icons.timer,
                label: completionTime,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.onPrimary, size: 16.sp),
          SizedBox(width: 2.w),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
