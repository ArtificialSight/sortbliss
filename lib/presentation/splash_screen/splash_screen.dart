import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  String _loadingText = 'Initializing...';
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Hide status bar for full-screen experience
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

      // Simulate initialization steps
      await _performInitializationSteps();

      // Navigate based on user state
      await _navigateToNextScreen();
    } catch (e) {
      _handleInitializationError();
    }
  }

  Future<void> _performInitializationSteps() async {
    final steps = [
      {'text': 'Loading user progress...', 'duration': 600},
      {'text': 'Initializing game systems...', 'duration': 500},
      {'text': 'Preparing first level...', 'duration': 400},
      {'text': 'Ready to play!', 'duration': 300},
    ];

    for (int i = 0; i < steps.length; i++) {
      if (mounted) {
        setState(() {
          _loadingText = steps[i]['text'] as String;
          _loadingProgress = (i + 1) / steps.length;
        });
      }

      await Future.delayed(Duration(milliseconds: steps[i]['duration'] as int));
    }

    // Add haptic feedback on completion
    HapticFeedback.lightImpact();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Restore system UI before navigation
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // Navigate to main menu (assuming returning user for demo)
      Navigator.pushReplacementNamed(context, '/main-menu');
    }
  }

  void _handleInitializationError() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingText = 'Something went wrong. Tap to retry.';
      });
    }
  }

  void _retryInitialization() {
    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.lightTheme.colorScheme.primary,
              AppTheme.lightTheme.colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildLogo(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: _buildLoadingSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80.w,
      height: 25.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20.w,
            height: 10.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'sort',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 12.w,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'SortBliss',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Organize & Relax',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _isLoading ? _buildLoadingIndicator() : _buildRetryButton(),
          SizedBox(height: 2.h),
          Text(
            _loadingText,
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        Container(
          width: 60.w,
          height: 0.8.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          width: 6.w,
          height: 6.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: _retryInitialization,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'refresh',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Retry',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
