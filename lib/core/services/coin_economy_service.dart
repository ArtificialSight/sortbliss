import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/analytics_logger.dart';

/// Coin economy service for managing virtual currency
///
/// Features:
/// - Earn coins from various sources
/// - Spend coins on power-ups
/// - Transaction history
/// - Analytics tracking
/// - Coin multipliers and bonuses
/// - Daily/weekly coin limits
///
/// Coin Sources:
/// - Level completion (base: 10-50 coins based on stars)
/// - Achievements (50-500 coins)
/// - Daily rewards (10-100 coins)
/// - Events (100-1000 coins)
/// - Referrals (100 coins per friend)
/// - Ads (50 coins per rewarded ad)
/// - IAP (bundles)
///
/// Coin Sinks:
/// - Power-ups (3-20 coins)
/// - Themes (500-2000 coins)
/// - Avatars (100-1000 coins)
///
/// Usage:
/// ```dart
/// await CoinEconomyService.instance.initialize();
///
/// // Earn coins
/// await CoinEconomyService.instance.earnCoins(50, CoinSource.levelComplete);
///
/// // Spend coins
/// final success = await CoinEconomyService.instance.spendCoins(10, CoinSink.powerUp);
///
/// // Check balance
/// final balance = CoinEconomyService.instance.getBalance();
/// ```
class CoinEconomyService {
  static final CoinEconomyService instance = CoinEconomyService._();
  CoinEconomyService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  int _balance = 0;
  final List<CoinTransaction> _transactions = [];

  static const String _keyBalance = 'coin_balance';
  static const String _keyTransactions = 'coin_transactions';
  static const String _keyLifetimeEarned = 'coins_lifetime_earned';
  static const String _keyLifetimeSpent = 'coins_lifetime_spent';

  // Multipliers and bonuses
  double _coinMultiplier = 1.0;

  /// Initialize coin economy
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Load balance
    _balance = _prefs?.getInt(_keyBalance) ?? 0;

    // Load transactions (last 100)
    // TODO: Load from storage if needed

    _initialized = true;

    debugPrint('✅ Coin Economy Service initialized (balance: $_balance)');
  }

  /// Get current coin balance
  int getBalance() => _balance;

  /// Earn coins from a source
  Future<void> earnCoins(
    int amount,
    CoinSource source, {
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_initialized) await initialize();
    if (amount <= 0) return;

    // Apply multiplier
    final multipliedAmount = (amount * _coinMultiplier).round();

    // Update balance
    _balance += multipliedAmount;
    await _saveBalance();

    // Update lifetime earned
    final lifetimeEarned = _prefs?.getInt(_keyLifetimeEarned) ?? 0;
    await _prefs?.setInt(_keyLifetimeEarned, lifetimeEarned + multipliedAmount);

    // Record transaction
    final transaction = CoinTransaction(
      amount: multipliedAmount,
      type: CoinTransactionType.earn,
      source: source,
      description: description ?? source.toString(),
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _transactions.add(transaction);
    if (_transactions.length > 100) {
      _transactions.removeAt(0); // Keep only last 100
    }

    // Log analytics
    AnalyticsLogger.logEvent(
      'coins_earned',
      parameters: {
        'amount': multipliedAmount,
        'source': source.toString(),
        'balance': _balance,
        ...?metadata,
      },
    );

    debugPrint(
        '💰 Earned $multipliedAmount coins from ${source.toString()} (balance: $_balance)');
  }

  /// Spend coins on something
  Future<bool> spendCoins(
    int amount,
    CoinSink sink, {
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_initialized) await initialize();
    if (amount <= 0) return false;

    // Check if user can afford
    if (_balance < amount) {
      debugPrint('❌ Insufficient coins: need $amount, have $_balance');
      return false;
    }

    // Update balance
    _balance -= amount;
    await _saveBalance();

    // Update lifetime spent
    final lifetimeSpent = _prefs?.getInt(_keyLifetimeSpent) ?? 0;
    await _prefs?.setInt(_keyLifetimeSpent, lifetimeSpent + amount);

    // Record transaction
    final transaction = CoinTransaction(
      amount: amount,
      type: CoinTransactionType.spend,
      sink: sink,
      description: description ?? sink.toString(),
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _transactions.add(transaction);
    if (_transactions.length > 100) {
      _transactions.removeAt(0);
    }

    // Log analytics
    AnalyticsLogger.logEvent(
      'coins_spent',
      parameters: {
        'amount': amount,
        'sink': sink.toString(),
        'balance': _balance,
        ...?metadata,
      },
    );

    debugPrint(
        '💸 Spent $amount coins on ${sink.toString()} (balance: $_balance)');

    return true;
  }

  /// Set coin multiplier (for events, power-ups, etc.)
  void setCoinMultiplier(double multiplier) {
    _coinMultiplier = multiplier;
    debugPrint('💎 Coin multiplier set to ${multiplier}x');
  }

  /// Reset coin multiplier
  void resetCoinMultiplier() {
    _coinMultiplier = 1.0;
  }

  /// Get coin statistics
  CoinStatistics getStatistics() {
    final lifetimeEarned = _prefs?.getInt(_keyLifetimeEarned) ?? 0;
    final lifetimeSpent = _prefs?.getInt(_keyLifetimeSpent) ?? 0;

    final earnTransactions =
        _transactions.where((t) => t.type == CoinTransactionType.earn).length;
    final spendTransactions =
        _transactions.where((t) => t.type == CoinTransactionType.spend).length;

    return CoinStatistics(
      currentBalance: _balance,
      lifetimeEarned: lifetimeEarned,
      lifetimeSpent: lifetimeSpent,
      earnTransactionCount: earnTransactions,
      spendTransactionCount: spendTransactions,
      totalTransactions: _transactions.length,
    );
  }

  /// Get recent transactions
  List<CoinTransaction> getRecentTransactions({int limit = 20}) {
    return _transactions.reversed.take(limit).toList();
  }

  /// Get top coin sources
  Map<CoinSource, int> getTopSources() {
    final sources = <CoinSource, int>{};
    for (final transaction in _transactions) {
      if (transaction.type == CoinTransactionType.earn &&
          transaction.source != null) {
        sources[transaction.source!] =
            (sources[transaction.source!] ?? 0) + transaction.amount;
      }
    }
    return sources;
  }

  /// Get top coin sinks
  Map<CoinSink, int> getTopSinks() {
    final sinks = <CoinSink, int>{};
    for (final transaction in _transactions) {
      if (transaction.type == CoinTransactionType.spend &&
          transaction.sink != null) {
        sinks[transaction.sink!] =
            (sinks[transaction.sink!] ?? 0) + transaction.amount;
      }
    }
    return sinks;
  }

  /// Add coins (admin/debug function)
  Future<void> addCoins(int amount) async {
    await earnCoins(amount, CoinSource.debug, description: 'Debug add coins');
  }

  /// Save balance to storage
  Future<void> _saveBalance() async {
    await _prefs?.setInt(_keyBalance, _balance);
  }

  /// Reset coins (for testing)
  Future<void> resetCoins() async {
    _balance = 0;
    await _saveBalance();
    await _prefs?.remove(_keyLifetimeEarned);
    await _prefs?.remove(_keyLifetimeSpent);
    _transactions.clear();

    debugPrint('🔄 Coins reset');
  }
}

/// Coin transaction record
class CoinTransaction {
  final int amount;
  final CoinTransactionType type;
  final CoinSource? source;
  final CoinSink? sink;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  CoinTransaction({
    required this.amount,
    required this.type,
    this.source,
    this.sink,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  @override
  String toString() {
    final prefix = type == CoinTransactionType.earn ? '+' : '-';
    return '$prefix$amount coins: $description';
  }
}

/// Transaction type
enum CoinTransactionType {
  earn,
  spend,
}

/// Coin sources (ways to earn)
enum CoinSource {
  levelComplete,
  achievementUnlock,
  dailyReward,
  eventReward,
  referral,
  rewardedAd,
  iap,
  streak,
  firstTimeBonus,
  debug,
}

/// Coin sinks (ways to spend)
enum CoinSink {
  powerUp,
  theme,
  avatar,
  bundle,
  continueLevel,
  other,
}

/// Coin statistics
class CoinStatistics {
  final int currentBalance;
  final int lifetimeEarned;
  final int lifetimeSpent;
  final int earnTransactionCount;
  final int spendTransactionCount;
  final int totalTransactions;

  CoinStatistics({
    required this.currentBalance,
    required this.lifetimeEarned,
    required this.lifetimeSpent,
    required this.earnTransactionCount,
    required this.spendTransactionCount,
    required this.totalTransactions,
  });

  double get earnSpendRatio =>
      lifetimeSpent > 0 ? lifetimeEarned / lifetimeSpent : 0.0;

  @override
  String toString() {
    return 'CoinStatistics(\n'
        '  balance: $currentBalance,\n'
        '  earned: $lifetimeEarned,\n'
        '  spent: $lifetimeSpent,\n'
        '  transactions: $totalTransactions\n'
        ')';
  }
}

/// Coin reward calculator
class CoinRewardCalculator {
  /// Calculate coins for level completion
  static int calculateLevelReward({
    required int level,
    required int stars,
    required bool isPerfect,
    required int combo,
  }) {
    int baseReward = 10; // Base reward

    // Level scaling (higher levels = more coins)
    baseReward += (level / 10).floor() * 2;

    // Star bonus
    baseReward += stars * 10; // 10 coins per star

    // Perfect bonus
    if (isPerfect) {
      baseReward += 20;
    }

    // Combo bonus
    if (combo >= 5) {
      baseReward += combo * 2;
    }

    return baseReward.clamp(10, 100); // Min 10, max 100
  }

  /// Calculate coins for achievement unlock
  static int calculateAchievementReward(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return 50;
      case 'silver':
        return 100;
      case 'gold':
        return 250;
      case 'platinum':
        return 500;
      default:
        return 50;
    }
  }

  /// Calculate daily reward
  static int calculateDailyReward(int dayNumber) {
    // Increasing rewards for consecutive days
    if (dayNumber == 1) return 10;
    if (dayNumber == 2) return 15;
    if (dayNumber == 3) return 20;
    if (dayNumber == 4) return 30;
    if (dayNumber == 5) return 40;
    if (dayNumber == 6) return 60;
    if (dayNumber == 7) return 100; // Big bonus on day 7

    // After day 7, cycle repeats with slight increase
    final cycle = (dayNumber / 7).floor();
    final dayInCycle = dayNumber % 7;
    return calculateDailyReward(dayInCycle == 0 ? 7 : dayInCycle) +
        (cycle * 5);
  }
}
