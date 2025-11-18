import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reusable animation library for consistent app-wide animations
///
/// Provides:
/// - Standard durations and curves
/// - Common animation presets
/// - Easy-to-use animation extensions
/// - Consistent timing across the app
///
/// Usage:
/// ```dart
/// Text('Hello').animate(effects: AppAnimations.fadeInUp);
/// Container().animate(effects: AppAnimations.scaleIn);
/// Icon(Icons.star).animate(effects: AppAnimations.bounceIn);
/// ```
class AppAnimations {
  // Standard durations
  static const Duration ultraFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Standard curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  // Common animation effects

  /// Fade in animation
  static List<Effect> get fadeIn => [
        FadeEffect(
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Fade in with upward slide
  static List<Effect> get fadeInUp => [
        FadeEffect(
          duration: normal,
          curve: easeOut,
        ),
        SlideEffect(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Fade in with downward slide
  static List<Effect> get fadeInDown => [
        FadeEffect(
          duration: normal,
          curve: easeOut,
        ),
        SlideEffect(
          begin: const Offset(0, -0.2),
          end: Offset.zero,
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Fade in from left
  static List<Effect> get fadeInLeft => [
        FadeEffect(
          duration: normal,
          curve: easeOut,
        ),
        SlideEffect(
          begin: const Offset(-0.2, 0),
          end: Offset.zero,
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Fade in from right
  static List<Effect> get fadeInRight => [
        FadeEffect(
          duration: normal,
          curve: easeOut,
        ),
        SlideEffect(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Scale in animation
  static List<Effect> get scaleIn => [
        ScaleEffect(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: normal,
          curve: easeOut,
        ),
        FadeEffect(
          duration: fast,
          curve: easeOut,
        ),
      ];

  /// Bounce in animation
  static List<Effect> get bounceIn => [
        ScaleEffect(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: slow,
          curve: bounceOut,
        ),
        FadeEffect(
          duration: fast,
          curve: easeOut,
        ),
      ];

  /// Elastic in animation
  static List<Effect> get elasticIn => [
        ScaleEffect(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
          duration: verySlow,
          curve: elasticOut,
        ),
        FadeEffect(
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Slide in from left
  static List<Effect> get slideInLeft => [
        SlideEffect(
          begin: const Offset(-1.0, 0),
          end: Offset.zero,
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Slide in from right
  static List<Effect> get slideInRight => [
        SlideEffect(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Slide in from top
  static List<Effect> get slideInTop => [
        SlideEffect(
          begin: const Offset(0, -1.0),
          end: Offset.zero,
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Slide in from bottom
  static List<Effect> get slideInBottom => [
        SlideEffect(
          begin: const Offset(0, 1.0),
          end: Offset.zero,
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Rotate in animation
  static List<Effect> get rotateIn => [
        RotateEffect(
          begin: -0.2,
          end: 0.0,
          duration: normal,
          curve: easeOut,
        ),
        ScaleEffect(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: normal,
          curve: easeOut,
        ),
        FadeEffect(
          duration: fast,
          curve: easeOut,
        ),
      ];

  /// Flip in animation
  static List<Effect> get flipIn => [
        FlipEffect(
          duration: slow,
          curve: easeOut,
        ),
      ];

  /// Shimmer effect (for loading states)
  static List<Effect> get shimmer => [
        ShimmerEffect(
          duration: 1500.ms,
          color: Colors.white.withOpacity(0.5),
        ),
      ];

  /// Shake animation (for errors)
  static List<Effect> get shake => [
        ShakeEffect(
          duration: 500.ms,
          hz: 4,
          offset: const Offset(10, 0),
        ),
      ];

  /// Pulse animation (for attention)
  static List<Effect> get pulse => [
        ScaleEffect(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          duration: 500.ms,
          curve: easeInOut,
        ),
      ];

  /// Glow effect
  static List<Effect> get glow => [
        BoxShadowEffect(
          duration: 1000.ms,
          curve: easeInOut,
          shadowColor: Colors.blue.withOpacity(0.5),
          blurRadius: 20,
          spreadRadius: 5,
        ),
      ];

  /// Stagger list items
  static List<Effect> staggeredList({
    int index = 0,
    Duration delay = const Duration(milliseconds: 50),
  }) =>
      [
        ...fadeInUp,
      ].map((effect) => effect.animate()).toList()
        ..forEach((effect) {
          effect.delay = delay * index;
        });

  /// Card flip animation
  static List<Effect> get cardFlip => [
        FlipEffect(
          duration: 600.ms,
          curve: easeInOut,
          direction: Axis.vertical,
        ),
      ];

  /// Success celebration
  static List<Effect> get success => [
        ScaleEffect(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: elasticOut,
        ),
        TintEffect(
          begin: 0,
          end: 1,
          duration: 300.ms,
          color: Colors.green.withOpacity(0.2),
        ),
      ];

  /// Error shake and glow
  static List<Effect> get error => [
        ...shake,
        TintEffect(
          begin: 0,
          end: 1,
          duration: 300.ms,
          color: Colors.red.withOpacity(0.2),
        ),
      ];

  /// Button press animation
  static List<Effect> get buttonPress => [
        ScaleEffect(
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.95, 0.95),
          duration: ultraFast,
          curve: easeOut,
        ),
      ];

  /// Coin collect animation
  static List<Effect> get coinCollect => [
        ScaleEffect(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.2, 1.2),
          duration: 300.ms,
          curve: easeOut,
        ),
        SlideEffect(
          begin: Offset.zero,
          end: const Offset(0, -0.5),
          duration: 400.ms,
          curve: easeOut,
        ),
        FadeEffect(
          begin: 1.0,
          end: 0.0,
          duration: 300.ms,
          delay: 200.ms,
          curve: easeOut,
        ),
      ];

  /// Achievement unlock animation
  static List<Effect> get achievementUnlock => [
        ScaleEffect(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          curve: elasticOut,
        ),
        ShakeEffect(
          duration: 300.ms,
          hz: 3,
          rotation: 0.05,
        ),
        BoxShadowEffect(
          duration: 500.ms,
          shadowColor: Colors.amber.withOpacity(0.8),
          blurRadius: 30,
          spreadRadius: 10,
        ),
      ];

  /// Level complete animation
  static List<Effect> get levelComplete => [
        ScaleEffect(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          duration: 200.ms,
          curve: easeOut,
        ),
        then(delay: 100.ms),
        ScaleEffect(
          begin: const Offset(1.1, 1.1),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: bounceOut,
        ),
        ShimmerEffect(
          duration: 800.ms,
          color: Colors.amber.withOpacity(0.5),
        ),
      ];

  /// Star rating animation
  static List<Effect> starAnimation({int index = 0}) => [
        ScaleEffect(
          begin: const Offset(0, 0),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          delay: Duration(milliseconds: 200 * index),
          curve: elasticOut,
        ),
        RotateEffect(
          begin: -0.5,
          end: 0.0,
          duration: 400.ms,
          delay: Duration(milliseconds: 200 * index),
          curve: easeOut,
        ),
      ];

  /// Notification badge pulse
  static List<Effect> get badgePulse => [
        ScaleEffect(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.2, 1.2),
          duration: 800.ms,
          curve: easeInOut,
        ).then().scale(1.0, duration: 800.ms, curve: easeInOut),
      ];

  /// Loading spinner
  static List<Effect> get loading => [
        RotateEffect(
          duration: 1000.ms,
          curve: Curves.linear,
        ).then().rotate(duration: 1000.ms, curve: Curves.linear),
      ];
}

/// Extension for easy animation application
extension AnimateExtension on Widget {
  /// Apply animation with custom delay
  Widget animateWith(
    List<Effect> effects, {
    Duration delay = Duration.zero,
  }) {
    return animate(effects: effects).then(delay: delay);
  }

  /// Fade in on appear
  Widget fadeIn({Duration delay = Duration.zero}) {
    return animate(effects: AppAnimations.fadeIn).then(delay: delay);
  }

  /// Fade in from bottom
  Widget fadeInUp({Duration delay = Duration.zero}) {
    return animate(effects: AppAnimations.fadeInUp).then(delay: delay);
  }

  /// Scale in on appear
  Widget scaleIn({Duration delay = Duration.zero}) {
    return animate(effects: AppAnimations.scaleIn).then(delay: delay);
  }

  /// Bounce in on appear
  Widget bounceIn({Duration delay = Duration.zero}) {
    return animate(effects: AppAnimations.bounceIn).then(delay: delay);
  }

  /// Slide in from left
  Widget slideInLeft({Duration delay = Duration.zero}) {
    return animate(effects: AppAnimations.slideInLeft).then(delay: delay);
  }

  /// Slide in from right
  Widget slideInRight({Duration delay = Duration.zero}) {
    return animate(effects: AppAnimations.slideInRight).then(delay: delay);
  }

  /// Shake for errors
  Widget shakeOnError() {
    return animate(effects: AppAnimations.shake);
  }

  /// Pulse for attention
  Widget pulseAttention() {
    return animate(effects: AppAnimations.pulse);
  }

  /// Success celebration
  Widget celebrateSuccess() {
    return animate(effects: AppAnimations.success);
  }
}

/// Helper for creating then() chains
Effect then({Duration delay = Duration.zero}) {
  return ThenEffect(delay: delay);
}
