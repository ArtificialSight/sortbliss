import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/statistics_service.dart';
import '../../core/services/achievement_service.dart';
import '../../core/theme/app_theme.dart';

/// Statistics screen showing player stats and achievements
///
/// Displays:
/// - Overview cards (levels, stars, coins)
/// - Performance metrics (efficiency score, combos)
/// - Session statistics
/// - Achievement progress
/// - Level records
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  final StatisticsService _stats = StatisticsService.instance;
  final AchievementService _achievements = AchievementService.instance;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Performance'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPerformanceTab(),
          _buildAchievementsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 3.w,
            crossAxisSpacing: 3.w,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                'Levels Played',
                _stats.getTotalLevelsPlayed().toString(),
                Icons.play_circle_outline,
                Colors.blue,
              ),
              _buildStatCard(
                'Levels Completed',
                _stats.getTotalLevelsCompleted().toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
              _buildStatCard(
                'Total Stars',
                _stats.getTotalStars().toString(),
                Icons.star,
                Colors.amber,
              ),
              _buildStatCard(
                'Coins Earned',
                _stats.getTotalCoinsEarned().toString(),
                Icons.monetization_on,
                Colors.orange,
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Completion rate
          _buildProgressCard(
            'Completion Rate',
            _stats.getCompletionRate(),
            Colors.green,
          ),

          SizedBox(height: 2.h),

          // Average stars
          _buildProgressCard(
            'Average Stars',
            _stats.getAverageStars() / 3.0,
            Colors.amber,
            subtitle: '${_stats.getAverageStars().toStringAsFixed(2)} / 3.0',
          ),

          SizedBox(height: 4.h),

          // Play time
          _buildInfoCard(
            'Total Play Time',
            _formatDuration(_stats.getTotalPlayTime()),
            Icons.access_time,
            Colors.purple,
          ),

          SizedBox(height: 2.h),

          // Three-star levels
          _buildInfoCard(
            'Perfect Levels (3 Stars)',
            '${_stats.getThreeStarLevels()} levels',
            Icons.stars,
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Efficiency score
          _buildScoreCard(
            'Efficiency Score',
            _stats.getEfficiencyScore(),
            100,
            Colors.blue,
          ),

          SizedBox(height: 4.h),

          // Performance metrics grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 3.w,
            crossAxisSpacing: 3.w,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                'Highest Combo',
                '${_stats.getHighestCombo()}x',
                Icons.local_fire_department,
                Colors.red,
              ),
              _buildStatCard(
                'Total Combos',
                _stats.getTotalCombos().toString(),
                Icons.flash_on,
                Colors.orange,
              ),
              _buildStatCard(
                'Perfect Levels',
                _stats.getPerfectLevels().toString(),
                Icons.emoji_events,
                Colors.amber,
              ),
              _buildStatCard(
                'Power-Ups Used',
                _stats.getPowerUpsUsed().toString(),
                Icons.power,
                Colors.purple,
              ),
            ],
          ),

          SizedBox(height: 4.h),

          Text(
            'Averages',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),

          SizedBox(height: 2.h),

          _buildInfoCard(
            'Average Moves per Level',
            _stats.getAverageMoves().toStringAsFixed(1),
            Icons.swap_horiz,
            Colors.blue,
          ),

          SizedBox(height: 2.h),

          _buildInfoCard(
            'Average Time per Level',
            _formatDuration(_stats.getAveragePlayTime().toInt()),
            Icons.timer,
            Colors.green,
          ),

          SizedBox(height: 4.h),

          // Session stats
          _buildSessionStatsCard(),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final summary = _achievements.getSummary();
    final inProgress = _achievements.getInProgressAchievements();
    final unlocked = _achievements.getUnlockedAchievementObjects();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Achievement summary
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Column(
              children: [
                Text(
                  '${summary.unlocked} / ${summary.total}',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Achievements Unlocked',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: summary.completionPercentage,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(summary.completionPercentage * 100).toInt()}% Complete',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on, color: Colors.amber, size: 5.w),
                    SizedBox(width: 2.w),
                    Text(
                      '${summary.totalRewards} coins earned',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // In progress achievements
          if (inProgress.isNotEmpty) ...[
            Text(
              'In Progress',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            SizedBox(height: 2.h),
            ...inProgress.map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: _buildAchievementCard(item.achievement, item.progress),
                )),
            SizedBox(height: 4.h),
          ],

          // Unlocked achievements
          Text(
            'Unlocked (${unlocked.length})',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),

          SizedBox(height: 2.h),

          if (unlocked.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, size: 15.w, color: Colors.grey),
                    SizedBox(height: 2.h),
                    Text(
                      'No achievements unlocked yet',
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Play levels to unlock achievements!',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ...unlocked.map((achievement) => Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: _buildAchievementCard(
                    achievement,
                    achievement.requirement,
                    isUnlocked: true,
                  ),
                )),
        ],
      ),
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
          Icon(icon, size: 10.w, color: color),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    String label,
    double value,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              Text(
                subtitle ?? '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 1.5.h,
            borderRadius: BorderRadius.circular(1.h),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Icon(icon, size: 8.w, color: color),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
    String label,
    int score,
    int maxScore,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 48.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'out of $maxScore',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 3.h),
          LinearProgressIndicator(
            value: score / maxScore,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 1.h,
            borderRadius: BorderRadius.circular(0.5.h),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStatsCard() {
    final session = _stats.getSessionStatistics();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timelapse, size: 6.w, color: Colors.blue),
              SizedBox(width: 2.w),
              Text(
                'Current Session',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSessionStat('Levels', session.levelsCompleted.toString()),
              _buildSessionStat('Stars', session.starsEarned.toString()),
              _buildSessionStat('Coins', session.coinsEarned.toString()),
              _buildSessionStat(
                'Time',
                _formatDuration(session.durationSeconds),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
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
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    int progress, {
    bool isUnlocked = false,
  }) {
    final progressPercentage = (progress / achievement.requirement).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isUnlocked
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: isUnlocked
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            achievement.icon,
            style: TextStyle(fontSize: 12.w),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Icon(Icons.check_circle, color: Colors.green, size: 5.w),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 1.h),
                if (!isUnlocked) ...[
                  LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '$progress / ${achievement.requirement}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                if (isUnlocked) ...[
                  Row(
                    children: [
                      Icon(Icons.monetization_on,
                          size: 4.w, color: Colors.amber),
                      SizedBox(width: 1.w),
                      Text(
                        '+${achievement.rewardCoins} coins',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes}m ${secs}s';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}
