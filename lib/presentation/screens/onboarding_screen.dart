import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/services/animation_coordinator.dart';
import '../../core/theme/app_theme.dart';

/// Onboarding screen with multiple pages for first-time users
///
/// Pages:
/// 1. Welcome - App intro and branding
/// 2. Features - Key features showcase
/// 3. Tutorial - Interactive game tutorial
/// 4. Permissions - Notification permissions request
/// 5. Ready - Start playing
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboarding = OnboardingService.instance;
  final AnimationCoordinator _animator = AnimationCoordinator.instance;

  int _currentPage = 0;
  final int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < _totalPages - 1) {
      await _animator.screenTransition();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  void _skipOnboarding() async {
    await _animator.buttonPress();
    await _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await _onboarding.completeOnboarding();
    _onboarding.logOnboardingEvent('onboarding_flow_completed');

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < _totalPages - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                  _animator.uiInteraction();
                },
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _FeaturesPage(onNext: _nextPage),
                  _TutorialPage(onNext: _nextPage),
                  _PermissionsPage(onNext: _nextPage),
                  _ReadyPage(onNext: _completeOnboarding),
                ],
              ),
            ),

            // Page indicator
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => _PageIndicator(
                    isActive: index == _currentPage,
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

/// Welcome page - App intro
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    OnboardingService.instance.markWelcomeSeen();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor,
              borderRadius: BorderRadius.circular(6.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.sort,
              size: 15.w,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 6.h),

          // App name
          Text(
            'Welcome to SortBliss',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 3.h),

          // Description
          Text(
            'Master the art of sorting with satisfying puzzles that challenge your mind',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          // Next button
          _OnboardingButton(
            text: 'Get Started',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// Features page - Key features showcase
class _FeaturesPage extends StatelessWidget {
  final VoidCallback onNext;

  const _FeaturesPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    OnboardingService.instance.markFeaturesSeen();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Why You\'ll Love SortBliss',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 6.h),

          // Features list
          _FeatureItem(
            icon: Icons.emoji_events,
            title: 'Progressive Challenges',
            description: 'Unlock 200+ levels across multiple difficulty tiers',
          ),

          SizedBox(height: 4.h),

          _FeatureItem(
            icon: Icons.stars,
            title: 'Earn Rewards',
            description: 'Collect stars, coins, and achievements as you play',
          ),

          SizedBox(height: 4.h),

          _FeatureItem(
            icon: Icons.calendar_today,
            title: 'Daily Rewards',
            description: 'Come back daily for streaks and bonus rewards',
          ),

          SizedBox(height: 4.h),

          _FeatureItem(
            icon: Icons.share,
            title: 'Challenge Friends',
            description: 'Share your scores and compete for high scores',
          ),

          SizedBox(height: 8.h),

          _OnboardingButton(
            text: 'Continue',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// Tutorial page - How to play
class _TutorialPage extends StatelessWidget {
  final VoidCallback onNext;

  const _TutorialPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'How to Play',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 6.h),

          // Tutorial steps
          _TutorialStep(
            number: 1,
            title: 'Drag and Drop',
            description: 'Move pieces by dragging them to empty spaces',
          ),

          SizedBox(height: 4.h),

          _TutorialStep(
            number: 2,
            title: 'Sort Colors',
            description: 'Group same-colored pieces together to clear them',
          ),

          SizedBox(height: 4.h),

          _TutorialStep(
            number: 3,
            title: 'Earn Stars',
            description: 'Complete levels efficiently to earn up to 3 stars',
          ),

          SizedBox(height: 8.h),

          _OnboardingButton(
            text: 'Got It!',
            onPressed: () async {
              await OnboardingService.instance.completeTutorial();
              onNext();
            },
          ),
        ],
      ),
    );
  }
}

/// Permissions page - Request notifications
class _PermissionsPage extends StatelessWidget {
  final VoidCallback onNext;

  const _PermissionsPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    OnboardingService.instance.markPermissionsSeen();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              size: 10.w,
              color: AppTheme.lightTheme.primaryColor,
            ),
          ),

          SizedBox(height: 4.h),

          Text(
            'Stay Connected',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 3.h),

          Text(
            'Get reminders for daily rewards and streak bonuses',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          _OnboardingButton(
            text: 'Enable Notifications',
            onPressed: () async {
              // TODO: Request notification permission
              // final granted = await NotificationService.instance.requestPermission();
              OnboardingService.instance.logOnboardingEvent(
                'notifications_permission_requested',
              );
              onNext();
            },
          ),

          SizedBox(height: 2.h),

          TextButton(
            onPressed: () async {
              OnboardingService.instance.logOnboardingEvent(
                'notifications_permission_skipped',
              );
              await AnimationCoordinator.instance.buttonPress();
              onNext();
            },
            child: Text(
              'Maybe Later',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ready page - Start playing
class _ReadyPage extends StatelessWidget {
  final VoidCallback onNext;

  const _ReadyPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success icon
          Container(
            width: 25.w,
            height: 25.w,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 12.w,
              color: Colors.green,
            ),
          ),

          SizedBox(height: 4.h),

          Text(
            'You\'re All Set!',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 3.h),

          Text(
            'Time to start your sorting journey.\nGood luck!',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          _OnboardingButton(
            text: 'Start Playing',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// Feature item widget
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3.w),
          ),
          child: Icon(
            icon,
            size: 6.w,
            color: AppTheme.lightTheme.primaryColor,
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tutorial step widget
class _TutorialStep extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const _TutorialStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Onboarding button widget
class _OnboardingButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _OnboardingButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: () async {
          await AnimationCoordinator.instance.buttonPress();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          elevation: 2,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Page indicator dot
class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      width: isActive ? 8.w : 2.w,
      height: 2.w,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.lightTheme.primaryColor
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(1.w),
      ),
    );
  }
}
