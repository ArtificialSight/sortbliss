import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class GameContainerWidget extends StatefulWidget {
  final String containerId;
  final Color containerColor;
  final List<Map<String, dynamic>> items;
  final bool isHighlighted;
  final Function(String itemId, String containerId) onItemDropped;
  final Function(String containerId) onContainerTap;

  const GameContainerWidget({
    Key? key,
    required this.containerId,
    required this.containerColor,
    required this.items,
    required this.isHighlighted,
    required this.onItemDropped,
    required this.onContainerTap,
  }) : super(key: key);

  @override
  State<GameContainerWidget> createState() => _GameContainerWidgetState();
}

class _GameContainerWidgetState extends State<GameContainerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(GameContainerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted != oldWidget.isHighlighted) {
      if (widget.isHighlighted) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onContainerTap(widget.containerId),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: DragTarget<Map<String, dynamic>>(
              onWillAcceptWithDetails: (data) => data != null,
              onAcceptWithDetails: (data) {
                widget.onItemDropped(data.data['id'] as String, widget.containerId);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: 35.w,
                  height: 25.h,
                  margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: widget.isHighlighted
                        ? widget.containerColor.withValues(alpha: 0.8)
                        : widget.containerColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isHighlighted
                          ? AppTheme.lightTheme.primaryColor
                          : Colors.transparent,
                      width: widget.isHighlighted ? 3 : 0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: widget.containerColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Container ${widget.containerId}',
                            style: AppTheme.lightTheme.textTheme.labelMedium
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          child: widget.items.isEmpty
                              ? Center(
                                  child: Text(
                                    'Drop items here',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                                  itemCount: widget.items.length,
                                  itemBuilder: (context, index) {
                                    final item = widget.items[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Color(item['color'] as int),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          item['shape'] as String,
                                          style: AppTheme
                                              .lightTheme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
}