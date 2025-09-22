import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class HapticManager {
  static final HapticManager _instance = HapticManager._internal();
  factory HapticManager() => _instance;
  HapticManager._internal();

  bool _hapticEnabled = true;

  bool get hapticEnabled => _hapticEnabled;

  // Initialize haptic system
  Future<void> initialize() async {
    try {
      // Check if vibration is available on device
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) {
        _hapticEnabled = false;
        if (kDebugMode) {
          print('Haptic feedback not available on this device');
        }
      }
    } catch (e) {
      _hapticEnabled = false;
      if (kDebugMode) {
        print('Haptic Manager initialization error: $e');
      }
    }
  }

  // Light tap feedback for button touches
  Future<void> lightTap() async {
    if (!_hapticEnabled) return;

    try {
      await Vibration.vibrate(duration: 10);
    } catch (e) {
      if (kDebugMode) {
        print('Light tap haptic error: $e');
      }
    }
  }

  // Medium impact for successful item placements
  Future<void> successImpact() async {
    if (!_hapticEnabled) return;

    try {
      await Vibration.vibrate(duration: 30);
    } catch (e) {
      if (kDebugMode) {
        print('Success impact haptic error: $e');
      }
    }
  }

  // Heavy impact for level completion
  Future<void> celebrationImpact() async {
    if (!_hapticEnabled) return;

    try {
      // Create a celebration pattern
      await Vibration.vibrate(
        pattern: [0, 100, 50, 100, 50, 200],
        intensities: [0, 255, 0, 255, 0, 255],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Celebration haptic error: $e');
      }
    }
  }

  // Selection feedback for menu interactions
  Future<void> selectionFeedback() async {
    if (!_hapticEnabled) return;

    try {
      await Vibration.vibrate(duration: 20);
    } catch (e) {
      if (kDebugMode) {
        print('Selection feedback haptic error: $e');
      }
    }
  }

  // Error feedback for wrong placements
  Future<void> errorFeedback() async {
    if (!_hapticEnabled) return;

    try {
      await Vibration.vibrate(
        pattern: [0, 50, 30, 50],
        intensities: [0, 128, 0, 128],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error feedback haptic error: $e');
      }
    }
  }

  // Settings
  void setHapticEnabled(bool enabled) {
    _hapticEnabled = enabled;
  }
}
