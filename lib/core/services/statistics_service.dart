import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/analytics_logger.dart';

/// Advanced statistics tracking service
///
/// Tracks:
/// - Gameplay statistics (levels, moves, time)
/// - Performance metrics (accuracy, efficiency, combos)
/// - Achievement progress
/// - Personal records
/// - Session statistics
/// - Trends over time
class StatisticsService {
  static final StatisticsService instance = StatisticsService._();
  StatisticsService._();

  SharedPreferences? _prefs;

  // Keys for persistent storage
  static const String _keyTotalLevelsPlayed = 'stats_total_levels_played';
  static const String _keyTotalLevelsCompleted = 'stats_total_levels_completed';
  static const String _keyTotalMoves = 'stats_total_moves';
  static const String _keyTotalPlayTime = 'stats_total_play_time'; // seconds
  static const String _keyTotalStars = 'stats_total_stars';
  static const String _keyThreeStarLevels = 'stats_three_star_levels';
  static const String _keyTotalCoinsEarned = 'stats_total_coins_earned';
  static const String _keyTotalCoinsSpent = 'stats_total_coins_spent';
  static const String _keyHighestCombo = 'stats_highest_combo';
  static const String _keyTotalCombos = 'stats_total_combos';
  static const String _keyPerfectLevels = 'stats_perfect_levels';
  static const String _keyPowerUpsUsed = 'stats_powerups_used';
  static const String _keyHintsUsed = 'stats_hints_used';
  static const String _keyUndosUsed = 'stats_undos_used';
  static const String _keyDailyStreakBest = 'stats_daily_streak_best';
  static const String _keyLevelRecords = 'stats_level_records'; // JSON map

  // Session statistics (reset on app restart)
  int _sessionLevelsCompleted = 0;
  int _sessionStars = 0;
  int _sessionCoins = 0;
  DateTime? _sessionStartTime;

  /// Initialize statistics service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _sessionStartTime = DateTime.now();

    AnalyticsLogger.logEvent('statistics_service_initialized', parameters: {
      'total_levels': getTotalLevelsPlayed(),
      'total_play_time_hours': getTotalPlayTime() / 3600,
    });
  }

  // ========== Gameplay Statistics ==========

  /// Get total levels played
  int getTotalLevelsPlayed() {
    return _prefs?.getInt(_keyTotalLevelsPlayed) ?? 0;
  }

  /// Get total levels completed
  int getTotalLevelsCompleted() {
    return _prefs?.getInt(_keyTotalLevelsCompleted) ?? 0;
  }

  /// Get total moves made
  int getTotalMoves() {
    return _prefs?.getInt(_keyTotalMoves) ?? 0;
  }

  /// Get total play time (seconds)
  int getTotalPlayTime() {
    return _prefs?.getInt(_keyTotalPlayTime) ?? 0;
  }

  /// Get total stars earned
  int getTotalStars() {
    return _prefs?.getInt(_keyTotalStars) ?? 0;
  }

  /// Get three-star levels count
  int getThreeStarLevels() {
    return _prefs?.getInt(_keyThreeStarLevels) ?? 0;
  }

  /// Get total coins earned
  int getTotalCoinsEarned() {
    return _prefs?.getInt(_keyTotalCoinsEarned) ?? 0;
  }

  /// Get total coins spent
  int getTotalCoinsSpent() {
    return _prefs?.getInt(_keyTotalCoinsSpent) ?? 0;
  }

  // ========== Performance Metrics ==========

  /// Get highest combo achieved
  int getHighestCombo() {
    return _prefs?.getInt(_keyHighestCombo) ?? 0;
  }

  /// Get total combos achieved
  int getTotalCombos() {
    return _prefs?.getInt(_keyTotalCombos) ?? 0;
  }

  /// Get perfect levels count (completed with minimum moves)
  int getPerfectLevels() {
    return _prefs?.getInt(_keyPerfectLevels) ?? 0;
  }

  /// Get power-ups used count
  int getPowerUpsUsed() {
    return _prefs?.getInt(_keyPowerUpsUsed) ?? 0;
  }

  /// Get hints used count
  int getHintsUsed() {
    return _prefs?.getInt(_keyHintsUsed) ?? 0;
  }

  /// Get undos used count
  int getUndosUsed() {
    return _prefs?.getInt(_keyUndosUsed) ?? 0;
  }

  /// Get best daily streak
  int getBestDailyStreak() {
    return _prefs?.getInt(_keyDailyStreakBest) ?? 0;
  }

  // ========== Calculated Metrics ==========

  /// Get completion rate (0.0 to 1.0)
  double getCompletionRate() {
    final played = getTotalLevelsPlayed();
    if (played == 0) return 0.0;
    return getTotalLevelsCompleted() / played;
  }

  /// Get average stars per level
  double getAverageStars() {
    final completed = getTotalLevelsCompleted();
    if (completed == 0) return 0.0;
    return getTotalStars() / completed;
  }

  /// Get average moves per level
  double getAverageMoves() {
    final completed = getTotalLevelsCompleted();
    if (completed == 0) return 0.0;
    return getTotalMoves() / completed;
  }

  /// Get average play time per level (seconds)
  double getAveragePlayTime() {
    final completed = getTotalLevelsCompleted();
    if (completed == 0) return 0.0;
    return getTotalPlayTime() / completed;
  }

  /// Get efficiency score (0-100)
  /// Based on: star rate, completion rate, perfect levels
  int getEfficiencyScore() {
    final starRate = getAverageStars() / 3.0; // 0-1
    final completionRate = getCompletionRate(); // 0-1
    final perfectRate = getPerfectLevels() / getTotalLevelsCompleted().clamp(1, 999999); // 0-1

    final score = (starRate * 0.5 + completionRate * 0.3 + perfectRate * 0.2) * 100;
    return score.round().clamp(0, 100);
  }

  // ========== Record Level Statistics ==========

  /// Record level played
  Future<void> recordLevelPlayed(int level) async {
    final current = getTotalLevelsPlayed();
    await _prefs?.setInt(_keyTotalLevelsPlayed, current + 1);

    AnalyticsLogger.logEvent('stats_level_played', parameters: {
      'level': level,
    });
  }

  /// Record level completed
  Future<void> recordLevelCompleted({
    required int level,
    required int stars,
    required int moves,
    required int playTimeSeconds,
    required int coinsEarned,
    required int combo,
    required bool isPerfect,
  }) async {
    // Update totals
    await _prefs?.setInt(_keyTotalLevelsCompleted, getTotalLevelsCompleted() + 1);
    await _prefs?.setInt(_keyTotalStars, getTotalStars() + stars);
    await _prefs?.setInt(_keyTotalMoves, getTotalMoves() + moves);
    await _prefs?.setInt(_keyTotalPlayTime, getTotalPlayTime() + playTimeSeconds);
    await _prefs?.setInt(_keyTotalCoinsEarned, getTotalCoinsEarned() + coinsEarned);

    // Update three-star count
    if (stars == 3) {
      await _prefs?.setInt(_keyThreeStarLevels, getThreeStarLevels() + 1);
    }

    // Update perfect levels
    if (isPerfect) {
      await _prefs?.setInt(_keyPerfectLevels, getPerfectLevels() + 1);
    }

    // Update highest combo
    if (combo > getHighestCombo()) {
      await _prefs?.setInt(_keyHighestCombo, combo);
    }

    // Update level record
    await _updateLevelRecord(level, stars, moves, playTimeSeconds);

    // Update session stats
    _sessionLevelsCompleted++;
    _sessionStars += stars;
    _sessionCoins += coinsEarned;

    AnalyticsLogger.logEvent('stats_level_completed', parameters: {
      'level': level,
      'stars': stars,
      'moves': moves,
      'play_time': playTimeSeconds,
      'combo': combo,
      'is_perfect': isPerfect,
    });
  }

  /// Record combo achieved
  Future<void> recordCombo(int combo) async {
    await _prefs?.setInt(_keyTotalCombos, getTotalCombos() + 1);

    if (combo > getHighestCombo()) {
      await _prefs?.setInt(_keyHighestCombo, combo);
    }
  }

  /// Record power-up used
  Future<void> recordPowerUpUsed(String powerUpType) async {
    await _prefs?.setInt(_keyPowerUpsUsed, getPowerUpsUsed() + 1);

    switch (powerUpType) {
      case 'hint':
        await _prefs?.setInt(_keyHintsUsed, getHintsUsed() + 1);
        break;
      case 'undo':
        await _prefs?.setInt(_keyUndosUsed, getUndosUsed() + 1);
        break;
    }

    AnalyticsLogger.logEvent('stats_powerup_used', parameters: {
      'type': powerUpType,
    });
  }

  /// Record coins spent
  Future<void> recordCoinsSpent(int amount) async {
    await _prefs?.setInt(_keyTotalCoinsSpent, getTotalCoinsSpent() + amount);
  }

  /// Update best daily streak
  Future<void> updateBestDailyStreak(int streak) async {
    if (streak > getBestDailyStreak()) {
      await _prefs?.setInt(_keyDailyStreakBest, streak);

      AnalyticsLogger.logEvent('stats_new_streak_record', parameters: {
        'streak': streak,
      });
    }
  }

  // ========== Level Records ==========

  /// Get level record (best performance for level)
  LevelRecord? getLevelRecord(int level) {
    final recordsJson = _prefs?.getString(_keyLevelRecords);
    if (recordsJson == null) return null;

    final records = jsonDecode(recordsJson) as Map<String, dynamic>;
    final levelKey = level.toString();
    if (!records.containsKey(levelKey)) return null;

    return LevelRecord.fromJson(records[levelKey]);
  }

  /// Update level record (if better than previous)
  Future<void> _updateLevelRecord(
    int level,
    int stars,
    int moves,
    int playTimeSeconds,
  ) async {
    final existing = getLevelRecord(level);
    final isNewRecord = existing == null ||
        stars > existing.stars ||
        (stars == existing.stars && moves < existing.moves);

    if (isNewRecord) {
      final recordsJson = _prefs?.getString(_keyLevelRecords) ?? '{}';
      final records = jsonDecode(recordsJson) as Map<String, dynamic>;

      records[level.toString()] = {
        'stars': stars,
        'moves': moves,
        'playTime': playTimeSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs?.setString(_keyLevelRecords, jsonEncode(records));

      AnalyticsLogger.logEvent('stats_new_level_record', parameters: {
        'level': level,
        'stars': stars,
        'moves': moves,
      });
    }
  }

  // ========== Session Statistics ==========

  /// Get session statistics
  SessionStatistics getSessionStatistics() {
    final sessionDuration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;

    return SessionStatistics(
      levelsCompleted: _sessionLevelsCompleted,
      starsEarned: _sessionStars,
      coinsEarned: _sessionCoins,
      durationSeconds: sessionDuration,
    );
  }

  /// Reset session statistics
  void resetSessionStatistics() {
    _sessionLevelsCompleted = 0;
    _sessionStars = 0;
    _sessionCoins = 0;
    _sessionStartTime = DateTime.now();
  }

  // ========== Export Statistics ==========

  /// Get all statistics as map
  Map<String, dynamic> getAllStatistics() {
    return {
      'gameplay': {
        'total_levels_played': getTotalLevelsPlayed(),
        'total_levels_completed': getTotalLevelsCompleted(),
        'total_moves': getTotalMoves(),
        'total_play_time': getTotalPlayTime(),
        'total_stars': getTotalStars(),
        'three_star_levels': getThreeStarLevels(),
        'total_coins_earned': getTotalCoinsEarned(),
        'total_coins_spent': getTotalCoinsSpent(),
      },
      'performance': {
        'highest_combo': getHighestCombo(),
        'total_combos': getTotalCombos(),
        'perfect_levels': getPerfectLevels(),
        'powerups_used': getPowerUpsUsed(),
        'hints_used': getHintsUsed(),
        'undos_used': getUndosUsed(),
        'best_daily_streak': getBestDailyStreak(),
      },
      'calculated': {
        'completion_rate': getCompletionRate(),
        'average_stars': getAverageStars(),
        'average_moves': getAverageMoves(),
        'average_play_time': getAveragePlayTime(),
        'efficiency_score': getEfficiencyScore(),
      },
      'session': getSessionStatistics().toJson(),
    };
  }
}

/// Level record data class
class LevelRecord {
  final int stars;
  final int moves;
  final int playTime;
  final DateTime timestamp;

  LevelRecord({
    required this.stars,
    required this.moves,
    required this.playTime,
    required this.timestamp,
  });

  factory LevelRecord.fromJson(Map<String, dynamic> json) {
    return LevelRecord(
      stars: json['stars'] as int,
      moves: json['moves'] as int,
      playTime: json['playTime'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stars': stars,
      'moves': moves,
      'playTime': playTime,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Session statistics data class
class SessionStatistics {
  final int levelsCompleted;
  final int starsEarned;
  final int coinsEarned;
  final int durationSeconds;

  SessionStatistics({
    required this.levelsCompleted,
    required this.starsEarned,
    required this.coinsEarned,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'levels_completed': levelsCompleted,
      'stars_earned': starsEarned,
      'coins_earned': coinsEarned,
      'duration_seconds': durationSeconds,
    };
  }
}
