import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'core/app_export.dart';
import 'core/audio_manager.dart';
import 'core/config/environment.dart';
import 'core/haptic_manager.dart';
import 'core/premium_audio_manager.dart';
import 'core/services/achievements_tracker_service.dart';
import 'core/services/player_profile_service.dart';
import 'core/services/user_settings_service.dart';
import 'widgets/custom_error_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(
      errorDetails: details,
      errorMessage: details.exceptionAsString(),
    );
  };

  await Environment.bootstrap();

  await Future.wait<void>([
    AchievementsTrackerService.instance.ensureInitialized(),
    PlayerProfileService.instance.ensureInitialized(),
    UserSettingsService.instance.ensureInitialized(),
  ]);

  await Future.wait<void>([
    AudioManager().initialize(),
    PremiumAudioManager().initialize(),
    HapticManager().initialize(),
  ]);

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const SortBlissApp());
}

class SortBlissApp extends StatelessWidget {
  const SortBlissApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'sortbliss',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    );
  }
}
