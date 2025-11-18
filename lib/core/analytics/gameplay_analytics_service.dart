import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_logger.dart';

/// Comprehensive gameplay analytics service for tracking user behavior,
/// session metrics, and monetization opportunities.
///
/// This service provides deep insights into player engagement, retention,
/// and revenue potential through detailed event tracking and analysis.
class GameplayAnalyticsService {
  GameplayAnalyticsService._();

  static final GameplayAnalyticsService instance = GameplayAnalyticsService._();

  static const String _sessionKey = 'analytics_current_session';
  static const String _historicalKey = 'analytics_historical_data';
  static const String _metricsKey = 'analytics_metrics_v1';

  SharedPreferences? _preferences;
  bool _initialized = false;

  GameSession? _currentSession;
  final ValueNotifier<GameplayMetrics> _metricsNotifier =
      ValueNotifier(GameplayMetrics.empty());

  ValueListenable<GameplayMetrics> get metrics => _metricsNotifier;
  GameplayMetrics get currentMetrics => _metricsNotifier.value;
  GameSession? get currentSession => _currentSession;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    _preferences = await SharedPreferences.getInstance();
    await _loadMetrics();
    _initialized = true;
  }

  /// Start a new gameplay session
  Future<void> startSession() async {
    if (!_initialized) await ensureInitialized();

    _currentSession = GameSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
    );

    await _saveSession();

    AnalyticsLogger.logEvent('session_started', parameters: {
      'session_id': _currentSession!.sessionId,
      'timestamp': _currentSession!.startTime.toIso8601String(),
    });
  }

  /// End the current gameplay session with summary data
  Future<void> endSession({
    int? levelsPlayed,
    int? coinsEarned,
    int? adsWatched,
    bool? madeIAPurchase,
  }) async {
    if (!_initialized) await ensureInitialized();
    if (_currentSession == null) return;

    final session = _currentSession!.copyWith(
      endTime: DateTime.now(),
      levelsPlayed: levelsPlayed ?? 0,
      coinsEarned: coinsEarned ?? 0,
      adsWatched: adsWatched ?? 0,
      madeIAPurchase: madeIAPurchase ?? false,
    );

    final duration = session.endTime!.difference(session.startTime);

    AnalyticsLogger.logEvent('session_ended', parameters: {
      'session_id': session.sessionId,
      'duration_seconds': duration.inSeconds,
      'levels_played': session.levelsPlayed,
      'coins_earned': session.coinsEarned,
      'ads_watched': session.adsWatched,
      'made_purchase': session.madeIAPurchase,
    });

    await _updateMetricsFromSession(session);
    await _archiveSession(session);

    _currentSession = null;
    await _preferences?.remove(_sessionKey);
  }

  /// Track level start event
  void trackLevelStart({
    required int levelNumber,
    required String difficulty,
  }) {
    AnalyticsLogger.logEvent('level_started', parameters: {
      'level_number': levelNumber,
      'difficulty': difficulty,
      'session_id': _currentSession?.sessionId ?? 'unknown',
    });
  }

  /// Track level completion with detailed metrics
  Future<void> trackLevelComplete({
    required int levelNumber,
    required int score,
    required int moves,
    required double timeSeconds,
    required bool perfectScore,
    required int starsEarned,
    required int coinsEarned,
  }) async {
    if (!_initialized) await ensureInitialized();

    final metrics = _metricsNotifier.value;
    final updated = metrics.copyWith(
      totalLevelsCompleted: metrics.totalLevelsCompleted + 1,
      totalScore: metrics.totalScore + score,
      totalCoinsEarned: metrics.totalCoinsEarned + coinsEarned,
      totalTimePlayedSeconds: metrics.totalTimePlayedSeconds + timeSeconds,
      perfectLevels: perfectScore
          ? metrics.perfectLevels + 1
          : metrics.perfectLevels,
      averageMovesPerLevel: _calculateNewAverage(
        metrics.averageMovesPerLevel,
        metrics.totalLevelsCompleted,
        moves.toDouble(),
      ),
      averageScorePerLevel: _calculateNewAverage(
        metrics.averageScorePerLevel,
        metrics.totalLevelsCompleted,
        score.toDouble(),
      ),
    );

    _metricsNotifier.value = updated;
    await _saveMetrics();

    AnalyticsLogger.logEvent('level_completed', parameters: {
      'level_number': levelNumber,
      'score': score,
      'moves': moves,
      'time_seconds': timeSeconds,
      'perfect_score': perfectScore,
      'stars_earned': starsEarned,
      'coins_earned': coinsEarned,
      'session_id': _currentSession?.sessionId ?? 'unknown',
    });
  }

  /// Track level failure
  void trackLevelFailed({
    required int levelNumber,
    required int moves,
    required double timeSeconds,
    required String failureReason,
  }) {
    AnalyticsLogger.logEvent('level_failed', parameters: {
      'level_number': levelNumber,
      'moves': moves,
      'time_seconds': timeSeconds,
      'failure_reason': failureReason,
      'session_id': _currentSession?.sessionId ?? 'unknown',
    });
  }

  /// Track monetization events
  Future<void> trackMonetizationEvent({
    required String eventType,
    String? productId,
    double? amount,
    int? coinsAwarded,
  }) async {
    if (!_initialized) await ensureInitialized();

    final metrics = _metricsNotifier.value;

    if (eventType == 'iap_purchase' && amount != null) {
      final updated = metrics.copyWith(
        totalIAPRevenue: metrics.totalIAPRevenue + amount,
        totalIAPurchases: metrics.totalIAPurchases + 1,
      );
      _metricsNotifier.value = updated;
      await _saveMetrics();
    } else if (eventType == 'rewarded_ad_watched') {
      final updated = metrics.copyWith(
        totalAdsWatched: metrics.totalAdsWatched + 1,
      );
      _metricsNotifier.value = updated;
      await _saveMetrics();
    }

    AnalyticsLogger.logEvent('monetization_event', parameters: {
      'event_type': eventType,
      if (productId != null) 'product_id': productId,
      if (amount != null) 'amount': amount,
      if (coinsAwarded != null) 'coins_awarded': coinsAwarded,
      'session_id': _currentSession?.sessionId ?? 'unknown',
    });
  }

  /// Track user engagement milestones
  void trackMilestone({
    required String milestoneType,
    required String milestone,
    Map<String, dynamic>? additionalData,
  }) {
    AnalyticsLogger.logEvent('milestone_achieved', parameters: {
      'milestone_type': milestoneType,
      'milestone': milestone,
      if (additionalData != null) ...additionalData,
      'session_id': _currentSession?.sessionId ?? 'unknown',
    });
  }

  /// Track user retention indicators
  Future<void> trackRetentionIndicator({
    required String indicatorType,
    required dynamic value,
  }) async {
    if (!_initialized) await ensureInitialized();

    AnalyticsLogger.logEvent('retention_indicator', parameters: {
      'indicator_type': indicatorType,
      'value': value.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get engagement score (0-100) based on player behavior
  double getEngagementScore() {
    final metrics = _metricsNotifier.value;

    if (metrics.totalLevelsCompleted == 0) return 0.0;

    double score = 0.0;

    // Factor 1: Completion rate (0-30 points)
    final completionRate = metrics.totalLevelsCompleted > 0 ? 30.0 : 0.0;
    score += completionRate;

    // Factor 2: Perfect level rate (0-25 points)
    final perfectRate = metrics.totalLevelsCompleted > 0
        ? (metrics.perfectLevels / metrics.totalLevelsCompleted) * 25.0
        : 0.0;
    score += perfectRate;

    // Factor 3: Session frequency (0-20 points)
    final sessionFrequency = metrics.totalSessions > 10 ? 20.0 : metrics.totalSessions * 2.0;
    score += sessionFrequency;

    // Factor 4: Monetization engagement (0-15 points)
    final monetizationScore = (metrics.totalIAPurchases > 0 ? 10.0 : 0.0) +
        (metrics.totalAdsWatched > 0 ? 5.0 : 0.0);
    score += monetizationScore;

    // Factor 5: Average session length (0-10 points)
    final avgSessionLength = metrics.totalSessions > 0
        ? metrics.totalTimePlayedSeconds / metrics.totalSessions
        : 0.0;
    final sessionLengthScore = (avgSessionLength / 600.0).clamp(0.0, 1.0) * 10.0; // 10 min ideal
    score += sessionLengthScore;

    return score.clamp(0.0, 100.0);
  }

  /// Get monetization potential score (0-100)
  double getMonetizationPotential() {
    final metrics = _metricsNotifier.value;

    double score = 0.0;

    // Already monetizing
    if (metrics.totalIAPurchases > 0) {
      score += 40.0;
    }

    // Engagement level (high engagement = high potential)
    final engagement = getEngagementScore();
    score += (engagement / 100.0) * 30.0;

    // Ad tolerance
    if (metrics.totalAdsWatched > 5) {
      score += 15.0;
    }

    // Session frequency
    if (metrics.totalSessions > 10) {
      score += 15.0;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Get churn risk score (0-100, higher = more risk)
  double getChurnRiskScore() {
    final metrics = _metricsNotifier.value;

    double risk = 0.0;

    // Low total playtime
    if (metrics.totalTimePlayedSeconds < 600) {
      risk += 30.0;
    }

    // Few sessions
    if (metrics.totalSessions < 3) {
      risk += 25.0;
    }

    // Low engagement
    final engagement = getEngagementScore();
    risk += (100.0 - engagement) * 0.2;

    // No monetization
    if (metrics.totalIAPurchases == 0 && metrics.totalAdsWatched == 0) {
      risk += 15.0;
    }

    // Short average session
    final avgSessionLength = metrics.totalSessions > 0
        ? metrics.totalTimePlayedSeconds / metrics.totalSessions
        : 0.0;
    if (avgSessionLength < 180) {
      // Less than 3 minutes
      risk += 10.0;
    }

    return risk.clamp(0.0, 100.0);
  }

  /// Get comprehensive analytics report
  Map<String, dynamic> getAnalyticsReport() {
    final metrics = _metricsNotifier.value;

    return {
      'summary': {
        'total_levels_completed': metrics.totalLevelsCompleted,
        'total_sessions': metrics.totalSessions,
        'total_playtime_hours': (metrics.totalTimePlayedSeconds / 3600.0).toStringAsFixed(2),
        'total_score': metrics.totalScore,
        'total_coins_earned': metrics.totalCoinsEarned,
      },
      'performance': {
        'average_score_per_level': metrics.averageScorePerLevel.toStringAsFixed(1),
        'average_moves_per_level': metrics.averageMovesPerLevel.toStringAsFixed(1),
        'perfect_level_rate': metrics.totalLevelsCompleted > 0
            ? ((metrics.perfectLevels / metrics.totalLevelsCompleted) * 100).toStringAsFixed(1)
            : '0.0',
        'perfect_levels_count': metrics.perfectLevels,
      },
      'monetization': {
        'total_iap_revenue': metrics.totalIAPRevenue.toStringAsFixed(2),
        'total_iap_purchases': metrics.totalIAPurchases,
        'total_ads_watched': metrics.totalAdsWatched,
        'monetization_potential_score': getMonetizationPotential().toStringAsFixed(1),
      },
      'engagement': {
        'engagement_score': getEngagementScore().toStringAsFixed(1),
        'churn_risk_score': getChurnRiskScore().toStringAsFixed(1),
        'average_session_length_minutes': metrics.totalSessions > 0
            ? ((metrics.totalTimePlayedSeconds / metrics.totalSessions) / 60.0).toStringAsFixed(1)
            : '0.0',
      },
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Reset all analytics data (for testing or user request)
  Future<void> resetAnalytics() async {
    if (!_initialized) await ensureInitialized();

    _metricsNotifier.value = GameplayMetrics.empty();
    _currentSession = null;

    await _preferences?.remove(_sessionKey);
    await _preferences?.remove(_metricsKey);
    await _preferences?.remove(_historicalKey);

    AnalyticsLogger.logEvent('analytics_reset');
  }

  double _calculateNewAverage(double oldAvg, int oldCount, double newValue) {
    if (oldCount == 0) return newValue;
    return ((oldAvg * oldCount) + newValue) / (oldCount + 1);
  }

  Future<void> _loadMetrics() async {
    final jsonString = _preferences?.getString(_metricsKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        _metricsNotifier.value = GameplayMetrics.fromJson(data);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Failed to load metrics: $error');
        }
      }
    }
  }

  Future<void> _saveMetrics() async {
    await _preferences?.setString(
      _metricsKey,
      jsonEncode(_metricsNotifier.value.toJson()),
    );
  }

  Future<void> _saveSession() async {
    if (_currentSession != null) {
      await _preferences?.setString(
        _sessionKey,
        jsonEncode(_currentSession!.toJson()),
      );
    }
  }

  Future<void> _updateMetricsFromSession(GameSession session) async {
    final metrics = _metricsNotifier.value;

    final duration = session.endTime!.difference(session.startTime);

    final updated = metrics.copyWith(
      totalSessions: metrics.totalSessions + 1,
      totalTimePlayedSeconds: metrics.totalTimePlayedSeconds + duration.inSeconds,
      totalAdsWatched: metrics.totalAdsWatched + session.adsWatched,
    );

    if (session.madeIAPurchase) {
      // Purchase amount would be tracked separately in trackMonetizationEvent
    }

    _metricsNotifier.value = updated;
    await _saveMetrics();
  }

  Future<void> _archiveSession(GameSession session) async {
    final historicalJson = _preferences?.getString(_historicalKey);
    List<dynamic> sessions = [];

    if (historicalJson != null && historicalJson.isNotEmpty) {
      try {
        sessions = jsonDecode(historicalJson) as List<dynamic>;
      } catch (_) {
        sessions = [];
      }
    }

    sessions.add(session.toJson());

    // Keep only last 50 sessions
    if (sessions.length > 50) {
      sessions = sessions.sublist(sessions.length - 50);
    }

    await _preferences?.setString(_historicalKey, jsonEncode(sessions));
  }
}

/// Represents a single gameplay session
class GameSession {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final int levelsPlayed;
  final int coinsEarned;
  final int adsWatched;
  final bool madeIAPurchase;

  const GameSession({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.levelsPlayed = 0,
    this.coinsEarned = 0,
    this.adsWatched = 0,
    this.madeIAPurchase = false,
  });

  GameSession copyWith({
    String? sessionId,
    DateTime? startTime,
    DateTime? endTime,
    int? levelsPlayed,
    int? coinsEarned,
    int? adsWatched,
    bool? madeIAPurchase,
  }) {
    return GameSession(
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      levelsPlayed: levelsPlayed ?? this.levelsPlayed,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      adsWatched: adsWatched ?? this.adsWatched,
      madeIAPurchase: madeIAPurchase ?? this.madeIAPurchase,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      'levelsPlayed': levelsPlayed,
      'coinsEarned': coinsEarned,
      'adsWatched': adsWatched,
      'madeIAPurchase': madeIAPurchase,
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      sessionId: json['sessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      levelsPlayed: json['levelsPlayed'] as int? ?? 0,
      coinsEarned: json['coinsEarned'] as int? ?? 0,
      adsWatched: json['adsWatched'] as int? ?? 0,
      madeIAPurchase: json['madeIAPurchase'] as bool? ?? false,
    );
  }
}

/// Aggregated gameplay metrics
class GameplayMetrics {
  final int totalLevelsCompleted;
  final int totalSessions;
  final double totalTimePlayedSeconds;
  final int totalScore;
  final int totalCoinsEarned;
  final int perfectLevels;
  final double averageMovesPerLevel;
  final double averageScorePerLevel;
  final int totalAdsWatched;
  final int totalIAPurchases;
  final double totalIAPRevenue;

  const GameplayMetrics({
    required this.totalLevelsCompleted,
    required this.totalSessions,
    required this.totalTimePlayedSeconds,
    required this.totalScore,
    required this.totalCoinsEarned,
    required this.perfectLevels,
    required this.averageMovesPerLevel,
    required this.averageScorePerLevel,
    required this.totalAdsWatched,
    required this.totalIAPurchases,
    required this.totalIAPRevenue,
  });

  factory GameplayMetrics.empty() {
    return const GameplayMetrics(
      totalLevelsCompleted: 0,
      totalSessions: 0,
      totalTimePlayedSeconds: 0.0,
      totalScore: 0,
      totalCoinsEarned: 0,
      perfectLevels: 0,
      averageMovesPerLevel: 0.0,
      averageScorePerLevel: 0.0,
      totalAdsWatched: 0,
      totalIAPurchases: 0,
      totalIAPRevenue: 0.0,
    );
  }

  GameplayMetrics copyWith({
    int? totalLevelsCompleted,
    int? totalSessions,
    double? totalTimePlayedSeconds,
    int? totalScore,
    int? totalCoinsEarned,
    int? perfectLevels,
    double? averageMovesPerLevel,
    double? averageScorePerLevel,
    int? totalAdsWatched,
    int? totalIAPurchases,
    double? totalIAPRevenue,
  }) {
    return GameplayMetrics(
      totalLevelsCompleted: totalLevelsCompleted ?? this.totalLevelsCompleted,
      totalSessions: totalSessions ?? this.totalSessions,
      totalTimePlayedSeconds:
          totalTimePlayedSeconds ?? this.totalTimePlayedSeconds,
      totalScore: totalScore ?? this.totalScore,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      perfectLevels: perfectLevels ?? this.perfectLevels,
      averageMovesPerLevel: averageMovesPerLevel ?? this.averageMovesPerLevel,
      averageScorePerLevel: averageScorePerLevel ?? this.averageScorePerLevel,
      totalAdsWatched: totalAdsWatched ?? this.totalAdsWatched,
      totalIAPurchases: totalIAPurchases ?? this.totalIAPurchases,
      totalIAPRevenue: totalIAPRevenue ?? this.totalIAPRevenue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLevelsCompleted': totalLevelsCompleted,
      'totalSessions': totalSessions,
      'totalTimePlayedSeconds': totalTimePlayedSeconds,
      'totalScore': totalScore,
      'totalCoinsEarned': totalCoinsEarned,
      'perfectLevels': perfectLevels,
      'averageMovesPerLevel': averageMovesPerLevel,
      'averageScorePerLevel': averageScorePerLevel,
      'totalAdsWatched': totalAdsWatched,
      'totalIAPurchases': totalIAPurchases,
      'totalIAPRevenue': totalIAPRevenue,
    };
  }

  factory GameplayMetrics.fromJson(Map<String, dynamic> json) {
    return GameplayMetrics(
      totalLevelsCompleted: json['totalLevelsCompleted'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      totalTimePlayedSeconds:
          (json['totalTimePlayedSeconds'] as num?)?.toDouble() ?? 0.0,
      totalScore: json['totalScore'] as int? ?? 0,
      totalCoinsEarned: json['totalCoinsEarned'] as int? ?? 0,
      perfectLevels: json['perfectLevels'] as int? ?? 0,
      averageMovesPerLevel:
          (json['averageMovesPerLevel'] as num?)?.toDouble() ?? 0.0,
      averageScorePerLevel:
          (json['averageScorePerLevel'] as num?)?.toDouble() ?? 0.0,
      totalAdsWatched: json['totalAdsWatched'] as int? ?? 0,
      totalIAPurchases: json['totalIAPurchases'] as int? ?? 0,
      totalIAPRevenue: (json['totalIAPRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
