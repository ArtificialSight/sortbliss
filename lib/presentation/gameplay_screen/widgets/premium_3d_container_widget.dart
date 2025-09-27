import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/audio_manager.dart';
import '../../../core/game_items_data.dart';
import '../../../core/haptic_manager.dart';
import '../../../theme/app_theme.dart';
import './realistic_3d_item_widget.dart';

class Premium3DContainerWidget extends StatefulWidget {
  final String containerId;
  final List<Map<String, dynamic>> items;
  final bool isHighlighted;
  final Function(String itemId, String containerId) onItemDropped;
  final Function(String containerId) onContainerTap;
  final int currentLevel;
  final String theme;
  final bool enableTutorialMode;

  const Premium3DContainerWidget({
    Key? key,
    required this.containerId,
    required this.items,
    required this.isHighlighted,
    required this.onItemDropped,
    required this.onContainerTap,
    this.currentLevel = 1,
    this.theme = 'default',
    this.enableTutorialMode = false,
  }) : super(key: key);

  @override
  State<Premium3DContainerWidget> createState() =>
      _Premium3DContainerWidgetState();
}

class _Premium3DContainerWidgetState extends State<Premium3DContainerWidget>
    with TickerProviderStateMixin {
  late AnimationController _highlightController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _lidController;
  late AnimationController _bounceController;
  late AnimationController _spinController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _lidAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _spinAnimation;
  late Animation<double> _glowAnimation;

  Map<String, dynamic>? _containerConfig;
  bool _isDraggedOver = false;
  bool _isCorrectDrop = false;
  bool _showSuccessParticles = false;
  String _containerTheme = 'default';

  final AudioManager _audioManager = AudioManager();
  final HapticManager _hapticManager = HapticManager();

  @override
  void initState() {
    super.initState();
    _containerConfig = GameItemsData.getContainerConfig(widget.containerId);
    _containerTheme = _getUnlockedTheme();
    _initializeAdvancedAnimations();
  }

  String _getUnlockedTheme() {
    if (widget.currentLevel >= 20) return 'crystal';
    if (widget.currentLevel >= 15) return 'neon';
    if (widget.currentLevel >= 10) return 'golden';
    if (widget.currentLevel >= 5) return 'metallic';
    return 'default';
  }

  void _initializeAdvancedAnimations() {
    // Enhanced highlight animation
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Breathing pulse effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Particle effects controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animated lid controller
    _lidController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Bounce animation for correct placement
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Spin animation for incorrect placement
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Glow effect controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create animations
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _lidAnimation = Tween<double>(
      begin: 0.0,
      end: -math.pi / 6, // 30 degrees open
    ).animate(CurvedAnimation(
      parent: _lidController,
      curve: Curves.easeOutBack,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi / 8, // Shake effect
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.elasticInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    final baseColor = Color(_containerConfig?['color'] ?? 0xFF718096);
    _colorAnimation = ColorTween(
      begin: baseColor,
      end: _getThemeAccentColor(),
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));

    // Start ambient glow
    _glowController.repeat(reverse: true);
  }

  Color _getThemeAccentColor() {
    switch (_containerTheme) {
      case 'crystal':
        return Colors.cyan.shade200;
      case 'neon':
        return Colors.purple.shade300;
      case 'golden':
        return Colors.amber.shade400;
      case 'metallic':
        return Colors.grey.shade400;
      default:
        return Color(_containerConfig?['color'] ?? 0xFF718096);
    }
  }

  @override
  void didUpdateWidget(Premium3DContainerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted != oldWidget.isHighlighted) {
      if (widget.isHighlighted) {
        _highlightController.forward();
        _pulseController.repeat(reverse: true);
        _lidController.forward();
        _hapticManager.lightTap();
        _audioManager.playButtonTapSound();
      } else {
        _highlightController.reverse();
        _pulseController.stop();
        _pulseController.reset();
        _lidController.reverse();
      }
    }
  }

  void _onDragEntered() {
    setState(() {
      _isDraggedOver = true;
    });
    _lidController.forward();
    _hapticManager.selectionFeedback();

    // Enhanced audio feedback for tutorial mode
    if (widget.enableTutorialMode) {
      _audioManager.playButtonTapSound(); // Clearer feedback sound
    } else {
      _audioManager.playWhooshSound();
    }
  }

  void _onDragExited() {
    setState(() {
      _isDraggedOver = false;
    });
    if (!widget.isHighlighted) {
      _lidController.reverse();
    }
  }

  void _onItemAccepted(Map<String, dynamic> item) {
    final isCorrect =
        GameItemsData.itemBelongsToCategory(item, widget.containerId);

    setState(() {
      _isCorrectDrop = isCorrect;
      _showSuccessParticles = isCorrect;
    });

    if (isCorrect) {
      // Enhanced success animation sequence for tutorial
      _bounceController.forward().then((_) {
        _bounceController.reset();
      });
      _lidController.forward().then((_) {
        Future.delayed(
            Duration(milliseconds: widget.enableTutorialMode ? 400 : 200), () {
          _lidController.reverse();
        });
      });

      // Enhanced success feedback for tutorial
      if (widget.enableTutorialMode) {
        _audioManager.playSparkleSound(); // More celebratory sound
        _hapticManager.celebrationImpact(); // Stronger haptic
      } else {
        _audioManager.playSuccessSound();
        _hapticManager.successImpact();
      }
    } else {
      // Enhanced error animation sequence
      _spinController.forward().then((_) {
        _spinController.reverse();
      });

      _audioManager.playDropSound();
      _hapticManager.errorFeedback();
    }

    _particleController.forward().then((_) {
      _particleController.reset();
      setState(() {
        _showSuccessParticles = false;
      });
    });

    widget.onItemDropped(item['id'] as String, widget.containerId);
  }

  @override
  void dispose() {
    _highlightController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _lidController.dispose();
    _bounceController.dispose();
    _spinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerName = _containerConfig?['name'] ?? 'Container';
    final containerEmoji = _containerConfig?['emoji'] ?? '📦';
    final gradientColors = _getThemeGradient();
    final description = _containerConfig?['description'] ?? 'Sort items here';

    return GestureDetector(
      // CRITICAL FIX: Enhanced tap behavior for tutorial
      behavior: widget.enableTutorialMode
          ? HitTestBehavior.opaque // Ensure all taps are detected in tutorial
          : HitTestBehavior.deferToChild,
      onTap: () {
        widget.onContainerTap(widget.containerId);
        HapticFeedback.selectionClick();
      },
      child: Tilt(
        borderRadius: BorderRadius.circular(20),
        disable:
            widget.enableTutorialMode, // Disable tilt effects during tutorial
        lightConfig: const LightConfig(
          disable: false,
          color: Colors.white,
          minIntensity: 0.1,
          maxIntensity: 0.8,
        ),
        shadowConfig: ShadowConfig(
          disable: false,
          color: _getThemeAccentColor(),
          minIntensity: 0.05,
          maxIntensity: 0.4,
        ),
        tiltConfig: const TiltConfig(
          angle: 10,
          enableReverse: true,
          filterQuality: FilterQuality.high,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _pulseAnimation,
            _colorAnimation,
            _bounceAnimation,
            _spinAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value *
                  (widget.enableTutorialMode ? 1.0 : _pulseAnimation.value) *
                  _bounceAnimation.value,
              child: Transform.rotate(
                angle: _spinAnimation.value,
                child: DragTarget<Map<String, dynamic>>(
                  onWillAcceptWithDetails: (data) => data.data != null,
                  onAcceptWithDetails: (data) => _onItemAccepted(data.data),
                  // CRITICAL FIX: Enhanced tutorial mode drag target behavior
                  hitTestBehavior: widget.enableTutorialMode
                      ? HitTestBehavior
                          .opaque // Always accept drags in tutorial
                      : HitTestBehavior.deferToChild,
                  onMove: (_) {
                    _onDragEntered();
                    // CRITICAL FIX: Extra haptic feedback for tutorial mode
                    if (widget.enableTutorialMode) {
                      HapticFeedback.mediumImpact(); // Stronger feedback
                    }
                  },
                  onLeave: (_) => _onDragExited(),
                  builder: (context, candidateData, rejectedData) {
                    final isActive = candidateData.isNotEmpty || _isDraggedOver;

                    return Container(
                      width: 38.w,
                      height: 30.h,
                      margin:
                          EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        border: Border.all(
                          color: (widget.isHighlighted || _isDraggedOver)
                              ? _getThemeAccentColor()
                              : (widget.enableTutorialMode
                                  ? Colors.yellow.withOpacity(0.9) // Brighter border for tutorial
                                  : Colors.transparent),
                          width: (widget.isHighlighted || _isDraggedOver)
                              ? 4 // Thicker highlight border
                              : (widget.enableTutorialMode
                                  ? 4 // Thick tutorial border
                                  : 0),
                        ),
                        boxShadow: [
                          // CRITICAL FIX: Enhanced shadow for tutorial visibility
                          BoxShadow(
                            color: _getThemeAccentColor().withOpacity(widget.enableTutorialMode
                                    ? 0.7 // Much stronger shadow
                                    : 0.3),
                            blurRadius: (widget.isHighlighted || isActive)
                                ? 40 // Maximum blur for tutorial
                                : (widget.enableTutorialMode ? 30 : 15),
                            offset: const Offset(0, 12),
                            spreadRadius: (widget.isHighlighted || isActive)
                                ? 8 // Maximum spread for tutorial
                                : (widget.enableTutorialMode ? 5 : 1),
                          ),
                          // CRITICAL FIX: Enhanced tutorial mode highlight
                          if (widget.enableTutorialMode)
                            BoxShadow(
                              color: Colors.yellow.withOpacity(0.6), // Much stronger yellow glow
                              blurRadius: 35,
                              offset: const Offset(0, 0),
                              spreadRadius: 6,
                            ),
                          // Enhanced active drag feedback for tutorial
                          if (isActive && widget.enableTutorialMode)
                            BoxShadow(
                              color: Colors.green
                                  .withOpacity(0.8), // Maximum feedback
                              blurRadius: 30,
                              offset: const Offset(0, 0),
                              spreadRadius: 5,
                            ),
                          // Ambient glow effect
                          if ((widget.isHighlighted || _isDraggedOver) &&
                              !widget.enableTutorialMode)
                            BoxShadow(
                              color: _getThemeAccentColor().withOpacity(0.5 * _glowAnimation.value,
                              ),
                              blurRadius: 30,
                              offset: const Offset(0, 0),
                              spreadRadius: 5,
                            ),
                          // Enhanced tutorial mode highlight
                          if (widget.enableTutorialMode)
                            BoxShadow(
                              color: Colors.yellow.withOpacity(0.4), // Stronger yellow glow
                              blurRadius: 30,
                              offset: const Offset(0, 0),
                              spreadRadius: 4,
                            ),
                          // Enhanced active drag feedback for tutorial
                          if (isActive && widget.enableTutorialMode)
                            BoxShadow(
                              color: Colors.green
                                  .withOpacity(0.6), // Stronger feedback
                              blurRadius: 25,
                              offset: const Offset(0, 0),
                              spreadRadius: 3,
                            ),
                          if (isActive && !widget.enableTutorialMode)
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 0),
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Main container content
                          _buildContainerContent(
                              containerName, containerEmoji, description),

                          // Animated lid overlay
                          _buildAnimatedLid(),

                          // Success particle effects
                          if (_showSuccessParticles &&
                              !widget.enableTutorialMode)
                            _buildSuccessParticles(),

                          // Tutorial mode success indicator
                          if (_showSuccessParticles &&
                              widget.enableTutorialMode)
                            _buildTutorialSuccessIndicator(),

                          // Theme-specific effects (disabled in tutorial)
                          if (!widget.enableTutorialMode) _buildThemeEffects(),

                          // CRITICAL FIX: Enhanced tutorial mode helper text
                          if (widget.enableTutorialMode && isActive)
                            _buildSuperEnhancedTutorialDropHint(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      )
          .animate()
          .slideY(
            begin: 0.3,
            duration: 600.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(
            duration: 400.ms,
          ),
    );
  }

  List<Color> _getThemeGradient() {
    final originalColors =
        _containerConfig?['gradient'] as List<int>? ?? [0xFF718096, 0xFFA0AEC0];

    switch (_containerTheme) {
      case 'crystal':
        return [
          Colors.cyan.shade100.withOpacity(0.9),
          Colors.blue.shade200.withOpacity(0.8),
          Colors.purple.shade100.withOpacity(0.7),
        ];
      case 'neon':
        return [
          Colors.purple.shade400.withOpacity(0.9),
          Colors.pink.shade300.withOpacity(0.8),
          Colors.blue.shade400.withOpacity(0.7),
        ];
      case 'golden':
        return [
          Colors.amber.shade300.withOpacity(0.9),
          Colors.orange.shade200.withOpacity(0.8),
          Colors.yellow.shade100.withOpacity(0.7),
        ];
      case 'metallic':
        return [
          Colors.grey.shade300.withOpacity(0.9),
          Colors.blueGrey.shade200.withOpacity(0.8),
          Colors.grey.shade100.withOpacity(0.7),
        ];
      default:
        return [
          Color(originalColors[0]).withOpacity((_isDraggedOver || widget.isHighlighted) ? 0.95 : 0.8,
          ),
          Color(originalColors[1]).withOpacity((_isDraggedOver || widget.isHighlighted) ? 0.9 : 0.7,
          ),
        ];
    }
  }

  Widget _buildContainerContent(
      String containerName, String containerEmoji, String description) {
    return Column(
      children: [
        // Enhanced header with theme styling
        Container(
          height: 7.h,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getThemeAccentColor().withOpacity(0.8),
                _getThemeAccentColor().withOpacity(0.6),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Glass morphism background
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Header content
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      containerEmoji,
                      style: TextStyle(fontSize: 22.sp),
                    ).animate().scale(
                          duration: 300.ms,
                          curve: Curves.elasticOut,
                        ),
                    SizedBox(width: 3.w),
                    Text(
                      containerName,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    // Theme indicator
                    if (_containerTheme != 'default')
                      Container(
                        margin: EdgeInsets.only(left: 2.w),
                        padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _containerTheme.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ).animate().slideX(delay: 200.ms),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Items area
        Expanded(
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
            child: widget.items.isEmpty
                ? _buildEnhancedEmptyState(description)
                : _buildEnhancedItemsGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLid() {
    return AnimatedBuilder(
      animation: _lidAnimation,
      builder: (context, child) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_lidAnimation.value),
            child: Container(
              height: 7.h,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getThemeAccentColor().withOpacity(0.9),
                    _getThemeAccentColor().withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, _lidAnimation.value * 10),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.8),
                    size: 8.w,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessParticles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: SuccessParticlesPainter(
              animation: _particleController,
              color: _getThemeAccentColor(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTutorialSuccessIndicator() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: RadialGradient(
                colors: [
                  Colors.green.withOpacity(0.3 * (1.0 - _particleController.value)),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.check_circle,
                color: Colors.green
                    .withOpacity(1.0 - _particleController.value),
                size: 20.w * _particleController.value,
              ),
            ),
          );
        },
      ),
    );
  }

  // CRITICAL FIX: Super enhanced tutorial drop hint
  Widget _buildSuperEnhancedTutorialDropHint() {
    return Positioned(
      bottom: 1.h,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade400,
                Colors.green.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.7),
                blurRadius: 20,
                offset: const Offset(0, 5),
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_double_arrow_down,
                color: Colors.white,
                size: 8.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'DROP HERE!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn()
          .scale(
            curve: Curves.elasticOut,
            duration: 600.ms,
          )
          .then()
          .shimmer(
            duration: 1000.ms,
            color: Colors.white.withOpacity(0.5),
          )
          .then(delay: 500.ms)
          .shake(hz: 2, curve: Curves.easeInOut),
    );
  }

  Widget _buildThemeEffects() {
    if (_containerTheme == 'default') return const SizedBox.shrink();

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  _getThemeAccentColor().withOpacity(0.1 * _glowAnimation.value,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedEmptyState(String description) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getThemeAccentColor().withOpacity(0.4),
                      _getThemeAccentColor().withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: Colors.white.withOpacity(0.9),
                  size: 8.w,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 2.h),
        Text(
          description,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (_containerTheme != 'default') ...[
          SizedBox(height: 1.h),
          Text(
            '${_containerTheme.toUpperCase()} THEME UNLOCKED',
            style: TextStyle(
              color: _getThemeAccentColor(),
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedItemsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            math.min(3, (widget.items.length / 2).ceil().clamp(1, 3)),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return Realistic3DItemWidget(
          item: item,
          onDragStarted: (_) {},
          onDragEnd: (_) {},
          isInContainer: true,
        )
            .animate(delay: Duration(milliseconds: index * 100))
            .slideY(begin: 0.3, curve: Curves.easeOutBack)
            .fadeIn();
      },
    );
  }
}

class SuccessParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  SuccessParticlesPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(1.0 - animation.value)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final particleCount = 12;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi) / particleCount;
      final distance = 50 * animation.value;
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        4 * (1.0 - animation.value),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
