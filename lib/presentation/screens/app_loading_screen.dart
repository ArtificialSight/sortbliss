import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/app_initialization_service.dart';
import '../../core/theme/app_theme.dart';

/// App loading/splash screen with initialization
///
/// Features:
/// - Branded splash screen
/// - Progress bar with step labels
/// - Error handling
/// - Smooth transitions
/// - Version display
/// - Minimum splash time for branding
///
/// Initialization Steps:
/// 1. User settings
/// 2. Analytics
/// 3. Remote config
/// 4. Coins & economy
/// 5. Achievements
/// 6. Statistics
/// 7. Power-ups
/// 8. Leaderboards
/// 9. Events
/// 10. Notifications
/// 11. Tutorials
/// 12. Health check
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({Key? key}) : super(key: key);

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  final AppInitializationService _init = AppInitializationService.instance;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  double _progress = 0.0;
  String _currentStep = 'Starting...';
  bool _hasError = false;
  String _errorMessage = '';

  static const Duration _minimumSplashTime = Duration(seconds: 2);
  final Stopwatch _splashTimer = Stopwatch();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    _splashTimer.start();

    try {
      await _init.initialize(
        onProgress: (step, progress) {
          if (mounted) {
            setState(() {
              _currentStep = step;
              _progress = progress;
            });
          }
        },
      );

      // Ensure minimum splash time for branding
      final elapsed = _splashTimer.elapsedMilliseconds;
      if (elapsed < _minimumSplashTime.inMilliseconds) {
        await Future.delayed(
          Duration(
            milliseconds:
                _minimumSplashTime.inMilliseconds - elapsed,
          ),
        );
      }

      // Navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.primaryColor,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.lightTheme.primaryColor,
                Colors.purple.shade700,
              ],
            ),
          ),
          child: _hasError ? _buildErrorState() : _buildLoadingState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // App logo/icon with pulse animation
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sort,
                  size: 30.w,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // App name
          Text(
            'SortBliss',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),

          SizedBox(height: 1.h),

          // Tagline
          Text(
            'Organize Your Mind',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
            ),
          ),

          const Spacer(flex: 1),

          // Progress indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Column(
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.w),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 1.5.h,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),

                SizedBox(height: 2.h),

                // Current step
                Text(
                  _currentStep,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),

          // Version info
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.7),
            ),
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 25.w,
              color: Colors.white,
            ),

            SizedBox(height: 4.h),

            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 2.h),

            Text(
              'Something went wrong during initialization.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Error details (debug mode)
            if (true) // TODO: Check debug mode
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withOpacity(0.8),
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            SizedBox(height: 4.h),

            // Retry button
            SizedBox(
              width: 60.w,
              height: 6.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                    _progress = 0.0;
                    _currentStep = 'Starting...';
                  });
                  _initializeApp();
                },
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Retry',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.lightTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.w),
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

/// Simpler splash screen without initialization (instant)
class SimpleSplashScreen extends StatefulWidget {
  final Duration duration;

  const SimpleSplashScreen({
    Key? key,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // Navigate after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
              AppTheme.lightTheme.primaryColor,
              Colors.purple.shade700,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sort,
                  size: 35.w,
                  color: Colors.white,
                ),
                SizedBox(height: 4.h),
                Text(
                  'SortBliss',
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
