import 'package:flutter/material.dart';
import 'package:sortbliss/core/services/player_profile_service.dart';
import 'package:sortbliss/presentation/gameplay_screen/complete_gameplay_screen.dart';

/// Simple level selector for market validation
/// Shows playable levels with completion status
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Level'),
        backgroundColor: const Color(0xFF0F172A),
      ),
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
        child: ValueListenableBuilder(
          valueListenable: PlayerProfileService.instance.profileListenable,
          builder: (context, profile, child) {
            // Generate 75 levels (as per original design)
            final totalLevels = 75;
            final unlockedLevels = profile.currentLevel;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: totalLevels,
              itemBuilder: (context, index) {
                final levelNumber = index + 1;
                final isUnlocked = levelNumber <= unlockedLevels;
                final isCompleted = levelNumber < profile.currentLevel;
                final isCurrent = levelNumber == profile.currentLevel;

                return _buildLevelButton(
                  context: context,
                  levelNumber: levelNumber,
                  isUnlocked: isUnlocked,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelButton({
    required BuildContext context,
    required int levelNumber,
    required bool isUnlocked,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    Color backgroundColor;
    Color textColor;
    Widget? icon;

    if (isCompleted) {
      backgroundColor = Colors.green.withOpacity(0.3);
      textColor = Colors.white;
      icon = const Icon(Icons.check_circle, color: Colors.green, size: 16);
    } else if (isCurrent) {
      backgroundColor = Colors.blue.withOpacity(0.3);
      textColor = Colors.white;
      icon = const Icon(Icons.play_circle_filled, color: Colors.blue, size: 16);
    } else if (isUnlocked) {
      backgroundColor = Colors.white.withOpacity(0.1);
      textColor = Colors.white;
    } else {
      backgroundColor = Colors.black.withOpacity(0.3);
      textColor = Colors.white38;
      icon = const Icon(Icons.lock, color: Colors.white38, size: 16);
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isUnlocked
            ? () {
                // Launch gameplay
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CompleteGameplayScreen(
                      levelNumber: levelNumber,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? Colors.blue
                  : Colors.white.withOpacity(0.2),
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) icon,
              const SizedBox(height: 4),
              Text(
                '$levelNumber',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
