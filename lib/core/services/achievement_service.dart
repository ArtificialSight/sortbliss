import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/analytics_logger.dart';

/// Achievement system for tracking player accomplishments
///
/// Categories:
/// - Progression: Level completion milestones
/// - Mastery: Perfect scores, high combos
/// - Collection: Stars, coins collected
/// - Social: Sharing, referrals
/// - Dedication: Daily streaks, total playtime
/// - Special: Hidden achievements
class AchievementService {
  static final AchievementService instance = AchievementService._();
  AchievementService._();

  SharedPreferences? _prefs;

  static const String _keyUnlockedAchievements = 'achievements_unlocked';
  static const String _keyAchievementProgress = 'achievements_progress';
  static const String _keyLastChecked = 'achievements_last_checked';

  /// Initialize achievement service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    AnalyticsLogger.logEvent('achievement_service_initialized', parameters: {
      'unlocked_count': getUnlockedAchievements().length,
      'total_count': getAllAchievements().length,
    });
  }

  /// Get all achievements
  List<Achievement> getAllAchievements() {
    return [
      // ===== PROGRESSION ACHIEVEMENTS =====
      Achievement(
        id: 'first_steps',
        name: 'First Steps',
        description: 'Complete your first level',
        category: AchievementCategory.progression,
        tier: AchievementTier.bronze,
        requirement: 1,
        rewardCoins: 50,
        icon: '🎯',
      ),
      Achievement(
        id: 'getting_started',
        name: 'Getting Started',
        description: 'Complete 10 levels',
        category: AchievementCategory.progression,
        tier: AchievementTier.bronze,
        requirement: 10,
        rewardCoins: 100,
        icon: '🎮',
      ),
      Achievement(
        id: 'dedicated_player',
        name: 'Dedicated Player',
        description: 'Complete 50 levels',
        category: AchievementCategory.progression,
        tier: AchievementTier.silver,
        requirement: 50,
        rewardCoins: 250,
        icon: '🎪',
      ),
      Achievement(
        id: 'veteran',
        name: 'Veteran',
        description: 'Complete 100 levels',
        category: AchievementCategory.progression,
        tier: AchievementTier.gold,
        requirement: 100,
        rewardCoins: 500,
        icon: '🏆',
      ),
      Achievement(
        id: 'master',
        name: 'Master Sorter',
        description: 'Complete 200 levels',
        category: AchievementCategory.progression,
        tier: AchievementTier.platinum,
        requirement: 200,
        rewardCoins: 1000,
        icon: '👑',
      ),

      // ===== MASTERY ACHIEVEMENTS =====
      Achievement(
        id: 'perfectionist',
        name: 'Perfectionist',
        description: 'Complete a level with a perfect score',
        category: AchievementCategory.mastery,
        tier: AchievementTier.bronze,
        requirement: 1,
        rewardCoins: 100,
        icon: '✨',
      ),
      Achievement(
        id: 'three_star_specialist',
        name: 'Three Star Specialist',
        description: 'Earn 3 stars on 10 levels',
        category: AchievementCategory.mastery,
        tier: AchievementTier.silver,
        requirement: 10,
        rewardCoins: 200,
        icon: '⭐',
      ),
      Achievement(
        id: 'combo_starter',
        name: 'Combo Starter',
        description: 'Achieve a 5x combo',
        category: AchievementCategory.mastery,
        tier: AchievementTier.bronze,
        requirement: 5,
        rewardCoins: 75,
        icon: '🔥',
      ),
      Achievement(
        id: 'combo_master',
        name: 'Combo Master',
        description: 'Achieve a 10x combo',
        category: AchievementCategory.mastery,
        tier: AchievementTier.silver,
        requirement: 10,
        rewardCoins: 150,
        icon: '💥',
      ),
      Achievement(
        id: 'combo_legend',
        name: 'Combo Legend',
        description: 'Achieve a 20x combo',
        category: AchievementCategory.mastery,
        tier: AchievementTier.gold,
        requirement: 20,
        rewardCoins: 300,
        icon: '⚡',
      ),
      Achievement(
        id: 'speedrunner',
        name: 'Speedrunner',
        description: 'Complete a level in under 30 seconds',
        category: AchievementCategory.mastery,
        tier: AchievementTier.silver,
        requirement: 1,
        rewardCoins: 150,
        icon: '⏱️',
      ),

      // ===== COLLECTION ACHIEVEMENTS =====
      Achievement(
        id: 'star_collector',
        name: 'Star Collector',
        description: 'Collect 100 stars',
        category: AchievementCategory.collection,
        tier: AchievementTier.bronze,
        requirement: 100,
        rewardCoins: 100,
        icon: '🌟',
      ),
      Achievement(
        id: 'star_hoarder',
        name: 'Star Hoarder',
        description: 'Collect 500 stars',
        category: AchievementCategory.collection,
        tier: AchievementTier.gold,
        requirement: 500,
        rewardCoins: 500,
        icon: '💫',
      ),
      Achievement(
        id: 'coin_collector',
        name: 'Coin Collector',
        description: 'Earn 1,000 coins (lifetime)',
        category: AchievementCategory.collection,
        tier: AchievementTier.bronze,
        requirement: 1000,
        rewardCoins: 100,
        icon: '🪙',
      ),
      Achievement(
        id: 'wealthy',
        name: 'Wealthy',
        description: 'Earn 10,000 coins (lifetime)',
        category: AchievementCategory.collection,
        tier: AchievementTier.platinum,
        requirement: 10000,
        rewardCoins: 1000,
        icon: '💰',
      ),

      // ===== SOCIAL ACHIEVEMENTS =====
      Achievement(
        id: 'first_share',
        name: 'Share the Joy',
        description: 'Share your first score',
        category: AchievementCategory.social,
        tier: AchievementTier.bronze,
        requirement: 1,
        rewardCoins: 50,
        icon: '📤',
      ),
      Achievement(
        id: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Share 10 scores',
        category: AchievementCategory.social,
        tier: AchievementTier.silver,
        requirement: 10,
        rewardCoins: 200,
        icon: '🦋',
      ),
      Achievement(
        id: 'refer_friend',
        name: 'Friend Recruiter',
        description: 'Refer a friend to the game',
        category: AchievementCategory.social,
        tier: AchievementTier.gold,
        requirement: 1,
        rewardCoins: 250,
        icon: '🤝',
      ),

      // ===== DEDICATION ACHIEVEMENTS =====
      Achievement(
        id: 'daily_dedication',
        name: 'Daily Dedication',
        description: 'Play for 7 days in a row',
        category: AchievementCategory.dedication,
        tier: AchievementTier.bronze,
        requirement: 7,
        rewardCoins: 150,
        icon: '📅',
      ),
      Achievement(
        id: 'committed',
        name: 'Committed',
        description: 'Play for 30 days in a row',
        category: AchievementCategory.dedication,
        tier: AchievementTier.gold,
        requirement: 30,
        rewardCoins: 500,
        icon: '🔥',
      ),
      Achievement(
        id: 'marathon_player',
        name: 'Marathon Player',
        description: 'Play for 10 total hours',
        category: AchievementCategory.dedication,
        tier: AchievementTier.silver,
        requirement: 36000, // seconds
        rewardCoins: 300,
        icon: '⏰',
      ),

      // ===== SPECIAL/HIDDEN ACHIEVEMENTS =====
      Achievement(
        id: 'power_user',
        name: 'Power User',
        description: 'Use 50 power-ups',
        category: AchievementCategory.special,
        tier: AchievementTier.silver,
        requirement: 50,
        rewardCoins: 200,
        icon: '⚡',
        isHidden: true,
      ),
      Achievement(
        id: 'no_hints_needed',
        name: 'No Hints Needed',
        description: 'Complete 20 levels without using hints',
        category: AchievementCategory.special,
        tier: AchievementTier.gold,
        requirement: 20,
        rewardCoins: 300,
        icon: '🧠',
        isHidden: true,
      ),
      Achievement(
        id: 'event_master',
        name: 'Event Master',
        description: 'Complete 3 seasonal events',
        category: AchievementCategory.special,
        tier: AchievementTier.platinum,
        requirement: 3,
        rewardCoins: 500,
        icon: '🎉',
        isHidden: true,
      ),
      Achievement(
        id: 'lucky_seven',
        name: 'Lucky Seven',
        description: 'Score exactly 777 points in a level',
        category: AchievementCategory.special,
        tier: AchievementTier.gold,
        requirement: 1,
        rewardCoins: 777,
        icon: '🎰',
        isHidden: true,
      ),
    ];
  }

  /// Get unlocked achievements
  List<String> getUnlockedAchievements() {
    final unlockedJson = _prefs?.getString(_keyUnlockedAchievements);
    if (unlockedJson == null) return [];

    final List<dynamic> unlocked = jsonDecode(unlockedJson);
    return unlocked.cast<String>();
  }

  /// Check if achievement is unlocked
  bool isUnlocked(String achievementId) {
    return getUnlockedAchievements().contains(achievementId);
  }

  /// Get achievement progress
  int getProgress(String achievementId) {
    final progressJson = _prefs?.getString(_keyAchievementProgress);
    if (progressJson == null) return 0;

    final Map<String, dynamic> progress = jsonDecode(progressJson);
    return progress[achievementId] as int? ?? 0;
  }

  /// Update achievement progress
  Future<Achievement?> updateProgress(String achievementId, int progress) async {
    final achievement = getAllAchievements().firstWhere((a) => a.id == achievementId);

    // Already unlocked
    if (isUnlocked(achievementId)) return null;

    // Update progress
    final progressJson = _prefs?.getString(_keyAchievementProgress) ?? '{}';
    final Map<String, dynamic> progressMap = jsonDecode(progressJson);
    progressMap[achievementId] = progress;
    await _prefs?.setString(_keyAchievementProgress, jsonEncode(progressMap));

    // Check if unlocked
    if (progress >= achievement.requirement) {
      return await _unlockAchievement(achievementId);
    }

    return null;
  }

  /// Increment achievement progress
  Future<Achievement?> incrementProgress(String achievementId, [int amount = 1]) async {
    final current = getProgress(achievementId);
    return await updateProgress(achievementId, current + amount);
  }

  /// Unlock achievement
  Future<Achievement> _unlockAchievement(String achievementId) async {
    final achievement = getAllAchievements().firstWhere((a) => a.id == achievementId);

    // Add to unlocked list
    final unlocked = getUnlockedAchievements();
    unlocked.add(achievementId);
    await _prefs?.setString(_keyUnlockedAchievements, jsonEncode(unlocked));

    AnalyticsLogger.logEvent('achievement_unlocked', parameters: {
      'achievement_id': achievementId,
      'name': achievement.name,
      'tier': achievement.tier.toString(),
      'reward_coins': achievement.rewardCoins,
    });

    return achievement;
  }

  /// Get achievement by ID
  Achievement? getAchievement(String achievementId) {
    try {
      return getAllAchievements().firstWhere((a) => a.id == achievementId);
    } catch (e) {
      return null;
    }
  }

  /// Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return getAllAchievements().where((a) => a.category == category).toList();
  }

  /// Get unlocked achievements (full objects)
  List<Achievement> getUnlockedAchievementObjects() {
    final unlockedIds = getUnlockedAchievements();
    return getAllAchievements().where((a) => unlockedIds.contains(a.id)).toList();
  }

  /// Get completion percentage
  double getCompletionPercentage() {
    final total = getAllAchievements().length;
    final unlocked = getUnlockedAchievements().length;
    return total > 0 ? unlocked / total : 0.0;
  }

  /// Get achievements in progress (visible achievements with >0 progress)
  List<AchievementWithProgress> getInProgressAchievements() {
    final unlocked = getUnlockedAchievements();
    final achievements = getAllAchievements()
        .where((a) => !unlocked.contains(a.id) && !a.isHidden)
        .toList();

    final List<AchievementWithProgress> inProgress = [];
    for (final achievement in achievements) {
      final progress = getProgress(achievement.id);
      if (progress > 0) {
        inProgress.add(AchievementWithProgress(
          achievement: achievement,
          progress: progress,
        ));
      }
    }

    return inProgress;
  }

  /// Get total rewards earned
  int getTotalRewardsEarned() {
    final unlocked = getUnlockedAchievementObjects();
    return unlocked.fold(0, (sum, a) => sum + a.rewardCoins);
  }

  /// Get summary
  AchievementSummary getSummary() {
    final total = getAllAchievements().length;
    final unlocked = getUnlockedAchievements().length;

    return AchievementSummary(
      total: total,
      unlocked: unlocked,
      locked: total - unlocked,
      completionPercentage: getCompletionPercentage(),
      totalRewards: getTotalRewardsEarned(),
    );
  }

  /// Check multiple achievements at once (call after level complete, etc.)
  Future<List<Achievement>> checkAchievements({
    int? levelsCompleted,
    int? perfectLevels,
    int? threeStarLevels,
    int? maxCombo,
    int? totalStars,
    int? totalCoins,
    int? sharesCount,
    int? referralsCount,
    int? dailyStreak,
    int? totalPlayTime,
    int? powerUpsUsed,
    int? eventsCompleted,
    int? levelScore,
  }) async {
    final List<Achievement> newlyUnlocked = [];

    // Progression
    if (levelsCompleted != null) {
      final a1 = await updateProgress('first_steps', levelsCompleted);
      final a2 = await updateProgress('getting_started', levelsCompleted);
      final a3 = await updateProgress('dedicated_player', levelsCompleted);
      final a4 = await updateProgress('veteran', levelsCompleted);
      final a5 = await updateProgress('master', levelsCompleted);
      if (a1 != null) newlyUnlocked.add(a1);
      if (a2 != null) newlyUnlocked.add(a2);
      if (a3 != null) newlyUnlocked.add(a3);
      if (a4 != null) newlyUnlocked.add(a4);
      if (a5 != null) newlyUnlocked.add(a5);
    }

    // Mastery
    if (perfectLevels != null) {
      final a = await updateProgress('perfectionist', perfectLevels);
      if (a != null) newlyUnlocked.add(a);
    }

    if (threeStarLevels != null) {
      final a = await updateProgress('three_star_specialist', threeStarLevels);
      if (a != null) newlyUnlocked.add(a);
    }

    if (maxCombo != null) {
      final a1 = await updateProgress('combo_starter', maxCombo);
      final a2 = await updateProgress('combo_master', maxCombo);
      final a3 = await updateProgress('combo_legend', maxCombo);
      if (a1 != null) newlyUnlocked.add(a1);
      if (a2 != null) newlyUnlocked.add(a2);
      if (a3 != null) newlyUnlocked.add(a3);
    }

    // Collection
    if (totalStars != null) {
      final a1 = await updateProgress('star_collector', totalStars);
      final a2 = await updateProgress('star_hoarder', totalStars);
      if (a1 != null) newlyUnlocked.add(a1);
      if (a2 != null) newlyUnlocked.add(a2);
    }

    if (totalCoins != null) {
      final a1 = await updateProgress('coin_collector', totalCoins);
      final a2 = await updateProgress('wealthy', totalCoins);
      if (a1 != null) newlyUnlocked.add(a1);
      if (a2 != null) newlyUnlocked.add(a2);
    }

    // Social
    if (sharesCount != null) {
      final a1 = await updateProgress('first_share', sharesCount);
      final a2 = await updateProgress('social_butterfly', sharesCount);
      if (a1 != null) newlyUnlocked.add(a1);
      if (a2 != null) newlyUnlocked.add(a2);
    }

    if (referralsCount != null) {
      final a = await updateProgress('refer_friend', referralsCount);
      if (a != null) newlyUnlocked.add(a);
    }

    // Dedication
    if (dailyStreak != null) {
      final a1 = await updateProgress('daily_dedication', dailyStreak);
      final a2 = await updateProgress('committed', dailyStreak);
      if (a1 != null) newlyUnlocked.add(a1);
      if (a2 != null) newlyUnlocked.add(a2);
    }

    if (totalPlayTime != null) {
      final a = await updateProgress('marathon_player', totalPlayTime);
      if (a != null) newlyUnlocked.add(a);
    }

    // Special
    if (powerUpsUsed != null) {
      final a = await updateProgress('power_user', powerUpsUsed);
      if (a != null) newlyUnlocked.add(a);
    }

    if (eventsCompleted != null) {
      final a = await updateProgress('event_master', eventsCompleted);
      if (a != null) newlyUnlocked.add(a);
    }

    if (levelScore == 777) {
      final a = await updateProgress('lucky_seven', 1);
      if (a != null) newlyUnlocked.add(a);
    }

    return newlyUnlocked;
  }
}

/// Achievement data class
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementCategory category;
  final AchievementTier tier;
  final int requirement;
  final int rewardCoins;
  final String icon;
  final bool isHidden;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.tier,
    required this.requirement,
    required this.rewardCoins,
    required this.icon,
    this.isHidden = false,
  });
}

/// Achievement category enum
enum AchievementCategory {
  progression,
  mastery,
  collection,
  social,
  dedication,
  special,
}

/// Achievement tier enum
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
}

/// Achievement with progress data class
class AchievementWithProgress {
  final Achievement achievement;
  final int progress;

  AchievementWithProgress({
    required this.achievement,
    required this.progress,
  });

  double get progressPercentage =>
      (progress / achievement.requirement).clamp(0.0, 1.0);
}

/// Achievement summary data class
class AchievementSummary {
  final int total;
  final int unlocked;
  final int locked;
  final double completionPercentage;
  final int totalRewards;

  AchievementSummary({
    required this.total,
    required this.unlocked,
    required this.locked,
    required this.completionPercentage,
    required this.totalRewards,
  });
}
