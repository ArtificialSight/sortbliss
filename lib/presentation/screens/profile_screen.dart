import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/statistics_service.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/powerup_service.dart';
import '../../core/services/social_share_service.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/theme/app_theme.dart';

/// Comprehensive player profile screen
///
/// Features:
/// - Player avatar and info
/// - Level progress with XP bar
/// - Key statistics cards
/// - Achievement showcase (recent + progress)
/// - Power-ups inventory
/// - Social stats (referrals, shares)
/// - Settings access
/// - Share profile button
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StatisticsService _stats = StatisticsService.instance;
  final AchievementService _achievements = AchievementService.instance;
  final PowerUpService _powerUps = PowerUpService.instance;
  final SocialShareService _social = SocialShareService.instance;
  final LeaderboardService _leaderboard = LeaderboardService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar with gradient
            _buildAppBar(),

            // Content
            SliverPadding(
              padding: EdgeInsets.all(4.w),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Player card with avatar and level
                  _buildPlayerCard(),

                  SizedBox(height: 3.h),

                  // Statistics grid
                  Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),

                  SizedBox(height: 2.h),

                  _buildStatisticsGrid(),

                  SizedBox(height: 3.h),

                  // Achievements section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/achievements');
                        },
                        child: Text('View All'),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),

                  _buildRecentAchievements(),

                  SizedBox(height: 3.h),

                  // Power-ups inventory
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Power-Ups',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/powerups');
                        },
                        child: Text('Shop'),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),

                  _buildPowerUpsInventory(),

                  SizedBox(height: 3.h),

                  // Social stats
                  Text(
                    'Social',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),

                  SizedBox(height: 2.h),

                  _buildSocialStats(),

                  SizedBox(height: 3.h),

                  // Share profile button
                  _buildShareProfileButton(),

                  SizedBox(height: 2.h),

                  // Settings button
                  _buildSettingsButton(),

                  SizedBox(height: 4.h),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 20.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightTheme.primaryColor,
                Colors.purple.shade600,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard() {
    final levelsCompleted = _stats.getTotalLevelsCompleted();
    final totalStars = _stats.getTotalStars();
    final highScore = _leaderboard.getHighScore();

    // Calculate level and XP (level = levels completed / 10, XP = remainder)
    final level = (levelsCompleted / 10).floor() + 1;
    final currentXP = levelsCompleted % 10;
    final xpForNextLevel = 10;
    final xpProgress = currentXP / xpForNextLevel;

    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar and info
          Row(
            children: [
              // Avatar with level badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 10.w,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Icon(Icons.person, size: 12.w, color: Colors.white),
                  ),
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(3.w),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        'Lv $level',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(width: 4.w),

              // Name and title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player', // TODO: Get from user service
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Sort Master', // TODO: Get title based on achievements
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.9),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // High score badge
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 6.w),
                    SizedBox(height: 0.5.h),
                    Text(
                      highScore.toString(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Best',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // XP progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level Progress',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '$currentXP / $xpForNextLevel XP',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(2.w),
                child: LinearProgressIndicator(
                  value: xpProgress,
                  minHeight: 2.h,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat('⭐', totalStars.toString(), 'Stars'),
              _buildQuickStat(
                '🏆',
                '${_achievements.getSummary().unlocked}',
                'Achievements',
              ),
              _buildQuickStat(
                '🎯',
                '${_stats.getPerfectLevels()}',
                'Perfect',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 5.w)),
            SizedBox(width: 1.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    final stats = _stats.getLifetimeStatistics();
    final efficiency = _stats.getEfficiencyScore();
    final averageStars = _stats.getAverageStarsPerLevel();
    final playTime = _stats.getTotalPlayTime();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 3.w,
      crossAxisSpacing: 3.w,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Levels',
          stats.totalLevelsCompleted.toString(),
          Icons.grid_view,
          Colors.blue,
        ),
        _buildStatCard(
          'Efficiency',
          '${efficiency.toStringAsFixed(1)}%',
          Icons.speed,
          Colors.green,
        ),
        _buildStatCard(
          'Avg Stars',
          averageStars.toStringAsFixed(2),
          Icons.star,
          Colors.amber,
        ),
        _buildStatCard(
          'Play Time',
          _formatPlayTime(playTime),
          Icons.access_time,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements() {
    final achievements = _achievements.getAllAchievements();
    final unlocked = achievements.where((a) => a.isUnlocked).toList();
    final inProgress = achievements.where((a) => !a.isUnlocked).toList();

    // Show 3 most recent unlocked + 3 closest to unlock
    final recent = unlocked.take(3).toList();
    final upcoming = inProgress.take(3).toList();
    final displayList = [...recent, ...upcoming].take(6).toList();

    if (displayList.isEmpty) {
      return _buildEmptyState(
        'No achievements yet',
        'Start playing to unlock achievements!',
        Icons.emoji_events,
      );
    }

    return SizedBox(
      height: 20.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayList.length,
        separatorBuilder: (context, index) => SizedBox(width: 3.w),
        itemBuilder: (context, index) {
          final achievement = displayList[index];
          return _buildAchievementCard(achievement);
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      width: 35.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isUnlocked
            ? _getTierColor(achievement.tier).withOpacity(0.1)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: isUnlocked
              ? _getTierColor(achievement.tier)
              : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? _getTierColor(achievement.tier).withOpacity(0.2)
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 8.w,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
          ),

          SizedBox(height: 1.h),

          // Name
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.grey[900] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 0.5.h),

          // Progress or tier
          if (isUnlocked)
            Text(
              _getTierName(achievement.tier),
              style: TextStyle(
                fontSize: 10.sp,
                color: _getTierColor(achievement.tier),
                fontWeight: FontWeight.w600,
              ),
            )
          else if (achievement.currentProgress != null &&
              achievement.targetValue != null)
            Text(
              '${achievement.currentProgress}/${achievement.targetValue}',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPowerUpsInventory() {
    final inventory = _powerUps.getInventory();

    return Row(
      children: [
        Expanded(
          child: _buildPowerUpItem('Undo', inventory['undo'] ?? 0, '↩️'),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildPowerUpItem('Hint', inventory['hint'] ?? 0, '💡'),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildPowerUpItem('Shuffle', inventory['shuffle'] ?? 0, '🔀'),
        ),
      ],
    );
  }

  Widget _buildPowerUpItem(String name, int count, String emoji) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 6.w)),
          SizedBox(height: 1.h),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            name,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialStats() {
    final socialStats = _social.getSocialStatistics();

    return Row(
      children: [
        Expanded(
          child: _buildSocialStatCard(
            'Shares',
            socialStats.totalShares.toString(),
            Icons.share,
            Colors.blue,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildSocialStatCard(
            'Referrals',
            socialStats.totalReferrals.toString(),
            Icons.group_add,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareProfileButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton.icon(
        onPressed: () async {
          final stats = _stats.getLifetimeStatistics();
          await _social.shareProfile(
            context: context,
            level: (stats.totalLevelsCompleted / 10).floor() + 1,
            totalStars: stats.totalStars,
            achievementCount: _achievements.getSummary().unlocked,
          );
        },
        icon: Icon(Icons.share, size: 5.w),
        label: Text(
          'Share Profile',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).pushNamed('/settings');
        },
        icon: Icon(Icons.settings, size: 5.w),
        label: Text(
          'Settings',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.lightTheme.primaryColor,
          side: BorderSide(color: AppTheme.lightTheme.primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15.w, color: Colors.grey.shade400),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatPlayTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).floor()}m';
    return '${(seconds / 3600).floor()}h';
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Colors.brown;
      case AchievementTier.silver:
        return Colors.grey.shade600;
      case AchievementTier.gold:
        return Colors.amber;
      case AchievementTier.platinum:
        return Colors.blue.shade700;
    }
  }

  String _getTierName(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
    }
  }
}
