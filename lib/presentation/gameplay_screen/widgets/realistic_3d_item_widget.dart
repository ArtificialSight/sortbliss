import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;

import '../../../core/game_items_data.dart';

class Realistic3DItemWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(String itemId) onDragStarted;
  final Function(String itemId) onDragEnd;
  final bool isInContainer;
  final bool enableTutorialMode;

  const Realistic3DItemWidget({
    Key? key,
    required this.item,
    required this.onDragStarted,
    required this.onDragEnd,
    this.isInContainer = false,
    this.enableTutorialMode = false,
  }) : super(key: key);

  @override
  State<Realistic3DItemWidget> createState() => _Realistic3DItemWidgetState();
}

class _Realistic3DItemWidgetState extends State<Realistic3DItemWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _bounceController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _bounceAnimation;

  bool _isDragging = false;
  Map<String, dynamic>? _visualProperties;

  @override
  void initState() {
    super.initState();
    _visualProperties = GameItemsData.get3DVisualProperties(widget.item);
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Continuous rotation for 3D effect
    _rotationController = AnimationController(
      duration: Duration(seconds: 6 + (widget.item['id'].hashCode % 4)),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Pulse effect for attracting attention
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Glow effect for modern 3D look
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Bounce animation for drag feedback
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    // Start continuous rotation - reduced during tutorial
    if (widget.enableTutorialMode) {
      _rotationController.duration = Duration(seconds: 12); // Slower rotation
    }
    _rotationController.repeat();

    // Start glow effect if enabled
    if (_visualProperties?['glowEffect'] == true &&
        !widget.enableTutorialMode) {
      _glowController.repeat(reverse: true);
    }

    // Start pulse animation if enabled
    if (_visualProperties?['pulseAnimation'] == true) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _triggerBounce() {
    _bounceController.reset();
    _bounceController.forward().then((_) {
      if (mounted) {
        _bounceController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemSize = widget.isInContainer ? 8.w : 14.w;
    final emoji = widget.item['emoji'] as String? ?? '📦';
    final color = Color(widget.item['color'] as int? ?? 0xFF718096);
    final scale = _visualProperties?['scale'] ?? 1.0;
    final shadowIntensity = _visualProperties?['shadowIntensity'] ?? 0.5;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotationAnimation,
        _pulseAnimation,
        _glowAnimation,
        _bounceAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: (_isDragging ? 1.2 : 1.0) *
              _bounceAnimation.value *
              (widget.enableTutorialMode ? 1.0 : _pulseAnimation.value) *
              scale,
          child: Transform.rotate(
            angle: widget.enableTutorialMode
                ? _rotationAnimation.value *
                    0.05 // More subtle rotation in tutorial
                : _rotationAnimation.value * 0.1,
            child: Draggable<Map<String, dynamic>>(
              data: widget.item,
              maxSimultaneousDrags: 1, // Prevent multi-drag issues in tutorial
              // CRITICAL FIX: Enhanced tutorial mode drag behavior
              dragAnchorStrategy: widget.enableTutorialMode
                  ? childDragAnchorStrategy // Use child position for better tutorial UX
                  : pointerDragAnchorStrategy,
              // CRITICAL FIX: Enhanced tutorial drag detection
              hitTestBehavior: widget.enableTutorialMode
                  ? HitTestBehavior
                      .deferToChild // More precise hit testing in tutorial
                  : HitTestBehavior.opaque,
              onDragStarted: () {
                setState(() {
                  _isDragging = true;
                });
                _triggerBounce();
                // CRITICAL FIX: Enhanced haptic feedback for tutorial
                if (widget.enableTutorialMode) {
                  HapticFeedback
                      .heavyImpact(); // Strongest feedback for tutorial
                } else {
                  HapticFeedback.lightImpact();
                }
                widget.onDragStarted(widget.item['id'] as String);
              },
              onDragEnd: (details) {
                setState(() {
                  _isDragging = false;
                });
                widget.onDragEnd(widget.item['id'] as String);
              },
              // CRITICAL FIX: Enhanced feedback widget for tutorial
              feedback: Material(
                color: Colors.transparent,
                elevation: widget.enableTutorialMode
                    ? 20 // Maximum elevation for tutorial visibility
                    : 8,
                child: _build3DContainer(
                  emoji: emoji,
                  color: color,
                  size: itemSize *
                      (widget.enableTutorialMode
                          ? 1.3 // Even larger in tutorial for better visibility
                          : 1.1),
                  shadowIntensity:
                      shadowIntensity * (widget.enableTutorialMode ? 4.0 : 2.0),
                  isDragging: true,
                  scale: scale,
                ),
              ),
              childWhenDragging: _build3DContainer(
                emoji: emoji,
                color: Colors.grey.withValues(
                    alpha: widget.enableTutorialMode
                        ? 0.7
                        : 0.3), // More visible in tutorial
                size: itemSize,
                shadowIntensity: 0.2,
                isDragging: false,
                scale: scale * 0.8,
                isGhost: true,
              ),
              child: GestureDetector(
                // CRITICAL FIX: Enhanced tap detection for tutorial
                behavior: widget.enableTutorialMode
                    ? HitTestBehavior.opaque // Ensure tap detection in tutorial
                    : HitTestBehavior.deferToChild,
                onTap: () {
                  _triggerBounce();
                  // Enhanced tutorial mode tap feedback
                  if (widget.enableTutorialMode) {
                    HapticFeedback.mediumImpact(); // Stronger tap feedback
                  } else {
                    HapticFeedback.selectionClick();
                  }
                },
                child: _build3DContainer(
                  emoji: emoji,
                  color: color,
                  size: itemSize,
                  shadowIntensity: shadowIntensity,
                  isDragging: false,
                  scale: scale,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _build3DContainer({
    required String emoji,
    required Color color,
    required double size,
    required double shadowIntensity,
    required bool isDragging,
    required double scale,
    bool isGhost = false,
  }) {
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isGhost
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.9),
                  color,
                  color.withValues(
                    red: (color.red * 0.8).clamp(0, 255),
                    green: (color.green * 0.8).clamp(0, 255),
                    blue: (color.blue * 0.8).clamp(0, 255),
                  ),
                ],
              ),
        color: isGhost ? Colors.grey.withValues(alpha: 0.3) : null,
        border: isGhost
            ? Border.all(
                color: Colors.grey.withValues(alpha: 0.5),
                width: 2,
                style: BorderStyle.solid,
              )
            : (widget.enableTutorialMode && !isGhost
                ? Border.all(
                    color: Colors.yellow.withValues(alpha: 0.6),
                    width: 2,
                  )
                : null),
        boxShadow: [
          // Enhanced main shadow for tutorial mode
          BoxShadow(
            color: Colors.black.withValues(
                alpha:
                    shadowIntensity * (widget.enableTutorialMode ? 0.4 : 0.3)),
            blurRadius: isDragging ? 25 : (widget.enableTutorialMode ? 15 : 12),
            offset: Offset(
                0, isDragging ? 10 : (widget.enableTutorialMode ? 8 : 6)),
            spreadRadius: isDragging ? 3 : (widget.enableTutorialMode ? 1 : 0),
          ),
          // Colored shadow for 3D effect
          if (!isGhost)
            BoxShadow(
              color: color.withValues(alpha: shadowIntensity * 0.4),
              blurRadius: isDragging ? 18 : 10,
              offset: Offset(0, isDragging ? 8 : 5),
              spreadRadius: -2,
            ),
          // Tutorial mode glow effect
          if (widget.enableTutorialMode && !isGhost)
            BoxShadow(
              color: Colors.yellow.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 0),
              spreadRadius: 2,
            ),
          // Glow effect for non-tutorial mode
          if (_visualProperties?['glowEffect'] == true &&
              !isGhost &&
              !widget.enableTutorialMode)
            BoxShadow(
              color: color.withValues(alpha: _glowAnimation.value * 0.5),
              blurRadius: 25,
              offset: const Offset(0, 0),
              spreadRadius: 3,
            ),
        ],
      ),
      child: Stack(
        children: [
          // Background gradient overlay for depth
          if (!isGhost)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),

          // Main emoji content with enhanced tutorial visibility
          Center(
            child: Transform.rotate(
              angle: (_visualProperties?['rotation'] ?? 0) * math.pi / 180,
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: (widget.isInContainer ? 18.sp : 24.sp) *
                      (widget.enableTutorialMode ? 1.1 : 1.0),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                    // Extra shadow for tutorial mode
                    if (widget.enableTutorialMode)
                      Shadow(
                        color: Colors.yellow.withValues(alpha: 0.5),
                        offset: const Offset(0, 0),
                        blurRadius: 8,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Enhanced highlight effect for tutorial mode
          if (!isGhost)
            Positioned(
              top: 2,
              left: 2,
              right: size * 0.3,
              child: Container(
                height: size * 0.3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(
                          alpha: widget.enableTutorialMode ? 0.6 : 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
