import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_logger.dart';
import '../analytics/gameplay_analytics_service.dart';
import '../services/player_profile_service.dart';
import '../services/user_settings_service.dart';
import '../network/openai_proxy_service.dart';

/// AI-powered adaptive difficulty adjustment engine.
///
/// Analyzes player performance, behavior patterns, and engagement metrics
/// to dynamically recommend optimal difficulty settings that maximize
/// retention, engagement, and enjoyment.
class AdaptiveDifficultyEngine {
  AdaptiveDifficultyEngine._();

  static final AdaptiveDifficultyEngine instance = AdaptiveDifficultyEngine._();

  static const String _prefsKey = 'adaptive_difficulty_data';
  static const Duration _analysisInterval = Duration(hours: 24);

  SharedPreferences? _preferences;
  bool _initialized = false;
  DateTime? _lastAnalysisTime;
  DifficultyRecommendation? _currentRecommendation;

  final ValueNotifier<DifficultyInsights> _insightsNotifier =
      ValueNotifier(DifficultyInsights.empty());

  ValueListenable<DifficultyInsights> get insights => _insightsNotifier;
  DifficultyInsights get currentInsights => _insightsNotifier.value;
  DifficultyRecommendation? get currentRecommendation => _currentRecommendation;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    _preferences = await SharedPreferences.getInstance();
    await _loadData();
    _initialized = true;
  }

  /// Analyze player performance and generate difficulty recommendation
  Future<DifficultyRecommendation> analyzeDifficulty({
    bool useAI = true,
  }) async {
    if (!_initialized) await ensureInitialized();

    final profile = PlayerProfileService.instance.currentProfile;
    final settings = UserSettingsService.instance.settings.value;
    final analytics = GameplayAnalyticsService.instance.currentMetrics;

    // Calculate local metrics
    final performanceScore = _calculatePerformanceScore(profile, analytics);
    final engagementScore = GameplayAnalyticsService.instance.getEngagementScore();
    final churnRisk = GameplayAnalyticsService.instance.getChurnRiskScore();

    DifficultyRecommendation recommendation;

    if (useAI && await _shouldUseAI()) {
      // Use AI analysis for advanced recommendations
      recommendation = await _getAIRecommendation(
        performanceScore: performanceScore,
        engagementScore: engagementScore,
        churnRisk: churnRisk,
        currentDifficulty: settings.difficulty,
        profile: profile,
        analytics: analytics,
      );
    } else {
      // Use rule-based system
      recommendation = _getRuleBasedRecommendation(
        performanceScore: performanceScore,
        engagementScore: engagementScore,
        churnRisk: churnRisk,
        currentDifficulty: settings.difficulty,
      );
    }

    _currentRecommendation = recommendation;
    _lastAnalysisTime = DateTime.now();

    await _updateInsights(recommendation);
    await _saveData();

    AnalyticsLogger.logEvent('difficulty_analyzed', parameters: {
      'current_difficulty': settings.difficulty,
      'recommended_difficulty': recommendation.recommendedDifficulty,
      'confidence': recommendation.confidence,
      'performance_score': performanceScore,
      'engagement_score': engagementScore,
      'churn_risk': churnRisk,
      'used_ai': useAI,
    });

    return recommendation;
  }

  /// Apply recommended difficulty adjustment
  Future<void> applyRecommendation(DifficultyRecommendation recommendation) async {
    if (!_initialized) await ensureInitialized();

    await UserSettingsService.instance.setDifficulty(
      recommendation.recommendedDifficulty,
    );

    AnalyticsLogger.logEvent('difficulty_adjusted', parameters: {
      'new_difficulty': recommendation.recommendedDifficulty,
      'reason': recommendation.reason,
      'confidence': recommendation.confidence,
    });
  }

  /// Get real-time difficulty insights without full analysis
  DifficultyInsights getQuickInsights() {
    final profile = PlayerProfileService.instance.currentProfile;
    final settings = UserSettingsService.instance.settings.value;
    final analytics = GameplayAnalyticsService.instance.currentMetrics;

    final performanceScore = _calculatePerformanceScore(profile, analytics);
    final currentDifficulty = settings.difficulty;

    String assessment;
    if (performanceScore > 80.0 && currentDifficulty < 0.7) {
      assessment = 'Player is performing well - difficulty may be too easy';
    } else if (performanceScore < 40.0 && currentDifficulty > 0.3) {
      assessment = 'Player is struggling - difficulty may be too hard';
    } else {
      assessment = 'Difficulty appears well-balanced for player skill';
    }

    return DifficultyInsights(
      performanceScore: performanceScore,
      currentDifficulty: currentDifficulty,
      assessment: assessment,
      lastUpdated: DateTime.now(),
    );
  }

  /// Check if difficulty should be auto-adjusted
  bool shouldSuggestAdjustment() {
    if (_currentRecommendation == null) return false;

    final settings = UserSettingsService.instance.settings.value;
    final diff = (settings.difficulty - _currentRecommendation!.recommendedDifficulty).abs();

    // Suggest if recommendation differs by more than 0.15 and confidence > 70%
    return diff > 0.15 && _currentRecommendation!.confidence > 0.7;
  }

  double _calculatePerformanceScore(
    PlayerProfile profile,
    GameplayMetrics analytics,
  ) {
    double score = 0.0;

    // Factor 1: Completion rate (40 points)
    if (analytics.totalLevelsCompleted > 0) {
      score += 40.0;
    }

    // Factor 2: Perfect completion rate (30 points)
    if (analytics.totalLevelsCompleted > 0) {
      final perfectRate = analytics.perfectLevels / analytics.totalLevelsCompleted;
      score += perfectRate * 30.0;
    }

    // Factor 3: Streak maintenance (20 points)
    final streakScore = (profile.currentStreak / 30.0).clamp(0.0, 1.0) * 20.0;
    score += streakScore;

    // Factor 4: Average score performance (10 points)
    if (analytics.averageScorePerLevel > 0) {
      // Assume max score is around 1000
      final scoreRate = (analytics.averageScorePerLevel / 1000.0).clamp(0.0, 1.0);
      score += scoreRate * 10.0;
    }

    return score.clamp(0.0, 100.0);
  }

  DifficultyRecommendation _getRuleBasedRecommendation({
    required double performanceScore,
    required double engagementScore,
    required double churnRisk,
    required double currentDifficulty,
  }) {
    double recommendedDifficulty = currentDifficulty;
    String reason = '';
    double confidence = 0.8;

    // Rule 1: High performance, low difficulty → increase
    if (performanceScore > 75.0 && currentDifficulty < 0.6) {
      recommendedDifficulty = (currentDifficulty + 0.15).clamp(0.0, 1.0);
      reason = 'Strong performance suggests readiness for more challenge';
    }
    // Rule 2: Low performance, high difficulty → decrease
    else if (performanceScore < 40.0 && currentDifficulty > 0.4) {
      recommendedDifficulty = (currentDifficulty - 0.15).clamp(0.0, 1.0);
      reason = 'Performance indicates difficulty may be too high';
    }
    // Rule 3: High churn risk → make easier
    else if (churnRisk > 70.0) {
      recommendedDifficulty = (currentDifficulty - 0.1).clamp(0.0, 1.0);
      reason = 'High churn risk - reducing difficulty to improve retention';
      confidence = 0.9;
    }
    // Rule 4: High engagement, moderate performance → slight increase
    else if (engagementScore > 70.0 && performanceScore > 60.0) {
      recommendedDifficulty = (currentDifficulty + 0.1).clamp(0.0, 1.0);
      reason = 'High engagement and good performance support gradual increase';
    }
    // Rule 5: Balanced state
    else {
      reason = 'Current difficulty appears well-suited to player';
      confidence = 0.7;
    }

    return DifficultyRecommendation(
      recommendedDifficulty: recommendedDifficulty,
      currentDifficulty: currentDifficulty,
      reason: reason,
      confidence: confidence,
      adjustmentType: _getAdjustmentType(recommendedDifficulty, currentDifficulty),
      performanceFactors: {
        'performance_score': performanceScore,
        'engagement_score': engagementScore,
        'churn_risk': churnRisk,
      },
    );
  }

  Future<DifficultyRecommendation> _getAIRecommendation({
    required double performanceScore,
    required double engagementScore,
    required double churnRisk,
    required double currentDifficulty,
    required PlayerProfile profile,
    required GameplayMetrics analytics,
  }) async {
    try {
      final prompt = _buildAIPrompt(
        performanceScore: performanceScore,
        engagementScore: engagementScore,
        churnRisk: churnRisk,
        currentDifficulty: currentDifficulty,
        profile: profile,
        analytics: analytics,
      );

      final openAIService = OpenAiProxyService.instance;
      final response = await openAIService.generateChatCompletion(
        messages: [
          {'role': 'system', 'content': _getSystemPrompt()},
          {'role': 'user', 'content': prompt},
        ],
        temperature: 0.3, // Lower temperature for consistent recommendations
        maxTokens: 500,
      );

      final aiResponse = _parseAIResponse(response);

      return DifficultyRecommendation(
        recommendedDifficulty: aiResponse['recommended_difficulty'] as double,
        currentDifficulty: currentDifficulty,
        reason: aiResponse['reason'] as String,
        confidence: aiResponse['confidence'] as double,
        adjustmentType: _getAdjustmentType(
          aiResponse['recommended_difficulty'] as double,
          currentDifficulty,
        ),
        performanceFactors: {
          'performance_score': performanceScore,
          'engagement_score': engagementScore,
          'churn_risk': churnRisk,
          'ai_analysis': aiResponse['analysis'] as String? ?? '',
        },
      );
    } catch (error) {
      // Fallback to rule-based if AI fails
      AnalyticsLogger.logEvent('ai_difficulty_failed', parameters: {
        'error': error.toString(),
      });

      return _getRuleBasedRecommendation(
        performanceScore: performanceScore,
        engagementScore: engagementScore,
        churnRisk: churnRisk,
        currentDifficulty: currentDifficulty,
      );
    }
  }

  String _getSystemPrompt() {
    return '''You are an expert game difficulty balancing AI for a casual puzzle game.
Your goal is to recommend optimal difficulty settings that maximize player engagement,
enjoyment, and retention while preventing frustration and churn.

Difficulty scale: 0.0 (easiest) to 1.0 (hardest)
- 0.0-0.25: Tranquil (very easy)
- 0.26-0.50: Balanced (moderate)
- 0.51-0.75: Challenging (hard)
- 0.76-1.00: Brain Burner (very hard)

Respond with a JSON object containing:
- recommended_difficulty (number 0.0-1.0)
- reason (string explaining the recommendation)
- confidence (number 0.0-1.0 indicating how confident you are)
- analysis (brief analysis of player state)

Consider:
1. Performance score (higher = better performance)
2. Engagement score (higher = more engaged)
3. Churn risk (higher = more likely to leave)
4. Player progression and skill development
5. Balance between challenge and frustration''';
  }

  String _buildAIPrompt({
    required double performanceScore,
    required double engagementScore,
    required double churnRisk,
    required double currentDifficulty,
    required PlayerProfile profile,
    required GameplayMetrics analytics,
  }) {
    return '''Analyze this player's performance and recommend optimal difficulty:

Current Difficulty: ${currentDifficulty.toStringAsFixed(2)} (${_getDifficultyLabel(currentDifficulty)})

Performance Metrics:
- Performance Score: ${performanceScore.toStringAsFixed(1)}/100
- Engagement Score: ${engagementScore.toStringAsFixed(1)}/100
- Churn Risk: ${churnRisk.toStringAsFixed(1)}/100
- Current Streak: ${profile.currentStreak} days
- Levels Completed: ${analytics.totalLevelsCompleted}
- Perfect Levels: ${analytics.perfectLevels}
- Average Score: ${analytics.averageScorePerLevel.toStringAsFixed(0)}
- Total Sessions: ${analytics.totalSessions}
- Total Playtime: ${(analytics.totalTimePlayedSeconds / 3600.0).toStringAsFixed(1)} hours

What difficulty level (0.0-1.0) would you recommend and why?''';
  }

  Map<String, dynamic> _parseAIResponse(String response) {
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        return {
          'recommended_difficulty': (data['recommended_difficulty'] as num).toDouble().clamp(0.0, 1.0),
          'reason': data['reason'] as String? ?? 'AI recommendation',
          'confidence': (data['confidence'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.75,
          'analysis': data['analysis'] as String? ?? '',
        };
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to parse AI response: $error');
      }
    }

    // Fallback values
    return {
      'recommended_difficulty': 0.5,
      'reason': 'Unable to parse AI recommendation - using balanced difficulty',
      'confidence': 0.5,
      'analysis': 'AI parsing failed',
    };
  }

  AdjustmentType _getAdjustmentType(double recommended, double current) {
    final diff = recommended - current;
    if (diff.abs() < 0.05) return AdjustmentType.maintain;
    if (diff > 0) {
      return diff > 0.15 ? AdjustmentType.increaseSignificant : AdjustmentType.increaseSlightly;
    } else {
      return diff < -0.15 ? AdjustmentType.decreaseSignificant : AdjustmentType.decreaseSlightly;
    }
  }

  String _getDifficultyLabel(double difficulty) {
    if (difficulty <= 0.25) return 'Tranquil';
    if (difficulty <= 0.5) return 'Balanced';
    if (difficulty <= 0.75) return 'Challenging';
    return 'Brain Burner';
  }

  Future<bool> _shouldUseAI() async {
    // Only use AI if enough data is available and not analyzed recently
    final analytics = GameplayAnalyticsService.instance.currentMetrics;

    if (analytics.totalLevelsCompleted < 5) {
      return false; // Not enough data
    }

    if (_lastAnalysisTime != null) {
      final timeSinceLastAnalysis = DateTime.now().difference(_lastAnalysisTime!);
      if (timeSinceLastAnalysis < _analysisInterval) {
        return false; // Too soon
      }
    }

    return true;
  }

  Future<void> _updateInsights(DifficultyRecommendation recommendation) async {
    final profile = PlayerProfileService.instance.currentProfile;
    final analytics = GameplayAnalyticsService.instance.currentMetrics;

    _insightsNotifier.value = DifficultyInsights(
      performanceScore: _calculatePerformanceScore(profile, analytics),
      currentDifficulty: recommendation.currentDifficulty,
      recommendedDifficulty: recommendation.recommendedDifficulty,
      assessment: recommendation.reason,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> _loadData() async {
    final jsonString = _preferences?.getString(_prefsKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        if (data['last_analysis_time'] != null) {
          _lastAnalysisTime = DateTime.parse(data['last_analysis_time'] as String);
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Failed to load adaptive difficulty data: $error');
        }
      }
    }
  }

  Future<void> _saveData() async {
    final data = {
      'last_analysis_time': _lastAnalysisTime?.toIso8601String(),
    };
    await _preferences?.setString(_prefsKey, jsonEncode(data));
  }
}

/// Difficulty adjustment recommendation
class DifficultyRecommendation {
  final double recommendedDifficulty;
  final double currentDifficulty;
  final String reason;
  final double confidence;
  final AdjustmentType adjustmentType;
  final Map<String, dynamic> performanceFactors;

  const DifficultyRecommendation({
    required this.recommendedDifficulty,
    required this.currentDifficulty,
    required this.reason,
    required this.confidence,
    required this.adjustmentType,
    required this.performanceFactors,
  });

  String get difficultyLabel {
    if (recommendedDifficulty <= 0.25) return 'Tranquil';
    if (recommendedDifficulty <= 0.5) return 'Balanced';
    if (recommendedDifficulty <= 0.75) return 'Challenging';
    return 'Brain Burner';
  }

  double get changeAmount => recommendedDifficulty - currentDifficulty;
  double get changePercent => (changeAmount / currentDifficulty) * 100.0;
}

/// Real-time difficulty insights
class DifficultyInsights {
  final double performanceScore;
  final double currentDifficulty;
  final double? recommendedDifficulty;
  final String assessment;
  final DateTime lastUpdated;

  const DifficultyInsights({
    required this.performanceScore,
    required this.currentDifficulty,
    this.recommendedDifficulty,
    required this.assessment,
    required this.lastUpdated,
  });

  factory DifficultyInsights.empty() {
    return DifficultyInsights(
      performanceScore: 0.0,
      currentDifficulty: 0.5,
      assessment: 'No data available yet',
      lastUpdated: DateTime.now(),
    );
  }
}

enum AdjustmentType {
  maintain,
  increaseSlightly,
  increaseSignificant,
  decreaseSlightly,
  decreaseSignificant,
}
