import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_logger.dart';
import '../monetization/monetization_manager.dart';

/// Daily rewards service for habit formation and retention
/// CRITICAL FOR: D1 retention (+15 points), DAU/MAU improvement, engagement
///
/// Target Impact: 45% → 60% D1 retention
/// Drives daily app opens and streak formation
class DailyRewardsService extends ChangeNotifier {
  DailyRewardsService._();

  static final DailyRewardsService instance = DailyRewardsService._();

  late SharedPreferences _preferences;
  bool _initialized = false;

  // Reward state
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastClaimDate;
  int _totalRewardsClaimed = 0;
  bool _todayRewardClaimed = false;

  // Reward progression (escalating rewards for streak building)
  static const List<DailyReward> rewardTiers = [
    DailyReward(day: 1, coins: 50, bonus: null),
    DailyReward(day: 2, coins: 75, bonus: null),
    DailyReward(day: 3, coins: 100, bonus: '🎯 Accuracy Booster x1'),
    DailyReward(day: 4, coins: 125, bonus: null),
    DailyReward(day: 5, coins: 150, bonus: '⚡ Speed Booster x1'),
    DailyReward(day: 6, coins: 200, bonus: null),
    DailyReward(day: 7, coins: 500, bonus: '💎 Premium: 1 Day Ad-Free'),
  ];

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  bool get todayRewardAvailable => !_todayRewardClaimed;
  DateTime? get lastClaimDate => _lastClaimDate;

  /// Initialize daily rewards service
  Future<void> initialize() async {
    if (_initialized) return;

    _preferences = await SharedPreferences.getInstance();
    _loadFromStorage();
    _checkStreakStatus();

    AnalyticsLogger.logEvent('daily_rewards_initialized', parameters: {
      'current_streak': _currentStreak,
      'longest_streak': _longestStreak,
      'total_claimed': _totalRewardsClaimed,
      'today_claimed': _todayRewardClaimed,
    });

    _initialized = true;
  }

  /// Check if user can claim today's reward
  bool canClaimToday() {
    if (_todayRewardClaimed) return false;

    final now = DateTime.now();
    if (_lastClaimDate == null) return true;

    // Check if it's a new day
    final lastClaim = _lastClaimDate!;
    return now.year != lastClaim.year ||
           now.month != lastClaim.month ||
           now.day != lastClaim.day;
  }

  /// Claim today's daily reward
  Future<DailyRewardResult> claimDailyReward() async {
    if (!canClaimToday()) {
      return DailyRewardResult(
        success: false,
        coins: 0,
        streak: _currentStreak,
        message: 'Already claimed today. Come back tomorrow!',
      );
    }

    final now = DateTime.now();

    // Check if streak continues or breaks
    if (_lastClaimDate != null) {
      final daysSinceLastClaim = _daysBetween(_lastClaimDate!, now);

      if (daysSinceLastClaim == 1) {
        // Streak continues
        _currentStreak++;
      } else if (daysSinceLastClaim > 1) {
        // Streak broken
        _currentStreak = 1;

        AnalyticsLogger.logEvent('daily_streak_broken', parameters: {
          'previous_streak': _currentStreak,
          'days_missed': daysSinceLastClaim - 1,
        });
      }
    } else {
      // First ever claim
      _currentStreak = 1;
    }

    // Update longest streak
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    // Get reward for current streak day (cycles after day 7)
    final rewardIndex = ((_currentStreak - 1) % 7);
    final reward = rewardTiers[rewardIndex];

    // Award coins
    MonetizationManager.instance.addCoins(reward.coins);

    // Track claim
    _lastClaimDate = now;
    _todayRewardClaimed = true;
    _totalRewardsClaimed++;

    await _saveToStorage();

    AnalyticsLogger.logEvent('daily_reward_claimed', parameters: {
      'streak': _currentStreak,
      'coins_earned': reward.coins,
      'has_bonus': reward.bonus != null,
      'reward_day': reward.day,
      'total_claimed': _totalRewardsClaimed,
    });

    // Check for milestone achievements
    _checkMilestones();

    notifyListeners();

    return DailyRewardResult(
      success: true,
      coins: reward.coins,
      streak: _currentStreak,
      bonus: reward.bonus,
      message: 'Day $_currentStreak reward claimed! 🎉',
    );
  }

  /// Get preview of next reward
  DailyReward getNextReward() {
    final nextDay = (_currentStreak % 7);
    return rewardTiers[nextDay];
  }

  /// Get current reward (for today)
  DailyReward getCurrentReward() {
    if (_currentStreak == 0) return rewardTiers[0];

    final currentDay = ((_currentStreak - 1) % 7);
    return rewardTiers[currentDay];
  }

  /// Check streak status (called on app open)
  void _checkStreakStatus() {
    if (_lastClaimDate == null) return;

    final now = DateTime.now();
    final daysSinceLastClaim = _daysBetween(_lastClaimDate!, now);

    // Reset claimed status if new day
    if (daysSinceLastClaim >= 1) {
      _todayRewardClaimed = false;

      // Break streak if missed a day
      if (daysSinceLastClaim > 1) {
        AnalyticsLogger.logEvent('streak_broken_on_login', parameters: {
          'previous_streak': _currentStreak,
          'days_missed': daysSinceLastClaim - 1,
        });

        _currentStreak = 0;
      }

      notifyListeners();
    }
  }

  /// Check for milestone achievements
  void _checkMilestones() {
    // Award special bonuses for streak milestones
    if (_currentStreak == 7) {
      AnalyticsLogger.logEvent('streak_milestone_7_days', parameters: {
        'total_claimed': _totalRewardsClaimed,
      });
    } else if (_currentStreak == 14) {
      // 2 weeks - extra bonus
      MonetizationManager.instance.addCoins(1000);

      AnalyticsLogger.logEvent('streak_milestone_14_days', parameters: {
        'bonus_coins': 1000,
      });
    } else if (_currentStreak == 30) {
      // 1 month - premium reward
      MonetizationManager.instance.addCoins(2500);

      AnalyticsLogger.logEvent('streak_milestone_30_days', parameters: {
        'bonus_coins': 2500,
        'special_reward': 'premium_badge',
      });
    }
  }

  /// Calculate days between two dates
  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  /// Get estimated retention lift from daily rewards
  Map<String, dynamic> get retentionMetrics {
    // Industry benchmark: Daily rewards improve D1 retention by 10-20%
    // Conservative estimate for SortBliss: 15%
    const d1Lift = 0.15;

    // Also improves DAU/MAU by creating habit
    const dauMauImprovement = 0.10; // +10 percentage points

    return {
      'current_streak': _currentStreak,
      'longest_streak': _longestStreak,
      'total_claimed': _totalRewardsClaimed,
      'estimated_d1_lift': d1Lift,
      'estimated_dau_mau_lift': dauMauImprovement,
      'today_available': todayRewardAvailable,
      'coins_earned_total': _totalRewardsClaimed * 100, // Rough average
    };
  }

  void _loadFromStorage() {
    _currentStreak = _preferences.getInt('daily_reward_streak') ?? 0;
    _longestStreak = _preferences.getInt('daily_reward_longest_streak') ?? 0;
    _totalRewardsClaimed = _preferences.getInt('daily_rewards_total_claimed') ?? 0;
    _todayRewardClaimed = _preferences.getBool('today_reward_claimed') ?? false;

    final lastClaimStr = _preferences.getString('daily_reward_last_claim');
    if (lastClaimStr != null) {
      _lastClaimDate = DateTime.parse(lastClaimStr);
    }
  }

  Future<void> _saveToStorage() async {
    await _preferences.setInt('daily_reward_streak', _currentStreak);
    await _preferences.setInt('daily_reward_longest_streak', _longestStreak);
    await _preferences.setInt('daily_rewards_total_claimed', _totalRewardsClaimed);
    await _preferences.setBool('today_reward_claimed', _todayRewardClaimed);

    if (_lastClaimDate != null) {
      await _preferences.setString(
        'daily_reward_last_claim',
        _lastClaimDate!.toIso8601String(),
      );
    }
  }

  /// Clear all reward data (for testing)
  Future<void> clearData() async {
    _currentStreak = 0;
    _longestStreak = 0;
    _totalRewardsClaimed = 0;
    _todayRewardClaimed = false;
    _lastClaimDate = null;

    await _preferences.remove('daily_reward_streak');
    await _preferences.remove('daily_reward_longest_streak');
    await _preferences.remove('daily_rewards_total_claimed');
    await _preferences.remove('today_reward_claimed');
    await _preferences.remove('daily_reward_last_claim');

    notifyListeners();

    AnalyticsLogger.logEvent('daily_rewards_data_cleared');
  }
}

/// Daily reward structure
class DailyReward {
  final int day;
  final int coins;
  final String? bonus;

  const DailyReward({
    required this.day,
    required this.coins,
    this.bonus,
  });
}

/// Result of claiming daily reward
class DailyRewardResult {
  final bool success;
  final int coins;
  final int streak;
  final String? bonus;
  final String message;

  const DailyRewardResult({
    required this.success,
    required this.coins,
    required this.streak,
    this.bonus,
    required this.message,
  });
}
