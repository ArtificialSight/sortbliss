import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../core/config/environment.dart';
import '../../core/services/daily_challenge_service.dart';
import '../../core/services/player_profile_service.dart';
import '../../theme/app_theme.dart';
import '../daily_challenge/daily_challenge_screen.dart';
import '../achievements/achievements_screen.dart';
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

class _MainMenuState extends State<MainMenu>
    with TickerProviderStateMixin {
  late final PlayerProfileService _profileService;
  late final DailyChallengeService _dailyChallengeService;
  late final VoidCallback _profileListener;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  PlayerProfile profile = PlayerProfile.defaults;
  DailyChallengePayload? dailyChallenge;
  Duration? dailyChallengeTimeRemaining;
  Timer? _timer;
  bool _loadingDailyChallenge = true;

  @override
  void initState() {
    super.initState();
    _profileService = PlayerProfileService.instance;
    profile = _profileService.currentProfile;
    _profileListener = () {
      if (!mounted) {
        return;
      }
      setState(() {
        profile = _profileService.currentProfile;
      });
    };
    _profileService.profileListenable.addListener(_profileListener);
    unawaited(_profileService.ensureInitialized().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        profile = _profileService.currentProfile;
      });
    }));

    _dailyChallengeService = DailyChallengeService(
      supabaseRestEndpoint: Environment.supabaseDailyChallengeEndpoint,
      supabaseAnonKey: Environment.supabaseAnonKeyOrNull,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();

    unawaited(_refreshDailyChallenge());
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  Future<void> _refreshDailyChallenge() async {
    setState(() {
      _loadingDailyChallenge = true;
    });
    try {
      final payload = await _dailyChallengeService.loadDailyChallenge();
      if (!mounted) {
        return;
      }
      setState(() {
        dailyChallenge = payload;
        dailyChallengeTimeRemaining = payload.timeUntilReset;
        _loadingDailyChallenge = false;
      });
    } catch (error) {
      debugPrint('Error loading daily challenge: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        dailyChallenge = null;
        dailyChallengeTimeRemaining = null;
        _loadingDailyChallenge = false;
      });
    }
  }

  void _updateTimeRemaining() {
    if (!mounted) {
      return;
    }
    final Duration? nextValue = dailyChallenge?.timeUntilReset;
    if (dailyChallengeTimeRemaining == nextValue) {
      return;
    }
    setState(() {
      dailyChallengeTimeRemaining = nextValue;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _timer?.cancel();
    _profileService.profileListenable.removeListener(_profileListener);
    _dailyChallengeService.dispose();
    super.dispose();
  }

  void _openStorefront() {
    try {
      // Log analytics if service is available
      Navigator.pushNamed(context, '/storefront');
    } catch (e) {
      debugPrint('Error opening storefront: $e');
    }
  }

  void _shareProgress(PlayerProfile profile) async {
    try {
      final message =
          'Just reached level ${profile.currentLevel} in SortBliss! 🎯\n'
          'Levels Completed: ${profile.levelsCompleted}\n'
          'Achievements Unlocked: ${profile.unlockedAchievements.length}\n\n'
          'Can you beat my score? Download SortBliss now! 🚀';
      await Share.share(message, subject: 'Check out my SortBliss progress!');
      unawaited(_profileService.incrementShareCount());
    } catch (e) {
      debugPrint('Error sharing progress: $e');
    }
  }

  void _rateApp() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing();
      }
    } catch (e) {
      debugPrint('Error requesting app review: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackgroundWidget(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    child: Column(
                      children: [
                        // Title and Player Stats
                        Container(
                          margin: EdgeInsets.only(bottom: 4.h),
                          child: Column(
                            children: [
                              Text(
                                'SortBliss',
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 2.h),
                              PlayerStatsWidget(
                                coinsEarned: profile.coinsEarned,
                                currentStreak: profile.currentStreak,
                                levelsCompleted: profile.levelsCompleted,
                              ),
                            ],
                          ),
                        ),
                        // Play Button
                        Container(
                          margin: EdgeInsets.only(bottom: 4.h),
                          child: PlayButtonWidget(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.gameplay,
                              );
                            },
                          ),
                        ),
                        // Level Progress
                        Container(
                          margin: EdgeInsets.only(bottom: 4.h),
                          child: LevelProgressWidget(
                            currentLevel: profile.currentLevel,
                            progressPercentage: profile.levelProgress,
                          ),
                        ),
                        // Daily Challenge
                        if (dailyChallenge != null || _loadingDailyChallenge)
                          Container(
                            margin: EdgeInsets.only(bottom: 4.h),
                            child: DailyChallengeWidget(
                              challenge: dailyChallenge,
                              timeRemaining: dailyChallengeTimeRemaining,
                              isLoading: _loadingDailyChallenge,
                              onPressed:
                                  dailyChallenge != null && !_loadingDailyChallenge
                                      ? () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DailyChallengeScreen(
                                                service: _dailyChallengeService,
                                                initialChallenge:
                                                    dailyChallenge!,
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                            ),
                          ),
                        // Menu Actions
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'More Options',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              MenuActionButtonWidget(
                                iconName: 'trophy',
                                title: 'Achievements',
                                subtitle: 'View your accomplishments',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AchievementsScreen(),
                                    ),
                                  );
                                },
                                iconColor: Colors.amber,
                              ),
                              SizedBox(height: 3.h),
                              MenuActionButtonWidget(
                                iconName: 'flash',
                                title: 'Power-Ups',
                                subtitle: 'Buy boosts and consumables',
                                onPressed: () {
                                  Navigator.of(context).pushNamed(AppRoutes.powerUps);
                                },
                                iconColor: Colors.purple,
                              ),
                              SizedBox(height: 3.h),
                              MenuActionButtonWidget(
                                iconName: 'shop',
                                title: 'Shop',
                                subtitle: 'Unlock premium features & themes',
                                onPressed: _openStorefront,
                                iconColor: Colors.green,
                              ),
                              SizedBox(height: 3.h),
                              MenuActionButtonWidget(
                                iconName: 'share',
                                title: 'Share Progress',
                                subtitle: 'Tell friends about your achievements',
                                onPressed: () {
                                  _shareProgress(profile);
                                },
                                iconColor: Colors.blue,
                              ),
                              SizedBox(height: 3.h),
                              MenuActionButtonWidget(
                                iconName: 'star',
                                title: 'Rate SortBliss',
                                subtitle: 'Help us improve the game',
                                onPressed: _rateApp,
                                iconColor: Colors.amber,
                              ),
                              SizedBox(height: 6.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
