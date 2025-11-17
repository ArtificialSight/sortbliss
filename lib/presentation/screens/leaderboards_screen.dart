import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/theme/app_theme.dart';

/// Leaderboards screen with daily/weekly/all-time tabs
///
/// Features:
/// - 3 tabs (Daily, Weekly, All-Time)
/// - Top 50 rankings display
/// - Player's rank highlighted
/// - Personal best card
/// - Beautiful rank badges
/// - Pull to refresh
class LeaderboardsScreen extends StatefulWidget {
  const LeaderboardsScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends State<LeaderboardsScreen>
    with SingleTickerProviderStateMixin {
  final LeaderboardService _leaderboard = LeaderboardService.instance;
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
        title: const Text('Leaderboards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'All-Time'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Personal best card
          _buildPersonalBestCard(),

          // Leaderboard tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDailyTab(),
                _buildWeeklyTab(),
                _buildAllTimeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestCard() {
    final highScore = _leaderboard.getHighScore();
    final totalScore = _leaderboard.getTotalScore();

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Trophy icon
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              size: 10.w,
              color: Colors.amber,
            ),
          ),

          SizedBox(width: 4.w),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Best',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  highScore.toString(),
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Total Score: ${totalScore.toString()}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTab() {
    final entries = _leaderboard.getDailyLeaderboard();

    if (entries.isEmpty) {
      return _buildEmptyState('No daily scores yet', 'Complete a level today to appear on the daily leaderboard!');
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return _buildLeaderboardEntry(entries[index], index + 1);
        },
      ),
    );
  }

  Widget _buildWeeklyTab() {
    final entries = _leaderboard.getWeeklyLeaderboard();

    if (entries.isEmpty) {
      return _buildEmptyState('No weekly scores yet', 'Play this week to compete for the top spot!');
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return _buildLeaderboardEntry(entries[index], index + 1);
        },
      ),
    );
  }

  Widget _buildAllTimeTab() {
    final entries = _leaderboard.getAllTimeLeaderboard(limit: 50);

    if (entries.isEmpty) {
      return _buildEmptyState('No scores yet', 'Start playing to set your first record!');
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return _buildLeaderboardEntry(entries[index], index + 1);
        },
      ),
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int rank) {
    final isTopThree = rank <= 3;
    final rankColor = _getRankColor(rank);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isTopThree ? rankColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: isTopThree ? rankColor.withOpacity(0.3) : Colors.grey.shade300,
          width: isTopThree ? 2 : 1,
        ),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: rankColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          _buildRankBadge(rank),

          SizedBox(width: 3.w),

          // Level info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level ${entry.level}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              SizedBox(height: 0.5.h),
              if (entry.stars != null)
                Row(
                  children: List.generate(
                    3,
                    (i) => Icon(
                      i < entry.stars! ? Icons.star : Icons.star_border,
                      size: 4.w,
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),

          const Spacer(),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.score.toString(),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                _formatTimestamp(entry.timestamp),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    final isTopThree = rank <= 3;
    final rankColor = _getRankColor(rank);

    if (isTopThree) {
      return Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [rankColor, rankColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: rankColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _getRankIcon(rank),
            style: TextStyle(fontSize: 7.w),
          ),
        ),
      );
    }

    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 20.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 3.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey.shade400; // Silver
      case 3:
        return Colors.brown.shade400; // Bronze
      default:
        return Colors.blue;
    }
  }

  String _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}
