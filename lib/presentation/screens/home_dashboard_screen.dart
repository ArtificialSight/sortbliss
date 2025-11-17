import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/statistics_service.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/services/seasonal_events_service.dart';
import '../../core/services/powerup_service.dart';
import '../../core/theme/app_theme.dart';

/// Enhanced home dashboard showing all features and stats
///
/// Features:
/// - Player profile card
/// - Quick stats overview
/// - Featured event card
/// - Feature navigation grid
/// - Daily streak indicator
/// - Achievement progress
/// - Quick action buttons
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final StatisticsService _stats = StatisticsService.instance;
  final AchievementService _achievements = AchievementService.instance;
  final LeaderboardService _leaderboard = LeaderboardService.instance;
  final SeasonalEventsService _events = SeasonalEventsService.instance;
  final PowerUpService _powerUps = PowerUpService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App header
                _buildAppHeader(),

                SizedBox(height: 3.h),

                // Player profile card
                _buildProfileCard(),

                SizedBox(height: 3.h),

                // Quick stats
                _buildQuickStats(),

                SizedBox(height: 3.h),

                // Active event (if any)
                _buildActiveEventCard(),

                SizedBox(height: 3.h),

                // Features grid
                Text(
                  'Features',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),

                SizedBox(height: 2.h),

                _buildFeaturesGrid(),

                SizedBox(height: 3.h),

                // Play button
                _buildPlayButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor,
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Icon(Icons.sort, color: Colors.white, size: 8.w),
            ),
            SizedBox(width: 3.w),
            Text(
              'SortBliss',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.primaryColor,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.settings, size: 6.w),
          onPressed: () {
            Navigator.of(context).pushNamed('/settings');
          },
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final levelsCompleted = _stats.getTotalLevelsCompleted();
    final totalStars = _stats.getTotalStars();
    final achievementsSummary = _achievements.getSummary();
    final highScore = _leaderboard.getHighScore();

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
          // Avatar and name
          Row(
            children: [
              CircleAvatar(
                radius: 8.w,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Icon(Icons.person, size: 10.w, color: Colors.white),
              ),
              SizedBox(width: 4.w),
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
                    Text(
                      'Level $levelsCompleted',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // High score badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(5.w),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white, size: 5.w),
                    SizedBox(width: 1.w),
                    Text(
                      highScore.toString(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatPill('⭐', totalStars.toString(), 'Stars'),
              _buildStatPill('🏆', '${achievementsSummary.unlocked}/${achievementsSummary.total}', 'Achievements'),
              _buildStatPill('📊', '${(_stats.getEfficiencyScore()).toString()}%', 'Efficiency'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String emoji, String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5.w),
      ),
      child: Column(
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
      ),
    );
  }

  Widget _buildQuickStats() {
    final session = _stats.getSessionStatistics();
    final powerUpCount = _powerUps.getTotalPowerUpCount();

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            'Session',
            '${session.levelsCompleted} levels',
            Icons.play_circle_outline,
            Colors.blue,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildQuickStatCard(
            'Power-Ups',
            '$powerUpCount owned',
            Icons.power,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEventCard() {
    final activeEvents = _events.getActiveEvents();

    if (activeEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final event = activeEvents.first;
    final timeRemaining = event.timeRemaining;
    final days = timeRemaining.inDays;
    final hours = timeRemaining.inHours % 24;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/events');
      },
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade500],
          ),
          borderRadius: BorderRadius.circular(4.w),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              '🎉',
              style: TextStyle(fontSize: 12.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Ends in $days days $hours hours',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 5.w),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 3.w,
      crossAxisSpacing: 3.w,
      childAspectRatio: 0.9,
      children: [
        _buildFeatureCard(
          'Statistics',
          Icons.bar_chart,
          Colors.blue,
          '/statistics',
        ),
        _buildFeatureCard(
          'Leaderboards',
          Icons.leaderboard,
          Colors.green,
          '/leaderboards',
        ),
        _buildFeatureCard(
          'Achievements',
          Icons.emoji_events,
          Colors.amber,
          '/achievements',
        ),
        _buildFeatureCard(
          'Events',
          Icons.celebration,
          Colors.orange,
          '/events',
        ),
        _buildFeatureCard(
          'Power-Ups',
          Icons.power,
          Colors.purple,
          '/powerups',
        ),
        _buildFeatureCard(
          'Profile',
          Icons.person,
          Colors.indigo,
          '/profile',
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    String label,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 8.w),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return SizedBox(
      width: double.infinity,
      height: 7.h,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pushNamed('/game');
        },
        icon: Icon(Icons.play_arrow, size: 7.w),
        label: Text(
          'Play Now',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
