import 'package:flutter/material.dart';
import 'package:sortbliss/core/services/daily_rewards_service.dart';

/// Daily rewards modal - shows daily reward claim UI
/// Pops up automatically when user opens app with unclaimed reward
class DailyRewardsModal extends StatefulWidget {
  const DailyRewardsModal({super.key});

  @override
  State<DailyRewardsModal> createState() => _DailyRewardsModalState();
}

class _DailyRewardsModalState extends State<DailyRewardsModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _claimed = false;
  DailyRewardResult? _claimResult;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    final result = await DailyRewardsService.instance.claimDailyReward();

    setState(() {
      _claimed = true;
      _claimResult = result;
    });

    // Auto-close after showing success
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _claimed ? _buildSuccessView() : _buildClaimView(),
        ),
      ),
    );
  }

  Widget _buildClaimView() {
    final service = DailyRewardsService.instance;
    final currentReward = service.getCurrentReward();
    final nextReward = service.getNextReward();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade700,
            Colors.blue.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          const Icon(
            Icons.card_giftcard,
            color: Colors.amber,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Daily Reward',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Day ${service.currentStreak + 1} Streak',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 24),

          // Reward Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.amber.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Coins
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${currentReward.coins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Bonus if available
                if (currentReward.bonus != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentReward.bonus!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Streak Progress
          _buildStreakIndicator(),

          const SizedBox(height: 24),

          // Claim Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _claimReward,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: const Text(
                'Claim Reward',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Next Reward Preview
          Text(
            'Tomorrow: ${nextReward.coins} coins',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    if (_claimResult == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade700,
            Colors.teal.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            _claimResult!.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '+${_claimResult!.coins} Coins',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakIndicator() {
    final service = DailyRewardsService.instance;
    final currentStreak = service.currentStreak + 1; // +1 for today

    return Column(
      children: [
        Text(
          'Daily Streak',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final day = index + 1;
            final isCompleted = day < currentStreak;
            final isToday = day == currentStreak;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted || isToday
                          ? Colors.amber
                          : Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 20,
                            )
                          : Text(
                              '$day',
                              style: TextStyle(
                                color: isToday
                                    ? Colors.black
                                    : Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (day == 7)
                    const Icon(
                      Icons.diamond,
                      color: Colors.amber,
                      size: 12,
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
