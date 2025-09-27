import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late final DailyChallengeService _dailyChallengeService;
  DailyChallengePayload? _dailyChallenge;
  Duration? _dailyChallengeTimeRemaining;
  Timer? _timer;
  late PlayerProfilePayload profile;
  late StreamSubscription _profileSubscription;
  late StreamSubscription _analyticsSubscription;
  late StreamSubscription _dailyChallengeSubscription;
  late StreamSubscription _dailyChallengeTimerSubscription;

  @override
  void initState() {
    super.initState();
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

    _dailyChallengeService = DailyChallengeService.instance;
    profile = PlayerProfileService.instance.profile;

    _initializeSubscriptions();
    _refreshDailyChallenge();
  }

  void _initializeSubscriptions() {
    _profileSubscription =
        PlayerProfileService.instance.profileStream.listen((newProfile) {
      if (mounted) {
        setState(() {
          profile = newProfile;
        });
      }
    });

    _analyticsSubscription = AnalyticsService.instance.eventStream.listen((_) {
      if (mounted) {
        setState(() {
          profile = PlayerProfileService.instance.profile;
        });
      }
    });

    _dailyChallengeSubscription =
        _dailyChallengeService.challengeStream.listen((challenge) {
      if (mounted) {
        setState(() {
          _dailyChallenge = challenge;
        });
      }
    });

    _dailyChallengeTimerSubscription =
        _dailyChallengeService.timeRemainingStream.listen((timeRemaining) {
      if (mounted) {
        setState(() {
          _dailyChallengeTimeRemaining = timeRemaining;
        });
      }
    });

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          profile = PlayerProfileService.instance.profile;
        });
      }
    });
  }

  void _refreshDailyChallenge() {
    try {
      final challenge = _dailyChallengeService.getCurrentChallenge();
      final timeRemaining = _dailyChallengeService.getTimeRemaining();
      if (mounted) {
        setState(() {
          _dailyChallenge = challenge;
          _dailyChallengeTimeRemaining = timeRemaining;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing daily challenge: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _timer?.cancel();
    _profileSubscription.cancel();
    _analyticsSubscription.cancel();
    _dailyChallengeSubscription.cancel();
    _dailyChallengeTimerSubscription.cancel();
    super.dispose();
  }

  void _openStorefront() {
    try {
      AnalyticsService.instance.logEvent('storefront_opened', {});
      Navigator.pushNamed(context, AppRoutes.storefrontRoute);
    } catch (e) {
      debugPrint('Error opening storefront: $e');
    }
  }

  void _shareProgress(PlayerProfilePayload profile) async {
    try {
      // Log analytics
      AnalyticsService.instance.logEvent('share_progress_initiated', {
        'level': profile.currentLevel,
        'total_score': profile.totalScore,
        'achievements_unlocked': profile.achievements.length,
      });

      final message = 
          'Just reached level ${profile.currentLevel} in SortBliss! 🎯\n'
          'Total Score: ${profile.totalScore.toStringAsFixed(0)} points\n'
          'Achievements Unlocked: ${profile.achievements.length}\n\n'
          'Can you beat my score? Download SortBliss now! 🚀';

      await Share.share(message, subject: 'Check out my SortBliss progress!');

      // Log successful share
      AnalyticsService.instance.logEvent('share_progress_completed', {
        'level': profile.currentLevel,
      });
    } catch (e) {
      debugPrint('Error sharing progress: $e');
      AnalyticsService.instance.logEvent('share_progress_failed', {
        'error': e.toString(),
      });
    }
  }

  void _rateApp() async {
    try {
      AnalyticsService.instance.logEvent('rate_app_initiated', {});
      
      final InAppReview inAppReview = InAppReview.instance;
      
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        AnalyticsService.instance.logEvent('rate_app_review_shown', {});
      } else {
        await inAppReview.openStoreListing();
        AnalyticsService.instance.logEvent('rate_app_store_opened', {});
      }
    } catch (e) {
      debugPrint('Error requesting app review: $e');
      AnalyticsService.instance.logEvent('rate_app_failed', {
        'error': e.toString(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackgroundWidget(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: StreamBuilder<PlayerProfilePayload>(
            stream: PlayerProfileService.instance.profileStream,
            builder: (context, snapshot) {
              final profile = snapshot.data ?? this.profile;
              return CustomScrollView(
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
                                      color: AppTheme.primaryText,
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
                                  PlayerStatsWidget(profile: profile),
                                ],
                              ),
                            ),

                            // Play Button
                            Container(
                              margin: EdgeInsets.only(bottom: 4.h),
                              child: PlayButtonWidget(profile: profile),
                            ),

                            // Level Progress
                            Container(
                              margin: EdgeInsets.only(bottom: 4.h),
                              child: LevelProgressWidget(profile: profile),
                            ),

                            // Daily Challenge
                            if (_dailyChallenge != null)
                              Container(
                                margin: EdgeInsets.only(bottom: 4.h),
                                child: DailyChallengeWidget(
                                  challenge: _dailyChallenge!,
                                  timeRemaining: _dailyChallengeTimeRemaining,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DailyChallengeScreen(
                                          challenge: _dailyChallenge!,
                                        ),
                                      ),
                                    );
                                  },
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
                                      color: AppTheme.primaryText,
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
              );
            },
          ),
        ),
      ),
    );
  }
}