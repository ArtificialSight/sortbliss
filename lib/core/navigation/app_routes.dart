import 'package:flutter/material.dart';
import '../../presentation/screens/app_loading_screen.dart';
import '../../presentation/screens/home_dashboard_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/statistics_screen.dart';
import '../../presentation/screens/achievements_screen.dart';
import '../../presentation/screens/leaderboards_screen.dart';
import '../../presentation/screens/events_screen.dart';
import '../../presentation/screens/powerups_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/daily_rewards_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/level_select_screen.dart';
import '../screens/debug_menu_screen.dart';

/// Centralized route configuration for the entire app
///
/// Usage:
/// ```dart
/// MaterialApp(
///   initialRoute: AppRoutes.splash,
///   onGenerateRoute: AppRoutes.onGenerateRoute,
/// )
/// ```
class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String statistics = '/statistics';
  static const String achievements = '/achievements';
  static const String leaderboards = '/leaderboards';
  static const String events = '/events';
  static const String powerups = '/powerups';
  static const String settings = '/settings';
  static const String dailyRewards = '/daily-rewards';
  static const String game = '/game';
  static const String levelSelect = '/level-select';
  static const String debug = '/debug';

  /// Generate routes with optional arguments
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(
          const AppLoadingScreen(),
          settings: settings,
        );

      case onboarding:
        return _buildRoute(
          const OnboardingScreen(),
          settings: settings,
        );

      case home:
        return _buildRoute(
          const HomeDashboardScreen(),
          settings: settings,
        );

      case profile:
        return _buildRoute(
          const ProfileScreen(),
          settings: settings,
        );

      case statistics:
        return _buildRoute(
          const StatisticsScreen(),
          settings: settings,
        );

      case achievements:
        return _buildRoute(
          const AchievementsScreen(),
          settings: settings,
        );

      case leaderboards:
        return _buildRoute(
          const LeaderboardsScreen(),
          settings: settings,
        );

      case events:
        return _buildRoute(
          const EventsScreen(),
          settings: settings,
        );

      case powerups:
        return _buildRoute(
          const PowerUpsScreen(),
          settings: settings,
        );

      case settings:
        return _buildRoute(
          const SettingsScreen(),
          settings: settings,
        );

      case dailyRewards:
        return _buildRoute(
          const DailyRewardsScreen(),
          settings: settings,
        );

      case debug:
        return _buildRoute(
          const DebugMenuScreen(),
          settings: settings,
        );

      // Game screen - TODO: implement
      case game:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          _buildComingSoonScreen('Game Screen'),
          settings: settings,
        );

      case levelSelect:
        return _buildRoute(
          const LevelSelectScreen(),
          settings: settings,
        );

      case debug:
        return _buildRoute(
          const DebugMenuScreen(),
          settings: settings,
        );

      default:
        return _buildRoute(
          _build404Screen(settings.name ?? 'unknown'),
          settings: settings,
        );
    }
  }

  /// Build route with custom transitions
  static MaterialPageRoute _buildRoute(
    Widget page, {
    required RouteSettings settings,
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute(
      builder: (context) => page,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Build custom page route with slide transition
  static PageRouteBuilder _buildSlideRoute(
    Widget page, {
    required RouteSettings settings,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Build custom page route with fade transition
  static PageRouteBuilder _buildFadeRoute(
    Widget page, {
    required RouteSettings settings,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Coming soon placeholder
  static Widget _buildComingSoonScreen(String featureName) {
    return Scaffold(
      appBar: AppBar(title: Text(featureName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 100),
            const SizedBox(height: 20),
            Text(
              '$featureName Coming Soon!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('This feature is under development.'),
          ],
        ),
      ),
    );
  }

  /// 404 screen
  static Widget _build404Screen(String routeName) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Route "$routeName" does not exist.'),
          ],
        ),
      ),
    );
  }
}

/// Debug menu screen (placeholder)
class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Menu')),
      body: const Center(child: Text('Debug Menu - To be implemented')),
    );
  }
}

/// Deep link handler
class DeepLinkHandler {
  /// Handle deep link URI
  static String? handleDeepLink(Uri uri) {
    // Example: sortbliss://game/123 -> /game with level=123
    final path = uri.path;
    final params = uri.queryParameters;

    switch (path) {
      case '/game':
        return AppRoutes.game;
      case '/profile':
        return AppRoutes.profile;
      case '/achievements':
        return AppRoutes.achievements;
      case '/leaderboards':
        return AppRoutes.leaderboards;
      case '/events':
        return AppRoutes.events;
      case '/powerups':
        return AppRoutes.powerups;
      default:
        return AppRoutes.home;
    }
  }
}

/// Navigation extensions for convenience
extension NavigationExtensions on BuildContext {
  /// Navigate to route
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate and replace
  Future<T?> navigateReplace<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this)
        .pushReplacementNamed<T, dynamic>(routeName, arguments: arguments);
  }

  /// Navigate and clear stack
  Future<T?> navigateClearStack<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back
  void goBack<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// Can go back
  bool canGoBack() {
    return Navigator.of(this).canPop();
  }
}
