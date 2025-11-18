import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../utils/analytics_logger.dart';

/// Backend API service for referral system
///
/// Production Implementation Required:
/// - Set up backend server (Node.js, Django, Firebase Functions, etc.)
/// - Implement secure API endpoints
/// - Add authentication/authorization
/// - Set up database (PostgreSQL, MongoDB, Firestore, etc.)
/// - Configure rate limiting and fraud prevention
/// - Add webhook support for real-time notifications
///
/// This service provides the structure and integration points.
/// Replace mock responses with actual API calls in production.
class ReferralApiService {
  static final ReferralApiService instance = ReferralApiService._();
  ReferralApiService._();

  // TODO: Replace with actual production API URL
  static const String baseUrl = 'https://api.sortbliss.com/v1';

  // API endpoints
  static const String _endpointValidateCode = '/referrals/validate';
  static const String _endpointRegisterReferral = '/referrals/register';
  static const String _endpointGetReferrals = '/referrals/list';
  static const String _endpointGetStats = '/referrals/stats';
  static const String _endpointClaimReward = '/referrals/claim';
  static const String _endpointLeaderboard = '/referrals/leaderboard';

  // Timeout durations
  static const Duration _timeout = Duration(seconds: 10);

  // Dio client
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  /// Validate a referral code with backend
  ///
  /// Returns:
  /// - isValid: Whether code exists and is active
  /// - userId: ID of user who owns the code
  /// - userName: Display name of referrer
  Future<ValidateCodeResponse> validateReferralCode(String code) async {
    if (kDebugMode) {
      debugPrint('🔍 Validating referral code: $code');
    }

    try {
      final response = await _dio.post(
        _endpointValidateCode,
        data: {
          'referral_code': code,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _getAuthToken()}',
          },
        ),
      );

      if (response.statusCode == 200) {
        return ValidateCodeResponse.fromJson(response.data);
      } else {
        throw ApiException(
          'Failed to validate code',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error validating referral code: $e');
      }

      // TEMPORARY: Return mock response for development
      return _mockValidateCode(code);
    }
  }

  /// Register a successful referral with backend
  ///
  /// Called when new user signs up with referral code
  Future<RegisterReferralResponse> registerReferral({
    required String referralCode,
    required String inviteeUserId,
    required String inviteeEmail,
  }) async {
    if (kDebugMode) {
      debugPrint('📝 Registering referral: $referralCode -> $inviteeUserId');
    }

    try {
      final response = await _dio.post(
        _endpointRegisterReferral,
        data: {
          'referral_code': referralCode,
          'invitee_user_id': inviteeUserId,
          'invitee_email': inviteeEmail,
          'timestamp': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _getAuthToken()}',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Log analytics
        AnalyticsLogger.logEvent('referral_registered_backend', parameters: {
          'referral_code': referralCode,
          'invitee_id': inviteeUserId,
        });

        return RegisterReferralResponse.fromJson(response.data);
      } else {
        throw ApiException(
          'Failed to register referral',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error registering referral: $e');
      }

      // TEMPORARY: Return mock response for development
      return _mockRegisterReferral();
    }
  }

  /// Get user's referral statistics from backend
  Future<ReferralStatsResponse> getReferralStats(String userId) async {
    try {
      final response = await _dio.get(
        _endpointGetStats,
        queryParameters: {'user_id': userId},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _getAuthToken()}',
          },
        ),
      );

      if (response.statusCode == 200) {
        return ReferralStatsResponse.fromJson(response.data);
      } else {
        throw ApiException(
          'Failed to fetch stats',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching referral stats: $e');
      }
      return _mockGetStats();
    }
  }

  /// Get referral leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    int limit = 100,
    String period = 'all_time', // 'daily', 'weekly', 'monthly', 'all_time'
  }) async {
    try {
      final response = await _dio.get(
        _endpointLeaderboard,
        queryParameters: {
          'limit': limit,
          'period': period,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _getAuthToken()}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((item) => LeaderboardEntry.fromJson(item)).toList();
      } else {
        throw ApiException(
          'Failed to fetch leaderboard',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching leaderboard: $e');
      }
      return _mockGetLeaderboard();
    }
  }

  /// Notify backend when user shares referral link
  Future<void> trackShare({
    required String userId,
    required String referralCode,
    required String method, // 'whatsapp', 'facebook', 'sms', 'email', etc.
  }) async {
    try {
      await _dio.post(
        '/referrals/share',
        data: {
          'user_id': userId,
          'referral_code': referralCode,
          'method': method,
          'timestamp': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _getAuthToken()}',
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to track share: $e');
      }
    }
  }

  /// Get authentication token
  /// TODO: Implement proper authentication
  Future<String> _getAuthToken() async {
    // In production, get from secure storage or auth service
    return 'development_token';
  }

  // ========== MOCK RESPONSES FOR DEVELOPMENT ==========
  // Remove these in production and use actual API calls

  ValidateCodeResponse _mockValidateCode(String code) {
    // Simulate validation - accept codes starting with 'SB'
    final isValid = code.startsWith('SB') && code.length >= 8;
    return ValidateCodeResponse(
      isValid: isValid,
      userId: isValid ? 'user_${code.substring(2, 6)}' : null,
      userName: isValid ? 'Player ${code.substring(2, 6)}' : null,
    );
  }

  RegisterReferralResponse _mockRegisterReferral() {
    return RegisterReferralResponse(
      success: true,
      inviterReward: 100,
      inviteeReward: 50,
      referralId: 'ref_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  ReferralStatsResponse _mockGetStats() {
    return ReferralStatsResponse(
      totalReferrals: 0,
      successfulReferrals: 0,
      pendingReferrals: 0,
      totalRewardsEarned: 0,
      currentRank: null,
    );
  }

  List<LeaderboardEntry> _mockGetLeaderboard() {
    return [
      LeaderboardEntry(
        rank: 1,
        userId: 'user_001',
        userName: 'TopReferrer',
        referralCount: 150,
        totalRewards: 25000,
      ),
      LeaderboardEntry(
        rank: 2,
        userId: 'user_002',
        userName: 'ShareMaster',
        referralCount: 98,
        totalRewards: 15000,
      ),
    ];
  }
}

// ========== API Response Models ==========

class ValidateCodeResponse {
  final bool isValid;
  final String? userId;
  final String? userName;

  ValidateCodeResponse({
    required this.isValid,
    this.userId,
    this.userName,
  });

  factory ValidateCodeResponse.fromJson(Map<String, dynamic> json) {
    return ValidateCodeResponse(
      isValid: json['is_valid'] as bool,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
    );
  }
}

class RegisterReferralResponse {
  final bool success;
  final int inviterReward;
  final int inviteeReward;
  final String referralId;

  RegisterReferralResponse({
    required this.success,
    required this.inviterReward,
    required this.inviteeReward,
    required this.referralId,
  });

  factory RegisterReferralResponse.fromJson(Map<String, dynamic> json) {
    return RegisterReferralResponse(
      success: json['success'] as bool,
      inviterReward: json['inviter_reward'] as int,
      inviteeReward: json['invitee_reward'] as int,
      referralId: json['referral_id'] as String,
    );
  }
}

class ReferralStatsResponse {
  final int totalReferrals;
  final int successfulReferrals;
  final int pendingReferrals;
  final int totalRewardsEarned;
  final int? currentRank;

  ReferralStatsResponse({
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.pendingReferrals,
    required this.totalRewardsEarned,
    this.currentRank,
  });

  factory ReferralStatsResponse.fromJson(Map<String, dynamic> json) {
    return ReferralStatsResponse(
      totalReferrals: json['total_referrals'] as int,
      successfulReferrals: json['successful_referrals'] as int,
      pendingReferrals: json['pending_referrals'] as int,
      totalRewardsEarned: json['total_rewards_earned'] as int,
      currentRank: json['current_rank'] as int?,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String userName;
  final int referralCount;
  final int totalRewards;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.referralCount,
    required this.totalRewards,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      referralCount: json['referral_count'] as int,
      totalRewards: json['total_rewards'] as int,
    );
  }
}

/// Custom API exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
