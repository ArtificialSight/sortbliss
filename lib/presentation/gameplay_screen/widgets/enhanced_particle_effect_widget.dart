import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:sizer/sizer.dart';

class EnhancedParticleEffectWidget extends StatefulWidget {
  final bool isActive;
  final Color particleColor;
  final int particleCount;
  final Duration duration;

  const EnhancedParticleEffectWidget({
    Key? key,
    required this.isActive,
    required this.particleColor,
    this.particleCount = 30,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<EnhancedParticleEffectWidget> createState() =>
      _EnhancedParticleEffectWidgetState();
}

class _EnhancedParticleEffectWidgetState
    extends State<EnhancedParticleEffectWidget> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _particles = [];
    _initializeParticles();
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        startX: 50.w + (random.nextDouble() - 0.5) * 20.w,
        startY: 40.h + (random.nextDouble() - 0.5) * 10.h,
        endX: (random.nextDouble() * 100).w,
        endY: (random.nextDouble() * 40).h,
        color: _getRandomParticleColor(),
        size: 2 + random.nextDouble() * 4,
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 4,
      );
    });
  }

  Color _getRandomParticleColor() {
    final random = math.Random();
    final colors = [
      widget.particleColor,
      widget.particleColor.withValues(alpha: 0.8),
      Colors.white.withValues(alpha: 0.9),
      Colors.yellow.withValues(alpha: 0.8),
      Colors.orange.withValues(alpha: 0.7),
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void didUpdateWidget(EnhancedParticleEffectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeParticles();
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: EnhancedParticlePainter(
                particles: _particles,
                progress: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class Particle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;

  Particle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class EnhancedParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  EnhancedParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final currentX =
          particle.startX + (particle.endX - particle.startX) * progress;
      final currentY =
          particle.startY + (particle.endY - particle.startY) * progress;

      // Calculate opacity based on progress (fade out towards end)
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final currentColor =
          particle.color.withValues(alpha: particle.color.opacity * opacity);

      // Calculate current size (shrink over time)
      final currentSize = particle.size * (1 - progress * 0.5);

      // Calculate current rotation
      final currentRotation =
          particle.rotation + particle.rotationSpeed * progress * 2 * math.pi;

      final paint = Paint()
        ..color = currentColor
        ..style = PaintingStyle.fill;

      // Add glow effect
      final glowPaint = Paint()
        ..color = currentColor.withValues(alpha: currentColor.opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRotation);

      // Draw glow
      canvas.drawCircle(Offset.zero, currentSize * 2, glowPaint);

      // Draw main particle
      canvas.drawCircle(Offset.zero, currentSize, paint);

      // Add sparkle effect
      if (progress < 0.7) {
        final sparkleSize = currentSize * 0.3;
        final sparklePaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.8)
          ..style = PaintingStyle.fill;

        // Draw cross-shaped sparkle
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: sparkleSize * 2,
            height: sparkleSize * 0.5,
          ),
          sparklePaint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: sparkleSize * 0.5,
            height: sparkleSize * 2,
          ),
          sparklePaint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
