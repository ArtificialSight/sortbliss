import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LevelCompleteModalWidget extends StatefulWidget {
  final int levelNumber;
  final int score;
  final int stars;
  final int moveCount;
  final int maxMoves;
  final Function() onNextLevel;
  final Function() onRestart;
  final Function() onMainMenu;

  const LevelCompleteModalWidget({
    Key? key,
    required this.levelNumber,
    required this.score,
    required this.stars,
    required this.moveCount,
    required this.maxMoves,
    required this.onNextLevel,
    required this.onRestart,
    required this.onMainMenu,
  }) : super(key: key);

  @override
  State<LevelCompleteModalWidget> createState() =>
      _LevelCompleteModalWidgetState();
}

class _LevelCompleteModalWidgetState extends State<LevelCompleteModalWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _starController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _starAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _starAnimation = CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _starController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 85.w,
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration header
                Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Column(
                    children: [
                      Text(
                        'Level Complete!',
                        style: AppTheme.lightTheme.textTheme.headlineSmall
                            ?.copyWith(
                          color: AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Level ${widget.levelNumber}',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Star rating
                AnimatedBuilder(
                  animation: _starAnimation,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isActive = index < widget.stars;
                        final delay = index * 0.2;
                        final starProgress =
                            (_starAnimation.value - delay).clamp(0.0, 1.0);

                        return Transform.scale(
                          scale: isActive ? starProgress : 0.5,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 1.w),
                            child: CustomIconWidget(
                              iconName: isActive ? 'star' : 'star_border',
                              color: isActive
                                  ? Colors.amber
                                  : Colors.grey.withOpacity(0.4),
                              size: 10.w,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),

                SizedBox(height: 3.h),

                // Score breakdown
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildScoreRow('Score', widget.score.toString()),
                      SizedBox(height: 1.h),
                      _buildScoreRow('Moves Used',
                          '${widget.moveCount}/${widget.maxMoves}'),
                      SizedBox(height: 1.h),
                      _buildScoreRow('Efficiency',
                          '${((widget.maxMoves - widget.moveCount) / widget.maxMoves * 100).round()}%'),
                    ],
                  ),
                ),

                SizedBox(height: 4.h),

                // Action buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onNextLevel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lightTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Next Level',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            CustomIconWidget(
                              iconName: 'arrow_forward',
                              color: Colors.white,
                              size: 5.w,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onRestart,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Restart',
                              style: AppTheme.lightTheme.textTheme.titleSmall,
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: TextButton(
                            onPressed: widget.onMainMenu,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Main Menu',
                              style: AppTheme.lightTheme.textTheme.titleSmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
