import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'dart:math' as math;

class CameraParallaxWidget extends StatefulWidget {
  final Widget child;
  final double intensity;
  final bool enableGyroscope;
  final bool enableParallax;

  const CameraParallaxWidget({
    Key? key,
    required this.child,
    this.intensity = 1.0,
    this.enableGyroscope = true,
    this.enableParallax = true,
  }) : super(key: key);

  @override
  State<CameraParallaxWidget> createState() => _CameraParallaxWidgetState();
}

class _CameraParallaxWidgetState extends State<CameraParallaxWidget>
    with TickerProviderStateMixin {
  late AnimationController _cameraController;
  late AnimationController _zoomController;
  late AnimationController _lightingController;

  late Animation<double> _cameraXAnimation;
  late Animation<double> _cameraYAnimation;
  late Animation<double> _zoomAnimation;
  late Animation<double> _lightingAnimation;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  double _currentTiltX = 0.0;
  double _currentTiltY = 0.0;
  double _currentZoom = 1.0;
  double _targetZoom = 1.0;
  double _lightIntensity = 0.5;

  // Parallax layers
  List<ParallaxLayer> _parallaxLayers = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeParallaxLayers();
    if (widget.enableGyroscope) {
      _initializeSensors();
    }
    _startCameraMovement();
  }

  void _initializeAnimations() {
    _cameraController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _lightingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Smooth camera movement
    _cameraXAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _cameraController,
      curve: Curves.easeInOut,
    ));

    _cameraYAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _cameraController,
      curve: Curves.easeInOut,
    ));

    // Dynamic zoom animation
    _zoomAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInOut,
    ));

    // Dynamic lighting
    _lightingAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _lightingController,
      curve: Curves.easeInOut,
    ));

    // Start continuous animations
    _cameraController.repeat(reverse: true);
    _zoomController.repeat(reverse: true);
    _lightingController.repeat(reverse: true);
  }

  void _initializeParallaxLayers() {
    _parallaxLayers = [
      ParallaxLayer(
        depth: 0.1,
        opacity: 0.1,
        color: Colors.blue.shade900,
        offset: const Offset(-50, -30),
      ),
      ParallaxLayer(
        depth: 0.3,
        opacity: 0.15,
        color: Colors.purple.shade800,
        offset: const Offset(30, -20),
      ),
      ParallaxLayer(
        depth: 0.5,
        opacity: 0.1,
        color: Colors.indigo.shade700,
        offset: const Offset(-20, 40),
      ),
    ];
  }

  void _initializeSensors() {
    _accelerometerSubscription =
        accelerometerEvents.listen(_handleAccelerometer);
    _gyroscopeSubscription = gyroscopeEvents.listen(_handleGyroscope);
  }

  void _handleAccelerometer(AccelerometerEvent event) {
    if (!widget.enableGyroscope) return;

    setState(() {
      _currentTiltX = (-event.x * 0.1 * widget.intensity).clamp(-0.2, 0.2);
      _currentTiltY = (event.y * 0.1 * widget.intensity).clamp(-0.2, 0.2);
    });
  }

  void _handleGyroscope(GyroscopeEvent event) {
    if (!widget.enableGyroscope) return;

    // Subtle zoom effect based on rotation
    final rotationMagnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (rotationMagnitude > 2.0) {
      setState(() {
        _targetZoom = (1.0 + rotationMagnitude * 0.02).clamp(0.9, 1.1);
      });

      // Smooth zoom transition
      _currentZoom += (_targetZoom - _currentZoom) * 0.1;
    }
  }

  void _startCameraMovement() {
    // Periodic subtle camera movements for immersion
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final randomFactor = math.Random().nextDouble();
      if (randomFactor > 0.7) {
        _triggerCameraShift();
      }
    });
  }

  void _triggerCameraShift() {
    // Slight camera shift for dynamic feel
    final shiftX = (math.Random().nextDouble() - 0.5) * 0.02;
    final shiftY = (math.Random().nextDouble() - 0.5) * 0.01;

    setState(() {
      _currentTiltX = (_currentTiltX + shiftX).clamp(-0.1, 0.1);
      _currentTiltY = (_currentTiltY + shiftY).clamp(-0.1, 0.1);
    });

    // Return to neutral position
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentTiltX *= 0.9;
          _currentTiltY *= 0.9;
        });
      }
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _zoomController.dispose();
    _lightingController.dispose();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _cameraXAnimation,
        _cameraYAnimation,
        _zoomAnimation,
        _lightingAnimation,
      ]),
      builder: (context, child) {
        final totalTiltX = _cameraXAnimation.value + _currentTiltX;
        final totalTiltY = _cameraYAnimation.value + _currentTiltY;
        final totalZoom = _zoomAnimation.value * _currentZoom;

        return Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Parallax background layers
              if (widget.enableParallax)
                ..._buildParallaxLayers(totalTiltX, totalTiltY),

              // Dynamic lighting overlay
              _buildLightingOverlay(),

              // Main content with camera effects
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..scale(totalZoom)
                  ..translate(
                    totalTiltX * 100,
                    totalTiltY * 100,
                  )
                  ..rotateX(totalTiltY * 0.1)
                  ..rotateY(totalTiltX * 0.1),
                child: widget.child,
              ),

              // Subtle vignette effect
              _buildVignetteOverlay(),

              // Film grain effect (very subtle)
              _buildFilmGrainOverlay(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildParallaxLayers(double tiltX, double tiltY) {
    return _parallaxLayers.map((layer) {
      final parallaxX = tiltX * layer.depth * 50;
      final parallaxY = tiltY * layer.depth * 30;

      return Positioned(
        left: layer.offset.dx + parallaxX,
        top: layer.offset.dy + parallaxY,
        child: Transform.scale(
          scale: 1.0 + layer.depth * 0.2,
          child: Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8 + layer.depth * 0.3,
                colors: [
                  layer.color.withValues(alpha: layer.opacity),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLightingOverlay() {
    return AnimatedBuilder(
      animation: _lightingAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                Colors.white.withValues(
                  alpha: 0.05 * _lightingAnimation.value,
                ),
                Colors.transparent,
                Colors.black.withValues(
                  alpha: 0.1 * (1.0 - _lightingAnimation.value),
                ),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVignetteOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.3),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildFilmGrainOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _lightingController,
        builder: (context, child) {
          return CustomPaint(
            painter: FilmGrainPainter(
              intensity: 0.02,
              time: _lightingController.value,
            ),
          );
        },
      ),
    );
  }
}

class ParallaxLayer {
  final double depth;
  final double opacity;
  final Color color;
  final Offset offset;

  ParallaxLayer({
    required this.depth,
    required this.opacity,
    required this.color,
    required this.offset,
  });
}

class FilmGrainPainter extends CustomPainter {
  final double intensity;
  final double time;

  FilmGrainPainter({
    required this.intensity,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random((time * 1000).round());
    final paint = Paint();

    for (int i = 0;
        i < (size.width * size.height * intensity * 0.001).round();
        i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = random.nextDouble() * 0.1;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
