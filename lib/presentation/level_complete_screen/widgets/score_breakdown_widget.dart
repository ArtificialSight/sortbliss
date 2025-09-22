import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ScoreBreakdownWidget extends StatefulWidget {
  final int basePoints;
  final int timeBonus;
  final int moveEfficiency;
  final int totalScore;
  final VoidCallback? onAnimationComplete;

  const ScoreBreakdownWidget({
    Key? key,
    required this.basePoints,
    required this.timeBonus,
    required this.moveEfficiency,
    required this.totalScore,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<ScoreBreakdownWidget> createState() => _ScoreBreakdownWidgetState();
}

class _ScoreBreakdownWidgetState extends State<ScoreBreakdownWidget>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late Animation<int> _basePointsAnimation;
  late Animation<int> _timeBonusAnimation;
  late Animation<int> _moveEfficiencyAnimation;
  late Animation<int> _totalScoreAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCountingAnimation();
  }

  void _initializeAnimations() {
    _countController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _basePointsAnimation = IntTween(begin: 0, end: widget.basePoints).animate(
      CurvedAnimation(
        parent: _countController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _timeBonusAnimation = IntTween(begin: 0, end: widget.timeBonus).animate(
      CurvedAnimation(
        parent: _countController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _moveEfficiencyAnimation =
        IntTween(begin: 0, end: widget.moveEfficiency).animate(
      CurvedAnimation(
        parent: _countController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _totalScoreAnimation = IntTween(begin: 0, end: widget.totalScore).animate(
      CurvedAnimation(
        parent: _countController,
        curve: const Interval(0.8, 1.0, curve: Curves.bounceOut),
      ),
    );
  }

  void _startCountingAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _countController.forward().then((_) {
        widget.onAnimationComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  Widget _buildScoreRow(String label, Animation<int> animation, Color color) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '+${animation.value}',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildScoreRow(
            'Base Points',
            _basePointsAnimation,
            AppTheme.lightTheme.colorScheme.primary,
          ),
          _buildScoreRow(
            'Time Bonus',
            _timeBonusAnimation,
            AppTheme.lightTheme.colorScheme.secondary,
          ),
          _buildScoreRow(
            'Move Efficiency',
            _moveEfficiencyAnimation,
            AppTheme.lightTheme.colorScheme.tertiary,
          ),
          Divider(
            color: AppTheme.lightTheme.colorScheme.outline,
            thickness: 1,
            height: 3.h,
          ),
          AnimatedBuilder(
            animation: _totalScoreAnimation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Score',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_totalScoreAnimation.value}',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
