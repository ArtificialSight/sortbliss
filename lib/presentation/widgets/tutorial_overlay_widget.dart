import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/tutorial_service.dart';
import '../../core/services/animation_coordinator.dart';
import '../../core/theme/app_theme.dart';

/// Tutorial overlay widget showing interactive tutorials
///
/// Features:
/// - Darkened background with spotlight on target
/// - Animated pointer/arrow to target
/// - Tutorial text with instructions
/// - Skip and Continue buttons
/// - Pulse animation on target area
class TutorialOverlayWidget extends StatefulWidget {
  final int stage;
  final Offset? targetPosition;
  final Size? targetSize;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const TutorialOverlayWidget({
    Key? key,
    required this.stage,
    this.targetPosition,
    this.targetSize,
    this.onComplete,
    this.onSkip,
  }) : super(key: key);

  @override
  State<TutorialOverlayWidget> createState() => _TutorialOverlayWidgetState();
}

class _TutorialOverlayWidgetState extends State<TutorialOverlayWidget>
    with SingleTickerProviderStateMixin {
  final TutorialService _tutorial = TutorialService.instance;
  final AnimationCoordinator _animator = AnimationCoordinator.instance;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _tutorial.getTutorialContent(widget.stage);

    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          // Spotlight on target (if provided)
          if (widget.targetPosition != null && widget.targetSize != null)
            _buildSpotlight(),

          // Animated pointer (if target provided)
          if (widget.targetPosition != null) _buildPointer(),

          // Tutorial content
          _buildContent(content),

          // Skip button
          Positioned(
            top: 6.h,
            right: 4.w,
            child: TextButton(
              onPressed: () async {
                await _animator.buttonPress();
                await _tutorial.skipTutorial();
                widget.onSkip?.call();
              },
              child: Text(
                'Skip Tutorial',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlight() {
    return Positioned(
      left: widget.targetPosition!.dx - (widget.targetSize!.width / 2),
      top: widget.targetPosition!.dy - (widget.targetSize!.height / 2),
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: widget.targetSize!.width,
          height: widget.targetSize!.height,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(2.w),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointer() {
    // Calculate pointer position (below or above target)
    final screenHeight = MediaQuery.of(context).size.height;
    final isAbove = widget.targetPosition!.dy > screenHeight / 2;

    return Positioned(
      left: widget.targetPosition!.dx - 4.w,
      top: isAbove
          ? widget.targetPosition!.dy - 15.h
          : widget.targetPosition!.dy + 10.h,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Transform.rotate(
          angle: isAbove ? 3.14 : 0, // 180 degrees if above
          child: Icon(
            Icons.arrow_downward,
            size: 8.w,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TutorialContent content) {
    return Positioned(
      bottom: 15.h,
      left: 6.w,
      right: 6.w,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stage indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  width: 2.w,
                  height: 2.w,
                  decoration: BoxDecoration(
                    color: index < widget.stage
                        ? AppTheme.lightTheme.primaryColor
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Title
            Text(
              content.title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Description
            Text(
              content.description,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: () async {
                  await _animator.buttonPress();
                  await _completeStage();
                  widget.onComplete?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                ),
                child: Text(
                  content.actionText,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeStage() async {
    switch (widget.stage) {
      case 1:
        await _tutorial.completeStage1();
        break;
      case 2:
        await _tutorial.completeStage2();
        break;
      case 3:
        await _tutorial.completeStage3();
        break;
      case 4:
        await _tutorial.completeStage4();
        break;
      case 5:
        await _tutorial.completeStage5();
        break;
      case 6:
        await _tutorial.completeStage6();
        break;
    }
  }
}

/// Simple tutorial tooltip widget (non-intrusive)
class TutorialTooltip extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const TutorialTooltip({
    Key? key,
    required this.message,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 5.w,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Contextual hint widget (appears as needed)
class ContextualHint extends StatefulWidget {
  final String hint;
  final Duration displayDuration;

  const ContextualHint({
    Key? key,
    required this.hint,
    this.displayDuration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  State<ContextualHint> createState() => _ContextualHintState();
}

class _ContextualHintState extends State<ContextualHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            // Notify parent to remove widget
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
          borderRadius: BorderRadius.circular(3.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: Colors.white,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                widget.hint,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
