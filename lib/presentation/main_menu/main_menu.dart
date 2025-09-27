import 'dart:async';

import 'package:flutter/material.dart';
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

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late final DailyChallengeService _dailyChallengeService;
  DailyChallengePayload? _dailyChallenge;
  Duration? _dailyChallengeTimeRemaining;
  bool _loadingDailyChallenge = true;
  StreamSubscription<DailyChallengePayload>? _challengeSubscription;
  StreamSubscription<Duration>? _countdownSubscription;
  late final PlayerProfileService _profileService;
  late Future<void> _profileInitialization;

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
    _profileService = PlayerProfileService.instance;
    _profileInitialization = _profileService.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDailyChallenge();
      _profileInitialization.then((_) {
        if (!mounted) return;
        _maybeShowRatePrompt(_profileService.currentProfile);
      });
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

  void _navigateToAchievements(PlayerProfile profile) {
    Navigator.pushNamed(
      context,
      AppRoutes.achievements,
      arguments: AchievementsScreenArgs.fromProfile(profile),
    );
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, AppRoutes.settings);
  }

  Future<void> _shareProgress(PlayerProfile profile) async {
    final coins = profile.coinsEarned;
    final level = profile.currentLevel;
    final streak = profile.currentStreak;
    final message =
        'I just completed level $level in SortBliss with a $streak day streak and $coins coins earned! Can you beat my score?';

    try {
      await Share.share(message, subject: 'SortBliss Progress Update');
      await _profileService.incrementShareCount();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open share sheet: $error')),
      );
    }
  }

  void _rateApp() {
    _showRatingPrompt();
  }

  Future<void> _purchaseRemoveAds(PlayerProfile profile) async {
    if (profile.hasRemoveAdsPurchase) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ads already removed. Thank you!')),
        );
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing your Remove Ads purchase...')),
    );
    await _profileService.setRemoveAdsPurchased(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ads removed. Enjoy the uninterrupted flow!')),
    );
  }

  Future<void> _maybeShowRatePrompt(PlayerProfile profile) async {
    if (!profile.showRatePrompt) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) {
      return;
    }
    await _showRatingPrompt();
    await _profileService.markRatePromptShown();
  }

  Future<void> _showRatingPrompt() async {
    double rating = 4;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enjoying SortBliss?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Tap a star to rate your relaxation journey. We read every review!',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = rating >= starValue;
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            rating = starValue.toDouble();
                          });
                        },
                        icon: Icon(
                          isSelected ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 1.5.h),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Thank you for rating us $rating ★!'),
                              ),
                            );
                          },
                          child: const Text('Submit'),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Maybe later'),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _profileInitialization,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return ValueListenableBuilder<PlayerProfile>(
              valueListenable: _profileService.profileListenable,
              builder: (context, profile, _) {
                final recentAchievements =
                    profile.unlockedAchievements.take(3).toList(growable: false);
                final achievementsSubtitle = recentAchievements.isEmpty
                    ? 'Track your milestones'
                    : 'Recent: ${recentAchievements.join(', ')}';
                return Stack(
                  children: [
                    const AnimatedBackgroundWidget(),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await _loadDailyChallenge(forceRefresh: true);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Daily challenge updated!'),
                              ),
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
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Organize. Sort. Relax.',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.lightTheme.colorScheme
                                      .onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              SizedBox(height: 4.h),

                              // Player Stats
                              PlayerStatsWidget(
                                levelsCompleted: profile.levelsCompleted,
                                currentStreak: profile.currentStreak,
                                coinsEarned: profile.coinsEarned,
                              ),
                              SizedBox(height: 3.h),

                              // Level Progress
                              LevelProgressWidget(
                                currentLevel: profile.currentLevel,
                                progressPercentage: profile.levelProgress,
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
                                subtitle: achievementsSubtitle,
                                onPressed: () =>
                                    _navigateToAchievements(profile),
                                iconColor: Colors.orange,
                                showBadge:
                                    profile.unlockedAchievements.isNotEmpty,
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
                              SizedBox(height: 3.h),

                              if (!profile.hasRemoveAdsPurchase)
                                MenuActionButtonWidget(
                                  iconName: 'block',
                                  title: 'Remove Ads',
                                  subtitle: 'One-time purchase - \$2.99',
                                  onPressed: () {
                                    _purchaseRemoveAds(profile);
                                  },
                                  iconColor: Colors.red,
                                ),
                              if (!profile.hasRemoveAdsPurchase)
                                SizedBox(height: 3.h),

                              MenuActionButtonWidget(
                                iconName: 'share',
                                title: 'Share Progress',
                                subtitle:
                                    'Tell friends about your achievements',
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
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
