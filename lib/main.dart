import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'core/app_export.dart';
import 'core/services/achievements_tracker_service.dart';
import 'core/services/player_profile_service.dart';
import 'widgets/custom_error_widget.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.bootstrap();

  await AchievementsTrackerService.instance.ensureInitialized();
  await PlayerProfileService.instance.ensureInitialized();

  bool _hasShownError = false;
  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;
      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(const Duration(seconds: 5), () {
        _hasShownError = false;
      });
      return CustomErrorWidget(
        errorDetails: details,
      );
    }
    return const SizedBox.shrink();
  };
  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const SortBlissApp());
}

class SortBlissApp extends StatelessWidget {
  const SortBlissApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'SortBliss',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: AppRoutes.initial,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
