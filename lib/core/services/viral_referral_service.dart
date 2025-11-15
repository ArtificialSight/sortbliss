import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_logger.dart';
import 'player_profile_service.dart';
import '../monetization/monetization_manager.dart';

/// Viral referral service for tracking and rewarding user invites
/// CRITICAL FOR: CAC reduction, viral coefficient validation, organic growth
class ViralReferralService {
  ViralReferralService._();

  static final ViralReferralService instance = ViralReferralService._();

  late SharedPreferences _preferences;
  bool _initialized = false;

  // User's personal referral code
  String? _myReferralCode;

  // Codes this user was referred by (for attribution)
  String? _referredByCode;

  // Track successful referrals (people who used my code)
  final Set<String> _successfulReferrals = {};

  // Share tracking
  int _totalShares = 0;
  int _shareConversions = 0;

  // Rewards configuration
  static const int coinsPerReferral = 150;
  static const int coinsForFirstShare = 50;
  static const int milestoneReferrals = 3; // Unlock bonus at 3 referrals
  static const int milestoneBonus = 500; // Coins + 7 days ad-free

  Future<void> initialize() async {
    if (_initialized) return;

    _preferences = await SharedPreferences.getInstance();
    _loadFromStorage();

    // Generate referral code if doesn't exist
    if (_myReferralCode == null) {
      _myReferralCode = _generateReferralCode();
      _preferences.setString('my_referral_code', _myReferralCode!);

      AnalyticsLogger.logEvent('referral_code_generated', parameters: {
        'code': _myReferralCode,
      });
    }

    _initialized = true;
  }

  /// Get user's unique referral code
  String get myReferralCode {
    if (!_initialized) {
      throw StateError('ViralReferralService not initialized. Call initialize() first.');
    }
    return _myReferralCode!;
  }

  /// Get viral metrics for analytics dashboard
  Map<String, dynamic> get viralMetrics => {
    'total_shares': _totalShares,
    'share_conversions': _shareConversions,
    'successful_referrals': _successfulReferrals.length,
    'viral_coefficient': viralCoefficient,
    'referred_by': _referredByCode,
  };

  /// Calculate viral coefficient (conversions / shares)
  double get viralCoefficient {
    if (_totalShares == 0) return 0.0;
    return _shareConversions / _totalShares;
  }

  /// Track when user shares their score
  Future<void> trackShare() async {
    _totalShares++;
    await _preferences.setInt('total_shares', _totalShares);

    AnalyticsLogger.logEvent('score_shared', parameters: {
      'total_shares': _totalShares,
      'referral_code': _myReferralCode,
      'share_number': _totalShares,
    });

    // Reward first share with coins
    if (_totalShares == 1) {
      MonetizationManager.instance.addCoins(coinsForFirstShare);

      AnalyticsLogger.logEvent('first_share_reward', parameters: {
        'coins_earned': coinsForFirstShare,
      });
    }
  }

  /// Process incoming referral code (new user was referred)
  Future<void> processIncomingReferral(String referralCode) async {
    if (_referredByCode != null) {
      // Already attributed to someone, ignore
      AnalyticsLogger.logEvent('referral_already_attributed', parameters: {
        'existing_code': _referredByCode,
        'new_code': referralCode,
      });
      return;
    }

    _referredByCode = referralCode;
    await _preferences.setString('referred_by_code', referralCode);

    // Track conversion for the referrer (would sync via backend in production)
    AnalyticsLogger.logEvent('referral_conversion', parameters: {
      'referral_code': referralCode,
      'new_user': true,
    });

    // Give new user welcome bonus
    MonetizationManager.instance.addCoins(100); // New user gets 100 coins

    AnalyticsLogger.logEvent('referral_welcome_bonus', parameters: {
      'coins_earned': 100,
      'referred_by': referralCode,
    });
  }

  /// Track successful referral (someone used my code)
  /// In production, this would come from backend after verified install
  Future<void> trackSuccessfulReferral(String newUserCode) async {
    if (_successfulReferrals.contains(newUserCode)) return;

    _successfulReferrals.add(newUserCode);
    _shareConversions++;

    await _preferences.setStringList('successful_referrals', _successfulReferrals.toList());
    await _preferences.setInt('share_conversions', _shareConversions);

    // Reward referrer
    MonetizationManager.instance.addCoins(coinsPerReferral);

    AnalyticsLogger.logEvent('referral_success', parameters: {
      'referrer_code': _myReferralCode,
      'new_user_code': newUserCode,
      'total_referrals': _successfulReferrals.length,
      'coins_earned': coinsPerReferral,
    });

    // Check for milestone bonus
    if (_successfulReferrals.length == milestoneReferrals) {
      _awardMilestoneBonus();
    }
  }

  void _awardMilestoneBonus() {
    // Award bonus coins
    MonetizationManager.instance.addCoins(milestoneBonus);

    // In production, would also grant 7 days ad-free
    // For demo, just log the achievement
    AnalyticsLogger.logEvent('referral_milestone_achieved', parameters: {
      'milestone': milestoneReferrals,
      'total_referrals': _successfulReferrals.length,
      'bonus_coins': milestoneBonus,
      'bonus_unlocked': '7_days_ad_free',
    });
  }

  /// Generate shareable deep link with referral code
  String generateShareLink() {
    // In production: Use Firebase Dynamic Links or Branch.io
    // For demo: Use custom URI scheme
    return 'https://sortbliss.app/invite?ref=$_myReferralCode';
  }

  /// Generate share message with personalized stats
  String generateShareMessage({
    required int level,
    required int score,
    required int stars,
  }) {
    final shareLink = generateShareLink();

    final messages = [
      'I just scored $score on Level $level in SortBliss! 🎯\nCan you beat my $stars⭐ performance? Try it:\n$shareLink',
      'Level $level complete with $stars⭐ stars! Score: $score 🎉\nThink you can sort faster? Challenge accepted:\n$shareLink',
      'Just crushed Level $level in SortBliss! $score points, $stars⭐\nYour turn - download and beat my score:\n$shareLink',
      '$stars⭐ on Level $level! My score: $score 🎮\nPlay SortBliss and try to beat me:\n$shareLink',
    ];

    // Rotate message based on level for variety
    return messages[level % messages.length];
  }

  String _generateReferralCode() {
    // Generate 8-character alphanumeric code
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid confusing chars
    final random = Random.secure();

    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  void _loadFromStorage() {
    _myReferralCode = _preferences.getString('my_referral_code');
    _referredByCode = _preferences.getString('referred_by_code');
    _totalShares = _preferences.getInt('total_shares') ?? 0;
    _shareConversions = _preferences.getInt('share_conversions') ?? 0;

    final referralsList = _preferences.getStringList('successful_referrals') ?? [];
    _successfulReferrals.addAll(referralsList);
  }

  /// Clear all referral data (for testing)
  Future<void> clearData() async {
    _myReferralCode = null;
    _referredByCode = null;
    _successfulReferrals.clear();
    _totalShares = 0;
    _shareConversions = 0;

    await _preferences.remove('my_referral_code');
    await _preferences.remove('referred_by_code');
    await _preferences.remove('total_shares');
    await _preferences.remove('share_conversions');
    await _preferences.remove('successful_referrals');

    AnalyticsLogger.logEvent('referral_data_cleared');
  }
}
