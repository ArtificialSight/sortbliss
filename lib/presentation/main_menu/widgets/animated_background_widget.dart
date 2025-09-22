import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AnimatedBackgroundWidget extends StatefulWidget {
  const AnimatedBackgroundWidget({Key? key}) : super(key: key);

  @override
  State<AnimatedBackgroundWidget> createState() =>
      _AnimatedBackgroundWidgetState();
}

class _AnimatedBackgroundWidgetState extends State<AnimatedBackgroundWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();

    _controller1 = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _controller2 = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _controller3 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _animation1 = Tween<double>(begin: 0, end: 1).animate(_controller1);
    _animation2 = Tween<double>(begin: 0, end: 1).animate(_controller2);
    _animation3 = Tween<double>(begin: 0, end: 1).animate(_controller3);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightTheme.scaffoldBackgroundColor,
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _animation1,
          builder: (context, child) {
            return Positioned(
              left: 20.w + (30.w * _animation1.value),
              top: 10.h + (20.h * _animation1.value),
              child: Transform.rotate(
                angle: _animation1.value * 2 * 3.14159,
                child: Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _animation2,
          builder: (context, child) {
            return Positioned(
              right: 10.w + (25.w * _animation2.value),
              top: 30.h + (15.h * _animation2.value),
              child: Transform.rotate(
                angle: -_animation2.value * 2 * 3.14159,
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.secondary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _animation3,
          builder: (context, child) {
            return Positioned(
              left: 60.w + (20.w * _animation3.value),
              bottom: 20.h + (10.h * _animation3.value),
              child: Transform.rotate(
                angle: _animation3.value * 1.5 * 3.14159,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
