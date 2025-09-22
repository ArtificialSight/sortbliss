import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../core/game_items_data.dart';
import './realistic_3d_item_widget.dart';

class ModernGameContainerWidget extends StatefulWidget {
  final String containerId;
  final List<Map<String, dynamic>> items;
  final bool isHighlighted;
  final Function(String itemId, String containerId) onItemDropped;
  final Function(String containerId) onContainerTap;

  const ModernGameContainerWidget({
    Key? key,
    required this.containerId,
    required this.items,
    required this.isHighlighted,
    required this.onItemDropped,
    required this.onContainerTap,
  }) : super(key: key);

  @override
  State<ModernGameContainerWidget> createState() =>
      _ModernGameContainerWidgetState();
}

class _ModernGameContainerWidgetState extends State<ModernGameContainerWidget>
    with TickerProviderStateMixin {
  late AnimationController _highlightController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  Map<String, dynamic>? _containerConfig;
  bool _isDraggedOver = false;

  @override
  void initState() {
    super.initState();
    _containerConfig = GameItemsData.getContainerConfig(widget.containerId);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    final baseColor = Color(_containerConfig?['color'] ?? 0xFF718096);
    _colorAnimation = ColorTween(
      begin: baseColor,
      end: baseColor.withValues(alpha: 0.9),
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(ModernGameContainerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted != oldWidget.isHighlighted) {
      if (widget.isHighlighted) {
        _highlightController.forward();
        _pulseController.repeat(reverse: true);
        HapticFeedback.lightImpact();
      } else {
        _highlightController.reverse();
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  void _onDragEntered() {
    setState(() {
      _isDraggedOver = true;
    });
    HapticFeedback.selectionClick();
  }

  void _onDragExited() {
    setState(() {
      _isDraggedOver = false;
    });
  }

  void _onItemAccepted(Map<String, dynamic> item) {
    _particleController.forward().then((_) {
      _particleController.reset();
    });

    HapticFeedback.mediumImpact();
    widget.onItemDropped(item['id'] as String, widget.containerId);
  }

  @override
  void dispose() {
    _highlightController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerName = _containerConfig?['name'] ?? 'Container';
    final containerEmoji = _containerConfig?['emoji'] ?? '📦';
    final gradientColors =
        _containerConfig?['gradient'] as List<int>? ?? [0xFF718096, 0xFFA0AEC0];
    final description = _containerConfig?['description'] ?? 'Sort items here';

    return GestureDetector(
      onTap: () {
        widget.onContainerTap(widget.containerId);
        HapticFeedback.selectionClick();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_scaleAnimation, _pulseAnimation, _colorAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: DragTarget<Map<String, dynamic>>(
              onWillAcceptWithDetails: (data) => data.data != null,
              onAcceptWithDetails: (data) => _onItemAccepted(data.data),
              onMove: (_) => _onDragEntered(),
              onLeave: (_) => _onDragExited(),
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: 38.w,
                  height: 28.h,
                  margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(gradientColors[0]).withValues(
                            alpha: (_isDraggedOver || widget.isHighlighted)
                                ? 0.95
                                : 0.8),
                        Color(gradientColors[1]).withValues(
                            alpha: (_isDraggedOver || widget.isHighlighted)
                                ? 0.9
                                : 0.7),
                      ],
                    ),
                    border: Border.all(
                      color: widget.isHighlighted
                          ? AppTheme.lightTheme.primaryColor
                          : _isDraggedOver
                              ? Colors.white
                              : Colors.transparent,
                      width: widget.isHighlighted
                          ? 3
                          : _isDraggedOver
                              ? 2
                              : 0,
                    ),
                    boxShadow: [
                      // Main shadow
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: widget.isHighlighted ? 20 : 12,
                        offset: const Offset(0, 8),
                        spreadRadius: widget.isHighlighted ? 2 : 0,
                      ),
                      // Colored glow
                      if (widget.isHighlighted || _isDraggedOver)
                        BoxShadow(
                          color:
                              Color(gradientColors[0]).withValues(alpha: 0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 0),
                          spreadRadius: 3,
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Modern header with gradient and glass effect
                      Container(
                        height: 6.h,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(gradientColors[0]),
                              Color(gradientColors[1]),
                            ],
                          ),
                          // Glass morphism effect
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Background blur effect
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Content
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    containerEmoji,
                                    style: TextStyle(fontSize: 20.sp),
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    containerName,
                                    style: AppTheme
                                        .lightTheme.textTheme.titleMedium
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          offset: const Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Items area with enhanced visual effects
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            // Subtle inner glow
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: widget.items.isEmpty
                              ? _buildEmptyState(description)
                              : _buildItemsGrid(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String description) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated placeholder
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 6.w,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 2.h),
        Text(
          description,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildItemsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            math.min(3, (widget.items.length / 2).ceil().clamp(1, 3)),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return Realistic3DItemWidget(
          item: item,
          onDragStarted: (_) {},
          onDragEnd: (_) {},
          isInContainer: true,
        );
      },
    );
  }
}
