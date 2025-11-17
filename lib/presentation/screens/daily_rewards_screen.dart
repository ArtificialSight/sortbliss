import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/daily_rewards_service.dart';
import '../../core/services/coin_economy_service.dart';
import '../../core/theme/app_theme.dart';

/// Daily rewards screen with 7-day calendar
///
/// Features:
/// - 7-day reward calendar
/// - Visual progress indicators
/// - Current streak display
/// - Claim button
/// - Missed days indication
/// - Auto-show on app open (if unclaimed)
/// - Celebration animation on claim
/// - Increasing rewards (day 7 is biggest)
///
/// Rewards Schedule:
/// Day 1: 10 coins
/// Day 2: 15 coins
/// Day 3: 20 coins
/// Day 4: 30 coins
/// Day 5: 40 coins
/// Day 6: 60 coins
/// Day 7: 100 coins + special bonus
class DailyRewardsScreen extends StatefulWidget {
  final bool autoShow;

  const DailyRewardsScreen({
    Key? key,
    this.autoShow = false,
  }) : super(key: key);

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen>
    with SingleTickerProviderStateMixin {
  final DailyRewardsService _rewards = DailyRewardsService.instance;
  final CoinEconomyService _coins = CoinEconomyService.instance;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _claimed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canClaim = _rewards.canClaimToday();
    final streak = _rewards.getCurrentStreak();
    final nextReward = _rewards.getNextRewardAmount();

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.all(5.w),
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5.w),
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
                // Close button (if not auto-show)
                if (!widget.autoShow)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                // Header
                Text(
                  '🎁',
                  style: TextStyle(fontSize: 20.w),
                ),

                SizedBox(height: 2.h),

                Text(
                  'Daily Rewards',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),

                SizedBox(height: 1.h),

                Text(
                  'Come back every day to earn rewards!',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 3.h),

                // Streak indicator
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.red.shade500],
                    ),
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 6.w)),
                      SizedBox(width: 2.w),
                      Text(
                        '$streak Day Streak',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 3.h),

                // 7-day calendar
                _buildCalendar(),

                SizedBox(height: 3.h),

                // Claim button
                if (!_claimed)
                  _buildClaimButton(canClaim, nextReward)
                else
                  _buildClaimedMessage(),

                SizedBox(height: 2.h),

                // Next reward hint
                if (!canClaim)
                  Text(
                    'Come back tomorrow for $nextReward coins!',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final streak = _rewards.getCurrentStreak();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final day = index + 1;
        final reward = CoinRewardCalculator.calculateDailyReward(day);
        final isToday = day == streak + 1;
        final isClaimed = day <= streak;
        final isFuture = day > streak + 1;

        return _buildDayCard(
          day: day,
          reward: reward,
          isToday: isToday,
          isClaimed: isClaimed,
          isFuture: isFuture,
        );
      }),
    );
  }

  Widget _buildDayCard({
    required int day,
    required int reward,
    required bool isToday,
    required bool isClaimed,
    required bool isFuture,
  }) {
    Color bgColor;
    Color textColor;
    Widget? icon;

    if (isClaimed) {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      icon = Icon(Icons.check_circle, color: Colors.green, size: 5.w);
    } else if (isToday) {
      bgColor = Colors.amber.shade100;
      textColor = Colors.amber.shade900;
    } else {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade600;
    }

    return Column(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isToday ? Colors.amber : Colors.transparent,
              width: 3,
            ),
          ),
          child: Center(
            child: icon ??
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          '$reward',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        Text(
          '💰',
          style: TextStyle(fontSize: 3.w),
        ),
      ],
    );
  }

  Widget _buildClaimButton(bool canClaim, int nextReward) {
    return SizedBox(
      width: double.infinity,
      height: 7.h,
      child: ElevatedButton(
        onPressed: canClaim ? _claimReward : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canClaim ? Colors.green.shade600 : Colors.grey,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          elevation: canClaim ? 4 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canClaim)
              ScaleTransition(
                scale: _scaleAnimation,
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: Text('💰', style: TextStyle(fontSize: 8.w)),
                ),
              ),
            if (canClaim) SizedBox(width: 3.w),
            Text(
              canClaim ? 'Claim $nextReward Coins' : 'Already Claimed Today',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimedMessage() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 8.w),
          SizedBox(width: 3.w),
          Text(
            'Reward Claimed!',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claimReward() async {
    final reward = await _rewards.claimDailyReward();

    if (reward > 0) {
      // Award coins
      await _coins.earnCoins(
        reward,
        CoinSource.dailyReward,
        description: 'Daily login reward',
      );

      // Play animation
      _animationController.forward();

      // Show claimed state
      setState(() {
        _claimed = true;
      });

      // Show celebration
      _showCelebration(reward);

      // Auto-close after delay
      if (widget.autoShow) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _showCelebration(int reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉', style: TextStyle(fontSize: 25.w)),
              SizedBox(height: 2.h),
              Text(
                '+$reward Coins!',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Keep your streak going!',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                ),
                child: Text(
                  'Awesome!',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show daily rewards screen automatically (static method)
  static Future<void> showIfAvailable(BuildContext context) async {
    final rewards = DailyRewardsService.instance;

    if (rewards.canClaimToday()) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const DailyRewardsScreen(autoShow: true),
      );
    }
  }
}
