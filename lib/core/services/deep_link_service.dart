import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'referral_service.dart';
import '../utils/analytics_logger.dart';
import '../config/app_constants.dart';

/// Deep link service for handling app links
///
/// Supports:
/// - Universal Links (iOS)
/// - App Links (Android)
/// - Custom URL schemes
/// - Referral code handling
/// - Navigation coordination
///
/// URL Formats:
/// - sortbliss://app/referral?code=SBXXXX1234
/// - https://sortbliss.com/referral?code=SBXXXX1234
class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  static const MethodChannel _channel = MethodChannel('sortbliss/deep_links');

  bool _initialized = false;
  StreamController<DeepLink>? _linkStreamController;

  /// Stream of incoming deep links
  Stream<DeepLink> get linkStream => _linkStreamController!.stream;

  /// Initialize deep link handling
  Future<void> initialize() async {
    if (_initialized) return;

    _linkStreamController = StreamController<DeepLink>.broadcast();

    // Set up method channel for native deep links
    _channel.setMethodCallHandler(_handleMethodCall);

    // Check for initial deep link (app opened via link)
    await _checkInitialLink();

    _initialized = true;

    if (kDebugMode) {
      debugPrint('🔗 Deep Link Service initialized');
    }
  }

  /// Handle method calls from native platforms
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeepLink':
        final String? url = call.arguments as String?;
        if (url != null) {
          await _processDeepLink(url);
        }
        break;
      default:
        if (kDebugMode) {
          debugPrint('Unknown method: ${call.method}');
        }
    }
  }

  /// Check for initial deep link when app starts
  Future<void> _checkInitialLink() async {
    try {
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      if (initialLink != null && initialLink.isNotEmpty) {
        await _processDeepLink(initialLink);
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting initial link: ${e.message}');
      }
    }
  }

  /// Process incoming deep link
  Future<void> _processDeepLink(String url) async {
    if (kDebugMode) {
      debugPrint('🔗 Processing deep link: $url');
    }

    try {
      final uri = Uri.parse(url);
      final link = _parseDeepLink(uri);

      if (link != null) {
        // Emit link to stream for app to handle
        _linkStreamController?.add(link);

        // Handle referral links automatically
        if (link.type == DeepLinkType.referral && link.referralCode != null) {
          await _handleReferralLink(link.referralCode!);
        }

        // Log analytics
        AnalyticsLogger.logEvent('deep_link_opened', parameters: {
          'url': url,
          'type': link.type.toString(),
          'referral_code': link.referralCode,
        });
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Could not parse deep link: $url');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing deep link: $e');
      }
    }
  }

  /// Parse URI into DeepLink object
  DeepLink? _parseDeepLink(Uri uri) {
    // Handle custom scheme: sortbliss://app/...
    // Handle universal link: https://sortbliss.com/...

    final path = uri.path.toLowerCase();
    final queryParams = uri.queryParameters;

    // Referral link
    if (path.contains('referral')) {
      final code = queryParams['code'];
      if (code != null && code.isNotEmpty) {
        return DeepLink(
          type: DeepLinkType.referral,
          url: uri.toString(),
          referralCode: code,
        );
      }
    }

    // Level share link
    if (path.contains('level')) {
      final levelId = queryParams['id'];
      if (levelId != null) {
        return DeepLink(
          type: DeepLinkType.levelShare,
          url: uri.toString(),
          levelId: levelId,
        );
      }
    }

    // Event link
    if (path.contains('event')) {
      final eventId = queryParams['id'];
      if (eventId != null) {
        return DeepLink(
          type: DeepLinkType.event,
          url: uri.toString(),
          eventId: eventId,
        );
      }
    }

    // Challenge link
    if (path.contains('challenge')) {
      final challengeId = queryParams['id'];
      if (challengeId != null) {
        return DeepLink(
          type: DeepLinkType.challenge,
          url: uri.toString(),
          challengeId: challengeId,
        );
      }
    }

    // Default/unknown
    return DeepLink(
      type: DeepLinkType.unknown,
      url: uri.toString(),
    );
  }

  /// Handle referral deep link
  Future<void> _handleReferralLink(String code) async {
    try {
      final result = await ReferralService.instance.applyReferralCode(code);

      if (result.success) {
        if (kDebugMode) {
          debugPrint('✅ Referral code applied: $code (+${result.coinsEarned} coins)');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to apply referral code: ${result.error}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error handling referral link: $e');
      }
    }
  }

  /// Generate referral deep link
  String generateReferralLink(String referralCode) {
    // Universal link format (preferred for production)
    return 'https://sortbliss.com/referral?code=$referralCode';
  }

  /// Generate level share deep link
  String generateLevelShareLink(String levelId) {
    return 'https://sortbliss.com/level?id=$levelId';
  }

  /// Generate event deep link
  String generateEventLink(String eventId) {
    return 'https://sortbliss.com/event?id=$eventId';
  }

  /// Generate challenge deep link
  String generateChallengeLink(String challengeId) {
    return 'https://sortbliss.com/challenge?id=$challengeId';
  }

  /// Dispose resources
  void dispose() {
    _linkStreamController?.close();
    _initialized = false;
  }
}

/// Type of deep link
enum DeepLinkType {
  referral,
  levelShare,
  event,
  challenge,
  unknown,
}

/// Deep link data object
class DeepLink {
  final DeepLinkType type;
  final String url;
  final String? referralCode;
  final String? levelId;
  final String? eventId;
  final String? challengeId;
  final Map<String, dynamic>? customData;

  DeepLink({
    required this.type,
    required this.url,
    this.referralCode,
    this.levelId,
    this.eventId,
    this.challengeId,
    this.customData,
  });

  @override
  String toString() {
    return 'DeepLink(type: $type, url: $url, referralCode: $referralCode, '
        'levelId: $levelId, eventId: $eventId, challengeId: $challengeId)';
  }
}
