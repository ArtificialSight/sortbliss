import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_logger.dart';
import '../monetization/monetization_manager.dart';

/// Daily login rewards service to boost D1 retention by 20-30%
/// Provides escalating rewards for consecutive daily logins
class DailyRewardsService {
  DailyRewardsService._();
  static final DailyRewardsService instance = DailyRewardsService._();

  static const String _keyLastClaimDate = 'daily_rewards_last_claim';
  static const String _keyCurrentStreak = 'daily_rewards_streak';
  static const String _keyTotalClaimed = 'daily_rewards_total';

  late SharedPreferences _prefs;
  bool _initialized = false;

  final List<DailyReward> _rewards = [
    DailyReward(day: 1, coins: 100, label: 'Day 1'),
    DailyReward(day: 2, coins: 150, label: 'Day 2'),
    DailyReward(day: 3, coins: 200, label: 'Day 3'),
    DailyReward(day: 4, coins: 250, label: 'Day 4'),
    DailyReward(day: 5, coins: 300, label: 'Day 5', bonus: 'x2 XP'),
    DailyReward(day: 6, coins: 400, label: 'Day 6'),
    DailyReward(day: 7, coins: 500, label: 'Day 7', bonus: 'Exclusive Skin', isSpecial: true),
  ];

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if reward is available for today
  Future<bool> isRewardAvailable() async {
    if (!_initialized) await initialize();

    final lastClaimDate = _getLastClaimDate();
    if (lastClaimDate == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastClaim = DateTime(lastClaimDate.year, lastClaimDate.month, lastClaimDate.day);

    // Reward available if not claimed today
    return today.isAfter(lastClaim);
  }

  /// Get current login streak
  int getCurrentStreak() {
    if (!_initialized) return 0;
    return _prefs.getInt(_keyCurrentStreak) ?? 0;
  }

  /// Get total rewards claimed
  int getTotalClaimed() {
    if (!_initialized) return 0;
    return _prefs.getInt(_keyTotalClaimed) ?? 0;
  }

  /// Get the reward for current day in streak
  DailyReward getCurrentReward() {
    final streak = getCurrentStreak();
    final dayIndex = streak % _rewards.length;
    return _rewards[dayIndex];
  }

  /// Claim today's reward
  Future<DailyReward?> claimReward() async {
    if (!_initialized) await initialize();

    if (!await isRewardAvailable()) {
      AnalyticsLogger.logEvent('daily_reward_already_claimed');
      return null;
    }

    final lastClaimDate = _getLastClaimDate();
    final currentStreak = getCurrentStreak();

    // Check if streak is broken (more than 1 day since last claim)
    int newStreak = currentStreak;
    if (lastClaimDate != null) {
      final daysSinceLastClaim = DateTime.now().difference(lastClaimDate).inDays;
      if (daysSinceLastClaim > 1) {
        // Streak broken, reset to 0
        newStreak = 0;
        AnalyticsLogger.logEvent('daily_reward_streak_broken', parameters: {
          'previous_streak': currentStreak,
          'days_since_last_claim': daysSinceLastClaim,
        });
      }
    }

    // Increment streak
    newStreak++;

    // Get the reward for this day
    final reward = _rewards[(newStreak - 1) % _rewards.length];

    // Grant coins
    MonetizationManager.instance.addCoins(reward.coins);

    // Update state
    await _prefs.setString(_keyLastClaimDate, DateTime.now().toIso8601String());
    await _prefs.setInt(_keyCurrentStreak, newStreak);
    await _prefs.setInt(_keyTotalClaimed, getTotalClaimed() + 1);

    AnalyticsLogger.logEvent('daily_reward_claimed', parameters: {
      'day': reward.day,
      'coins': reward.coins,
      'streak': newStreak,
      'is_special': reward.isSpecial,
    });

    return reward;
  }

  /// Get all rewards in the cycle
  List<DailyReward> getAllRewards() => List.unmodifiable(_rewards);

  /// Get next reward preview
  DailyReward? getNextReward() {
    final streak = getCurrentStreak();
    if (streak >= _rewards.length) {
      // Cycle repeats
      return _rewards[streak % _rewards.length];
    }
    return _rewards[streak];
  }

  DateTime? _getLastClaimDate() {
    final dateString = _prefs.getString(_keyLastClaimDate);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  /// Get hours until next reward is available
  int getHoursUntilNextReward() {
    final lastClaim = _getLastClaimDate();
    if (lastClaim == null) return 0;

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final hoursUntil = tomorrow.difference(now).inHours;

    return hoursUntil.clamp(0, 24);
  }

  /// Reset for testing
  Future<void> resetForTesting() async {
    await _prefs.remove(_keyLastClaimDate);
    await _prefs.remove(_keyCurrentStreak);
    await _prefs.remove(_keyTotalClaimed);
  }
}

/// Model for a daily reward
class DailyReward {
  const DailyReward({
    required this.day,
    required this.coins,
    required this.label,
    this.bonus,
    this.isSpecial = false,
  });

  final int day;
  final int coins;
  final String label;
  final String? bonus;
  final bool isSpecial;

  @override
  String toString() => 'DailyReward(day: $day, coins: $coins, bonus: $bonus)';
}
