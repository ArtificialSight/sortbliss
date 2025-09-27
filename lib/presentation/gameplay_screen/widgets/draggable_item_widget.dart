import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DraggableItemWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(String itemId) onDragStarted;
  final Function(String itemId) onDragEnd;

  const DraggableItemWidget({
    Key? key,
    required this.item,
    required this.onDragStarted,
    required this.onDragEnd,
  }) : super(key: key);

  @override
  State<DraggableItemWidget> createState() => _DraggableItemWidgetState();
}

class _DraggableItemWidgetState extends State<DraggableItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startPulse() {
    _pulseController.repeat(reverse: true);
  }

  void _stopPulse() {
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  Widget build(BuildContext context) {
    // Extract opacity values to descriptive variables
    const double feedbackShadowOpacity = 0.4;
    const double placeholderOpacity = 0.3;
    const double placeholderBorderOpacity = 0.5;
    const double placeholderTextOpacity = 0.6;
    const double itemShadowOpacity = 0.2;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isDragging ? 1.2 : _pulseAnimation.value,
          child: Draggable<Map<String, dynamic>>(
            data: widget.item,
            onDragStarted: () {
              setState(() {
                _isDragging = true;
              });
              _stopPulse();
              widget.onDragStarted(widget.item['id'] as String);
            },
            onDragEnd: (details) {
              setState(() {
                _isDragging = false;
              });
              widget.onDragEnd(widget.item['id'] as String);
            },
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: Color(widget.item['color'] as int),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(feedbackShadowOpacity),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.item['shape'] as String,
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(placeholderOpacity),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(placeholderBorderOpacity),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Text(
                  widget.item['shape'] as String,
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: Colors.grey.withOpacity(placeholderTextOpacity),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            child: GestureDetector(
              onTap: () {
                if (!_isDragging) {
                  _startPulse();
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      _stopPulse();
                    }
                  });
                }
              },
              child: Container(
                width: 12.w,
                height: 12.w,
                margin: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: Color(widget.item['color'] as int),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(itemShadowOpacity),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.item['shape'] as String,
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
