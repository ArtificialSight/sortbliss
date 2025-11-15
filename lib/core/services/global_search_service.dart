import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sortbliss/core/services/player_profile_service.dart';
import 'package:sortbliss/core/services/achievements_tracker_service.dart';
import '../analytics/analytics_logger.dart';

/// Global search service for finding levels, achievements, settings, and content.
///
/// Provides unified search across all game content with fuzzy matching,
/// category filtering, and search history for improved accessibility and UX.
class GlobalSearchService {
  GlobalSearchService._();

  static final GlobalSearchService instance = GlobalSearchService._();

  final List<String> _searchHistory = [];
  static const int _maxHistorySize = 20;

  /// Search across all searchable content
  Future<SearchResults> search(String query, {
    Set<SearchCategory>? categories,
    int maxResults = 50,
  }) async {
    if (query.trim().isEmpty) {
      return SearchResults.empty();
    }

    final normalizedQuery = query.trim().toLowerCase();
    final searchCategories = categories ?? SearchCategory.values.toSet();

    final results = <SearchResult>[];

    // Search levels
    if (searchCategories.contains(SearchCategory.levels)) {
      results.addAll(await _searchLevels(normalizedQuery));
    }

    // Search achievements
    if (searchCategories.contains(SearchCategory.achievements)) {
      results.addAll(await _searchAchievements(normalizedQuery));
    }

    // Search settings
    if (searchCategories.contains(SearchCategory.settings)) {
      results.addAll(_searchSettings(normalizedQuery));
    }

    // Search help topics
    if (searchCategories.contains(SearchCategory.help)) {
      results.addAll(_searchHelp(normalizedQuery));
    }

    // Sort by relevance
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    // Limit results
    final limitedResults = results.take(maxResults).toList();

    // Track search
    _addToHistory(query);
    AnalyticsLogger.logEvent('search_performed', parameters: {
      'query': query,
      'results_count': limitedResults.length,
      'categories': searchCategories.map((c) => c.name).join(','),
    });

    return SearchResults(
      query: query,
      results: limitedResults,
      totalCount: results.length,
      categories: searchCategories,
    );
  }

  /// Get search suggestions based on partial query
  Future<List<String>> getSuggestions(String partialQuery) async {
    if (partialQuery.trim().isEmpty) {
      return _searchHistory.take(5).toList();
    }

    final normalized = partialQuery.trim().toLowerCase();
    final suggestions = <String>[];

    // Add from history
    suggestions.addAll(
      _searchHistory.where((h) => h.toLowerCase().contains(normalized)).take(3),
    );

    // Add popular searches
    final popularSearches = [
      'level ${PlayerProfileService.instance.currentProfile.currentLevel}',
      'achievements',
      'settings',
      'daily challenge',
      'coins',
      'difficulty',
      'sound',
      'help',
    ];

    suggestions.addAll(
      popularSearches.where((s) => s.contains(normalized)).take(5),
    );

    return suggestions.toSet().toList();
  }

  /// Get search history
  List<String> getSearchHistory() {
    return List.unmodifiable(_searchHistory);
  }

  /// Clear search history
  void clearHistory() {
    _searchHistory.clear();
    AnalyticsLogger.logEvent('search_history_cleared');
  }

  Future<List<SearchResult>> _searchLevels(String query) async {
    final results = <SearchResult>[];
    final profile = PlayerProfileService.instance.currentProfile;

    // Search by level number
    final levelNumber = int.tryParse(query);
    if (levelNumber != null) {
      results.add(SearchResult(
        id: 'level_$levelNumber',
        title: 'Level $levelNumber',
        description: levelNumber <= profile.levelsCompleted
            ? 'Completed'
            : levelNumber == profile.currentLevel
                ? 'Current Level'
                : 'Locked',
        category: SearchCategory.levels,
        relevanceScore: 1.0,
        action: SearchAction.navigateToLevel(levelNumber),
      ));
    }

    // Search by status keywords
    if (query.contains('current')) {
      results.add(SearchResult(
        id: 'current_level',
        title: 'Current Level ${profile.currentLevel}',
        description: 'Continue your progress',
        category: SearchCategory.levels,
        relevanceScore: 0.9,
        action: SearchAction.navigateToLevel(profile.currentLevel),
      ));
    }

    if (query.contains('completed') || query.contains('done')) {
      results.add(SearchResult(
        id: 'completed_levels',
        title: 'Completed Levels',
        description: '${profile.levelsCompleted} levels completed',
        category: SearchCategory.levels,
        relevanceScore: 0.8,
        action: SearchAction.navigateTo('/level-select?filter=completed'),
      ));
    }

    return results;
  }

  Future<List<SearchResult>> _searchAchievements(String query) async {
    final results = <SearchResult>[];
    final profile = PlayerProfileService.instance.currentProfile;
    final tracked = AchievementsTrackerService.instance.trackedIds;

    // Predefined achievements
    final allAchievements = [
      'Speed Demon',
      'Perfectionist',
      'Marathon Runner',
      'Combo Master',
      'Social Butterfly',
      'Sound Maestro',
      'Coin Collector',
      'Streak Master',
    ];

    for (final achievement in allAchievements) {
      if (achievement.toLowerCase().contains(query) ||
          query.contains(achievement.toLowerCase())) {
        final isUnlocked = profile.unlockedAchievements.contains(achievement);
        final isTracked = tracked.contains(achievement);

        results.add(SearchResult(
          id: 'achievement_$achievement',
          title: achievement,
          description: isUnlocked
              ? 'Unlocked'
              : isTracked
                  ? 'Tracked - In Progress'
                  : 'Not yet unlocked',
          category: SearchCategory.achievements,
          relevanceScore: _calculateRelevance(achievement.toLowerCase(), query),
          action: SearchAction.navigateTo('/achievements?highlight=$achievement'),
        ));
      }
    }

    return results;
  }

  List<SearchResult> _searchSettings(String query) {
    final results = <SearchResult>[];

    final settingsMap = {
      'sound': 'Sound Settings',
      'music': 'Music Settings',
      'audio': 'Audio Settings',
      'haptic': 'Haptic Feedback',
      'vibration': 'Vibration Settings',
      'notification': 'Notification Settings',
      'difficulty': 'Difficulty Settings',
      'voice': 'Voice Commands',
      'accessibility': 'Accessibility Options',
    };

    settingsMap.forEach((keyword, title) {
      if (keyword.contains(query) || query.contains(keyword)) {
        results.add(SearchResult(
          id: 'setting_$keyword',
          title: title,
          description: 'Adjust your preferences',
          category: SearchCategory.settings,
          relevanceScore: _calculateRelevance(keyword, query),
          action: SearchAction.navigateTo('/settings?section=$keyword'),
        ));
      }
    });

    return results;
  }

  List<SearchResult> _searchHelp(String query) {
    final results = <SearchResult>[];

    final helpTopics = {
      'how to play': 'How to Play',
      'tutorial': 'Game Tutorial',
      'coins': 'About Coins',
      'achievements': 'Achievement Guide',
      'daily challenge': 'Daily Challenge Info',
      'share': 'Sharing Progress',
      'purchase': 'In-App Purchases',
      'remove ads': 'Remove Ads',
      'restore': 'Restore Purchases',
      'support': 'Customer Support',
      'privacy': 'Privacy Policy',
      'terms': 'Terms of Service',
    };

    helpTopics.forEach((keyword, title) {
      if (keyword.contains(query) || query.contains(keyword) ||
          title.toLowerCase().contains(query)) {
        results.add(SearchResult(
          id: 'help_${keyword.replaceAll(' ', '_')}',
          title: title,
          description: 'Learn more',
          category: SearchCategory.help,
          relevanceScore: _calculateRelevance(keyword, query),
          action: SearchAction.navigateTo('/help?topic=$keyword'),
        ));
      }
    });

    return results;
  }

  double _calculateRelevance(String text, String query) {
    text = text.toLowerCase();
    query = query.toLowerCase();

    // Exact match
    if (text == query) return 1.0;

    // Starts with query
    if (text.startsWith(query)) return 0.9;

    // Contains query
    if (text.contains(query)) return 0.7;

    // Fuzzy match (common substring ratio)
    final commonLength = _longestCommonSubstring(text, query);
    return (commonLength / query.length) * 0.6;
  }

  int _longestCommonSubstring(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0;

    int maxLength = 0;
    final table = List.generate(
      s1.length + 1,
      (_) => List.filled(s2.length + 1, 0),
    );

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          table[i][j] = table[i - 1][j - 1] + 1;
          maxLength = maxLength > table[i][j] ? maxLength : table[i][j];
        }
      }
    }

    return maxLength;
  }

  void _addToHistory(String query) {
    // Remove if already exists
    _searchHistory.remove(query);

    // Add to front
    _searchHistory.insert(0, query);

    // Limit size
    if (_searchHistory.length > _maxHistorySize) {
      _searchHistory.removeRange(_maxHistorySize, _searchHistory.length);
    }
  }
}

/// Search results container
class SearchResults {
  final String query;
  final List<SearchResult> results;
  final int totalCount;
  final Set<SearchCategory> categories;

  const SearchResults({
    required this.query,
    required this.results,
    required this.totalCount,
    required this.categories,
  });

  factory SearchResults.empty() {
    return const SearchResults(
      query: '',
      results: [],
      totalCount: 0,
      categories: {},
    );
  }

  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;

  List<SearchResult> byCategory(SearchCategory category) {
    return results.where((r) => r.category == category).toList();
  }
}

/// Individual search result
class SearchResult {
  final String id;
  final String title;
  final String description;
  final SearchCategory category;
  final double relevanceScore;
  final SearchAction action;

  const SearchResult({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.relevanceScore,
    required this.action,
  });
}

/// Search categories
enum SearchCategory {
  levels,
  achievements,
  settings,
  help,
}

/// Action to take when result is selected
class SearchAction {
  final String type;
  final Map<String, dynamic> params;

  const SearchAction._(this.type, this.params);

  factory SearchAction.navigateTo(String route) {
    return SearchAction._('navigate', {'route': route});
  }

  factory SearchAction.navigateToLevel(int levelNumber) {
    return SearchAction._('navigate_level', {'level': levelNumber});
  }

  factory SearchAction.custom(String actionType, Map<String, dynamic> params) {
    return SearchAction._(actionType, params);
  }
}
