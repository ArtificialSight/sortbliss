import 'package:flutter/services.dart';
import '../utils/analytics_logger.dart';
import 'user_settings_service.dart';

/// Centralized haptic feedback service with intensity levels and user preferences
///
/// Provides 6 intensity levels of haptic feedback coordinated with game events:
/// - success: Light tap for successful actions
/// - light: Soft feedback for UI interactions
/// - medium: Standard feedback for game actions
/// - heavy: Strong feedback for achievements
/// - rigid: Firm feedback for errors/warnings
/// - soft: Gentle feedback for subtle interactions
class HapticFeedbackService {
  static final HapticFeedbackService instance = HapticFeedbackService._();
  HapticFeedbackService._();

  final UserSettingsService _settings = UserSettingsService.instance;
  bool _initialized = false;

  /// Initialize haptic feedback service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if haptics are supported
      _initialized = true;

      AnalyticsLogger.logEvent('haptic_service_initialized', parameters: {
        'haptics_enabled': _settings.hapticsEnabled,
      });
    } catch (e) {
      AnalyticsLogger.logEvent('haptic_init_error', parameters: {
        'error': e.toString(),
      });
    }
  }

  /// Play success haptic (light tap)
  /// Use for: Successful moves, button taps, selections
  Future<void> success() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.lightImpact();
      _logFeedback('success');
    } catch (e) {
      _handleError('success', e);
    }
  }

  /// Play light haptic (soft feedback)
  /// Use for: UI interactions, scrolling, swiping
  Future<void> light() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.selectionClick();
      _logFeedback('light');
    } catch (e) {
      _handleError('light', e);
    }
  }

  /// Play medium haptic (standard feedback)
  /// Use for: Piece placement, game actions, sorting
  Future<void> medium() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.mediumImpact();
      _logFeedback('medium');
    } catch (e) {
      _handleError('medium', e);
    }
  }

  /// Play heavy haptic (strong feedback)
  /// Use for: Level complete, achievements, milestones
  Future<void> heavy() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.heavyImpact();
      _logFeedback('heavy');
    } catch (e) {
      _handleError('heavy', e);
    }
  }

  /// Play rigid haptic (firm feedback)
  /// Use for: Errors, invalid moves, warnings
  Future<void> rigid() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.vibrate();
      _logFeedback('rigid');
    } catch (e) {
      _handleError('rigid', e);
    }
  }

  /// Play soft haptic (gentle feedback)
  /// Use for: Subtle UI changes, tooltips, hints
  Future<void> soft() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.selectionClick();
      _logFeedback('soft');
    } catch (e) {
      _handleError('soft', e);
    }
  }

  /// Play celebration sequence (multiple heavy impacts)
  /// Use for: Level complete, perfect score, new high score
  Future<void> celebrate() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();

      _logFeedback('celebrate');
    } catch (e) {
      _handleError('celebrate', e);
    }
  }

  /// Play error sequence (rigid feedback)
  /// Use for: Failed moves, out of moves, game over
  Future<void> error() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.vibrate();

      _logFeedback('error');
    } catch (e) {
      _handleError('error', e);
    }
  }

  /// Play warning sequence (medium impacts)
  /// Use for: Low moves warning, time running out
  Future<void> warning() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.lightImpact();

      _logFeedback('warning');
    } catch (e) {
      _handleError('warning', e);
    }
  }

  /// Play combo sequence (escalating impacts)
  /// Use for: Combo achievements, multiplier increases
  /// intensity: 1-5 (higher = stronger feedback)
  Future<void> combo(int intensity) async {
    if (!_settings.hapticsEnabled) return;

    try {
      if (intensity <= 2) {
        await HapticFeedback.lightImpact();
      } else if (intensity <= 4) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.heavyImpact();
      }

      _logFeedback('combo', {'intensity': intensity});
    } catch (e) {
      _handleError('combo', e);
    }
  }

  /// Play unlock sequence (progressive impacts)
  /// Use for: Tier unlocks, feature unlocks, achievements
  Future<void> unlock() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();

      _logFeedback('unlock');
    } catch (e) {
      _handleError('unlock', e);
    }
  }

  /// Play star sequence (3 quick impacts)
  /// Use for: Earning stars, rating levels
  Future<void> star() async {
    if (!_settings.hapticsEnabled) return;

    try {
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.lightImpact();
        if (i < 2) await Future.delayed(const Duration(milliseconds: 120));
      }

      _logFeedback('star');
    } catch (e) {
      _handleError('star', e);
    }
  }

  /// Play coin collect sequence (light tap)
  /// Use for: Collecting coins, rewards
  Future<void> coin() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.lightImpact();
      _logFeedback('coin');
    } catch (e) {
      _handleError('coin', e);
    }
  }

  /// Play button press haptic
  /// Use for: General button presses, confirmations
  Future<void> buttonPress() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.lightImpact();
      _logFeedback('button_press');
    } catch (e) {
      _handleError('button_press', e);
    }
  }

  /// Play drag start haptic
  /// Use for: Starting to drag pieces, swipe gestures
  Future<void> dragStart() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.selectionClick();
      _logFeedback('drag_start');
    } catch (e) {
      _handleError('drag_start', e);
    }
  }

  /// Play drag end haptic (placement)
  /// Use for: Dropping pieces, completing gestures
  Future<void> dragEnd() async {
    if (!_settings.hapticsEnabled) return;

    try {
      await HapticFeedback.mediumImpact();
      _logFeedback('drag_end');
    } catch (e) {
      _handleError('drag_end', e);
    }
  }

  /// Play custom sequence from pattern
  /// pattern: List of intensities (1=light, 2=medium, 3=heavy) with 100ms delays
  Future<void> customSequence(List<int> pattern) async {
    if (!_settings.hapticsEnabled) return;

    try {
      for (int i = 0; i < pattern.length; i++) {
        switch (pattern[i]) {
          case 1:
            await HapticFeedback.lightImpact();
            break;
          case 2:
            await HapticFeedback.mediumImpact();
            break;
          case 3:
            await HapticFeedback.heavyImpact();
            break;
        }

        if (i < pattern.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      _logFeedback('custom_sequence', {'pattern': pattern.toString()});
    } catch (e) {
      _handleError('custom_sequence', e);
    }
  }

  void _logFeedback(String type, [Map<String, dynamic>? extra]) {
    // Only log occasionally to avoid spam (1% sampling)
    if (DateTime.now().millisecondsSinceEpoch % 100 == 0) {
      AnalyticsLogger.logEvent('haptic_feedback', parameters: {
        'type': type,
        ...?extra,
      });
    }
  }

  void _handleError(String type, dynamic error) {
    AnalyticsLogger.logEvent('haptic_error', parameters: {
      'type': type,
      'error': error.toString(),
    });
  }
}
