import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sizer/sizer.dart';

class AdvancedConfettiWidget extends StatefulWidget {
  final bool isActive;
  final Color primaryColor;
  final Color secondaryColor;
  final int particleCount;
  final Duration duration;

  const AdvancedConfettiWidget({
    Key? key,
    required this.isActive,
    required this.primaryColor,
    required this.secondaryColor,
    this.particleCount = 30,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<AdvancedConfettiWidget> createState() => _AdvancedConfettiWidgetState();
}

class _AdvancedConfettiWidgetState extends State<AdvancedConfettiWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _updateParticles();
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _particles.clear();
      }
    });
  }

  @override
  void didUpdateWidget(AdvancedConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _generateParticles();
      _controller.reset();
      _controller.forward();
    }
  }

  void _generateParticles() {
    _particles.clear();
    final random = Random();

    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        ConfettiParticle(
          x: 50.w,
          y: 50.h,
          velocityX: (random.nextDouble() - 0.5) * 400,
          velocityY: -random.nextDouble() * 300 - 100,
          color: i % 2 == 0 ? widget.primaryColor : widget.secondaryColor,
          size: random.nextDouble() * 8 + 4,
          rotation: random.nextDouble() * 2 * pi,
          rotationSpeed: (random.nextDouble() - 0.5) * 10,
          shape:
              ConfettiShape.values[random.nextInt(ConfettiShape.values.length)],
        ),
      );
    }
  }

  void _updateParticles() {
    final double progress = _controller.value;
    final double deltaTime = 1.0 / 60.0; // Assume 60 FPS

    for (var particle in _particles) {
      // Apply gravity and air resistance
      particle.velocityY += 500 * deltaTime; // Gravity
      particle.velocityX *= 0.995; // Air resistance

      // Update position
      particle.x += particle.velocityX * deltaTime;
      particle.y += particle.velocityY * deltaTime;

      // Update rotation
      particle.rotation += particle.rotationSpeed * deltaTime;

      // Fade out over time
      particle.opacity = (1.0 - progress).clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive && _particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: ConfettiPainter(_particles),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

enum ConfettiShape { circle, square, star, heart }

class ConfettiParticle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;
  double opacity;
  final ConfettiShape shape;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
    this.opacity = 1.0,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);

      switch (particle.shape) {
        case ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;
        case ConfettiShape.square:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size,
            ),
            paint,
          );
          break;
        case ConfettiShape.star:
          _drawStar(canvas, paint, particle.size);
          break;
        case ConfettiShape.heart:
          _drawHeart(canvas, paint, particle.size);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final double radius = size / 2;
    final double innerRadius = radius * 0.5;

    for (int i = 0; i < 10; i++) {
      final double angle = (i * pi) / 5;
      final double r = i % 2 == 0 ? radius : innerRadius;
      final double x = r * cos(angle - pi / 2);
      final double y = r * sin(angle - pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final double width = size;
    final double height = size * 0.8;

    path.moveTo(width / 2, height * 0.3);

    path.cubicTo(
      width / 2,
      height * 0.1,
      width * 0.1,
      height * 0.1,
      width * 0.1,
      height * 0.4,
    );

    path.cubicTo(
      width * 0.1,
      height * 0.6,
      width / 2,
      height * 0.9,
      width / 2,
      height,
    );

    path.cubicTo(
      width / 2,
      height * 0.9,
      width * 0.9,
      height * 0.6,
      width * 0.9,
      height * 0.4,
    );

    path.cubicTo(
      width * 0.9,
      height * 0.1,
      width / 2,
      height * 0.1,
      width / 2,
      height * 0.3,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
