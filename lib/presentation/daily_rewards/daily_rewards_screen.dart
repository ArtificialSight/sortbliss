import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/services/daily_rewards_service.dart';
import '../../theme/app_theme.dart';

class DailyRewardsScreen extends StatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen>
    with TickerProviderStateMixin {
  final DailyRewardsService _rewardsService = DailyRewardsService.instance;
  bool _isLoading = true;
  bool _isRewardAvailable = false;
  int _currentStreak = 0;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _rewardsService.initialize();
    final isAvailable = await _rewardsService.isRewardAvailable();
    final streak = _rewardsService.getCurrentStreak();

    if (mounted) {
      setState(() {
        _isRewardAvailable = isAvailable;
        _currentStreak = streak;
        _isLoading = false;
      });
    }
  }

  Future<void> _claimReward() async {
    final reward = await _rewardsService.claimReward();

    if (reward == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You\'ve already claimed today\'s reward!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Trigger celebration animation
    _celebrationController.forward(from: 0);

    if (!mounted) return;

    // Show success dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              reward.isSpecial ? Icons.star : Icons.card_giftcard,
              color: Theme.of(context).colorScheme.primary,
              size: 28.sp,
            ),
            SizedBox(width: 2.w),
            Text(
              reward.isSpecial ? 'Special Reward!' : 'Reward Claimed!',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on,
              size: 48.sp,
              color: Colors.amber,
            ),
            SizedBox(height: 2.h),
            Text(
              '+${reward.coins} Coins',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (reward.bonus != null) ...[
              SizedBox(height: 1.h),
              Text(
                'Bonus: ${reward.bonus}',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
            ],
            SizedBox(height: 2.h),
            Text(
              'Current Streak: ${_rewardsService.getCurrentStreak()} days',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadData(); // Refresh data
            },
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Rewards')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Rewards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Streak header
              _buildStreakHeader(colorScheme),
              SizedBox(height: 3.h),

              // 7-day reward calendar
              _buildRewardCalendar(colorScheme),
              SizedBox(height: 3.h),

              // Claim button or countdown
              if (_isRewardAvailable)
                _buildClaimButton(colorScheme)
              else
                _buildCountdownWidget(colorScheme),

              SizedBox(height: 3.h),

              // Stats
              _buildStatsSection(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakHeader(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 24.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Current Streak',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                '$_currentStreak Days',
                style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            Icons.emoji_events,
            size: 48.sp,
            color: colorScheme.primary.withOpacity(0.3),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildRewardCalendar(ColorScheme colorScheme) {
    final rewards = _rewardsService.getAllRewards();
    final currentDayIndex = _currentStreak % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-Day Reward Cycle',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 0.7,
          ),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            final isPast = index < currentDayIndex && _currentStreak > 0;
            final isCurrent = index == currentDayIndex;
            final isSpecial = reward.isSpecial;

            return _buildRewardCard(
              reward: reward,
              isPast: isPast,
              isCurrent: isCurrent,
              isSpecial: isSpecial,
              colorScheme: colorScheme,
            );
          },
        ),
      ],
    );
  }

  Widget _buildRewardCard({
    required DailyReward reward,
    required bool isPast,
    required bool isCurrent,
    required bool isSpecial,
    required ColorScheme colorScheme,
  }) {
    Color backgroundColor;
    Color textColor;
    IconData iconData;

    if (isPast) {
      backgroundColor = colorScheme.surfaceVariant;
      textColor = colorScheme.onSurfaceVariant;
      iconData = Icons.check_circle;
    } else if (isCurrent) {
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      iconData = isSpecial ? Icons.star : Icons.card_giftcard;
    } else {
      backgroundColor = colorScheme.surface;
      textColor = colorScheme.onSurface.withOpacity(0.5);
      iconData = isSpecial ? Icons.star_outline : Icons.monetization_on_outlined;
    }

    Widget card = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3.w),
        border: isCurrent
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(2.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            color: textColor,
            size: 18.sp,
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Day ${reward.day}',
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Text(
            '${reward.coins}',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (reward.bonus != null) ...[
            SizedBox(height: 0.25.h),
            Icon(
              Icons.add_circle,
              color: textColor,
              size: 10.sp,
            ),
          ],
        ],
      ),
    );

    if (isCurrent && _isRewardAvailable) {
      return card
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(duration: 1000.ms, begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1))
          .then()
          .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.5));
    }

    return card;
  }

  Widget _buildClaimButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 7.h,
      child: FilledButton(
        onPressed: _claimReward,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.w),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 24.sp),
            SizedBox(width: 2.w),
            Text(
              'Claim Today\'s Reward',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3));
  }

  Widget _buildCountdownWidget(ColorScheme colorScheme) {
    final hoursUntil = _rewardsService.getHoursUntilNextReward();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 32.sp,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 1.h),
          Text(
            'Next reward in $hoursUntil hours',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Come back tomorrow to continue your streak!',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ColorScheme colorScheme) {
    final totalClaimed = _rewardsService.getTotalClaimed();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department,
                label: 'Current Streak',
                value: '$_currentStreak days',
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today,
                label: 'Total Claimed',
                value: '$totalClaimed days',
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Daily Rewards'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log in every day to claim increasing rewards!',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
              SizedBox(height: 2.h),
              _buildInfoRow('🎁', 'Daily coins increase each day'),
              _buildInfoRow('🔥', 'Build your login streak'),
              _buildInfoRow('⭐', 'Day 7 has special bonus rewards'),
              _buildInfoRow('🔄', 'Cycle repeats after Day 7'),
              _buildInfoRow('⚠️', 'Missing a day breaks your streak'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 18.sp)),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
