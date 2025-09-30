import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../core/services/daily_challenge_service.dart';
import '../../core/services/player_profile_service.dart';
import '../../core/services/analytics_service.dart';
import '../../theme/app_theme.dart';
import '../daily_challenge/daily_challenge_screen.dart';
import '../achievements/achievements_screen.dart';
import './widgets/animated_background_widget.dart';
import './widgets/daily_challenge_widget.dart';
import './widgets/level_progress_widget.dart';
import './widgets/menu_action_button_widget.dart';
import './widgets/play_button_widget.dart';
import './widgets/player_stats_widget.dart';

// Simple player profile data class
class PlayerProfile {
  final int currentLevel;
  final double totalScore;
  final List<String> achievements;
  final double progressPercentage;
  final int coinsEarned;
  final int currentStreak;
  final int levelsCompleted;

  const PlayerProfile({
    this.currentLevel = 1,
    this.totalScore = 0.0,
    this.achievements = const [],
    this.progressPercentage = 0.0,
    this.coinsEarned = 0,
    this.currentStreak = 0,
    this.levelsCompleted = 0,
  });
}

// Simple daily challenge data class
class DailyChallenge {
  final String title;
  final String description;
  final int targetScore;
  final bool isCompleted;

  const DailyChallenge({
    required this.title,
    required this.description,
    this.targetScore = 1000,
    this.isCompleted = false,
  });
}

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Simplified profile management
  PlayerProfile profile = const PlayerProfile();
  DailyChallenge? dailyChallenge;
  Duration? dailyChallengeTimeRemaining;
  Timer? _timer;

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
    
    _initializeProfile();
    _refreshDailyChallenge();
    _startTimer();
  }

  void _initializeProfile() {
    // Initialize with default values
    setState(() {
      profile = const PlayerProfile(
        currentLevel: 1,
        totalScore: 0.0,
        achievements: [],
        progressPercentage: 0.0,
        coinsEarned: 0,
        currentStreak: 0,
        levelsCompleted: 0,
      );
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        // Update time remaining for daily challenge
        setState(() {
          dailyChallengeTimeRemaining = Duration(
            hours: 23 - DateTime.now().hour,
            minutes: 59 - DateTime.now().minute,
            seconds: 59 - DateTime.now().second,
          );
        });
      }
    });
  }

  void _refreshDailyChallenge() {
    setState(() {
      dailyChallenge = const DailyChallenge(
        title: 'Daily Challenge',
        description: 'Complete 5 levels today',
        targetScore: 1000,
        isCompleted: false,
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _timer?.cancel();
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
          'Total Score: ${profile.totalScore.toStringAsFixed(0)} points\n'
          'Achievements Unlocked: ${profile.achievements.length}\n\n'
          'Can you beat my score? Download SortBliss now! 🚀';
      await Share.share(message, subject: 'Check out my SortBliss progress!');
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
                              Navigator.pushNamed(context, '/gameplay');
                            },
                          ),
                        ),
                        // Level Progress
                        Container(
                          margin: EdgeInsets.only(bottom: 4.h),
                          child: LevelProgressWidget(
                            currentLevel: profile.currentLevel,
                            progressPercentage: profile.progressPercentage,
                            isLoading: false,
                          ),
                        ),
                        // Daily Challenge
                        if (dailyChallenge != null)
                          Container(
                            margin: EdgeInsets.only(bottom: 4.h),
                            child: DailyChallengeWidget(
                              initialChallenge: dailyChallenge!,
                              service: DailyChallengeService(),
                              args: const {},
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DailyChallengeScreen(
                                      challenge: dailyChallenge!,
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
