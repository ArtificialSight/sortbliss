import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/analytics_logger.dart';
import 'coin_economy_service.dart';
import '../config/app_constants.dart';

/// Referral and invite system for viral growth
///
/// Features:
/// - Unique referral codes per user
/// - Tracking of invited friends
/// - Coin rewards for both inviter and invitee
/// - Referral history and statistics
/// - Social sharing integration
/// - Deep linking support
/// - Leaderboard tracking
///
/// Reward Structure:
/// - Inviter: 100 coins per successful referral
/// - Invitee: 50 coins welcome bonus
/// - Milestone bonuses: 5 referrals = 500 coins, 10 = 1500 coins, 25 = 5000 coins
class ReferralService {
  static final ReferralService instance = ReferralService._();
  ReferralService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Storage keys
  static const String _keyReferralCode = 'user_referral_code';
  static const String _keyReferredBy = 'referred_by_code';
  static const String _keyReferralsList = 'referrals_list';
  static const String _keyReferralStats = 'referral_stats';
  static const String _keyMilestonesReached = 'milestones_reached';
  static const String _keyReferralRewardClaimed = 'referral_reward_claimed';
  static const String _keyLastShareTime = 'last_share_time';
  static const String _keyShareCount = 'share_count';

  // Reward configuration
  static const int rewardInviter = 100; // Coins for inviter
  static const int rewardInvitee = 50; // Coins for new user

  // Milestone rewards
  static const Map<int, int> milestoneRewards = {
    5: 500,
    10: 1500,
    25: 5000,
    50: 15000,
    100: 50000,
  };

  // State
  String? _referralCode;
  String? _referredByCode;
  List<ReferralRecord> _referrals = [];
  ReferralStats? _stats;

  /// Initialize the referral service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Generate or load referral code
    _referralCode = _prefs.getString(_keyReferralCode);
    if (_referralCode == null) {
      _referralCode = _generateReferralCode();
      await _prefs.setString(_keyReferralCode, _referralCode!);
    }

    // Load referral data
    _referredByCode = _prefs.getString(_keyReferredBy);
    _loadReferrals();
    _loadStats();

    _initialized = true;

    if (kDebugMode) {
      debugPrint('🎁 Referral Service initialized');
      debugPrint('   My Code: $_referralCode');
      debugPrint('   Referred By: ${_referredByCode ?? "None"}');
      debugPrint('   Total Referrals: ${_referrals.length}');
    }
  }

  /// Generate unique referral code
  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid confusing chars
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = List.generate(4, (i) => chars[random.nextInt(chars.length)]).join();
    final timestampPart = timestamp.substring(timestamp.length - 4);

    return 'SB$randomPart$timestampPart'; // SB = SortBliss
  }

  /// Apply referral code (when new user uses invite link)
  Future<ReferralResult> applyReferralCode(String code) async {
    if (!_initialized) await initialize();

    // Validate code
    if (code.isEmpty || code.length < 6) {
      return ReferralResult(
        success: false,
        error: 'Invalid referral code format',
      );
    }

    // Check if user already used a referral code
    if (_referredByCode != null) {
      return ReferralResult(
        success: false,
        error: 'You have already used a referral code',
      );
    }

    // Can't use own code
    if (code == _referralCode) {
      return ReferralResult(
        success: false,
        error: 'You cannot use your own referral code',
      );
    }

    // Apply the code
    await _prefs.setString(_keyReferredBy, code);
    _referredByCode = code;

    // Award welcome bonus to invitee
    final coinsEarned = rewardInvitee;
    CoinEconomyService.instance.earnCoins(
      coinsEarned,
      CoinSource.referral,
    );

    // Mark reward as claimed
    await _prefs.setBool(_keyReferralRewardClaimed, true);

    // Log analytics
    AnalyticsLogger.logEvent(AppConstants.eventReferralUsed, parameters: {
      'referral_code': code,
      'coins_earned': coinsEarned,
    });

    if (kDebugMode) {
      debugPrint('🎁 Referral code applied: $code (+$coinsEarned coins)');
    }

    // TODO: In production, notify the inviter via backend
    // This would typically be done through a server to prevent fraud

    return ReferralResult(
      success: true,
      coinsEarned: coinsEarned,
      message: 'Welcome! You earned $coinsEarned coins!',
    );
  }

  /// Record a successful referral (called by backend when invitee completes action)
  Future<void> recordReferral(String inviteeCode, String inviteeName) async {
    if (!_initialized) await initialize();

    // Create referral record
    final referral = ReferralRecord(
      inviteeCode: inviteeCode,
      inviteeName: inviteeName,
      timestamp: DateTime.now(),
      rewardEarned: rewardInviter,
    );

    // Add to list
    _referrals.add(referral);
    await _saveReferrals();

    // Award coins to inviter
    CoinEconomyService.instance.earnCoins(
      rewardInviter,
      CoinSource.referral,
    );

    // Update stats
    _updateStats();

    // Check for milestone rewards
    await _checkMilestones();

    // Log analytics
    AnalyticsLogger.logEvent(AppConstants.eventReferralCompleted, parameters: {
      'referral_code': _referralCode,
      'total_referrals': _referrals.length,
      'coins_earned': rewardInviter,
    });

    if (kDebugMode) {
      debugPrint('🎁 Referral recorded: $inviteeName (+$rewardInviter coins)');
      debugPrint('   Total referrals: ${_referrals.length}');
    }
  }

  /// Check and award milestone rewards
  Future<void> _checkMilestones() async {
    final totalReferrals = _referrals.length;
    final reachedMilestones = _prefs.getStringList(_keyMilestonesReached) ?? [];

    for (final entry in milestoneRewards.entries) {
      final milestone = entry.key;
      final reward = entry.value;

      if (totalReferrals >= milestone && !reachedMilestones.contains(milestone.toString())) {
        // Award milestone bonus
        CoinEconomyService.instance.earnCoins(
          reward,
          CoinSource.referral,
        );

        // Mark as reached
        reachedMilestones.add(milestone.toString());
        await _prefs.setStringList(_keyMilestonesReached, reachedMilestones);

        // Log analytics
        AnalyticsLogger.logEvent('referral_milestone_reached', parameters: {
          'milestone': milestone,
          'reward': reward,
          'total_referrals': totalReferrals,
        });

        if (kDebugMode) {
          debugPrint('🎉 Referral milestone reached: $milestone (+$reward coins)');
        }
      }
    }
  }

  /// Get user's referral code
  String getReferralCode() {
    return _referralCode ?? '';
  }

  /// Get referral share message
  String getShareMessage() {
    final code = getReferralCode();
    return '''Join me in SortBliss - the most addictive puzzle game! 🎮

Use my code: $code
Get ${rewardInvitee} free coins! 💰

Download now: ${AppConstants.appStoreUrl}''';
  }

  /// Get referral share URL (deep link)
  String getShareUrl() {
    final code = getReferralCode();
    // Deep link format: sortbliss://referral?code=XXXXX
    return '${AppConstants.appDeepLinkUrl}/referral?code=$code';
  }

  /// Track share action
  Future<void> trackShare(String method) async {
    final count = _prefs.getInt(_keyShareCount) ?? 0;
    await _prefs.setInt(_keyShareCount, count + 1);
    await _prefs.setInt(_keyLastShareTime, DateTime.now().millisecondsSinceEpoch);

    AnalyticsLogger.logEvent(AppConstants.eventReferralShared, parameters: {
      'method': method,
      'referral_code': _referralCode,
      'share_count': count + 1,
    });

    if (kDebugMode) {
      debugPrint('🎁 Referral shared via $method');
    }
  }

  /// Get referral statistics
  ReferralStats getStats() {
    if (_stats == null) {
      _updateStats();
    }
    return _stats!;
  }

  /// Get referral history
  List<ReferralRecord> getReferrals() {
    return List.unmodifiable(_referrals);
  }

  /// Get next milestone
  ReferralMilestone? getNextMilestone() {
    final totalReferrals = _referrals.length;
    final reachedMilestones = _prefs.getStringList(_keyMilestonesReached) ?? [];

    for (final entry in milestoneRewards.entries) {
      if (totalReferrals < entry.key && !reachedMilestones.contains(entry.key.toString())) {
        return ReferralMilestone(
          count: entry.key,
          reward: entry.value,
          progress: totalReferrals / entry.key,
        );
      }
    }

    return null;
  }

  /// Check if user has claimed referral reward
  bool hasClaimedReferralReward() {
    return _prefs.getBool(_keyReferralRewardClaimed) ?? false;
  }

  /// Check if user was referred by someone
  bool wasReferred() {
    return _referredByCode != null;
  }

  /// Get who referred this user
  String? getReferredBy() {
    return _referredByCode;
  }

  /// Update statistics
  void _updateStats() {
    final totalReferrals = _referrals.length;
    final totalCoinsEarned = _referrals.fold<int>(
      0,
      (sum, ref) => sum + ref.rewardEarned,
    );

    final reachedMilestones = _prefs.getStringList(_keyMilestonesReached) ?? [];
    final milestoneCoins = reachedMilestones.fold<int>(
      0,
      (sum, milestone) => sum + (milestoneRewards[int.parse(milestone)] ?? 0),
    );

    final shareCount = _prefs.getInt(_keyShareCount) ?? 0;

    _stats = ReferralStats(
      totalReferrals: totalReferrals,
      totalCoinsEarned: totalCoinsEarned + milestoneCoins,
      milestoneCoins: milestoneCoins,
      shareCount: shareCount,
      referralCode: _referralCode ?? '',
      wasReferred: _referredByCode != null,
      referredBy: _referredByCode,
    );

    // Save stats
    _saveStats();
  }

  /// Load referrals from storage
  void _loadReferrals() {
    final stored = _prefs.getString(_keyReferralsList);
    if (stored == null) {
      _referrals = [];
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(stored);
      _referrals = decoded
          .map((item) => ReferralRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading referrals: $e');
      }
      _referrals = [];
    }
  }

  /// Save referrals to storage
  Future<void> _saveReferrals() async {
    final encoded = jsonEncode(_referrals.map((r) => r.toJson()).toList());
    await _prefs.setString(_keyReferralsList, encoded);
  }

  /// Load stats from storage
  void _loadStats() {
    final stored = _prefs.getString(_keyReferralStats);
    if (stored == null) {
      _updateStats();
      return;
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(stored);
      _stats = ReferralStats.fromJson(decoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading referral stats: $e');
      }
      _updateStats();
    }
  }

  /// Save stats to storage
  Future<void> _saveStats() async {
    if (_stats != null) {
      final encoded = jsonEncode(_stats!.toJson());
      await _prefs.setString(_keyReferralStats, encoded);
    }
  }

  /// Reset referrals (for testing)
  Future<void> resetForTesting() async {
    await _prefs.remove(_keyReferredBy);
    await _prefs.remove(_keyReferralsList);
    await _prefs.remove(_keyReferralStats);
    await _prefs.remove(_keyMilestonesReached);
    await _prefs.remove(_keyReferralRewardClaimed);
    await _prefs.remove(_keyLastShareTime);
    await _prefs.remove(_keyShareCount);

    _referredByCode = null;
    _referrals = [];
    _updateStats();

    if (kDebugMode) {
      debugPrint('🎁 Referral data reset for testing');
    }
  }
}

/// Result of applying a referral code
class ReferralResult {
  final bool success;
  final int coinsEarned;
  final String? error;
  final String? message;

  ReferralResult({
    required this.success,
    this.coinsEarned = 0,
    this.error,
    this.message,
  });
}

/// Record of a single referral
class ReferralRecord {
  final String inviteeCode;
  final String inviteeName;
  final DateTime timestamp;
  final int rewardEarned;

  ReferralRecord({
    required this.inviteeCode,
    required this.inviteeName,
    required this.timestamp,
    required this.rewardEarned,
  });

  Map<String, dynamic> toJson() => {
        'inviteeCode': inviteeCode,
        'inviteeName': inviteeName,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'rewardEarned': rewardEarned,
      };

  factory ReferralRecord.fromJson(Map<String, dynamic> json) => ReferralRecord(
        inviteeCode: json['inviteeCode'] as String,
        inviteeName: json['inviteeName'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        rewardEarned: json['rewardEarned'] as int,
      );
}

/// Referral statistics
class ReferralStats {
  final int totalReferrals;
  final int totalCoinsEarned;
  final int milestoneCoins;
  final int shareCount;
  final String referralCode;
  final bool wasReferred;
  final String? referredBy;

  ReferralStats({
    required this.totalReferrals,
    required this.totalCoinsEarned,
    required this.milestoneCoins,
    required this.shareCount,
    required this.referralCode,
    required this.wasReferred,
    this.referredBy,
  });

  Map<String, dynamic> toJson() => {
        'totalReferrals': totalReferrals,
        'totalCoinsEarned': totalCoinsEarned,
        'milestoneCoins': milestoneCoins,
        'shareCount': shareCount,
        'referralCode': referralCode,
        'wasReferred': wasReferred,
        'referredBy': referredBy,
      };

  factory ReferralStats.fromJson(Map<String, dynamic> json) => ReferralStats(
        totalReferrals: json['totalReferrals'] as int,
        totalCoinsEarned: json['totalCoinsEarned'] as int,
        milestoneCoins: json['milestoneCoins'] as int,
        shareCount: json['shareCount'] as int,
        referralCode: json['referralCode'] as String,
        wasReferred: json['wasReferred'] as bool,
        referredBy: json['referredBy'] as String?,
      );
}

/// Referral milestone information
class ReferralMilestone {
  final int count;
  final int reward;
  final double progress;

  ReferralMilestone({
    required this.count,
    required this.reward,
    required this.progress,
  });
}
