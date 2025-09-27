import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../core/premium_audio_manager.dart';
import '../../../core/haptic_manager.dart';
import '../../../core/gesture_controller.dart';
import '../user_speed_classifier.dart';

class AdaptiveTutorialWidget extends StatefulWidget {
  final int currentLevel;
  final bool isFirstTime;
  final double userSpeed;
  final List<String> completedActions;
  final Function(String) onActionCompleted;
  final Function() onTutorialCompleted;

  const AdaptiveTutorialWidget({
    Key? key,
    required this.currentLevel,
    required this.isFirstTime,
    required this.userSpeed,
    required this.completedActions,
    required this.onActionCompleted,
    required this.onTutorialCompleted,
  }) : super(key: key);

  @override
  State<AdaptiveTutorialWidget> createState() => _AdaptiveTutorialWidgetState();
}

class _AdaptiveTutorialWidgetState extends State<AdaptiveTutorialWidget>
    with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late AnimationController _highlightController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  late Animation<double> _overlayAnimation;
  late Animation<double> _highlightAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textScaleAnimation;

  final PremiumAudioManager _audioManager = PremiumAudioManager();
  final HapticManager _hapticManager = HapticManager();
  final GestureController _gestureController = GestureController();

  int _currentStepIndex = 0;
  bool _isVisible = true;
  bool _voiceEnabled = true;
  bool _isWaitingForAction = false;
  double _adaptiveDelay = 1.0; // Adaptive delay based on user speed

  List<Map<String, dynamic>> _tutorialSteps = [];

  @override
  void initState() {
    super.initState();
    _calculateAdaptiveDelay();
    _generateTutorialSteps();
    _initializeAnimations();
    _startTutorial();
  }

  void _calculateAdaptiveDelay() {
    // Adapt tutorial speed to user's demonstrated speed
    _adaptiveDelay = calculateAdaptiveDelay(widget.userSpeed);
  }

  void _generateTutorialSteps() {
    if (widget.isFirstTime) {
      _tutorialSteps = [
        {
          'id': 'welcome',
          'title': 'Welcome to Sort Bliss!',
          'description': 'Let\'s learn how to play this amazing sorting game.',
          'voiceText': 'Welcome to Sort Bliss! Let\'s learn how to play.',
          'highlightArea': null,
          'waitForAction': false,
          'duration': 3.0,
        },
        {
          'id': 'drag_item',
          'title': 'Drag Items',
          'description':
              'Touch and drag an item from the bottom area to sort it.',
          'voiceText':
              'Touch and drag an item to sort it into the correct container.',
          'highlightArea': 'items_area',
          'waitForAction': true,
          'gesture': 'drag',
        },
        {
          'id': 'match_category',
          'title': 'Match Categories',
          'description': 'Drop items in containers with matching categories.',
          'voiceText':
              'Great! Now drop it in the container that matches its category.',
          'highlightArea': 'containers',
          'waitForAction': true,
          'gesture': 'drop',
        },
        {
          'id': 'watch_feedback',
          'title': 'Visual Feedback',
          'description': 'Watch for sparkles and sounds when you\'re correct!',
          'voiceText':
              'Perfect! Notice the sparkles and sounds when you sort correctly.',
          'highlightArea': null,
          'waitForAction': false,
          'duration': 2.5,
        },
        {
          'id': 'try_again',
          'title': 'Keep Practicing',
          'description': 'Try sorting a few more items to get comfortable.',
          'voiceText': 'Now try sorting a few more items to get comfortable.',
          'highlightArea': 'items_area',
          'waitForAction': true,
          'requiredActions': 3,
        },
        {
          'id': 'completion',
          'title': 'You\'re Ready!',
          'description': 'Excellent work! You\'re ready to play on your own.',
          'voiceText':
              'Excellent work! You\'re ready to play Sort Bliss on your own.',
          'highlightArea': null,
          'waitForAction': false,
          'duration': 2.0,
        },
      ];
    } else {
      // Advanced tutorial for returning players or new features
      _tutorialSteps = _generateAdvancedSteps();
    }
  }

  List<Map<String, dynamic>> _generateAdvancedSteps() {
    List<Map<String, dynamic>> steps = [];

    // Check for new features to introduce
    if (widget.currentLevel >= 5 &&
        !widget.completedActions.contains('voice_commands')) {
      steps.add({
        'id': 'voice_commands',
        'title': 'Voice Commands',
        'description': 'Say "hint" for help or "pause" to pause the game.',
        'voiceText':
            'You can now use voice commands! Say hint for help or pause to pause.',
        'highlightArea': null,
        'waitForAction': false,
        'duration': 3.0,
      });
    }

    if (widget.currentLevel >= 10 &&
        !widget.completedActions.contains('tilt_controls')) {
      steps.add({
        'id': 'tilt_controls',
        'title': 'Tilt Controls',
        'description': 'Tilt your device to highlight different containers.',
        'voiceText':
            'Try tilting your device to highlight different containers.',
        'highlightArea': 'containers',
        'waitForAction': true,
        'gesture': 'tilt',
      });
    }

    return steps;
  }

  void _initializeAnimations() {
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: (1000 * _adaptiveDelay).round()),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOut,
    ));

    _highlightAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _textScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startTutorial() {
    _overlayController.forward();
    _showCurrentStep();
  }

  void _showCurrentStep() {
    if (_currentStepIndex >= _tutorialSteps.length) {
      _completeTutorial();
      return;
    }

    final step = _tutorialSteps[_currentStepIndex];

    setState(() {
      _isWaitingForAction = step['waitForAction'] ?? false;
    });

    // Play voice narration if enabled
    if (_voiceEnabled && step['voiceText'] != null) {
      _gestureController.announceGameEvent(step['voiceText']);
    }

    // Start animations
    _textController.forward();
    if (step['highlightArea'] != null) {
      _highlightController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
    }

    // Auto-advance if not waiting for action
    if (!_isWaitingForAction) {
      final duration = step['duration'] ?? 2.0;
      Future.delayed(Duration(seconds: (duration * _adaptiveDelay).round()),
          () {
        if (mounted) _nextStep();
      });
    }

    _hapticManager.lightTap();
  }

  void _nextStep() {
    _textController.reset();
    _highlightController.stop();
    _highlightController.reset();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _currentStepIndex++;
    });

    _showCurrentStep();
  }

  void _completeTutorial() {
    _overlayController.reverse().then((_) {
      widget.onTutorialCompleted();
    });

    // Play completion sound and haptic
    _audioManager.playEnhancedSuccessSound(1, 3);
    _hapticManager.celebrationImpact();
  }

  void _skipTutorial() {
    _completeTutorial();
  }

  void _toggleVoice() {
    setState(() {
      _voiceEnabled = !_voiceEnabled;
    });
    _gestureController.setTtsEnabled(_voiceEnabled);
  }

  // Called by parent when user performs expected action
  void onUserAction(String actionType) {
    if (!_isWaitingForAction) return;

    final currentStep = _tutorialSteps[_currentStepIndex];
    final expectedGesture = currentStep['gesture'] as String?;

    if (expectedGesture == null || expectedGesture == actionType) {
      widget.onActionCompleted(currentStep['id']);
      _nextStep();
    }
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _highlightController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _currentStepIndex >= _tutorialSteps.length) {
      return const SizedBox.shrink();
    }

    final currentStep = _tutorialSteps[_currentStepIndex];

    return AnimatedBuilder(
      animation: Listenable.merge([
        _overlayAnimation,
        _textScaleAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return Stack(
          children: [
            // Semi-transparent overlay
            Container(
              color: Colors.black.withOpacity(_overlayAnimation.value),
              width: double.infinity,
              height: double.infinity,
            ),

            // Highlight area (if specified)
            if (currentStep['highlightArea'] != null)
              _buildHighlightArea(currentStep['highlightArea']),

            // Tutorial content
            Positioned(
              top: 15.h,
              left: 5.w,
              right: 5.w,
              child: Transform.scale(
                scale: _textScaleAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.lightTheme.primaryColor
                            .withOpacity(0.95),
                        AppTheme.lightTheme.primaryColor
                            .withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with step counter
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Step ${_currentStepIndex + 1}/${_tutorialSteps.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Voice toggle
                          GestureDetector(
                            onTap: _toggleVoice,
                            child: Icon(
                              _voiceEnabled
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                              color: Colors.white.withOpacity(0.8),
                              size: 6.w,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          // Skip button
                          GestureDetector(
                            onTap: _skipTutorial,
                            child: Icon(
                              Icons.skip_next,
                              color: Colors.white.withOpacity(0.8),
                              size: 6.w,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 3.h),

                      // Title
                      Text(
                        currentStep['title'] ?? '',
                        style: AppTheme.lightTheme.textTheme.headlineSmall
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      SizedBox(height: 2.h),

                      // Description
                      Text(
                        currentStep['description'] ?? '',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ).animate().slideX(
                            begin: -0.3,
                            delay: 400.ms,
                            duration: 600.ms,
                          ),

                      // Progress indicator for waiting actions
                      if (_isWaitingForAction) ...[
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            SizedBox(
                              width: 6.w,
                              height: 6.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Waiting for your action...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12.sp,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ).animate().slideY(
                    begin: -0.5,
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),

            // Floating hint for gesture areas
            if (currentStep['highlightArea'] != null && _isWaitingForAction)
              _buildGestureHint(currentStep),
          ],
        );
      },
    );
  }

  Widget _buildHighlightArea(String area) {
    Offset position = Offset.zero;
    Size size = Size.zero;

    switch (area) {
      case 'items_area':
        position = Offset(5.w, 70.h);
        size = Size(90.w, 25.h);
        break;
      case 'containers':
        position = Offset(5.w, 15.h);
        size = Size(90.w, 50.h);
        break;
      default:
        return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.yellow.withOpacity(0.8 * _highlightAnimation.value,
                  ),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5 * _highlightAnimation.value,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGestureHint(Map<String, dynamic> step) {
    final gesture = step['gesture'] as String?;
    if (gesture == null) return const SizedBox.shrink();

    IconData icon = Icons.touch_app;
    String hintText = 'Tap here';

    switch (gesture) {
      case 'drag':
        icon = Icons.open_with;
        hintText = 'Drag from here';
        break;
      case 'drop':
        icon = Icons.place;
        hintText = 'Drop here';
        break;
      case 'tilt':
        icon = Icons.screen_rotation;
        hintText = 'Tilt device';
        break;
    }

    return Positioned(
      bottom: 35.h,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade600,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 6.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      hintText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(delay: 1000.ms);
  }
}
