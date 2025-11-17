import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../analytics/analytics_logger.dart';

/// Social sharing service with score cards, referral tracking, and viral loops
/// Drives organic growth through incentivized sharing
class SocialShareService {
  SocialShareService._();
  static final SocialShareService instance = SocialShareService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  static const String _keyShareCount = 'social_share_count';
  static const String _keyReferralCode = 'social_referral_code';
  static const String _keyReferredBy = 'social_referred_by';
  static const String _keySuccessfulReferrals = 'social_successful_referrals';
  static const String _keyLastShareDate = 'social_last_share_date';

  // Referral rewards
  static const int _coinsForSharing = 50; // Reward for sharing
  static const int _coinsForReferral = 100; // Reward when referred user installs
  static const int _coinsForReferralMilestone = 500; // Bonus at 5 referrals

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();

    // Generate referral code if not exists
    if (!_prefs.containsKey(_keyReferralCode)) {
      final code = _generateReferralCode();
      await _prefs.setString(_keyReferralCode, code);
    }
  }

  /// Share level completion with visual score card
  Future<void> shareLevelComplete({
    required BuildContext context,
    required int level,
    required int stars,
    required int score,
    GlobalKey? scoreCardKey,
  }) async {
    if (!_initialized) await initialize();

    final message = 'I just completed level $level in SortBliss with $stars⭐ and a score of $score! Can you beat my score? 🎮';

    try {
      String? imagePath;

      // Capture score card as image if key provided
      if (scoreCardKey != null) {
        imagePath = await _captureWidget(scoreCardKey);
      }

      // Share with image
      if (imagePath != null) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: message,
        );
      } else {
        // Fallback to text only
        await Share.share(message);
      }

      await _recordShare('level_complete');

      AnalyticsLogger.logEvent('social_share_level_complete', parameters: {
        'level': level,
        'stars': stars,
        'score': score,
        'has_image': imagePath != null,
      });
    } catch (e) {
      debugPrint('Error sharing level: $e');
      AnalyticsLogger.logEvent('social_share_error', parameters: {
        'error': e.toString(),
        'type': 'level_complete',
      });
    }
  }

  /// Share achievement unlock
  Future<void> shareAchievement({
    required String achievementName,
    required String description,
  }) async {
    if (!_initialized) await initialize();

    final message = 'I just unlocked "$achievementName" in SortBliss! $description 🏆';

    try {
      await Share.share(message);
      await _recordShare('achievement');

      AnalyticsLogger.logEvent('social_share_achievement', parameters: {
        'achievement': achievementName,
      });
    } catch (e) {
      debugPrint('Error sharing achievement: $e');
    }
  }

  /// Share daily streak milestone
  Future<void> shareStreak({
    required int streakDays,
  }) async {
    if (!_initialized) await initialize();

    final message = 'I\'ve maintained a $streakDays-day streak in SortBliss! 🔥 Join me and start your journey!';

    try {
      await Share.share(message);
      await _recordShare('streak');

      AnalyticsLogger.logEvent('social_share_streak', parameters: {
        'streak_days': streakDays,
      });
    } catch (e) {
      debugPrint('Error sharing streak: $e');
    }
  }

  /// Share referral code (invite friends)
  Future<void> shareReferralCode() async {
    if (!_initialized) await initialize();

    final code = getReferralCode();
    final message = 'Join me on SortBliss - a relaxing puzzle game! Use my code "$code" to get 100 bonus coins when you start! 🎁\n\nDownload: [App Store Link]';

    try {
      await Share.share(message);
      await _recordShare('referral');

      AnalyticsLogger.logEvent('social_share_referral', parameters: {
        'referral_code': code,
      });
    } catch (e) {
      debugPrint('Error sharing referral: $e');
    }
  }

  /// Capture widget as image for sharing
  Future<String?> _captureWidget(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/score_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file.path;
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// Record share event
  Future<void> _recordShare(String shareType) async {
    final count = getShareCount() + 1;
    await _prefs.setInt(_keyShareCount, count);
    await _prefs.setString(_keyLastShareDate, DateTime.now().toIso8601String());

    // Reward coins for sharing (first 3 shares only to prevent abuse)
    if (count <= 3) {
      // Note: Actual coin granting would be done by calling code
      AnalyticsLogger.logEvent('social_share_reward_eligible', parameters: {
        'share_count': count,
        'reward_coins': _coinsForSharing,
      });
    }
  }

  /// Generate unique referral code
  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed ambiguous chars
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();

    for (int i = 0; i < 6; i++) {
      code.write(chars[(random + i) % chars.length]);
    }

    return code.toString();
  }

  /// Apply referral code (when new user enters code)
  Future<bool> applyReferralCode(String code) async {
    if (!_initialized) await initialize();

    // Don't allow self-referral
    if (code == getReferralCode()) {
      return false;
    }

    // Check if already referred
    if (_prefs.containsKey(_keyReferredBy)) {
      return false;
    }

    // Store referral
    await _prefs.setString(_keyReferredBy, code);

    AnalyticsLogger.logEvent('social_referral_applied', parameters: {
      'referral_code': code,
    });

    // TODO: Send to backend to credit referrer
    // In production, this would call a Cloud Function to:
    // 1. Validate referral code
    // 2. Credit referrer with coins
    // 3. Credit new user with welcome bonus

    return true;
  }

  /// Record successful referral (when referred user completes onboarding)
  Future<void> recordReferralSuccess(String code) async {
    // TODO: Call backend to credit referrer
    // This would be triggered after user completes tutorial or reaches level 5

    AnalyticsLogger.logEvent('social_referral_success', parameters: {
      'referral_code': code,
      'reward_coins': _coinsForReferral,
    });
  }

  // Getters
  int getShareCount() {
    return _prefs.getInt(_keyShareCount) ?? 0;
  }

  String getReferralCode() {
    return _prefs.getString(_keyReferralCode) ?? 'UNKNOWN';
  }

  String? getReferredBy() {
    return _prefs.getString(_keyReferredBy);
  }

  int getSuccessfulReferrals() {
    return _prefs.getInt(_keySuccessfulReferrals) ?? 0;
  }

  DateTime? getLastShareDate() {
    final dateString = _prefs.getString(_keyLastShareDate);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  /// Get share statistics
  ShareStats getShareStats() {
    return ShareStats(
      totalShares: getShareCount(),
      referralCode: getReferralCode(),
      referredBy: getReferredBy(),
      successfulReferrals: getSuccessfulReferrals(),
      lastShareDate: getLastShareDate(),
    );
  }

  /// Check if eligible for share reward
  bool isEligibleForShareReward() {
    return getShareCount() < 3;
  }

  /// Reset for testing
  Future<void> resetForTesting() async {
    await _prefs.remove(_keyShareCount);
    await _prefs.remove(_keyReferralCode);
    await _prefs.remove(_keyReferredBy);
    await _prefs.remove(_keySuccessfulReferrals);
    await _prefs.remove(_keyLastShareDate);

    // Regenerate referral code
    final code = _generateReferralCode();
    await _prefs.setString(_keyReferralCode, code);
  }
}

/// Share statistics model
class ShareStats {
  const ShareStats({
    required this.totalShares,
    required this.referralCode,
    this.referredBy,
    required this.successfulReferrals,
    this.lastShareDate,
  });

  final int totalShares;
  final String referralCode;
  final String? referredBy;
  final int successfulReferrals;
  final DateTime? lastShareDate;
}
