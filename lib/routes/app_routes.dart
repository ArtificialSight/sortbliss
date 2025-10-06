import 'package:flutter/material.dart';
import '../presentation/achievements/achievements_screen.dart';
import '../presentation/daily_challenge/daily_challenge_screen.dart';
import '../presentation/gameplay_screen/gameplay_screen.dart';
import '../presentation/level_complete_screen/level_complete_screen.dart';
import '../presentation/main_menu/main_menu.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String levelComplete = '/level-complete-screen';
  static const String gameplay = '/gameplay-screen';
  static const String mainMenu = '/main-menu';
  static const String dailyChallenge = '/daily-challenge';
  static const String achievements = '/achievements';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    levelComplete: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['levelData'] != null) {
        return LevelCompleteScreen(levelData: args['levelData']);
      }
      // Provide default levelData if not specified
      return const LevelCompleteScreen(levelData: <String, dynamic>{});
    },
    gameplay: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is GameplayScreenArgs) {
        return GameplayScreen(levelData: args.levelData);
      }
      if (args is Map<String, dynamic> && args['levelData'] != null) {
        return GameplayScreen(levelData: args['levelData']);
      }
      // Provide default level data if no arguments are passed
      return const GameplayScreen();
    },
    mainMenu: (context) => const MainMenu(),
    achievements: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is AchievementsScreenArgs) {
        return AchievementsScreen(args: args);
      }
      return const AchievementsScreen(
        args: AchievementsScreenArgs(
          levelsCompleted: 0,
          currentStreak: 0,
          coinsEarned: 0,
          unlockedAchievements: [],
          shareCount: 0,
          audioCustomized: false,
        ),
      );
    },
    settings: (context) => const SettingsScreen(),
    dailyChallenge: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is DailyChallengeScreenArgs) {
        return DailyChallengeScreen(
          service: args.service,
          initialChallenge: args.initialChallenge,
        );
      }
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Daily challenge data was not provided. Please relaunch from the main menu.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    },
    // TODO: Add your other routes here
  };
}

// Add GameplayScreenArgs class if it doesn't exist
class GameplayScreenArgs {
  final dynamic levelData;

  const GameplayScreenArgs({required this.levelData});
}