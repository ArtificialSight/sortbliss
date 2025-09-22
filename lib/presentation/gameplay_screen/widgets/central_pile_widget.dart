import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/audio_manager.dart';
import '../../../core/haptic_manager.dart';

/// Central pile widget displaying scattered 3D objects in hypercasual game style
class CentralPileWidget extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(String) onDragStarted;
  final Function(String) onDragEnd;
  final bool enableTutorialMode;
  final String? highlightedItemId;

  const CentralPileWidget({
    Key? key,
    required this.items,
    required this.onDragStarted,
    required this.onDragEnd,
    this.enableTutorialMode = false,
    this.highlightedItemId,
  }) : super(key: key);

  @override
  State<CentralPileWidget> createState() => _CentralPileWidgetState();
}

class _CentralPileWidgetState extends State<CentralPileWidget>
    with TickerProviderStateMixin {
  late AnimationController _pileAnimationController;
  late AnimationController _ambientController;
  late Animation<double> _pileAnimation;
  late Animation<double> _ambientAnimation;

  final AudioManager _audioManager = AudioManager();
  final HapticManager _hapticManager = HapticManager();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Pile breathing animation
    _pileAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pileAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pileAnimationController,
      curve: Curves.easeInOut,
    ));

    // Ambient lighting effect
    _ambientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _ambientAnimation = Tween<double>(
      begin: 0.1,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOut,
    ));

    _pileAnimationController.repeat(reverse: true);
    _ambientController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pileAnimationController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _buildEmptyPile();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pileAnimation, _ambientAnimation]),
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Ambient lighting overlay
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      AppTheme.lightTheme.primaryColor
                          .withValues(alpha: _ambientAnimation.value * 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Central scattered pile
              Transform.scale(
                scale: _pileAnimation.value,
                child: _buildScatteredPile(),
              ),

              // Tutorial overlay
              if (widget.enableTutorialMode) _buildTutorialOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScatteredPile() {
    final random = math.Random(widget.items.length);

    return Stack(
      children: widget.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        // Generate scattered positions in a messy pile format
        final centerX = 50.w;
        final centerY = 45.h;
        final radius = 35.w + (random.nextDouble() * 10.w);
        final angle = (random.nextDouble() * 2 * math.pi);
        final variation = (random.nextDouble() - 0.5) * 20.w;

        final x = centerX + (math.cos(angle) * radius) + variation;
        final y = centerY +
            (math.sin(angle) * radius * 0.6) +
            (random.nextDouble() - 0.5) * 15.h;

        return Positioned(
          left: x.clamp(5.w, 90.w),
          top: y.clamp(10.h, 75.h),
          child: _build3DScatteredItem(item, index),
        );
      }).toList(),
    );
  }

  Widget _build3DScatteredItem(Map<String, dynamic> item, int index) {
    final isHighlighted = widget.highlightedItemId == item['id'];
    final rotation = (item['rotation'] ?? 0.0) as double;
    final scale = (item['scale'] ?? 1.0) as double;

    return Draggable<String>(
      data: item['id'] as String,
      onDragStarted: () {
        widget.onDragStarted(item['id'] as String);
        _hapticManager.lightTap();
        _audioManager.playWhooshSound();
      },
      onDragEnd: (_) => widget.onDragEnd(item['id'] as String),
      feedback: _buildDragFeedback(item, scale),
      childWhenDragging: Container(),
      child: Transform.rotate(
        angle: rotation * math.pi / 180,
        child: Transform.scale(
          scale: scale * (isHighlighted ? 1.1 : 1.0),
          child: Container(
            width: 16.w,
            height: 16.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                // Main shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: Offset(2, 4),
                  spreadRadius: 1,
                ),
                // Depth shadow for 3D effect
                BoxShadow(
                  color: (Color(item['color'] as int)).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: Offset(1, 2),
                  spreadRadius: 0,
                ),
                // Highlight for tutorial mode
                if (widget.enableTutorialMode && isHighlighted)
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(item['color'] as int).withValues(alpha: 0.9),
                      Color(item['color'] as int).withValues(alpha: 0.7),
                      Color(item['color'] as int),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 3D lighting effect
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.center,
                          colors: [
                            Colors.white.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Item content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['emoji'] as String,
                            style: TextStyle(
                              fontSize: 8.w,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          if (!widget.enableTutorialMode) ...[
                            SizedBox(height: 0.5.h),
                            Text(
                              item['name'] as String,
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 2.2.w,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    offset: Offset(0.5, 0.5),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Highlight indicator
                    if (isHighlighted)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.enableTutorialMode
                                ? Colors.yellow
                                : Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
          .animate(
            delay: Duration(milliseconds: index * 100),
          )
          .fadeIn(duration: 600.ms)
          .scale(begin: Offset(0.5, 0.5)),
    );
  }

  Widget _buildDragFeedback(Map<String, dynamic> item, double scale) {
    return Transform.scale(
      scale: scale * 1.2,
      child: Container(
        width: 18.w,
        height: 18.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(item['color'] as int).withValues(alpha: 0.9),
              Color(item['color'] as int),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Color(item['color'] as int).withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            item['emoji'] as String,
            style: TextStyle(
              fontSize: 10.w,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.7,
          colors: [
            Colors.yellow.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.yellow.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'touch_app',
                color: Colors.yellow,
                size: 8.w,
              ),
              SizedBox(height: 1.h),
              Text(
                'Drag items to sort them!',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
                  AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Text(
              '🎉',
              style: TextStyle(fontSize: 20.w),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'All items sorted!',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Great job organizing everything!',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: Offset(0.8, 0.8));
  }
}
