import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/analytics_logger.dart';

/// Local leaderboard service (offline, device-only)
///
/// Tracks:
/// - Personal best scores for each level
/// - Daily high scores
/// - Weekly high scores
/// - All-time high scores
/// - Recent achievements
///
/// Note: This is local only. For online leaderboards, integrate Firebase/GameCenter
class LeaderboardService {
  static final LeaderboardService instance = LeaderboardService._();
  LeaderboardService._();

  SharedPreferences? _prefs;

  static const String _keyLevelScores = 'leaderboard_level_scores'; // JSON
  static const String _keyDailyScores = 'leaderboard_daily_scores'; // JSON array
  static const String _keyWeeklyScores = 'leaderboard_weekly_scores'; // JSON array
  static const String _keyAllTimeScores = 'leaderboard_alltime_scores'; // JSON array
  static const String _keyHighScore = 'leaderboard_high_score';
  static const String _keyTotalScore = 'leaderboard_total_score';

  /// Initialize leaderboard service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    AnalyticsLogger.logEvent('leaderboard_service_initialized', parameters: {
      'high_score': getHighScore(),
      'total_score': getTotalScore(),
    });
  }

  // ========== Level Scores ==========

  /// Get best score for level
  int getLevelScore(int level) {
    final scoresJson = _prefs?.getString(_keyLevelScores);
    if (scoresJson == null) return 0;

    final scores = jsonDecode(scoresJson) as Map<String, dynamic>;
    return scores[level.toString()] as int? ?? 0;
  }

  /// Update level score (if better)
  Future<bool> updateLevelScore(int level, int score) async {
    final currentBest = getLevelScore(level);
    if (score <= currentBest) return false;

    final scoresJson = _prefs?.getString(_keyLevelScores) ?? '{}';
    final scores = jsonDecode(scoresJson) as Map<String, dynamic>;
    scores[level.toString()] = score;
    await _prefs?.setString(_keyLevelScores, jsonEncode(scores));

    // Update high score
    if (score > getHighScore()) {
      await _prefs?.setInt(_keyHighScore, score);

      AnalyticsLogger.logEvent('leaderboard_new_high_score', parameters: {
        'score': score,
        'level': level,
      });
    }

    AnalyticsLogger.logEvent('leaderboard_new_level_record', parameters: {
      'level': level,
      'score': score,
      'previous_best': currentBest,
    });

    return true;
  }

  /// Get top N level scores
  List<LeaderboardEntry> getTopLevelScores(int limit) {
    final scoresJson = _prefs?.getString(_keyLevelScores);
    if (scoresJson == null) return [];

    final scores = jsonDecode(scoresJson) as Map<String, dynamic>;
    final entries = scores.entries
        .map((e) => LeaderboardEntry(
              level: int.parse(e.key),
              score: e.value as int,
              timestamp: DateTime.now(), // Not stored, use current
            ))
        .toList();

    entries.sort((a, b) => b.score.compareTo(a.score));
    return entries.take(limit).toList();
  }

  // ========== Daily Scores ==========

  /// Submit score to daily leaderboard
  Future<void> submitDailyScore({
    required int level,
    required int score,
    required int stars,
  }) async {
    final entry = LeaderboardEntry(
      level: level,
      score: score,
      stars: stars,
      timestamp: DateTime.now(),
    );

    await _addScoreToList(_keyDailyScores, entry);
    await _updateTotalScore(score);
    await _cleanOldDailyScores();
  }

  /// Get daily leaderboard (today only)
  List<LeaderboardEntry> getDailyLeaderboard() {
    return _getScoresFromList(_keyDailyScores, filterToday: true);
  }

  /// Get daily rank (1-indexed)
  int getDailyRank(int score) {
    final daily = getDailyLeaderboard();
    return daily.where((e) => e.score > score).length + 1;
  }

  // ========== Weekly Scores ==========

  /// Submit score to weekly leaderboard
  Future<void> submitWeeklyScore({
    required int level,
    required int score,
    required int stars,
  }) async {
    final entry = LeaderboardEntry(
      level: level,
      score: score,
      stars: stars,
      timestamp: DateTime.now(),
    );

    await _addScoreToList(_keyWeeklyScores, entry);
    await _cleanOldWeeklyScores();
  }

  /// Get weekly leaderboard (this week only)
  List<LeaderboardEntry> getWeeklyLeaderboard() {
    return _getScoresFromList(_keyWeeklyScores, filterWeek: true);
  }

  /// Get weekly rank (1-indexed)
  int getWeeklyRank(int score) {
    final weekly = getWeeklyLeaderboard();
    return weekly.where((e) => e.score > score).length + 1;
  }

  // ========== All-Time Scores ==========

  /// Submit score to all-time leaderboard
  Future<void> submitAllTimeScore({
    required int level,
    required int score,
    required int stars,
  }) async {
    final entry = LeaderboardEntry(
      level: level,
      score: score,
      stars: stars,
      timestamp: DateTime.now(),
    );

    await _addScoreToList(_keyAllTimeScores, entry, limit: 100);
  }

  /// Get all-time leaderboard
  List<LeaderboardEntry> getAllTimeLeaderboard({int limit = 50}) {
    final scores = _getScoresFromList(_keyAllTimeScores);
    return scores.take(limit).toList();
  }

  /// Get all-time rank (1-indexed)
  int getAllTimeRank(int score) {
    final allTime = getAllTimeLeaderboard(limit: 999999);
    return allTime.where((e) => e.score > score).length + 1;
  }

  // ========== High Scores ==========

  /// Get highest score ever
  int getHighScore() {
    return _prefs?.getInt(_keyHighScore) ?? 0;
  }

  /// Get total cumulative score
  int getTotalScore() {
    return _prefs?.getInt(_keyTotalScore) ?? 0;
  }

  /// Update total score
  Future<void> _updateTotalScore(int score) async {
    final current = getTotalScore();
    await _prefs?.setInt(_keyTotalScore, current + score);
  }

  // ========== Helper Methods ==========

  /// Add score to list
  Future<void> _addScoreToList(
    String key,
    LeaderboardEntry entry, {
    int limit = 1000,
  }) async {
    final scores = _getScoresFromList(key);
    scores.add(entry);
    scores.sort((a, b) => b.score.compareTo(a.score));

    // Keep only top entries
    final topScores = scores.take(limit).toList();

    final json = topScores.map((e) => e.toJson()).toList();
    await _prefs?.setString(key, jsonEncode(json));
  }

  /// Get scores from list
  List<LeaderboardEntry> _getScoresFromList(
    String key, {
    bool filterToday = false,
    bool filterWeek = false,
  }) {
    final scoresJson = _prefs?.getString(key);
    if (scoresJson == null) return [];

    final scoresList = jsonDecode(scoresJson) as List;
    final entries = scoresList
        .map((json) => LeaderboardEntry.fromJson(json))
        .toList();

    if (filterToday) {
      final today = DateTime.now();
      return entries.where((e) => _isSameDay(e.timestamp, today)).toList();
    }

    if (filterWeek) {
      final now = DateTime.now();
      return entries.where((e) => _isSameWeek(e.timestamp, now)).toList();
    }

    return entries;
  }

  /// Clean old daily scores (keep last 7 days)
  Future<void> _cleanOldDailyScores() async {
    final scores = _getScoresFromList(_keyDailyScores);
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = scores.where((e) => e.timestamp.isAfter(cutoff)).toList();

    final json = recent.map((e) => e.toJson()).toList();
    await _prefs?.setString(_keyDailyScores, jsonEncode(json));
  }

  /// Clean old weekly scores (keep last 4 weeks)
  Future<void> _cleanOldWeeklyScores() async {
    final scores = _getScoresFromList(_keyWeeklyScores);
    final cutoff = DateTime.now().subtract(const Duration(days: 28));
    final recent = scores.where((e) => e.timestamp.isAfter(cutoff)).toList();

    final json = recent.map((e) => e.toJson()).toList();
    await _prefs?.setString(_keyWeeklyScores, jsonEncode(json));
  }

  /// Check if same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if same week
  bool _isSameWeek(DateTime a, DateTime b) {
    final diff = b.difference(a).inDays;
    return diff >= 0 && diff < 7 && a.weekday <= b.weekday;
  }

  /// Get leaderboard summary
  LeaderboardSummary getSummary() {
    return LeaderboardSummary(
      highScore: getHighScore(),
      totalScore: getTotalScore(),
      dailyRank: getDailyRank(getHighScore()),
      weeklyRank: getWeeklyRank(getHighScore()),
      allTimeRank: getAllTimeRank(getHighScore()),
      totalEntries: getAllTimeLeaderboard(limit: 999999).length,
    );
  }
}

/// Leaderboard entry data class
class LeaderboardEntry {
  final int level;
  final int score;
  final int? stars;
  final DateTime timestamp;

  LeaderboardEntry({
    required this.level,
    required this.score,
    this.stars,
    required this.timestamp,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      level: json['level'] as int,
      score: json['score'] as int,
      stars: json['stars'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'score': score,
      if (stars != null) 'stars': stars,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Leaderboard summary data class
class LeaderboardSummary {
  final int highScore;
  final int totalScore;
  final int dailyRank;
  final int weeklyRank;
  final int allTimeRank;
  final int totalEntries;

  LeaderboardSummary({
    required this.highScore,
    required this.totalScore,
    required this.dailyRank,
    required this.weeklyRank,
    required this.allTimeRank,
    required this.totalEntries,
  });
}
