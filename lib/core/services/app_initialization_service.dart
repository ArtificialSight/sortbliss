import 'package:flutter/material.dart';
import '../utils/analytics_logger.dart';
import 'user_settings_service.dart';
import 'onboarding_service.dart';
import 'powerup_service.dart';
import 'combo_tracker_service.dart';
import 'tutorial_service.dart';
import 'statistics_service.dart';
import 'leaderboard_service.dart';
import 'seasonal_events_service.dart';
import 'achievement_service.dart';
import 'haptic_feedback_service.dart';
import 'sound_effect_service.dart';
import 'animation_coordinator.dart';

/// Centralized app initialization service
///
/// Coordinates initialization of all services in the correct order:
/// 1. Core services (settings, analytics)
/// 2. Gameplay services (stats, achievements, leaderboards)
/// 3. Feature services (power-ups, combos, tutorial)
/// 4. UI services (haptics, sound, animation)
/// 5. Live ops (events, onboarding)
///
/// Provides loading progress and error handling
class AppInitializationService {
  static final AppInitializationService instance = AppInitializationService._();
  AppInitializationService._();

  bool _initialized = false;
  final List<String> _initializationSteps = [];
  final List<String> _errors = [];

  /// Check if app is initialized
  bool get isInitialized => _initialized;

  /// Get initialization steps (for debugging)
  List<String> get initializationSteps => List.unmodifiable(_initializationSteps);

  /// Get errors (if any)
  List<String> get errors => List.unmodifiable(_errors);

  /// Initialize all app services
  Future<void> initialize({
    Function(String step, double progress)? onProgress,
  }) async {
    if (_initialized) return;

    final startTime = DateTime.now();
    _initializationSteps.clear();
    _errors.clear();

    try {
      // Total steps for progress calculation
      const totalSteps = 12;
      int currentStep = 0;

      // Helper to report progress
      void reportProgress(String step) {
        currentStep++;
        _initializationSteps.add(step);
        final progress = currentStep / totalSteps;
        onProgress?.call(step, progress);
        debugPrint('🔄 Init ($currentStep/$totalSteps): $step');
      }

      // ===== STEP 1: Core Services =====
      reportProgress('Initializing user settings');
      await UserSettingsService.instance.initialize();

      // ===== STEP 2: Analytics =====
      reportProgress('Initializing analytics');
      AnalyticsLogger.logEvent('app_initialization_started');

      // ===== STEP 3: Gameplay Services =====
      reportProgress('Initializing statistics');
      await StatisticsService.instance.initialize();

      reportProgress('Initializing achievements');
      await AchievementService.instance.initialize();

      reportProgress('Initializing leaderboards');
      await LeaderboardService.instance.initialize();

      // ===== STEP 4: Feature Services =====
      reportProgress('Initializing power-ups');
      await PowerUpService.instance.initialize();

      reportProgress('Initializing combo tracker');
      ComboTrackerService.instance.initialize();

      reportProgress('Initializing tutorial system');
      await TutorialService.instance.initialize();

      // ===== STEP 5: UI Services =====
      reportProgress('Initializing haptic feedback');
      await HapticFeedbackService.instance.initialize();

      reportProgress('Initializing sound effects');
      await SoundEffectService.instance.initialize();

      reportProgress('Initializing animation coordinator');
      await AnimationCoordinator.instance.initialize();

      // ===== STEP 6: Live Ops =====
      reportProgress('Initializing seasonal events');
      await SeasonalEventsService.instance.initialize();

      reportProgress('Initializing onboarding');
      await OnboardingService.instance.initialize();

      _initialized = true;

      final duration = DateTime.now().difference(startTime);

      AnalyticsLogger.logEvent('app_initialization_completed', parameters: {
        'duration_ms': duration.inMilliseconds,
        'steps': totalSteps,
        'errors': _errors.length,
      });

      debugPrint('✅ App initialization complete in ${duration.inMilliseconds}ms');
    } catch (e, stackTrace) {
      _errors.add(e.toString());

      AnalyticsLogger.logEvent('app_initialization_error', parameters: {
        'error': e.toString(),
        'step': _initializationSteps.lastOrNull ?? 'unknown',
      });

      debugPrint('❌ App initialization error: $e');
      debugPrint(stackTrace.toString());

      rethrow;
    }
  }

  /// Reset all services (for testing/debugging)
  Future<void> reset() async {
    _initialized = false;
    _initializationSteps.clear();
    _errors.clear();

    // Reset individual services if needed
    ComboTrackerService.instance.resetStatistics();

    AnalyticsLogger.logEvent('app_initialization_reset');
  }

  /// Get initialization summary
  InitializationSummary getSummary() {
    return InitializationSummary(
      initialized: _initialized,
      stepsCompleted: _initializationSteps.length,
      errors: _errors.length,
      services: {
        'user_settings': UserSettingsService.instance.toString(),
        'statistics': StatisticsService.instance.toString(),
        'achievements': AchievementService.instance.toString(),
        'leaderboards': LeaderboardService.instance.toString(),
        'power_ups': PowerUpService.instance.toString(),
        'combo_tracker': ComboTrackerService.instance.toString(),
        'tutorial': TutorialService.instance.toString(),
        'events': SeasonalEventsService.instance.toString(),
        'onboarding': OnboardingService.instance.toString(),
      },
    );
  }

  /// Check system health
  Future<HealthCheck> checkHealth() async {
    final issues = <String>[];

    // Check critical services
    if (!_initialized) {
      issues.add('App not initialized');
    }

    // Check for errors
    if (_errors.isNotEmpty) {
      issues.add('${_errors.length} initialization errors');
    }

    // Get service statistics
    final stats = StatisticsService.instance;
    final achievements = AchievementService.instance;
    final leaderboard = LeaderboardService.instance;
    final powerUps = PowerUpService.instance;

    return HealthCheck(
      isHealthy: issues.isEmpty,
      issues: issues,
      metrics: {
        'initialized': _initialized,
        'total_levels_played': stats.getTotalLevelsPlayed(),
        'achievements_unlocked': achievements.getUnlockedAchievements().length,
        'high_score': leaderboard.getHighScore(),
        'power_ups_total': powerUps.getTotalPowerUpCount(),
      },
    );
  }
}

/// Initialization summary data class
class InitializationSummary {
  final bool initialized;
  final int stepsCompleted;
  final int errors;
  final Map<String, String> services;

  InitializationSummary({
    required this.initialized,
    required this.stepsCompleted,
    required this.errors,
    required this.services,
  });
}

/// Health check data class
class HealthCheck {
  final bool isHealthy;
  final List<String> issues;
  final Map<String, dynamic> metrics;

  HealthCheck({
    required this.isHealthy,
    required this.issues,
    required this.metrics,
  });
}

/// Loading screen widget for app initialization
class AppLoadingScreen extends StatefulWidget {
  final Widget child;

  const AppLoadingScreen({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> {
  bool _initialized = false;
  String _currentStep = 'Initializing...';
  double _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await AppInitializationService.instance.initialize(
        onProgress: (step, progress) {
          if (mounted) {
            setState(() {
              _currentStep = step;
              _progress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _progress = 0.0;
                      });
                      _initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon/logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sort,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // App name
                  const Text(
                    'SortBliss',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Progress indicator
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Current step
                  Text(
                    _currentStep,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Progress percentage
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
