import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PlayerStatsWidget extends StatelessWidget {
  final int levelsCompleted;
  final int currentStreak;
  final int coinsEarned;

  const PlayerStatsWidget({
    Key? key,
    required this.levelsCompleted,
    required this.currentStreak,
    required this.coinsEarned,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90.w,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: 'check_circle',
            value: levelsCompleted.toString(),
            label: 'Levels',
            color: AppTheme.lightTheme.colorScheme.tertiary,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: 'local_fire_department',
            value: currentStreak.toString(),
            label: 'Streak',
            color: Colors.orange,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: 'monetization_on',
            value: coinsEarned.toString(),
            label: 'Coins',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: icon,
            color: color,
            size: 6.w,
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 6.h,
      width: 1,
      color: AppTheme.lightTheme.dividerColor,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
    );
  }
}
