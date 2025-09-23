import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
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

  final MonetizationManager _monetizationManager =
      MonetizationManager.instance;

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

    // Initialize monetization data
    playerData["coinsEarned"] = _monetizationManager.coinBalance.value;
    playerData["hasRemoveAdsPurchase"] = _monetizationManager.isAdFree;

    _monetizationManager.coinBalance.addListener(_onCoinBalanceChanged);
    _monetizationManager.addListener(_onMonetizationChanged);

    // Initialize daily challenge service
    _dailyChallengeService = DailyChallengeService(
      supabaseRestEndpoint: _envOrNull(
        const String.fromEnvironment(
          'SUPABASE_DAILY_CHALLENGE_ENDPOINT',
          defaultValue: '',
        ),
      ),
      supabaseAnonKey: _envOrNull(
        const String.fromEnvironment(
          'SUPABASE_DAILY_CHALLENGE_ANON_KEY',
          defaultValue: '',
        ),
      ),
    );

    _initializeDailyChallenge();
  }

  String? _envOrNull(String value) {
    return value.isEmpty ? null : value;
  }

  void _onCoinBalanceChanged() {
    if (mounted) {
      setState(() {
        playerData["coinsEarned"] = _monetizationManager.coinBalance.value;
      });
    }
  }

  void _onMonetizationChanged() {
    if (mounted) {
      setState(() {
        playerData["hasRemoveAdsPurchase"] = _monetizationManager.isAdFree;
      });
    }
  }

  Future<void> _initializeDailyChallenge() async {
    try {
      final payload = await _dailyChallengeService.initializeDailyChallenge();
      if (payload != null && mounted) {
        setState(() {
          _dailyChallenge = payload;
          _loadingDailyChallenge = false;
        });

        // Start listening to countdown updates
        _countdownSubscription = _dailyChallengeService
            .getDailyChallengeCountdown()
            .listen((duration) {
          if (mounted) {
            setState(() {
              _dailyChallengeTimeRemaining = duration;
            });
          }
        });
      } else if (mounted) {
        setState(() {
          _loadingDailyChallenge = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingDailyChallenge = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _challengeSubscription?.cancel();
    _countdownSubscription?.cancel();
    _monetizationManager.coinBalance.removeListener(_onCoinBalanceChanged);
    _monetizationManager.removeListener(_onMonetizationChanged);
    super.dispose();
  }

  void _navigateToGame() {
    Navigator.of(context).pushNamed('/game');
  }

  void _navigateToLeaderboard() {
    Navigator.of(context).pushNamed('/leaderboard');
  }

  void _navigateToAchievements() {
    Navigator.of(context).pushNamed('/achievements');
  }

  void _navigateToSettings() {
    Navigator.of(context).pushNamed('/settings');
  }

  void _navigateToDailyChallenge() {
    if (_dailyChallenge != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DailyChallengeScreen(
            challengePayload: _dailyChallenge!,
          ),
        ),
      );
    }
  }

  Future<void> _shareGame() async {
    await Share.share(
      'Check out SortBliss - the most addictive puzzle game! Download now and challenge your mind.',
      subject: 'SortBliss - Puzzle Game Challenge',
    );
  }

  Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            const AnimatedBackgroundWidget(),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    children: [
                      SizedBox(height: 2.h),

                      // Logo and Title
                      Container(
                        padding: EdgeInsets.all(6.w),
                        child: Column(
                          children: [
                            Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4.w),
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.shuffle,
                                color: Colors.white,
                                size: 10.w,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'SortBliss',
                              style: AppTextStyles.heading1.copyWith(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              'Master the Art of Sorting',
                              style: AppTextStyles.body1.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Player Stats
                      PlayerStatsWidget(
                        levelsCompleted: playerData["levelsCompleted"],
                        currentStreak: playerData["currentStreak"],
                        coinsEarned: playerData["coinsEarned"],
                      ),
                      SizedBox(height: 3.h),

                      // Level Progress
                      LevelProgressWidget(
                        currentLevel: playerData["currentLevel"],
                        progress: playerData["levelProgress"],
                      ),
                      SizedBox(height: 4.h),

                      // Daily Challenge
                      if (!_loadingDailyChallenge && _dailyChallenge != null)
                        DailyChallengeWidget(
                          challengePayload: _dailyChallenge!,
                          timeRemaining: _dailyChallengeTimeRemaining,
                          onPressed: _navigateToDailyChallenge,
                        ),
                      if (!_loadingDailyChallenge && _dailyChallenge != null)
                        SizedBox(height: 4.h),

                      // Play Button
                      PlayButtonWidget(
                        onPressed: _navigateToGame,
                      ),
                      SizedBox(height: 4.h),

                      // Action Buttons
                      // Leaderboard
                      MenuActionButtonWidget(
                        iconName: 'leaderboard',
                        title: 'Leaderboard',
                        subtitle: 'See how you rank globally',
                        onPressed: _navigateToLeaderboard,
                        iconColor: AppColors.primary,
                      ),
                      SizedBox(height: 3.h),

                      // Share Game
                      MenuActionButtonWidget(
                        iconName: 'share',
                        title: 'Share Game',
                        subtitle: 'Challenge your friends',
                        onPressed: _shareGame,
                        iconColor: AppColors.secondary,
                      ),
                      SizedBox(height: 3.h),

                      // Rate App
                      if (playerData["showRatePrompt"] == true)
                        MenuActionButtonWidget(
                          iconName: 'star',
                          title: 'Rate SortBliss',
                          subtitle: 'Help us improve the game',
                          onPressed: _rateApp,
                          iconColor: Colors.amber,
                          showBadge: true,
                        ),
                      if (playerData["showRatePrompt"] == true)
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