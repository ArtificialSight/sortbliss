import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GameHudWidget extends StatelessWidget {
  final int levelNumber;
  final int moveCount;
  final int maxMoves;
  final Function() onPausePressed;
  final Function() onHintPressed;
  final Function() onRestartPressed;

  const GameHudWidget({
    Key? key,
    required this.levelNumber,
    required this.moveCount,
    required this.maxMoves,
    required this.onPausePressed,
    required this.onHintPressed,
    required this.onRestartPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Level indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Level $levelNumber',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Pause button
                GestureDetector(
                  onTap: onPausePressed,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomIconWidget(
                      iconName: 'pause',
                      color: Colors.white,
                      size: 6.w,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            // Move counter
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'touch_app',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Moves: $moveCount/$maxMoves',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: moveCount > maxMoves * 0.8
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: 'refresh',
                  label: 'Restart',
                  onPressed: onRestartPressed,
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
                _buildActionButton(
                  icon: 'lightbulb_outline',
                  label: 'Hint',
                  onPressed: onHintPressed,
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: color,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
