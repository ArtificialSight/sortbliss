import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StarRatingWidget extends StatefulWidget {
  final int starCount;
  final VoidCallback? onAnimationComplete;

  const StarRatingWidget({
    Key? key,
    required this.starCount,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _starControllers;
  late List<Animation<double>> _starAnimations;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStarAnimations();
  }

  void _initializeAnimations() {
    _starControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _starAnimations = _starControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: controller, curve: Curves.elasticOut),
            ))
        .toList();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startStarAnimations() async {
    for (int i = 0; i < widget.starCount; i++) {
      await Future.delayed(Duration(milliseconds: 200 * i));
      if (mounted) {
        _starControllers[i].forward();
      }
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _pulseController.repeat(reverse: true);
      widget.onAnimationComplete?.call();
    }
  }

  @override
  void dispose() {
    for (var controller in _starControllers) {
      controller.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _starAnimations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _starAnimations[index].value,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 1.w),
                      child: CustomIconWidget(
                        iconName:
                            index < widget.starCount ? 'star' : 'star_border',
                        color: index < widget.starCount
                            ? AppTheme.lightTheme.colorScheme.tertiary
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 12.w,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }
}
