import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../core/premium_audio_manager.dart';
import '../../../core/haptic_manager.dart';
import '../../../core/gesture_controller.dart';

class EnhancedAdaptiveTutorialWidget extends StatefulWidget {
  final int currentLevel;
  final bool isFirstTime;
  final double userSpeed;
  final List<String> completedActions;
  final Function(String) onActionCompleted;
  final Function() onTutorialCompleted;
  final Function() onTutorialDismissed;
  final bool nextStepEnabled;
  final bool dragStarted;
  final bool dropCompleted;
  final int actionsCount;

  const EnhancedAdaptiveTutorialWidget({
    Key? key,
    required this.currentLevel,
    required this.isFirstTime,
    required this.userSpeed,
    required this.completedActions,
    required this.onActionCompleted,
    required this.onTutorialCompleted,
    required this.onTutorialDismissed,
    this.nextStepEnabled = false,
    this.dragStarted = false,
    this.dropCompleted = false,
    this.actionsCount = 0,
  }) : super(key: key);

  @override
  State<EnhancedAdaptiveTutorialWidget> createState() =>
      _EnhancedAdaptiveTutorialWidgetState();
}

class _EnhancedAdaptiveTutorialWidgetState
    extends State<EnhancedAdaptiveTutorialWidget>
    with TickerProviderStateMixin {
  late AnimationController _highlightController;
  late AnimationController _pulseController;
  late AnimationController _textController;

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
  double _adaptiveDelay = 1.0;

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
    if (widget.userSpeed > 1.5) {
      _adaptiveDelay = 0.7;
    } else if (widget.userSpeed < 0.7) {
      _adaptiveDelay = 1.5;
    } else {
      _adaptiveDelay = 1.0;
    }
  }

  void _generateTutorialSteps() {
    if (widget.isFirstTime) {
      _tutorialSteps = [
        {
          'id': 'welcome',
          'title': 'Welcome to Sort Bliss!',
          'description':
              'Let\'s learn how to drag and sort items into containers.',
          'voiceText':
              'Welcome to Sort Bliss! Let\'s learn how to drag and sort items.',
          'highlightArea': null,
          'waitForAction': false,
          'duration': 3.0,
          'showCloseButton': true,
        },
        {
          'id': 'drag_item',
          'title': 'Step 2: Drag Items',
          'description':
              'Touch and drag any item from the center area. Try dragging now!',
          'voiceText':
              'Touch and drag any item from the center area to start sorting.',
          'highlightArea': 'items_area',
          'waitForAction': true,
          'gesture': 'drag',
          'showCloseButton': true,
          'actionRequired': 'drag_started',
        },
        {
          'id': 'match_category',
          'title': 'Step 3: Match Categories',
          'description':
              'Great! Now drop the item in the container that matches its type.',
          'voiceText':
              'Perfect! Now drop it in the container that matches its category.',
          'highlightArea': 'containers',
          'waitForAction': true,
          'gesture': 'drop',
          'showCloseButton': true,
          'actionRequired': 'drop_completed',
        },
        {
          'id': 'watch_feedback',
          'title': 'Visual Feedback',
          'description':
              'Excellent! Notice the sparkles and sounds when you sort correctly!',
          'voiceText':
              'Excellent! Watch for sparkles and sounds when you sort correctly.',
          'highlightArea': null,
          'waitForAction': false,
          'duration': 3.0,
          'showCloseButton': true,
        },
        {
          'id': 'try_again',
          'title': 'Practice More',
          'description':
              'Try sorting 2 more items to get comfortable with the controls.',
          'voiceText': 'Now try sorting 2 more items to practice.',
          'highlightArea': 'items_area',
          'waitForAction': true,
          'requiredActions': 2,
          'showCloseButton': true,
          'actionRequired': 'practice_completed',
        },
        {
          'id': 'completion',
          'title': 'You\'re Ready!',
          'description':
              'Perfect! You\'ve mastered the controls. Enjoy playing Sort Bliss!',
          'voiceText':
              'Perfect! You\'ve mastered Sort Bliss. Have fun playing!',
          'highlightArea': null,
          'waitForAction': false,
          'duration': 3.0,
          'showCloseButton': true,
        },
      ];
    }
  }

  void _initializeAnimations() {
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: (800 * _adaptiveDelay).round()),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _highlightAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
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

    if (_voiceEnabled && step['voiceText'] != null) {
      _gestureController.announceGameEvent(step['voiceText']);
    }

    _textController.forward();
    if (step['highlightArea'] != null) {
      _highlightController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
    }

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
    if (_canAdvanceStep()) {
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
  }

  bool _canAdvanceStep() {
    if (_currentStepIndex >= _tutorialSteps.length) return false;

    final step = _tutorialSteps[_currentStepIndex];
    final actionRequired = step['actionRequired'] as String?;

    if (actionRequired == null) return true;

    switch (actionRequired) {
      case 'drag_started':
        return widget.dragStarted;
      case 'drop_completed':
        return widget.dropCompleted;
      case 'practice_completed':
        final required = step['requiredActions'] as int? ?? 1;
        return widget.actionsCount >= required;
      default:
        return widget.nextStepEnabled;
    }
  }

  void _completeTutorial() {
    widget.onTutorialCompleted();
    _audioManager.playEnhancedSuccessSound(1, 3);
    _hapticManager.celebrationImpact();
  }

  // CRITICAL FIX: ZERO-INTERFERENCE dismissal method
  void _dismissTutorial() {
    _audioManager.playThemeTapSound('default');
    _hapticManager.lightTap();

    // CRITICAL: Instant dismissal with no interference
    widget.onTutorialDismissed();
  }

  void _toggleVoice() {
    setState(() {
      _voiceEnabled = !_voiceEnabled;
    });
    _gestureController.setTtsEnabled(_voiceEnabled);
    _hapticManager.selectionFeedback();
  }

  void onUserAction(String actionType) {
    if (!_isWaitingForAction) return;

    final currentStep = _tutorialSteps[_currentStepIndex];
    final expectedGesture = currentStep['gesture'] as String?;

    bool actionMatches = false;

    if (expectedGesture == null || expectedGesture == actionType) {
      actionMatches = true;
      widget.onActionCompleted(currentStep['id']);

      // Auto-advance for immediate actions
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _canAdvanceStep()) {
          _nextStep();
        }
      });
    }

    if (actionMatches) {
      _hapticManager.successImpact();
      _audioManager.playEnhancedSuccessSound(1, 2);
    }
  }

  @override
  void didUpdateWidget(EnhancedAdaptiveTutorialWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-advance when conditions are met
    if (_isWaitingForAction &&
        _canAdvanceStep() &&
        !oldWidget.nextStepEnabled &&
        widget.nextStepEnabled) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _nextStep();
      });
    }
  }

  @override
  void dispose() {
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
        _textScaleAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        // CRITICAL FIX: REVOLUTIONARY NON-BLOCKING APPROACH
        // Use only positioned widgets that NEVER interfere with underlying elements
        return Stack(
          // CRITICAL: clipBehavior none to prevent any clipping interference
          clipBehavior: Clip.none,
          children: [
            // CRITICAL FIX: Highlight areas that NEVER block interactions
            if (currentStep['highlightArea'] != null)
              IgnorePointer(
                ignoring: true, // CRITICAL: Always ignore ALL events
                child: _buildAbsolutelyNonBlockingHighlight(
                    currentStep['highlightArea']),
              ),

            // CRITICAL FIX: RED X BUTTON - ABSOLUTE HIGHEST PRIORITY
            // Position FIRST so it's on top of everything
            Positioned(
              // CRITICAL: Extreme positioning to ensure it's always accessible
              top: 0.5.h,
              right: 0.5.w,
              // CRITICAL: Use Container with GestureDetector for maximum responsiveness
              child: GestureDetector(
                // CRITICAL: Opaque behavior ensures all taps are caught
                behavior: HitTestBehavior.opaque,
                onTap: _dismissTutorial,
                child: Container(
                  // CRITICAL: Extra large touch area
                  width: 25.w,
                  height: 25.w,
                  // CRITICAL: Maximum padding for easier tapping
                  padding: EdgeInsets.all(5.w),
                  // No decoration that could interfere
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      // CRITICAL: Maximum visibility shadows
                      BoxShadow(
                        color: Colors.red.withOpacity(1.0),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(1.0),
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 15.w,
                  ),
                ),
              ),
            )
                .animate()
                .scale(
                  delay: 100.ms,
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn()
                .then()
                .shimmer(
                  duration: 2000.ms,
                  color: Colors.white.withOpacity(0.6),
                ),

            // CRITICAL FIX: Tutorial content that NEVER blocks
            Positioned(
              top: 12.h, // Well below close button
              left: 2.w,
              right: 28.w, // Leave massive space for close button
              child: IgnorePointer(
                ignoring: true, // CRITICAL: NEVER intercept ANY events
                child: Transform.scale(
                  scale: _textScaleAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.lightTheme.primaryColor
                            .withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Step indicator
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.primaryColor
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Step ${_currentStepIndex + 1}/${_tutorialSteps.length}',
                            style: TextStyle(
                              color: AppTheme.lightTheme.primaryColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        SizedBox(height: 3.h),

                        // Title
                        Text(
                          currentStep['title'] ?? '',
                          style: AppTheme.lightTheme.textTheme.headlineSmall
                              ?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        SizedBox(height: 2.h),

                        // Description
                        Text(
                          currentStep['description'] ?? '',
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ).animate().slideX(
                              begin: -0.3,
                              delay: 400.ms,
                              duration: 600.ms,
                            ),

                        // Action progress indicator
                        if (_isWaitingForAction) ...[
                          SizedBox(height: 3.h),
                          Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: AppTheme.lightTheme.primaryColor
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildActionStatusIcon(),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getActionStatusText(),
                                        style: TextStyle(
                                          color:
                                              AppTheme.lightTheme.primaryColor,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_getProgressText().isNotEmpty) ...[
                                        SizedBox(height: 0.5.h),
                                        Text(
                                          _getProgressText(),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().slideY(
                      begin: -0.3,
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
              ),
            ),

            // CRITICAL FIX: Gesture hints that NEVER block
            if (currentStep['highlightArea'] != null && _isWaitingForAction)
              IgnorePointer(
                ignoring: true, // CRITICAL: NEVER block interactions
                child: _buildAbsolutelyNonBlockingGestureHint(currentStep),
              ),
          ],
        );
      },
    );
  }

  // CRITICAL FIX: Completely non-blocking highlight
  Widget _buildAbsolutelyNonBlockingHighlight(String area) {
    Rect highlightRect;

    switch (area) {
      case 'items_area':
        // Highlight center pile area - NEVER the bottom where containers might be
        highlightRect = Rect.fromLTWH(5.w, 20.h, 90.w, 45.h);
        break;
      case 'containers':
        // Highlight bottom container area
        highlightRect = Rect.fromLTWH(2.w, 70.h, 96.w, 28.h);
        break;
      default:
        return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Positioned(
          left: highlightRect.left,
          top: highlightRect.top,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: highlightRect.width,
              height: highlightRect.height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.yellow.withOpacity(0.9 * _highlightAnimation.value,
                  ),
                  width: 6, // Thicker for better visibility
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.8 * _highlightAnimation.value,
                    ),
                    blurRadius: 35,
                    offset: const Offset(0, 0),
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionStatusIcon() {
    final step = _tutorialSteps[_currentStepIndex];
    final actionRequired = step['actionRequired'] as String?;

    if (actionRequired == null) {
      return Icon(
        Icons.touch_app,
        color: AppTheme.lightTheme.primaryColor,
        size: 6.w,
      );
    }

    switch (actionRequired) {
      case 'drag_started':
        return Icon(
          widget.dragStarted ? Icons.check_circle : Icons.open_with,
          color: widget.dragStarted
              ? Colors.green
              : AppTheme.lightTheme.primaryColor,
          size: 6.w,
        );
      case 'drop_completed':
        return Icon(
          widget.dropCompleted ? Icons.check_circle : Icons.place,
          color: widget.dropCompleted
              ? Colors.green
              : AppTheme.lightTheme.primaryColor,
          size: 6.w,
        );
      case 'practice_completed':
        return Icon(
          _canAdvanceStep() ? Icons.check_circle : Icons.repeat,
          color: _canAdvanceStep()
              ? Colors.green
              : AppTheme.lightTheme.primaryColor,
          size: 6.w,
        );
      default:
        return Icon(
          Icons.touch_app,
          color: AppTheme.lightTheme.primaryColor,
          size: 6.w,
        );
    }
  }

  String _getActionStatusText() {
    final step = _tutorialSteps[_currentStepIndex];
    final actionRequired = step['actionRequired'] as String?;

    if (actionRequired == null) return 'Follow the instructions above';

    switch (actionRequired) {
      case 'drag_started':
        return widget.dragStarted
            ? 'Perfect! Item dragged ✓'
            : 'Drag an item from the center';
      case 'drop_completed':
        return widget.dropCompleted
            ? 'Excellent! Item sorted ✓'
            : 'Drop the item in a container';
      case 'practice_completed':
        final required = step['requiredActions'] as int? ?? 1;
        final completed = widget.actionsCount;
        return completed >= required
            ? 'Great practice! Ready to continue ✓'
            : 'Practice sorting ($completed/$required items)';
      default:
        return 'Waiting for your action...';
    }
  }

  String _getProgressText() {
    final step = _tutorialSteps[_currentStepIndex];
    final actionRequired = step['actionRequired'] as String?;

    if (actionRequired == 'practice_completed') {
      final required = step['requiredActions'] as int? ?? 1;
      final completed = widget.actionsCount;
      if (completed < required) {
        return 'Drag ${required - completed} more item${required - completed == 1 ? '' : 's'} to continue';
      }
    }

    return '';
  }

  // CRITICAL FIX: Absolutely non-blocking gesture hint
  Widget _buildAbsolutelyNonBlockingGestureHint(Map<String, dynamic> step) {
    final gesture = step['gesture'] as String?;
    if (gesture == null) return const SizedBox.shrink();

    IconData icon = Icons.touch_app;
    String hintText = 'Tap here';

    switch (gesture) {
      case 'drag':
        icon = Icons.open_with;
        hintText = 'Drag items from here';
        break;
      case 'drop':
        icon = Icons.place;
        hintText = 'Drop items here';
        break;
    }

    return Positioned(
      bottom: step['highlightArea'] == 'items_area' ? 35.h : 15.h,
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
                  horizontal: 6.w,
                  vertical: 2.5.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.yellow.shade500,
                      Colors.orange.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.7),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 7.w,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      hintText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).then().shimmer(
          duration: 1500.ms,
          color: Colors.white.withOpacity(0.4),
        );
  }
}
