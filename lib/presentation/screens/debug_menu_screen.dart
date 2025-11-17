import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/coin_economy_service.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/statistics_service.dart';
import '../../core/services/powerup_service.dart';
import '../../core/services/user_settings_service.dart';
import '../../core/services/daily_rewards_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/services/app_rating_service.dart';
import '../../core/game/level_generator.dart';
import '../../core/theme/app_theme.dart';

/// Comprehensive debug menu for testing all features
///
/// IMPORTANT: Only accessible in debug mode!
/// Remove or disable in production builds.
///
/// Features:
/// - Service testing
/// - Data manipulation
/// - Feature toggles
/// - Reset functions
/// - Analytics testing
/// - Navigation testing
class DebugMenuScreen extends StatefulWidget {
  const DebugMenuScreen({Key? key}) : super(key: key);

  @override
  State<DebugMenuScreen> createState() => _DebugMenuScreenState();
}

class _DebugMenuScreenState extends State<DebugMenuScreen> {
  final CoinEconomyService _coins = CoinEconomyService.instance;
  final AchievementService _achievements = AchievementService.instance;
  final StatisticsService _stats = StatisticsService.instance;
  final PowerUpService _powerUps = PowerUpService.instance;
  final DailyRewardsService _dailyRewards = DailyRewardsService.instance;
  final RemoteConfigService _remoteConfig = RemoteConfigService.instance;
  final AppRatingService _rating = AppRatingService.instance;
  final LevelGenerator _levelGen = LevelGenerator.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('🔧 Debug Menu'),
        backgroundColor: Colors.red[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDebugInfo(),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildWarningBanner(),
          SizedBox(height: 2.h),

          // Coins Section
          _buildSection(
            title: '💰 Coins',
            children: [
              _buildStatRow('Balance', _coins.getBalance().toString()),
              _buildButton('Add 1000 Coins', () async {
                await _coins.earnCoins(1000, CoinSource.debug);
                _showSnackBar('Added 1000 coins');
                setState(() {});
              }),
              _buildButton('Reset Coins', () async {
                await _coins.resetCoins();
                _showSnackBar('Coins reset');
                setState(() {});
              }),
            ],
          ),

          SizedBox(height: 2.h),

          // Achievements Section
          _buildSection(
            title: '🏆 Achievements',
            children: [
              _buildStatRow('Unlocked', '${_achievements.getSummary().unlocked}'),
              _buildStatRow('Total', '${_achievements.getSummary().total}'),
              _buildButton('Unlock All Achievements', () async {
                // TODO: Implement unlock all
                _showSnackBar('Feature coming soon');
              }),
              _buildButton('Reset Achievements', () async {
                // TODO: Implement reset
                _showSnackBar('Feature coming soon');
              }),
            ],
          ),

          SizedBox(height: 2.h),

          // Statistics Section
          _buildSection(
            title: '📊 Statistics',
            children: [
              _buildStatRow('Levels', '${_stats.getTotalLevelsCompleted()}'),
              _buildStatRow('Stars', '${_stats.getTotalStars()}'),
              _buildButton('Add 10 Levels', () async {
                for (int i = 0; i < 10; i++) {
                  await _stats.recordLevelCompleted(
                    level: i + 1,
                    stars: 3,
                    moves: 10,
                    playTimeSeconds: 60,
                    coinsEarned: 50,
                    combo: 5,
                    isPerfect: true,
                  );
                }
                _showSnackBar('Added 10 levels');
                setState(() {});
              }),
              _buildButton('Reset Statistics', () async {
                // TODO: Implement reset
                _showSnackBar('Feature coming soon');
              }),
            ],
          ),

          SizedBox(height: 2.h),

          // Power-Ups Section
          _buildSection(
            title: '⚡ Power-Ups',
            children: [
              _buildStatRow('Undo', '${_powerUps.getInventory()['undo'] ?? 0}'),
              _buildStatRow('Hint', '${_powerUps.getInventory()['hint'] ?? 0}'),
              _buildButton('Add All Power-Ups (x10)', () async {
                await _powerUps.addPowerUp('undo', 10);
                await _powerUps.addPowerUp('hint', 10);
                await _powerUps.addPowerUp('shuffle', 10);
                await _powerUps.addPowerUp('autosort', 10);
                await _powerUps.addPowerUp('extramoves', 10);
                _showSnackBar('Added all power-ups');
                setState(() {});
              }),
            ],
          ),

          SizedBox(height: 2.h),

          // Daily Rewards Section
          _buildSection(
            title: '🎁 Daily Rewards',
            children: [
              _buildStatRow('Streak', '${_dailyRewards.getCurrentStreak()}'),
              _buildStatRow('Can Claim', _dailyRewards.canClaimToday() ? 'Yes' : 'No'),
              _buildButton('Reset Daily Rewards', () async {
                // TODO: Implement reset
                _showSnackBar('Feature coming soon');
              }),
            ],
          ),

          SizedBox(height: 2.h),

          // Level Generator Section
          _buildSection(
            title: '🎮 Level Generator',
            children: [
              _buildButton('Test Level 1', () {
                final level = _levelGen.generateLevel(1);
                _showLevelInfo(level);
              }),
              _buildButton('Test Level 50', () {
                final level = _levelGen.generateLevel(50);
                _showLevelInfo(level);
              }),
              _buildButton('Test Level 100', () {
                final level = _levelGen.generateLevel(100);
                _showLevelInfo(level);
              }),
            ],
          ),

          SizedBox(height: 2.h),

          // Remote Config Section
          _buildSection(
            title: '🌐 Remote Config',
            children: [
              _buildStatRow('Initialized', _remoteConfig.getBool('achievements_enabled') ? 'Yes' : 'No'),
              _buildButton('Force Refresh', () async {
                await _remoteConfig.forceRefresh();
                _showSnackBar('Remote config refreshed');
              }),
              _buildButton('Reset to Defaults', () async {
                await _remoteConfig.resetToDefaults();
                _showSnackBar('Reset to defaults');
              }),
            ],
          ),

          SizedBox(height: 2.h),

          // App Rating Section
          _buildSection(
            title: '⭐ App Rating',
            children: [
              _buildStatRow('Should Prompt', _rating.shouldPromptForRating() ? 'Yes' : 'No'),
              _buildStatRow('Sessions', '${_rating.getStatistics().sessionCount}'),
              _buildButton('Test Rating Prompt', () async {
                await _rating.promptForRating(context);
              }),
              _buildButton('Reset Rating Service', () async {
                await _rating.resetAll();
                _showSnackBar('Rating service reset');
                setState(() {});
              }),
            ],
          ),

          SizedBox(height: 2.h),

          // Navigation Section
          _buildSection(
            title: '🧭 Navigation',
            children: [
              _buildButton('Test Home', () {
                Navigator.pushNamed(context, '/home');
              }),
              _buildButton('Test Profile', () {
                Navigator.pushNamed(context, '/profile');
              }),
              _buildButton('Test Achievements', () {
                Navigator.pushNamed(context, '/achievements');
              }),
              _buildButton('Test Leaderboards', () {
                Navigator.pushNamed(context, '/leaderboards');
              }),
              _buildButton('Test Events', () {
                Navigator.pushNamed(context, '/events');
              }),
              _buildButton('Test Power-Ups', () {
                Navigator.pushNamed(context, '/powerups');
              }),
              _buildButton('Test Settings', () {
                Navigator.pushNamed(context, '/settings');
              }),
              _buildButton('Test Daily Rewards', () {
                Navigator.pushNamed(context, '/daily-rewards');
              }),
            ],
          ),

          SizedBox(height: 2.h),

          // Danger Zone
          _buildSection(
            title: '⚠️ Danger Zone',
            color: Colors.red[900]!,
            children: [
              _buildDangerButton('Reset ALL Data', () async {
                final confirm = await _showConfirmDialog(
                  'Reset ALL Data?',
                  'This will delete all progress, coins, achievements, and statistics. This cannot be undone!',
                );

                if (confirm == true) {
                  await _coins.resetCoins();
                  // TODO: Reset all other services
                  _showSnackBar('All data reset');
                  setState(() {});
                }
              }),
            ],
          ),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.red[900],
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white, size: 30),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'DEBUG MODE ONLY\nRemove before production!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Color? color,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[850],
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildDangerButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Coins: ${_coins.getStatistics()}'),
              const SizedBox(height: 10),
              Text('Stats: ${_stats.getLifetimeStatistics()}'),
              const SizedBox(height: 10),
              Text('Rating: ${_rating.getStatistics()}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLevelInfo(Level level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Level ${level.number}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Colors: ${level.colors}'),
              Text('Items per color: ${level.itemsPerColor}'),
              Text('Empty containers: ${level.emptyContainers}'),
              Text('Max moves: ${level.maxMoves}'),
              Text('3-star moves: ${level.threeStarMoves}'),
              Text('2-star moves: ${level.twoStarMoves}'),
              const SizedBox(height: 10),
              Text('Total containers: ${level.containers.length}'),
              Text('Is solved: ${level.isSolved}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
