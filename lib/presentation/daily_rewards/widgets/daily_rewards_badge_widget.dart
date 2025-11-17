import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/daily_rewards_service.dart';
import '../../../theme/app_theme.dart';
import '../daily_rewards_screen.dart';

/// Badge widget to show on main menu indicating daily reward availability
class DailyRewardsBadgeWidget extends StatefulWidget {
  const DailyRewardsBadgeWidget({super.key});

  @override
  State<DailyRewardsBadgeWidget> createState() => _DailyRewardsBadgeWidgetState();
}

class _DailyRewardsBadgeWidgetState extends State<DailyRewardsBadgeWidget> {
  final DailyRewardsService _rewardsService = DailyRewardsService.instance;
  bool _isLoading = true;
  bool _isAvailable = false;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    await _rewardsService.initialize();
    final available = await _rewardsService.isRewardAvailable();
    final streak = _rewardsService.getCurrentStreak();

    if (mounted) {
      setState(() {
        _isAvailable = available;
        _currentStreak = streak;
        _isLoading = false;
      });
    }
  }

  void _navigateToDailyRewards() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DailyRewardsScreen(),
      ),
    ).then((_) {
      // Refresh status when returning
      _loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final nextReward = _rewardsService.getNextReward();

    return GestureDetector(
      onTap: _navigateToDailyRewards,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: _isAvailable
              ? LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isAvailable ? null : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(4.w),
          boxShadow: _isAvailable
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: _isAvailable
                    ? colorScheme.primary.withOpacity(0.2)
                    : colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isAvailable ? Icons.card_giftcard : Icons.schedule,
                color: _isAvailable
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 3.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Daily Reward',
                        style: AppTheme.lightTheme.textTheme.titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isAvailable
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_currentStreak > 0) ...[
                        SizedBox(width: 2.w),
                        Icon(
                          Icons.local_fire_department,
                          size: 16.sp,
                          color: Colors.orange,
                        ),
                        Text(
                          '$_currentStreak',
                          style: AppTheme.lightTheme.textTheme.labelMedium
                              ?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _isAvailable
                        ? 'Claim ${nextReward?.coins ?? 0} coins now!'
                        : 'Come back tomorrow',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: _isAvailable
                          ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                          : colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              color: _isAvailable
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ).animate(
      onPlay: (controller) {
        if (_isAvailable) {
          controller.repeat(reverse: true);
        }
      },
    ).shimmer(
      duration: 2000.ms,
      color: _isAvailable ? Colors.white.withOpacity(0.3) : Colors.transparent,
    );
  }
}
