import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../analytics/analytics_logger.dart';
import '../network/openai_proxy_service.dart';

/// AI-powered smart hint system for puzzle solving assistance.
///
/// Provides contextual, progressive hints that guide players without
/// giving away solutions, using AI to generate natural language guidance
/// tailored to the specific puzzle state and player skill level.
class SmartHintSystem {
  SmartHintSystem._();

  static final SmartHintSystem instance = SmartHintSystem._();

  final Map<String, List<Hint>> _hintCache = {};
  final Map<String, int> _hintUsageCount = {};

  /// Generate a progressive hint for the current puzzle state
  Future<Hint> generateHint({
    required String levelId,
    required PuzzleState puzzleState,
    required HintLevel hintLevel,
    bool useAI = true,
  }) async {
    final cacheKey = '$levelId-${hintLevel.index}';

    // Check cache first
    if (_hintCache.containsKey(cacheKey) && _hintCache[cacheKey]!.isNotEmpty) {
      final hints = _hintCache[cacheKey]!;
      final hint = hints[Random().nextInt(hints.length)];

      AnalyticsLogger.logEvent('hint_generated', parameters: {
        'level_id': levelId,
        'hint_level': hintLevel.name,
        'from_cache': true,
        'items_unsorted': puzzleState.unsortedItems.length,
      });

      _incrementHintUsage(levelId, hintLevel);
      return hint;
    }

    Hint hint;

    if (useAI && hintLevel != HintLevel.basic) {
      // Use AI for medium and advanced hints
      hint = await _generateAIHint(levelId, puzzleState, hintLevel);
    } else {
      // Use template-based hints for basic level
      hint = _generateTemplateHint(puzzleState, hintLevel);
    }

    // Cache the hint
    _hintCache.putIfAbsent(cacheKey, () => []);
    _hintCache[cacheKey]!.add(hint);

    AnalyticsLogger.logEvent('hint_generated', parameters: {
      'level_id': levelId,
      'hint_level': hintLevel.name,
      'from_cache': false,
      'used_ai': useAI && hintLevel != HintLevel.basic,
      'items_unsorted': puzzleState.unsortedItems.length,
    });

    _incrementHintUsage(levelId, hintLevel);
    return hint;
  }

  /// Get hint usage statistics for a level
  HintStatistics getHintStatistics(String levelId) {
    final basicCount = _hintUsageCount['$levelId-${HintLevel.basic.index}'] ?? 0;
    final mediumCount = _hintUsageCount['$levelId-${HintLevel.medium.index}'] ?? 0;
    final advancedCount = _hintUsageCount['$levelId-${HintLevel.advanced.index}'] ?? 0;

    return HintStatistics(
      levelId: levelId,
      basicHintsUsed: basicCount,
      mediumHintsUsed: mediumCount,
      advancedHintsUsed: advancedCount,
      totalHintsUsed: basicCount + mediumCount + advancedCount,
    );
  }

  /// Get recommended hint level based on player performance
  HintLevel getRecommendedHintLevel({
    required int attemptCount,
    required int timeSpentSeconds,
    required double difficultyLevel,
  }) {
    // Progressive hint system based on struggle indicators
    if (attemptCount <= 2 && timeSpentSeconds < 120) {
      return HintLevel.basic;
    } else if (attemptCount <= 5 || timeSpentSeconds < 300) {
      return HintLevel.medium;
    } else {
      return HintLevel.advanced;
    }
  }

  /// Check if player should be offered a hint
  bool shouldOfferHint({
    required int attemptCount,
    required int timeSpentSeconds,
    required int consecutiveFailures,
  }) {
    // Offer hint if:
    // - More than 3 failed attempts
    // - Spent more than 2 minutes without progress
    // - 2+ consecutive failures
    return attemptCount > 3 ||
           timeSpentSeconds > 120 ||
           consecutiveFailures >= 2;
  }

  Future<Hint> _generateAIHint(
    String levelId,
    PuzzleState puzzleState,
    HintLevel hintLevel,
  ) async {
    try {
      final openAIService = OpenAiProxyService.instance;

      final prompt = _buildHintPrompt(puzzleState, hintLevel);
      final systemPrompt = _getHintSystemPrompt(hintLevel);

      final response = await openAIService.generateChatCompletion(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
        temperature: 0.7,
        maxTokens: 150,
      );

      return Hint(
        text: response.trim(),
        level: hintLevel,
        isAIGenerated: true,
      );
    } catch (error) {
      AnalyticsLogger.logEvent('ai_hint_failed', parameters: {
        'error': error.toString(),
        'level_id': levelId,
      });

      // Fallback to template hint
      return _generateTemplateHint(puzzleState, hintLevel);
    }
  }

  String _getHintSystemPrompt(HintLevel level) {
    switch (level) {
      case HintLevel.basic:
        return '''You are a friendly puzzle game assistant providing basic hints.
Give encouraging, general guidance without revealing specific solutions.
Keep hints brief (1-2 sentences) and positive.''';

      case HintLevel.medium:
        return '''You are a puzzle game coach providing strategic hints.
Offer specific strategies and patterns to look for without giving exact solutions.
Keep hints concise (2-3 sentences) and actionable.''';

      case HintLevel.advanced:
        return '''You are a puzzle game expert providing detailed guidance.
Provide step-by-step recommendations and optimal strategies.
Be specific but still let the player execute the solution.
Keep hints helpful (3-4 sentences) and solution-oriented.''';
    }
  }

  String _buildHintPrompt(PuzzleState puzzleState, HintLevel level) {
    final categoryCounts = <String, int>{};
    for (final item in puzzleState.unsortedItems) {
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }

    final categoriesText = categoryCounts.entries
        .map((e) => '${e.value} ${e.key} items')
        .join(', ');

    return '''A player is sorting items in a puzzle game.

Unsorted items remaining: ${puzzleState.unsortedItems.length}
Categories: $categoriesText
Available containers: ${puzzleState.availableContainers.join(', ')}
Moves made: ${puzzleState.moveCount}

Provide a ${level.name} hint to help them progress.''';
  }

  Hint _generateTemplateHint(PuzzleState puzzleState, HintLevel level) {
    final templates = _getTemplatesByLevel(level);
    final template = templates[Random().nextInt(templates.length)];

    // Personalize template with puzzle state
    String hintText = template;

    if (puzzleState.unsortedItems.isNotEmpty) {
      final firstItem = puzzleState.unsortedItems.first;
      hintText = hintText.replaceAll('{item}', firstItem.displayName);
      hintText = hintText.replaceAll('{category}', firstItem.category);
    }

    hintText = hintText.replaceAll('{count}', puzzleState.unsortedItems.length.toString());

    return Hint(
      text: hintText,
      level: level,
      isAIGenerated: false,
    );
  }

  List<String> _getTemplatesByLevel(HintLevel level) {
    switch (level) {
      case HintLevel.basic:
        return [
          'Look for items that clearly belong to a specific category!',
          'Try grouping similar items together first.',
          'Start with the most obvious category matches.',
          'Focus on one container at a time.',
          'Take your time - there\'s no rush!',
        ];

      case HintLevel.medium:
        return [
          'Try sorting the {category} items first - they stand out!',
          'Look for {item} - it clearly belongs in {category}.',
          'You have {count} items left - focus on the largest category.',
          'Consider which container has the most obvious matches.',
          'Sort items that you\'re 100% sure about first.',
        ];

      case HintLevel.advanced:
        return [
          '{item} belongs in the {category} container. Start there!',
          'Optimal strategy: sort {category} items first, then work on the rest.',
          'You can complete this in fewer moves by sorting the largest category first.',
          'Try this sequence: {category} items, then reassess your options.',
          'The fastest solution starts with identifying all {category} items.',
        ];
    }
  }

  void _incrementHintUsage(String levelId, HintLevel level) {
    final key = '$levelId-${level.index}';
    _hintUsageCount[key] = (_hintUsageCount[key] ?? 0) + 1;
  }

  /// Clear hint cache (useful for testing or when puzzle structures change)
  void clearCache() {
    _hintCache.clear();
    AnalyticsLogger.logEvent('hint_cache_cleared');
  }

  /// Clear hint usage statistics
  void clearStatistics() {
    _hintUsageCount.clear();
    AnalyticsLogger.logEvent('hint_statistics_cleared');
  }
}

/// Represents the current state of the puzzle
class PuzzleState {
  final List<PuzzleItem> unsortedItems;
  final List<String> availableContainers;
  final int moveCount;
  final int correctPlacements;

  const PuzzleState({
    required this.unsortedItems,
    required this.availableContainers,
    this.moveCount = 0,
    this.correctPlacements = 0,
  });

  double get completionPercentage {
    final totalItems = correctPlacements + unsortedItems.length;
    return totalItems > 0 ? (correctPlacements / totalItems) * 100.0 : 0.0;
  }
}

/// Represents a puzzle item
class PuzzleItem {
  final String id;
  final String displayName;
  final String category;

  const PuzzleItem({
    required this.id,
    required this.displayName,
    required this.category,
  });
}

/// A generated hint
class Hint {
  final String text;
  final HintLevel level;
  final bool isAIGenerated;
  final DateTime generatedAt;

  Hint({
    required this.text,
    required this.level,
    required this.isAIGenerated,
  }) : generatedAt = DateTime.now();

  String get levelDescription {
    switch (level) {
      case HintLevel.basic:
        return 'General Guidance';
      case HintLevel.medium:
        return 'Strategic Tip';
      case HintLevel.advanced:
        return 'Detailed Solution';
    }
  }
}

/// Progressive hint levels
enum HintLevel {
  basic,    // General encouragement and simple tips
  medium,   // Strategic guidance with some specifics
  advanced, // Detailed step-by-step recommendations
}

/// Hint usage statistics
class HintStatistics {
  final String levelId;
  final int basicHintsUsed;
  final int mediumHintsUsed;
  final int advancedHintsUsed;
  final int totalHintsUsed;

  const HintStatistics({
    required this.levelId,
    required this.basicHintsUsed,
    required this.mediumHintsUsed,
    required this.advancedHintsUsed,
    required this.totalHintsUsed,
  });

  double get averageHintLevel {
    if (totalHintsUsed == 0) return 0.0;

    final weightedSum = (basicHintsUsed * 1) +
                        (mediumHintsUsed * 2) +
                        (advancedHintsUsed * 3);

    return weightedSum / totalHintsUsed;
  }

  bool get hasUsedHints => totalHintsUsed > 0;

  bool get reliesHeavilyOnHints => totalHintsUsed > 5;
}
