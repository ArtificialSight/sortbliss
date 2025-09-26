import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/services/daily_challenge_service.dart';
import '../../theme/app_theme.dart';
import '../daily_challenge/daily_challenge_screen.dart';
import './widgets/animated_background_widget.dart';
import './widgets/daily_challenge_widget.dart';
import './widgets/level_progress_widget.dart';
import './widgets/menu_action_button_widget.dart';
import './widgets/play_button_widget.dart';
import './widgets/player_stats_widget.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late final DailyChallengeService _dailyChallengeService;
  DailyChallengePayload? _dailyChallenge;
  Duration? _dailyChallengeTimeRemaining;
  bool _loadingDailyChallenge = true;
  StreamSubscription<DailyChallengePayload>? _challengeSubscription;
  StreamSubscription<Duration>? _countdownSubscription;

  // Mock data for the main menu
  final Map<String, dynamic> playerData = {
    "levelsCompleted": 47,
    "currentStreak": 12,
    "coinsEarned": 2850,
    "currentLevel": 48,
    "levelProgress": 0.65,
    "dailyChallengeCompleted": false,
    "timeUntilReset": "14h 32m",
    "recentAchievements": ["Speed Demon", "Perfectionist"],
    "showRatePrompt": false,
    "hasRemoveAdsPurchase": false,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    _dailyChallengeService = DailyChallengeService(
      supabaseRestEndpoint: Environment.supabaseDailyChallengeEndpoint,
      supabaseAnonKey: Environment.supabaseAnonKeyOrNull,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDailyChallenge();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _challengeSubscription?.cancel();
    _countdownSubscription?.cancel();
    unawaited(_dailyChallengeService.dispose());
    super.dispose();
  }

  Future<void> _loadDailyChallenge({bool forceRefresh = false}) async {
    setState(() {
      _loadingDailyChallenge = true;
    });
    try {
      _challengeSubscription ??=
          _dailyChallengeService.challengeStream.listen((payload) {
        if (!mounted) {
          return;
        }
        setState(() {
          _dailyChallenge = payload;
          _dailyChallengeTimeRemaining = payload.timeUntilReset;
        });
        _countdownSubscription?.cancel();
        _countdownSubscription = _dailyChallengeService
            .countdownStream(payload.resetAt)
            .listen((duration) {
          if (!mounted) {
            return;
          }
          setState(() {
            _dailyChallengeTimeRemaining = duration;
          });
        });
      });

      final challenge =
          await _dailyChallengeService.loadDailyChallenge(forceRefresh: forceRefresh);
      if (!mounted) {
        return;
      }
      setState(() {
        _dailyChallenge = challenge;
        _dailyChallengeTimeRemaining = challenge.timeUntilReset;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to sync daily challenge: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingDailyChallenge = false;
        });
      }
    }
  }

  void _navigateToGameplay() {
    Navigator.pushNamed(context, '/gameplay-screen');
  }

  void _navigateToDailyChallenge() {
    if (_dailyChallenge == null || _loadingDailyChallenge) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Daily challenge is syncing. Please try again in a moment.'),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.dailyChallenge,
      arguments: DailyChallengeScreenArgs(
        service: _dailyChallengeService,
        initialChallenge: _dailyChallenge!,
      ),
    );
  }

  void _navigateToAchievements() {
    // Navigate to achievements screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Achievements screen coming soon!')),
    );
  }

  void _navigateToSettings() {
    // Navigate to settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings screen coming soon!')),
    );
  }

  void _shareProgress() {
    // Share progress functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Level ${playerData["currentLevel"]} completed! \${playerData["coinsEarned"]} coins earned!'),
      ),
    );
  }

  void _rateApp() {
    // Rate app functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for rating SortBliss!')),
    );
  }

  void _purchaseRemoveAds() {
    // Remove ads purchase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Remove Ads for \$2.99 - Coming soon!')),
    );
  }

  Widget _buildPullDownMenu() {
    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 10.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 2.h),
          if (!(playerData["hasRemoveAdsPurchase"] as bool))
            MenuActionButtonWidget(
              iconName: 'block',
              title: 'Remove Ads',
              subtitle: 'One-time purchase - \$2.99',
              onPressed: _purchaseRemoveAds,
              iconColor: Colors.red,
            ),
          SizedBox(height: 2.h),
          MenuActionButtonWidget(
            iconName: 'share',
            title: 'Share Progress',
            subtitle: 'Tell friends about your achievements',
            onPressed: _shareProgress,
            iconColor: Colors.blue,
          ),
          SizedBox(height: 2.h),
          MenuActionButtonWidget(
            iconName: 'star',
            title: 'Rate SortBliss',
            subtitle: 'Help us improve the game',
            onPressed: _rateApp,
            iconColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const AnimatedBackgroundWidget(),
            FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadDailyChallenge(forceRefresh: true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Daily challenge updated!')),
                    );
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 2.h),
                      // App Logo/Title
                      Text(
                        'SortBliss',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Organize. Sort. Relax.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 4.h),

                      // Player Stats
                      PlayerStatsWidget(
                        levelsCompleted: playerData["levelsCompleted"] as int,
                        currentStreak: playerData["currentStreak"] as int,
                        coinsEarned: playerData["coinsEarned"] as int,
                      ),
                      SizedBox(height: 3.h),

                      // Level Progress
                      LevelProgressWidget(
                        currentLevel: playerData["currentLevel"] as int,
                        progressPercentage:
                            playerData["levelProgress"] as double,
                      ),
                      SizedBox(height: 4.h),

                      // Play Button
                      PlayButtonWidget(
                        onPressed: _navigateToGameplay,
                      ),
                      SizedBox(height: 4.h),

                      // Daily Challenge
                      DailyChallengeWidget(
                        challenge: _dailyChallenge,
                        timeRemaining: _dailyChallengeTimeRemaining,
                        isLoading: _loadingDailyChallenge,
                        onPressed: _dailyChallenge != null
                            ? _navigateToDailyChallenge
                            : null,
                      ),
                      SizedBox(height: 3.h),

                      // Achievements
                      MenuActionButtonWidget(
                        iconName: 'emoji_events',
                        title: 'Achievements',
                        subtitle:
                            'Recent: ${(playerData["recentAchievements"] as List).join(", ")}',
                        onPressed: _navigateToAchievements,
                        iconColor: Colors.orange,
                        showBadge: (playerData["recentAchievements"] as List)
                            .isNotEmpty,
                      ),
                      SizedBox(height: 3.h),

                      // Settings
                      MenuActionButtonWidget(
                        iconName: 'settings',
                        title: 'Settings',
                        subtitle: 'Sound, vibration, tutorial',
                        onPressed: _navigateToSettings,
                        iconColor: Colors.grey,
                      ),
                      SizedBox(height: 6.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
