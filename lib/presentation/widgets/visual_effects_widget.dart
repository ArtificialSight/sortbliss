import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/user_settings_service.dart';

/// Visual effects overlay for celebrations, particles, and animations
///
/// Provides non-intrusive visual feedback:
/// - Confetti explosions (level complete, achievements)
/// - Star bursts (earning stars)
/// - Coin sparkles (collecting coins)
/// - Particle trails (drag gestures)
/// - Flash effects (combos, milestones)
///
/// Respects user settings (reduce motion, particle effects enabled)
class VisualEffectsWidget extends StatefulWidget {
  final Widget child;

  const VisualEffectsWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<VisualEffectsWidget> createState() => VisualEffectsWidgetState();

  /// Get the state to trigger effects from anywhere
  static VisualEffectsWidgetState? of(BuildContext context) {
    return context.findAncestorStateOfType<VisualEffectsWidgetState>();
  }
}

class VisualEffectsWidgetState extends State<VisualEffectsWidget>
    with TickerProviderStateMixin {
  final UserSettingsService _settings = UserSettingsService.instance;
  final List<_Particle> _particles = [];
  AnimationController? _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        setState(() {
          _updateParticles();
        });
      });
  }

  @override
  void dispose() {
    _particleController?.dispose();
    super.dispose();
  }

  /// Trigger confetti explosion effect
  void confetti({Offset? origin}) {
    if (!_canShowEffects()) return;

    final center = origin ?? Offset(50.w, 50.h);
    final random = Random();

    for (int i = 0; i < 50; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 2.0 + random.nextDouble() * 3.0;

      _particles.add(_Particle(
        position: center,
        velocity: Offset(
          cos(angle) * speed,
          sin(angle) * speed - 1.0, // Upward bias
        ),
        color: _randomColor(random),
        size: 0.5 + random.nextDouble() * 1.0,
        shape: _ParticleShape.values[random.nextInt(3)],
        lifetime: 1.5 + random.nextDouble() * 0.5,
      ));
    }

    _particleController?.forward(from: 0.0);
  }

  /// Trigger star burst effect
  void starBurst({required Offset origin, int starCount = 3}) {
    if (!_canShowEffects()) return;

    final random = Random();

    for (int i = 0; i < starCount * 8; i++) {
      final angle = (i / (starCount * 8)) * 2 * pi;
      final speed = 1.5 + random.nextDouble() * 2.0;

      _particles.add(_Particle(
        position: origin,
        velocity: Offset(
          cos(angle) * speed,
          sin(angle) * speed,
        ),
        color: Colors.amber,
        size: 0.8 + random.nextDouble() * 0.4,
        shape: _ParticleShape.star,
        lifetime: 1.0 + random.nextDouble() * 0.5,
      ));
    }

    _particleController?.forward(from: 0.0);
  }

  /// Trigger coin sparkle effect
  void coinSparkle({required Offset origin}) {
    if (!_canShowEffects()) return;

    final random = Random();

    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 1.0 + random.nextDouble() * 1.5;

      _particles.add(_Particle(
        position: origin,
        velocity: Offset(
          cos(angle) * speed,
          sin(angle) * speed,
        ),
        color: Colors.amber.shade300,
        size: 0.3 + random.nextDouble() * 0.5,
        shape: _ParticleShape.circle,
        lifetime: 0.8 + random.nextDouble() * 0.4,
      ));
    }

    _particleController?.forward(from: 0.0);
  }

  /// Trigger particle trail (following gesture)
  void particleTrail({required Offset position}) {
    if (!_canShowEffects()) return;

    final random = Random();

    for (int i = 0; i < 3; i++) {
      _particles.add(_Particle(
        position: position,
        velocity: Offset(
          (random.nextDouble() - 0.5) * 0.5,
          random.nextDouble() * 0.5,
        ),
        color: Theme.of(context).primaryColor.withOpacity(0.6),
        size: 0.3 + random.nextDouble() * 0.3,
        shape: _ParticleShape.circle,
        lifetime: 0.5,
      ));
    }

    if (!_particleController!.isAnimating) {
      _particleController?.forward(from: 0.0);
    }
  }

  /// Trigger flash effect (screen flash)
  void flash({Color color = Colors.white}) {
    if (!_canShowEffects()) return;

    // TODO: Implement flash overlay
    // Could use AnimatedContainer with opacity fade
  }

  /// Trigger combo effect
  void combo({required Offset origin, required int comboCount}) {
    if (!_canShowEffects()) return;

    final random = Random();
    final particleCount = 10 + (comboCount * 5).clamp(0, 30);

    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 2.0 + random.nextDouble() * 2.0;

      _particles.add(_Particle(
        position: origin,
        velocity: Offset(
          cos(angle) * speed,
          sin(angle) * speed,
        ),
        color: _getComboColor(comboCount),
        size: 0.6 + random.nextDouble() * 0.6,
        shape: _ParticleShape.circle,
        lifetime: 1.0 + random.nextDouble() * 0.5,
      ));
    }

    _particleController?.forward(from: 0.0);
  }

  /// Trigger achievement unlock effect
  void achievementUnlock({Offset? origin}) {
    if (!_canShowEffects()) return;

    final center = origin ?? Offset(50.w, 50.h);
    final random = Random();

    // Outer ring
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi;
      final speed = 3.0;

      _particles.add(_Particle(
        position: center,
        velocity: Offset(
          cos(angle) * speed,
          sin(angle) * speed,
        ),
        color: Colors.purple.shade300,
        size: 0.8,
        shape: _ParticleShape.star,
        lifetime: 1.5,
      ));
    }

    _particleController?.forward(from: 0.0);
  }

  bool _canShowEffects() {
    if (!_settings.particleEffectsEnabled) return false;
    if (_settings.reduceMotion) return false;
    return true;
  }

  void _updateParticles() {
    final dt = 1.0 / 60.0; // Assume 60 FPS

    _particles.removeWhere((particle) {
      particle.update(dt);
      return particle.isDead;
    });

    if (_particles.isEmpty) {
      _particleController?.stop();
    }
  }

  Color _randomColor(Random random) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[random.nextInt(colors.length)];
  }

  Color _getComboColor(int comboCount) {
    if (comboCount >= 10) return Colors.purple;
    if (comboCount >= 7) return Colors.red;
    if (comboCount >= 5) return Colors.orange;
    if (comboCount >= 3) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ParticlePainter(particles: _particles),
              ),
            ),
          ),
      ],
    );
  }
}

/// Particle data class
class _Particle {
  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  final _ParticleShape shape;
  final double lifetime;
  double age = 0.0;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.shape,
    required this.lifetime,
  });

  void update(double dt) {
    age += dt;
    position += velocity * dt * 60; // Scale by 60 for consistent speed
    velocity += const Offset(0, 0.2); // Gravity
  }

  bool get isDead => age >= lifetime;

  double get opacity => (1.0 - (age / lifetime)).clamp(0.0, 1.0);
}

/// Particle shapes
enum _ParticleShape {
  circle,
  square,
  star,
}

/// Custom painter for particles
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      switch (particle.shape) {
        case _ParticleShape.circle:
          canvas.drawCircle(
            particle.position,
            particle.size.w,
            paint,
          );
          break;

        case _ParticleShape.square:
          canvas.drawRect(
            Rect.fromCenter(
              center: particle.position,
              width: particle.size.w * 2,
              height: particle.size.w * 2,
            ),
            paint,
          );
          break;

        case _ParticleShape.star:
          _drawStar(canvas, particle.position, particle.size.w, paint);
          break;
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final points = 5;
    final innerRadius = radius * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
