import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sizer/sizer.dart';

class SparkleParticleWidget extends StatefulWidget {
  final bool isActive;
  final Offset position;
  final Color color;
  final int sparkleCount;

  const SparkleParticleWidget({
    Key? key,
    required this.isActive,
    required this.position,
    required this.color,
    this.sparkleCount = 12,
  }) : super(key: key);

  @override
  State<SparkleParticleWidget> createState() => _SparkleParticleWidgetState();
}

class _SparkleParticleWidgetState extends State<SparkleParticleWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final List<SparkleParticle> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _generateSparkles();
  }

  @override
  void didUpdateWidget(SparkleParticleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _generateSparkles();
      _controller.reset();
      _controller.forward();
    }
  }

  void _generateSparkles() {
    _sparkles.clear();
    final random = Random();

    for (int i = 0; i < widget.sparkleCount; i++) {
      final angle = (i / widget.sparkleCount) * 2 * pi;
      final distance = random.nextDouble() * 30 + 10;

      _sparkles.add(
        SparkleParticle(
          offsetX: cos(angle) * distance,
          offsetY: sin(angle) * distance,
          size: random.nextDouble() * 4 + 2,
          delay: random.nextDouble() * 0.3,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(20.w, 20.w),
            painter: SparklePainter(
              sparkles: _sparkles,
              scale: _scaleAnimation.value,
              opacity: _opacityAnimation.value,
              color: widget.color,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class SparkleParticle {
  final double offsetX;
  final double offsetY;
  final double size;
  final double delay;

  SparkleParticle({
    required this.offsetX,
    required this.offsetY,
    required this.size,
    required this.delay,
  });
}

class SparklePainter extends CustomPainter {
  final List<SparkleParticle> sparkles;
  final double scale;
  final double opacity;
  final Color color;
  final double progress;

  SparklePainter({
    required this.sparkles,
    required this.scale,
    required this.opacity,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var sparkle in sparkles) {
      final sparkleProgress = (progress - sparkle.delay).clamp(0.0, 1.0);
      if (sparkleProgress <= 0) continue;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity * sparkleProgress)
        ..style = PaintingStyle.fill;

      final position = Offset(
        center.dx + sparkle.offsetX * scale,
        center.dy + sparkle.offsetY * scale,
      );

      // Draw sparkle as a star
      _drawSparkle(canvas, paint, position, sparkle.size * scale);
    }
  }

  void _drawSparkle(Canvas canvas, Paint paint, Offset position, double size) {
    canvas.save();
    canvas.translate(position.dx, position.dy);

    // Draw a 4-pointed star
    final path = Path();
    final radius = size / 2;

    // Vertical line
    path.moveTo(0, -radius);
    path.lineTo(0, radius);
    path.moveTo(-radius, 0);
    path.lineTo(radius, 0);

    // Diagonal lines
    final diagonalRadius = radius * 0.7;
    path.moveTo(-diagonalRadius, -diagonalRadius);
    path.lineTo(diagonalRadius, diagonalRadius);
    path.moveTo(diagonalRadius, -diagonalRadius);
    path.lineTo(-diagonalRadius, diagonalRadius);

    paint.strokeWidth = 2.0;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // Add a bright center
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 1.5, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
