import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/level_progression_service.dart';
import '../../core/config/app_constants.dart';
import '../gameplay_screen/gameplay_screen.dart';

/// Level selection screen
///
/// Displays a grid of all available levels with:
/// - Lock/unlock status
/// - Star ratings for completed levels
/// - Progress indicators
/// - Scroll to current level
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final ScrollController _scrollController = ScrollController();
  int _highestUnlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    await LevelProgressionService.instance.initialize();
    setState(() {
      _highestUnlockedLevel =
          LevelProgressionService.instance.getHighestUnlockedLevel();
    });

    // Scroll to current level after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  void _scrollToCurrentLevel() {
    if (_highestUnlockedLevel > 1) {
      // Scroll to show current level in middle of screen
      final targetPosition = (_highestUnlockedLevel - 1) * 60.0;
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressSummary(),
              Expanded(
                child: _buildLevelGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            'Select Level',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildScrollToCurrentButton(),
        ],
      ),
    );
  }

  Widget _buildScrollToCurrentButton() {
    return TextButton.icon(
      onPressed: _scrollToCurrentLevel,
      icon: const Icon(Icons.my_location_rounded, color: Colors.blue, size: 20),
      label: Text(
        'Level $_highestUnlockedLevel',
        style: const TextStyle(color: Colors.blue),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    final totalLevels = AppConstants.maxLevel;
    final stats = LevelProgressionService.instance.getProgressionStats();
    final completedLevels = _countCompletedLevels();
    final totalStars = stats.totalStars;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            value: '$completedLevels/$totalLevels',
            color: Colors.green,
          ),
          _buildStat(
            icon: Icons.star_rounded,
            label: 'Total Stars',
            value: '$totalStars',
            color: Colors.amber,
          ),
          _buildStat(
            icon: Icons.lock_open_rounded,
            label: 'Unlocked',
            value: '$_highestUnlockedLevel',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.8,
      ),
      itemCount: AppConstants.maxLevel,
      itemBuilder: (context, index) {
        final levelNumber = index + 1;
        return _buildLevelButton(levelNumber);
      },
    );
  }

  Widget _buildLevelButton(int levelNumber) {
    final isUnlocked = levelNumber <= _highestUnlockedLevel;
    final stars = LevelProgressionService.instance.getLevelStars(levelNumber);
    final isCompleted = stars > 0;

    return GestureDetector(
      onTap: isUnlocked
          ? () => _onLevelTapped(levelNumber)
          : () => _showLockedMessage(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCompleted
                      ? [Colors.green.shade700, Colors.green.shade900]
                      : [Colors.blue.shade700, Colors.blue.shade900],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade800, Colors.grey.shade900],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isUnlocked)
              Icon(
                Icons.lock_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 24,
              )
            else ...[
              Text(
                '$levelNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (starIndex) {
                    return Icon(
                      starIndex < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: starIndex < stars
                          ? Colors.amber
                          : Colors.white.withOpacity(0.3),
                      size: 12.sp,
                    );
                  }),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _onLevelTapped(int levelNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameplayScreen(levelNumber: levelNumber),
      ),
    ).then((_) {
      // Refresh progress when returning from gameplay
      _loadProgress();
    });
  }

  void _showLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Complete previous levels to unlock this one!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int _countCompletedLevels() {
    int count = 0;
    for (int i = 1; i <= _highestUnlockedLevel; i++) {
      if (LevelProgressionService.instance.getLevelStars(i) > 0) {
        count++;
      }
    }
    return count;
  }
}
