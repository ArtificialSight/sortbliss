import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ConfettiWidget extends StatefulWidget {
  final bool isActive;

  const ConfettiWidget({
    Key? key,
    required this.isActive,
  }) : super(key: key);

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<ConfettiParticle> _particles;
  final int _particleCount = 50;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _initializeParticles();

    if (widget.isActive) {
      _animationController.forward();
    }
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles = List.generate(_particleCount, (index) {
      return ConfettiParticle(
        x: random.nextDouble() * 100.w,
        y: -10.h,
        color: _getRandomColor(random),
        size: random.nextDouble() * 2.w + 1.w,
        velocity: random.nextDouble() * 5 + 2,
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: random.nextDouble() * 0.2 - 0.1,
      );
    });
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      AppTheme.lightTheme.colorScheme.primary,
      AppTheme.lightTheme.colorScheme.secondary,
      AppTheme.lightTheme.colorScheme.tertiary,
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void didUpdateWidget(ConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _animationController.reset();
      _initializeParticles();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isActive
        ? AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(100.w, 100.h),
                painter: ConfettiPainter(
                  particles: _particles,
                  progress: _animationController.value,
                ),
              );
            },
          )
        : const SizedBox.shrink();
  }
}

class ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double velocity;
  double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      final currentY =
          particle.y + (particle.velocity * progress * size.height);
      final currentRotation =
          particle.rotation + (particle.rotationSpeed * progress * 10);

      if (currentY < size.height + particle.size) {
        canvas.save();
        canvas.translate(particle.x, currentY);
        canvas.rotate(currentRotation);

        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(particle.size * 0.1)),
          paint,
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
