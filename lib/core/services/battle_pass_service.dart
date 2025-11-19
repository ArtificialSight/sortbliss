import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coin_economy_service.dart';
import '../utils/analytics_logger.dart';

/// Battle Pass system for premium monetization and engagement
///
/// Features:
/// - Free and Premium tiers
/// - 50 levels of rewards per season
/// - Weekly challenges for XP
/// - Exclusive cosmetic rewards
/// - Season progression tracking
/// - Auto-renewal option
/// - Catch-up mechanics
///
/// Monetization:
/// - Premium Pass: $9.99/season (30 days)
/// - Battle Pass Bundle: $19.99 (Premium + 10 tier skips)
/// - Tier Skip: $1.99 each
///
/// Expected Revenue:
/// - 5% conversion rate × 10,000 MAU = 500 premium buyers
/// - 500 × $9.99 = $4,995/month
/// - Annual: ~$60,000 from battle pass alone
class BattlePassService {
  static final BattlePassService instance = BattlePassService._();
  BattlePassService._();

  static const String _keyCurrentSeason = 'battle_pass_season';
  static const String _keySeasonProgress = 'battle_pass_progress';
  static const String _keySeasonXp = 'battle_pass_xp';
  static const String _keyPremiumPurchased = 'battle_pass_premium';
  static const String _keyClaimedRewards = 'battle_pass_claimed';
  static const String _keySeasonStartDate = 'battle_pass_start_date';
  static const String _keyWeeklyChallenges = 'battle_pass_weekly_challenges';

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Season configuration
  static const int _seasonNumber = 1;
  static const int _maxTier = 50;
  static const int _seasonDurationDays = 30;
  static const int _xpPerTier = 1000;

  // Pricing
  static const double _premiumPassPrice = 9.99;
  static const double _bundlePrice = 19.99;
  static const double _tierSkipPrice = 1.99;

  // Current season data
  int _currentTier = 0;
  int _currentXp = 0;
  bool _hasPremium = false;
  final Set<int> _claimedRewards = {};
  DateTime? _seasonStartDate;

  // Weekly challenges
  final List<BattlePassChallenge> _weeklyChallenges = [];

  /// Initialize battle pass service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Load season data
    final savedSeason = _prefs.getInt(_keyCurrentSeason) ?? 0;
    _currentTier = _prefs.getInt(_keySeasonProgress) ?? 0;
    _currentXp = _prefs.getInt(_keySeasonXp) ?? 0;
    _hasPremium = _prefs.getBool(_keyPremiumPurchased) ?? false;

    // Load claimed rewards
    final claimedList = _prefs.getStringList(_keyClaimedRewards) ?? [];
    _claimedRewards.addAll(claimedList.map((s) => int.parse(s)));

    // Load season start date
    final startTimestamp = _prefs.getInt(_keySeasonStartDate);
    if (startTimestamp != null) {
      _seasonStartDate = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
    } else {
      // Start new season
      await _startNewSeason();
    }

    // Check if season expired
    if (_isSeasonExpired()) {
      await _endSeason();
      await _startNewSeason();
    }

    // Load weekly challenges
    await _loadWeeklyChallenges();

    _initialized = true;

    if (kDebugMode) {
      debugPrint('🎫 Battle Pass initialized');
      debugPrint('   Season: $_seasonNumber');
      debugPrint('   Tier: $_currentTier/$_maxTier');
      debugPrint('   XP: $_currentXp/${_xpPerTier}');
      debugPrint('   Premium: $_hasPremium');
      debugPrint('   Days Remaining: ${getDaysRemaining()}');
    }
  }

  /// Start a new season
  Future<void> _startNewSeason() async {
    _seasonStartDate = DateTime.now();
    _currentTier = 0;
    _currentXp = 0;
    _hasPremium = false;
    _claimedRewards.clear();

    await _prefs.setInt(_keyCurrentSeason, _seasonNumber);
    await _prefs.setInt(_keySeasonProgress, 0);
    await _prefs.setInt(_keySeasonXp, 0);
    await _prefs.setBool(_keyPremiumPurchased, false);
    await _prefs.setStringList(_keyClaimedRewards, []);
    await _prefs.setInt(_keySeasonStartDate, _seasonStartDate!.millisecondsSinceEpoch);

    // Generate weekly challenges
    await _generateWeeklyChallenges();

    AnalyticsLogger.logEvent('battle_pass_season_started', parameters: {
      'season': _seasonNumber,
    });
  }

  /// End current season
  Future<void> _endSeason() async {
    AnalyticsLogger.logEvent('battle_pass_season_ended', parameters: {
      'season': _seasonNumber,
      'final_tier': _currentTier,
      'had_premium': _hasPremium,
      'rewards_claimed': _claimedRewards.length,
    });
  }

  /// Check if season has expired
  bool _isSeasonExpired() {
    if (_seasonStartDate == null) return false;
    final daysSinceStart = DateTime.now().difference(_seasonStartDate!).inDays;
    return daysSinceStart >= _seasonDurationDays;
  }

  /// Get days remaining in season
  int getDaysRemaining() {
    if (_seasonStartDate == null) return 0;
    final daysSinceStart = DateTime.now().difference(_seasonStartDate!).inDays;
    return (_seasonDurationDays - daysSinceStart).clamp(0, _seasonDurationDays);
  }

  /// Get hours remaining in season
  int getHoursRemaining() {
    if (_seasonStartDate == null) return 0;
    final endDate = _seasonStartDate!.add(Duration(days: _seasonDurationDays));
    final remaining = endDate.difference(DateTime.now());
    return remaining.inHours.clamp(0, _seasonDurationDays * 24);
  }

  /// Add XP to battle pass
  Future<BattlePassXpResult> addXp(int xp, String source) async {
    if (!_initialized) await initialize();

    final oldTier = _currentTier;
    _currentXp += xp;

    // Check for tier up
    final tiersGained = <int>[];
    while (_currentXp >= _xpPerTier && _currentTier < _maxTier) {
      _currentXp -= _xpPerTier;
      _currentTier++;
      tiersGained.add(_currentTier);
    }

    // Cap XP at max tier
    if (_currentTier >= _maxTier) {
      _currentXp = 0;
    }

    // Save progress
    await _prefs.setInt(_keySeasonProgress, _currentTier);
    await _prefs.setInt(_keySeasonXp, _currentXp);

    // Log analytics
    if (tiersGained.isNotEmpty) {
      AnalyticsLogger.logEvent('battle_pass_tier_up', parameters: {
        'old_tier': oldTier,
        'new_tier': _currentTier,
        'tiers_gained': tiersGained.length,
        'source': source,
      });
    }

    return BattlePassXpResult(
      xpGained: xp,
      newTier: _currentTier,
      tiersGained: tiersGained,
      currentXp: _currentXp,
      xpToNextTier: _xpPerTier - _currentXp,
    );
  }

  /// Purchase premium battle pass
  Future<bool> purchasePremiumPass() async {
    if (!_initialized) await initialize();

    if (_hasPremium) {
      return false; // Already purchased
    }

    // In production, this would integrate with IAP service
    // For now, simulate purchase
    _hasPremium = true;
    await _prefs.setBool(_keyPremiumPurchased, true);

    AnalyticsLogger.logEvent('battle_pass_premium_purchased', parameters: {
      'season': _seasonNumber,
      'tier': _currentTier,
      'price': _premiumPassPrice,
    });

    if (kDebugMode) {
      debugPrint('✅ Premium Battle Pass purchased!');
    }

    return true;
  }

  /// Purchase battle pass bundle (premium + tier skips)
  Future<bool> purchaseBundle() async {
    await purchasePremiumPass();
    await skipTiers(10);

    AnalyticsLogger.logEvent('battle_pass_bundle_purchased', parameters: {
      'season': _seasonNumber,
      'price': _bundlePrice,
    });

    return true;
  }

  /// Skip tiers (paid feature)
  Future<void> skipTiers(int count) async {
    if (!_initialized) await initialize();

    final newTier = (_currentTier + count).clamp(0, _maxTier);
    final actualSkip = newTier - _currentTier;

    _currentTier = newTier;
    await _prefs.setInt(_keySeasonProgress, _currentTier);

    AnalyticsLogger.logEvent('battle_pass_tiers_skipped', parameters: {
      'tiers_skipped': actualSkip,
      'new_tier': _currentTier,
    });
  }

  /// Claim reward at tier
  Future<BattlePassReward?> claimReward(int tier, bool isPremium) async {
    if (!_initialized) await initialize();

    // Validate
    if (tier > _currentTier) return null;
    if (isPremium && !_hasPremium) return null;
    if (_claimedRewards.contains(tier * 2 + (isPremium ? 1 : 0))) return null;

    // Get reward
    final reward = _getRewardForTier(tier, isPremium);
    if (reward == null) return null;

    // Grant reward
    await _grantReward(reward);

    // Mark as claimed
    final rewardId = tier * 2 + (isPremium ? 1 : 0);
    _claimedRewards.add(rewardId);
    await _prefs.setStringList(
      _keyClaimedRewards,
      _claimedRewards.map((i) => i.toString()).toList(),
    );

    AnalyticsLogger.logEvent('battle_pass_reward_claimed', parameters: {
      'tier': tier,
      'is_premium': isPremium,
      'reward_type': reward.type.toString(),
    });

    return reward;
  }

  /// Get reward for specific tier
  BattlePassReward? _getRewardForTier(int tier, bool isPremium) {
    // Define reward structure
    final rewards = _generateRewards();
    final key = '$tier-${isPremium ? 'premium' : 'free'}';
    return rewards[key];
  }

  /// Generate all rewards for season
  Map<String, BattlePassReward> _generateRewards() {
    final rewards = <String, BattlePassReward>{};

    for (int tier = 1; tier <= _maxTier; tier++) {
      // Free tier rewards (every 2 levels)
      if (tier % 2 == 0) {
        rewards['$tier-free'] = BattlePassReward(
          tier: tier,
          isPremium: false,
          type: BattlePassRewardType.coins,
          value: 100 * tier,
          name: '${100 * tier} Coins',
          description: 'Free reward coins',
        );
      }

      // Premium tier rewards (every level)
      rewards['$tier-premium'] = _generatePremiumReward(tier);
    }

    return rewards;
  }

  /// Generate premium reward for tier
  BattlePassReward _generatePremiumReward(int tier) {
    // Milestone tiers (10, 20, 30, 40, 50)
    if (tier % 10 == 0) {
      return BattlePassReward(
        tier: tier,
        isPremium: true,
        type: BattlePassRewardType.exclusiveSkin,
        value: tier,
        name: 'Legendary Skin',
        description: 'Exclusive tier $tier skin',
        rarity: RewardRarity.legendary,
      );
    }

    // Special tiers (5, 15, 25, 35, 45)
    if (tier % 5 == 0) {
      return BattlePassReward(
        tier: tier,
        isPremium: true,
        type: BattlePassRewardType.epicSkin,
        value: tier,
        name: 'Epic Skin',
        description: 'Rare tier $tier skin',
        rarity: RewardRarity.epic,
      );
    }

    // Regular tiers
    final rewardTypes = [
      BattlePassRewardType.coins,
      BattlePassRewardType.powerUp,
      BattlePassRewardType.commonSkin,
      BattlePassRewardType.xpBoost,
    ];

    final type = rewardTypes[tier % rewardTypes.length];

    switch (type) {
      case BattlePassRewardType.coins:
        return BattlePassReward(
          tier: tier,
          isPremium: true,
          type: type,
          value: 200 * tier,
          name: '${200 * tier} Coins',
          description: 'Premium reward coins',
          rarity: RewardRarity.common,
        );
      case BattlePassRewardType.powerUp:
        return BattlePassReward(
          tier: tier,
          isPremium: true,
          type: type,
          value: 5,
          name: '5x Power-Ups',
          description: 'Random power-up bundle',
          rarity: RewardRarity.rare,
        );
      case BattlePassRewardType.commonSkin:
        return BattlePassReward(
          tier: tier,
          isPremium: true,
          type: type,
          value: tier,
          name: 'Common Skin',
          description: 'Cosmetic skin unlock',
          rarity: RewardRarity.common,
        );
      case BattlePassRewardType.xpBoost:
        return BattlePassReward(
          tier: tier,
          isPremium: true,
          type: type,
          value: 50,
          name: '+50% XP Boost',
          description: '1 hour of bonus XP',
          rarity: RewardRarity.rare,
        );
      default:
        return BattlePassReward(
          tier: tier,
          isPremium: true,
          type: BattlePassRewardType.coins,
          value: 100,
          name: '100 Coins',
          description: 'Coins',
          rarity: RewardRarity.common,
        );
    }
  }

  /// Grant reward to player
  Future<void> _grantReward(BattlePassReward reward) async {
    switch (reward.type) {
      case BattlePassRewardType.coins:
        CoinEconomyService.instance.earnCoins(reward.value, CoinSource.battlePass);
        break;
      case BattlePassRewardType.powerUp:
        // Grant power-ups
        break;
      case BattlePassRewardType.commonSkin:
      case BattlePassRewardType.epicSkin:
      case BattlePassRewardType.exclusiveSkin:
        // Unlock skin
        break;
      case BattlePassRewardType.xpBoost:
        // Activate XP boost
        break;
    }
  }

  /// Generate weekly challenges
  Future<void> _generateWeeklyChallenges() async {
    _weeklyChallenges.clear();

    _weeklyChallenges.addAll([
      BattlePassChallenge(
        id: 'weekly_1',
        title: 'Complete 20 Levels',
        description: 'Finish 20 levels this week',
        xpReward: 2000,
        requirement: 20,
        progress: 0,
      ),
      BattlePassChallenge(
        id: 'weekly_2',
        title: 'Earn 3 Perfect Scores',
        description: 'Get 3 stars on 3 different levels',
        xpReward: 1500,
        requirement: 3,
        progress: 0,
      ),
      BattlePassChallenge(
        id: 'weekly_3',
        title: 'Use 10 Power-Ups',
        description: 'Use any power-ups 10 times',
        xpReward: 1000,
        requirement: 10,
        progress: 0,
      ),
    ]);

    await _saveWeeklyChallenges();
  }

  /// Load weekly challenges
  Future<void> _loadWeeklyChallenges() async {
    // In production, load from SharedPreferences
    await _generateWeeklyChallenges();
  }

  /// Save weekly challenges
  Future<void> _saveWeeklyChallenges() async {
    // In production, save to SharedPreferences
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress(String challengeId, int progress) async {
    final challenge = _weeklyChallenges.firstWhere((c) => c.id == challengeId);
    challenge.progress = progress.clamp(0, challenge.requirement);

    if (challenge.progress >= challenge.requirement && !challenge.completed) {
      challenge.completed = true;
      await addXp(challenge.xpReward, 'weekly_challenge');
    }

    await _saveWeeklyChallenges();
  }

  /// Get all battle pass tiers with rewards
  List<BattlePassTier> getAllTiers() {
    final tiers = <BattlePassTier>[];
    final rewards = _generateRewards();

    for (int tier = 1; tier <= _maxTier; tier++) {
      final freeReward = rewards['$tier-free'];
      final premiumReward = rewards['$tier-premium'];

      tiers.add(BattlePassTier(
        tier: tier,
        isUnlocked: tier <= _currentTier,
        freeReward: freeReward,
        premiumReward: premiumReward,
        freeRewardClaimed: freeReward != null && _claimedRewards.contains(tier * 2),
        premiumRewardClaimed: premiumReward != null && _claimedRewards.contains(tier * 2 + 1),
      ));
    }

    return tiers;
  }

  /// Get current tier
  int getCurrentTier() => _currentTier;

  /// Get current XP
  int getCurrentXp() => _currentXp;

  /// Get XP to next tier
  int getXpToNextTier() => _xpPerTier - _currentXp;

  /// Check if has premium
  bool hasPremium() => _hasPremium;

  /// Get weekly challenges
  List<BattlePassChallenge> getWeeklyChallenges() => List.unmodifiable(_weeklyChallenges);

  /// Get season number
  int getSeasonNumber() => _seasonNumber;

  /// Get progress percentage
  double getProgressPercentage() => _currentTier / _maxTier;
}

/// Battle pass XP result
class BattlePassXpResult {
  final int xpGained;
  final int newTier;
  final List<int> tiersGained;
  final int currentXp;
  final int xpToNextTier;

  BattlePassXpResult({
    required this.xpGained,
    required this.newTier,
    required this.tiersGained,
    required this.currentXp,
    required this.xpToNextTier,
  });

  bool get hadTierUp => tiersGained.isNotEmpty;
}

/// Battle pass tier data
class BattlePassTier {
  final int tier;
  final bool isUnlocked;
  final BattlePassReward? freeReward;
  final BattlePassReward? premiumReward;
  final bool freeRewardClaimed;
  final bool premiumRewardClaimed;

  BattlePassTier({
    required this.tier,
    required this.isUnlocked,
    this.freeReward,
    this.premiumReward,
    required this.freeRewardClaimed,
    required this.premiumRewardClaimed,
  });
}

/// Battle pass reward
class BattlePassReward {
  final int tier;
  final bool isPremium;
  final BattlePassRewardType type;
  final int value;
  final String name;
  final String description;
  final RewardRarity rarity;

  BattlePassReward({
    required this.tier,
    required this.isPremium,
    required this.type,
    required this.value,
    required this.name,
    required this.description,
    this.rarity = RewardRarity.common,
  });
}

/// Battle pass reward types
enum BattlePassRewardType {
  coins,
  powerUp,
  commonSkin,
  epicSkin,
  exclusiveSkin,
  xpBoost,
}

/// Reward rarity
enum RewardRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Weekly challenge
class BattlePassChallenge {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final int requirement;
  int progress;
  bool completed;

  BattlePassChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.requirement,
    this.progress = 0,
    this.completed = false,
  });

  double get progressPercentage => (progress / requirement).clamp(0.0, 1.0);
}
