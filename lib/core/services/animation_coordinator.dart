import 'package:flutter/material.dart';
import 'haptic_feedback_service.dart';
import 'sound_effect_service.dart';
import '../../presentation/widgets/visual_effects_widget.dart';
import '../utils/analytics_logger.dart';

/// Coordinates animations, haptics, and sound effects for cohesive feedback
///
/// Provides high-level methods that trigger multiple feedback systems:
/// - Visual effects (particles, animations)
/// - Haptic feedback (vibrations)
/// - Sound effects (audio)
///
/// Ensures all feedback is synchronized and respects user preferences
class AnimationCoordinator {
  static final AnimationCoordinator instance = AnimationCoordinator._();
  AnimationCoordinator._();

  final HapticFeedbackService _haptics = HapticFeedbackService.instance;
  final SoundEffectService _sound = SoundEffectService.instance;

  /// Initialize coordinator (initializes all feedback services)
  Future<void> initialize() async {
    await _haptics.initialize();
    await _sound.initialize();

    AnalyticsLogger.logEvent('animation_coordinator_initialized');
  }

  /// Level complete celebration
  Future<void> levelComplete({
    required BuildContext context,
    required int stars,
    Offset? origin,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.confetti(origin: origin);

      // Haptics
      await _haptics.celebrate();

      // Sound
      await _sound.levelComplete(stars: stars);

      // Star sequence
      if (stars > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
        for (int i = 0; i < stars; i++) {
          effectsWidget?.starBurst(
            origin: origin ?? Offset(MediaQuery.of(context).size.width / 2, 200),
          );
          await _haptics.star();
          await _sound.star();
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }

      AnalyticsLogger.logEvent('animation_level_complete', parameters: {
        'stars': stars,
      });
    } catch (e) {
      _logError('levelComplete', e);
    }
  }

  /// Achievement unlock celebration
  Future<void> achievementUnlock({
    required BuildContext context,
    Offset? origin,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.achievementUnlock(origin: origin);

      // Haptics
      await _haptics.unlock();

      // Sound
      await _sound.achievementUnlock();

      AnalyticsLogger.logEvent('animation_achievement_unlock');
    } catch (e) {
      _logError('achievementUnlock', e);
    }
  }

  /// Tier unlock celebration
  Future<void> tierUnlock({
    required BuildContext context,
    Offset? origin,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.achievementUnlock(origin: origin);

      // Haptics
      await _haptics.unlock();
      await Future.delayed(const Duration(milliseconds: 200));
      await _haptics.heavy();

      // Sound
      await _sound.tierUnlock();

      AnalyticsLogger.logEvent('animation_tier_unlock');
    } catch (e) {
      _logError('tierUnlock', e);
    }
  }

  /// Coin collect feedback
  Future<void> coinCollect({
    required BuildContext context,
    required Offset origin,
    int amount = 1,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.coinSparkle(origin: origin);

      // Haptics
      await _haptics.coin();

      // Sound
      await _sound.coinCollect();

      AnalyticsLogger.logEvent('animation_coin_collect', parameters: {
        'amount': amount,
      });
    } catch (e) {
      _logError('coinCollect', e);
    }
  }

  /// Star earned feedback
  Future<void> starEarned({
    required BuildContext context,
    required Offset origin,
    required int starNumber,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.starBurst(origin: origin, starCount: 1);

      // Haptics
      await _haptics.light();

      // Sound
      await _sound.star();

      AnalyticsLogger.logEvent('animation_star_earned', parameters: {
        'star_number': starNumber,
      });
    } catch (e) {
      _logError('starEarned', e);
    }
  }

  /// Combo feedback (with intensity)
  Future<void> combo({
    required BuildContext context,
    required Offset origin,
    required int comboCount,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.combo(origin: origin, comboCount: comboCount);

      // Haptics (intensity based on combo count)
      final intensity = (comboCount / 2).ceil().clamp(1, 5);
      await _haptics.combo(intensity);

      // Sound
      await _sound.combo(intensity);

      AnalyticsLogger.logEvent('animation_combo', parameters: {
        'combo_count': comboCount,
        'intensity': intensity,
      });
    } catch (e) {
      _logError('combo', e);
    }
  }

  /// Button press feedback
  Future<void> buttonPress() async {
    try {
      await _haptics.buttonPress();
      await _sound.buttonTap();
    } catch (e) {
      _logError('buttonPress', e);
    }
  }

  /// Piece pickup feedback
  Future<void> piecePickup({
    required BuildContext context,
    required Offset position,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.particleTrail(position: position);

      // Haptics
      await _haptics.dragStart();

      // Sound
      await _sound.piecePickup();
    } catch (e) {
      _logError('piecePickup', e);
    }
  }

  /// Piece placement feedback
  Future<void> piecePlacement({
    required BuildContext context,
    required Offset position,
  }) async {
    try {
      // Haptics
      await _haptics.dragEnd();

      // Sound
      await _sound.piecePlacement();
    } catch (e) {
      _logError('piecePlacement', e);
    }
  }

  /// Successful sort feedback
  Future<void> successfulSort({
    required BuildContext context,
    required Offset position,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.particleTrail(position: position);

      // Haptics
      await _haptics.success();

      // Sound
      await _sound.match();
    } catch (e) {
      _logError('successfulSort', e);
    }
  }

  /// Error feedback (invalid move)
  Future<void> error() async {
    try {
      // Haptics
      await _haptics.error();

      // Sound
      await _sound.error();

      AnalyticsLogger.logEvent('animation_error');
    } catch (e) {
      _logError('error', e);
    }
  }

  /// Warning feedback (low moves, time running out)
  Future<void> warning() async {
    try {
      // Haptics
      await _haptics.warning();

      // Sound
      await _sound.warning();

      AnalyticsLogger.logEvent('animation_warning');
    } catch (e) {
      _logError('warning', e);
    }
  }

  /// Power-up activation feedback
  Future<void> powerUpActivate({
    required BuildContext context,
    Offset? origin,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.flash(color: Colors.blue);

      // Haptics
      await _haptics.heavy();

      // Sound
      await _sound.powerUpActivate();

      AnalyticsLogger.logEvent('animation_powerup_activate');
    } catch (e) {
      _logError('powerUpActivate', e);
    }
  }

  /// Hint shown feedback
  Future<void> hintShown() async {
    try {
      // Haptics
      await _haptics.soft();

      // Sound
      await _sound.hint();

      AnalyticsLogger.logEvent('animation_hint_shown');
    } catch (e) {
      _logError('hintShown', e);
    }
  }

  /// Daily reward claim feedback
  Future<void> dailyRewardClaim({
    required BuildContext context,
    Offset? origin,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.confetti(origin: origin);

      // Haptics
      await _haptics.celebrate();

      // Sound
      await _sound.dailyReward();

      AnalyticsLogger.logEvent('animation_daily_reward');
    } catch (e) {
      _logError('dailyRewardClaim', e);
    }
  }

  /// Streak milestone feedback
  Future<void> streakMilestone({
    required BuildContext context,
    required int streakDays,
    Offset? origin,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.achievementUnlock(origin: origin);

      // Haptics
      await _haptics.celebrate();

      // Sound
      await _sound.streakMilestone();

      AnalyticsLogger.logEvent('animation_streak_milestone', parameters: {
        'streak_days': streakDays,
      });
    } catch (e) {
      _logError('streakMilestone', e);
    }
  }

  /// Purchase success feedback
  Future<void> purchaseSuccess({
    required BuildContext context,
    Offset? origin,
  }) async {
    try {
      // Visual effects
      final effectsWidget = VisualEffectsWidget.of(context);
      effectsWidget?.confetti(origin: origin);

      // Haptics
      await _haptics.heavy();

      // Sound
      await _sound.purchase();

      AnalyticsLogger.logEvent('animation_purchase_success');
    } catch (e) {
      _logError('purchaseSuccess', e);
    }
  }

  /// UI interaction feedback (swipe, scroll)
  Future<void> uiInteraction() async {
    try {
      await _haptics.light();
      await _sound.swipe();
    } catch (e) {
      _logError('uiInteraction', e);
    }
  }

  /// Popup open feedback
  Future<void> popupOpen() async {
    try {
      await _haptics.light();
      await _sound.popupOpen();
    } catch (e) {
      _logError('popupOpen', e);
    }
  }

  /// Popup close feedback
  Future<void> popupClose() async {
    try {
      await _haptics.soft();
      await _sound.popupClose();
    } catch (e) {
      _logError('popupClose', e);
    }
  }

  /// Screen transition feedback
  Future<void> screenTransition() async {
    try {
      await _haptics.light();
      await _sound.whoosh();
    } catch (e) {
      _logError('screenTransition', e);
    }
  }

  void _logError(String method, dynamic error) {
    AnalyticsLogger.logEvent('animation_coordinator_error', parameters: {
      'method': method,
      'error': error.toString(),
    });
  }
}
