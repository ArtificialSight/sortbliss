import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_logger.dart';
import '../monetization/monetization_manager.dart';

/// Enhanced level progression system with unlocking, difficulty tiers, and milestone rewards
/// Provides structured progression with gating to maintain challenge and increase retention
class LevelProgressionService {
  LevelProgressionService._();
  static final LevelProgressionService instance = LevelProgressionService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  static const String _keyUnlockedLevels = 'unlocked_levels';
  static const String _keyPlayerXP = 'player_xp';
  static const String _keyPlayerLevel = 'player_level';
  static const String _keyLastMilestone = 'last_milestone';
  static const String _keyLevelStars = 'level_stars'; // Map<int, int> as JSON

  // Level unlocking configuration
  static const int _levelsPerTier = 10;
  static const int _starsToUnlockNextTier = 15; // Need 15 stars to unlock next 10 levels

  // XP system configuration
  static const int _xpPerLevel = 100;
  static const int _xpPerStar = 50;
  static const int _xpPerPerfectLevel = 150;

  // Milestone rewards (level -> bonus coins)
  static const Map<int, int> _milestoneRewards = {
    10: 500,
    25: 1000,
    50: 2000,
    75: 3000,
    100: 5000,
    150: 7500,
    200: 10000,
  };

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();

    // Initialize with first tier unlocked
    if (!_prefs.containsKey(_keyUnlockedLevels)) {
      await _unlockInitialLevels();
    }
  }

  /// Unlock first tier of levels (1-10) on first launch
  Future<void> _unlockInitialLevels() async {
    final unlockedLevels = List<int>.generate(_levelsPerTier, (i) => i + 1);
    await _prefs.setStringList(
      _keyUnlockedLevels,
      unlockedLevels.map((l) => l.toString()).toList(),
    );

    AnalyticsLogger.logEvent('level_progression_initialized', parameters: {
      'unlocked_levels': _levelsPerTier,
    });
  }

  /// Check if a level is unlocked
  bool isLevelUnlocked(int level) {
    if (!_initialized) return false;

    final unlockedLevels = _getUnlockedLevels();
    return unlockedLevels.contains(level);
  }

  /// Get all unlocked levels
  List<int> getUnlockedLevels() {
    return _getUnlockedLevels();
  }

  List<int> _getUnlockedLevels() {
    final stored = _prefs.getStringList(_keyUnlockedLevels) ?? [];
    return stored.map((s) => int.tryParse(s) ?? 0).where((l) => l > 0).toList()..sort();
  }

  /// Get highest unlocked level
  int getHighestUnlockedLevel() {
    final unlocked = getUnlockedLevels();
    return unlocked.isEmpty ? 1 : unlocked.last;
  }

  /// Complete a level with star rating (1-3 stars)
  Future<LevelCompletionResult> completeLevel({
    required int level,
    required int starsEarned,
    required int baseScore,
    bool isPerfect = false,
  }) async {
    if (!_initialized) await initialize();

    // Validate stars
    final clampedStars = starsEarned.clamp(1, 3);

    // Update level stars (keep highest)
    await _updateLevelStars(level, clampedStars);

    // Award XP
    int xpEarned = _xpPerLevel;
    xpEarned += (clampedStars * _xpPerStar);
    if (isPerfect) xpEarned += _xpPerPerfectLevel;

    final previousXP = getPlayerXP();
    final newXP = previousXP + xpEarned;
    await _prefs.setInt(_keyPlayerXP, newXP);

    // Check for player level up
    final previousLevel = getPlayerLevel();
    final newLevel = _calculatePlayerLevel(newXP);
    bool leveledUp = newLevel > previousLevel;

    if (leveledUp) {
      await _prefs.setInt(_keyPlayerLevel, newLevel);
      AnalyticsLogger.logEvent('player_level_up', parameters: {
        'new_level': newLevel,
        'xp': newXP,
      });
    }

    // Check for tier unlock
    final tierUnlocked = await _checkTierUnlock();

    // Check for milestone rewards
    final milestoneReward = await _checkMilestoneReward(level);

    // Track analytics
    AnalyticsLogger.logEvent('level_completed', parameters: {
      'level': level,
      'stars': clampedStars,
      'score': baseScore,
      'xp_earned': xpEarned,
      'is_perfect': isPerfect,
      'tier_unlocked': tierUnlocked,
      'milestone_reward': milestoneReward ?? 0,
    });

    return LevelCompletionResult(
      level: level,
      starsEarned: clampedStars,
      xpEarned: xpEarned,
      totalXP: newXP,
      playerLeveledUp: leveledUp,
      newPlayerLevel: newLevel,
      tierUnlocked: tierUnlocked,
      milestoneReward: milestoneReward,
    );
  }

  /// Update level stars (keep highest rating)
  Future<void> _updateLevelStars(int level, int stars) async {
    final levelStarsMap = _getLevelStarsMap();
    final currentStars = levelStarsMap[level] ?? 0;

    if (stars > currentStars) {
      levelStarsMap[level] = stars;
      await _prefs.setString(_keyLevelStars, _encodeLevelStarsMap(levelStarsMap));
    }
  }

  /// Get stars earned for a specific level
  int getLevelStars(int level) {
    final levelStarsMap = _getLevelStarsMap();
    return levelStarsMap[level] ?? 0;
  }

  /// Get total stars across all levels
  int getTotalStars() {
    final levelStarsMap = _getLevelStarsMap();
    return levelStarsMap.values.fold(0, (sum, stars) => sum + stars);
  }

  Map<int, int> _getLevelStarsMap() {
    final stored = _prefs.getString(_keyLevelStars);
    if (stored == null) return {};

    try {
      final decoded = Map<String, dynamic>.from(
        // Parse stored JSON
        stored.split(',').fold<Map<String, dynamic>>({}, (map, entry) {
          final parts = entry.split(':');
          if (parts.length == 2) {
            map[parts[0]] = int.tryParse(parts[1]) ?? 0;
          }
          return map;
        }),
      );

      return decoded.map((key, value) => MapEntry(int.tryParse(key) ?? 0, value as int));
    } catch (e) {
      debugPrint('Error parsing level stars map: $e');
      return {};
    }
  }

  String _encodeLevelStarsMap(Map<int, int> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  /// Check if player has earned enough stars to unlock next tier
  Future<bool> _checkTierUnlock() async {
    final totalStars = getTotalStars();
    final highestUnlocked = getHighestUnlockedLevel();
    final nextTierStart = ((highestUnlocked ~/ _levelsPerTier) + 1) * _levelsPerTier + 1;

    // Calculate required stars for next tier
    final tiersUnlocked = highestUnlocked ~/ _levelsPerTier;
    final requiredStars = (tiersUnlocked + 1) * _starsToUnlockNextTier;

    if (totalStars >= requiredStars && highestUnlocked < 999) {
      // Unlock next tier (10 levels)
      final newUnlockedLevels = List<int>.generate(
        _levelsPerTier,
        (i) => nextTierStart + i,
      );

      final currentlyUnlocked = _getUnlockedLevels();
      currentlyUnlocked.addAll(newUnlockedLevels);

      await _prefs.setStringList(
        _keyUnlockedLevels,
        currentlyUnlocked.map((l) => l.toString()).toList(),
      );

      AnalyticsLogger.logEvent('tier_unlocked', parameters: {
        'tier_start': nextTierStart,
        'total_stars': totalStars,
        'required_stars': requiredStars,
      });

      return true;
    }

    return false;
  }

  /// Check for milestone reward and grant if applicable
  Future<int?> _checkMilestoneReward(int level) async {
    final lastMilestone = _prefs.getInt(_keyLastMilestone) ?? 0;

    // Check if this level is a milestone and hasn't been claimed yet
    if (_milestoneRewards.containsKey(level) && level > lastMilestone) {
      final reward = _milestoneRewards[level]!;

      // Grant coins
      MonetizationManager.instance.addCoins(reward);

      // Save last milestone
      await _prefs.setInt(_keyLastMilestone, level);

      AnalyticsLogger.logEvent('milestone_reward_earned', parameters: {
        'level': level,
        'reward_coins': reward,
      });

      return reward;
    }

    return null;
  }

  /// Get player XP
  int getPlayerXP() {
    return _prefs.getInt(_keyPlayerXP) ?? 0;
  }

  /// Get player level (based on XP)
  int getPlayerLevel() {
    return _prefs.getInt(_keyPlayerLevel) ?? 1;
  }

  /// Calculate player level from XP
  int _calculatePlayerLevel(int xp) {
    // Simple level formula: Level = (XP / 500) + 1
    // Level 1: 0-499 XP
    // Level 2: 500-999 XP
    // Level 3: 1000-1499 XP
    return (xp ~/ 500) + 1;
  }

  /// Get XP progress to next player level (0.0 - 1.0)
  double getXPProgressToNextLevel() {
    final currentXP = getPlayerXP();
    final currentLevel = getPlayerLevel();
    final xpForCurrentLevel = (currentLevel - 1) * 500;
    final xpIntoCurrentLevel = currentXP - xpForCurrentLevel;

    return (xpIntoCurrentLevel / 500).clamp(0.0, 1.0);
  }

  /// Get recommended next level based on performance
  int getRecommendedLevel() {
    final unlockedLevels = getUnlockedLevels();
    if (unlockedLevels.isEmpty) return 1;

    // Find first level with less than 3 stars
    for (final level in unlockedLevels) {
      final stars = getLevelStars(level);
      if (stars < 3) {
        return level;
      }
    }

    // All levels have 3 stars, recommend highest unlocked
    return unlockedLevels.last;
  }

  /// Get difficulty tier for a level
  LevelDifficulty getLevelDifficulty(int level) {
    if (level <= 20) return LevelDifficulty.easy;
    if (level <= 50) return LevelDifficulty.medium;
    if (level <= 100) return LevelDifficulty.hard;
    return LevelDifficulty.expert;
  }

  /// Get stars required to unlock next tier
  int getStarsToUnlockNextTier() {
    final totalStars = getTotalStars();
    final highestUnlocked = getHighestUnlockedLevel();
    final tiersUnlocked = highestUnlocked ~/ _levelsPerTier;
    final requiredStars = (tiersUnlocked + 1) * _starsToUnlockNextTier;

    return (requiredStars - totalStars).clamp(0, requiredStars);
  }

  /// Get next milestone level and reward
  MilestoneInfo? getNextMilestone() {
    final highestUnlocked = getHighestUnlockedLevel();

    for (final entry in _milestoneRewards.entries) {
      if (entry.key > highestUnlocked) {
        return MilestoneInfo(level: entry.key, reward: entry.value);
      }
    }

    return null;
  }

  /// Get progression statistics
  ProgressionStats getProgressionStats() {
    final totalStars = getTotalStars();
    final maxPossibleStars = getHighestUnlockedLevel() * 3;
    final completionRate = maxPossibleStars > 0 ? totalStars / maxPossibleStars : 0.0;

    return ProgressionStats(
      totalStars: totalStars,
      maxPossibleStars: maxPossibleStars,
      completionRate: completionRate,
      playerXP: getPlayerXP(),
      playerLevel: getPlayerLevel(),
      highestUnlockedLevel: getHighestUnlockedLevel(),
      totalUnlockedLevels: getUnlockedLevels().length,
      starsToUnlockNextTier: getStarsToUnlockNextTier(),
      nextMilestone: getNextMilestone(),
    );
  }

  /// Reset progression for testing
  Future<void> resetForTesting() async {
    await _prefs.remove(_keyUnlockedLevels);
    await _prefs.remove(_keyPlayerXP);
    await _prefs.remove(_keyPlayerLevel);
    await _prefs.remove(_keyLastMilestone);
    await _prefs.remove(_keyLevelStars);
    await _unlockInitialLevels();
  }
}

/// Result of level completion
class LevelCompletionResult {
  const LevelCompletionResult({
    required this.level,
    required this.starsEarned,
    required this.xpEarned,
    required this.totalXP,
    required this.playerLeveledUp,
    required this.newPlayerLevel,
    required this.tierUnlocked,
    this.milestoneReward,
  });

  final int level;
  final int starsEarned;
  final int xpEarned;
  final int totalXP;
  final bool playerLeveledUp;
  final int newPlayerLevel;
  final bool tierUnlocked;
  final int? milestoneReward;

  bool get hasSpecialReward => tierUnlocked || milestoneReward != null || playerLeveledUp;
}

/// Level difficulty tiers
enum LevelDifficulty {
  easy,
  medium,
  hard,
  expert;

  String get displayName {
    switch (this) {
      case LevelDifficulty.easy:
        return 'Easy';
      case LevelDifficulty.medium:
        return 'Medium';
      case LevelDifficulty.hard:
        return 'Hard';
      case LevelDifficulty.expert:
        return 'Expert';
    }
  }

  /// Base coin multiplier for difficulty
  double get coinMultiplier {
    switch (this) {
      case LevelDifficulty.easy:
        return 1.0;
      case LevelDifficulty.medium:
        return 1.5;
      case LevelDifficulty.hard:
        return 2.0;
      case LevelDifficulty.expert:
        return 3.0;
    }
  }
}

/// Milestone information
class MilestoneInfo {
  const MilestoneInfo({
    required this.level,
    required this.reward,
  });

  final int level;
  final int reward;
}

/// Progression statistics
class ProgressionStats {
  const ProgressionStats({
    required this.totalStars,
    required this.maxPossibleStars,
    required this.completionRate,
    required this.playerXP,
    required this.playerLevel,
    required this.highestUnlockedLevel,
    required this.totalUnlockedLevels,
    required this.starsToUnlockNextTier,
    this.nextMilestone,
  });

  final int totalStars;
  final int maxPossibleStars;
  final double completionRate;
  final int playerXP;
  final int playerLevel;
  final int highestUnlockedLevel;
  final int totalUnlockedLevels;
  final int starsToUnlockNextTier;
  final MilestoneInfo? nextMilestone;
}
