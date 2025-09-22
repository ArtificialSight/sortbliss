import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/level_complete_screen/level_complete_screen.dart';
import '../presentation/gameplay_screen/gameplay_screen.dart';
import '../presentation/main_menu/main_menu.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String levelComplete = '/level-complete-screen';
  static const String gameplay = '/gameplay-screen';
  static const String mainMenu = '/main-menu';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    levelComplete: (context) => const LevelCompleteScreen(),
    gameplay: (context) => const GameplayScreen(),
    mainMenu: (context) => const MainMenu(),
    // TODO: Add your other routes here
  };
}
