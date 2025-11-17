import 'dart:math';
import '../utils/analytics_logger.dart';
import 'user_settings_service.dart';

/// Centralized sound effect service with volume control and event coordination
///
/// Provides sound effect management for game events:
/// - UI sounds (tap, swipe, button)
/// - Game sounds (move, sort, complete)
/// - Achievement sounds (star, level complete, unlock)
/// - Feedback sounds (error, warning, success)
///
/// Note: Actual audio playback requires audioplayers package
/// This service provides the interface and event logging
class SoundEffectService {
  static final SoundEffectService instance = SoundEffectService._();
  SoundEffectService._();

  final UserSettingsService _settings = UserSettingsService.instance;
  bool _initialized = false;
  final Random _random = Random();

  // TODO: Uncomment after adding audioplayers package
  // import 'package:audioplayers/audioplayers.dart';
  // final AudioPlayer _player = AudioPlayer();
  // final Map<String, AudioCache> _cache = {};

  /// Initialize sound effect service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // TODO: Preload common sound effects
      // await _preloadSounds();

      _initialized = true;

      AnalyticsLogger.logEvent('sound_service_initialized', parameters: {
        'sound_enabled': _settings.soundEnabled,
        'volume': _settings.volume,
      });
    } catch (e) {
      AnalyticsLogger.logEvent('sound_init_error', parameters: {
        'error': e.toString(),
      });
    }
  }

  /// Play button tap sound
  Future<void> buttonTap() async {
    if (!_settings.soundEnabled) return;
    await _playSound('button_tap', volume: 0.3);
  }

  /// Play piece pickup sound
  Future<void> piecePickup() async {
    if (!_settings.soundEnabled) return;
    await _playSound('piece_pickup', volume: 0.4);
  }

  /// Play piece placement sound
  Future<void> piecePlacement() async {
    if (!_settings.soundEnabled) return;
    await _playSound('piece_placement', volume: 0.5);
  }

  /// Play sorting sound (pieces moving)
  Future<void> sorting() async {
    if (!_settings.soundEnabled) return;
    await _playSound('sorting', volume: 0.4);
  }

  /// Play match sound (successful sort)
  Future<void> match() async {
    if (!_settings.soundEnabled) return;
    await _playSound('match', volume: 0.6);
  }

  /// Play combo sound with intensity
  /// intensity: 1-5 (higher = different sound variant)
  Future<void> combo(int intensity) async {
    if (!_settings.soundEnabled) return;
    final soundFile = 'combo_$intensity';
    await _playSound(soundFile, volume: 0.5 + (intensity * 0.1));
  }

  /// Play star earned sound
  Future<void> star() async {
    if (!_settings.soundEnabled) return;
    await _playSound('star', volume: 0.7);
  }

  /// Play level complete sound
  Future<void> levelComplete({required int stars}) async {
    if (!_settings.soundEnabled) return;

    // Different sound based on star rating
    final soundFile = stars == 3 ? 'level_complete_perfect' : 'level_complete';
    await _playSound(soundFile, volume: 0.8);
  }

  /// Play achievement unlock sound
  Future<void> achievementUnlock() async {
    if (!_settings.soundEnabled) return;
    await _playSound('achievement_unlock', volume: 0.8);
  }

  /// Play tier unlock sound
  Future<void> tierUnlock() async {
    if (!_settings.soundEnabled) return;
    await _playSound('tier_unlock', volume: 0.9);
  }

  /// Play coin collect sound
  Future<void> coinCollect() async {
    if (!_settings.soundEnabled) return;
    await _playSound('coin_collect', volume: 0.5);
  }

  /// Play error sound (invalid move)
  Future<void> error() async {
    if (!_settings.soundEnabled) return;
    await _playSound('error', volume: 0.6);
  }

  /// Play warning sound (low moves, time running out)
  Future<void> warning() async {
    if (!_settings.soundEnabled) return;
    await _playSound('warning', volume: 0.5);
  }

  /// Play UI swipe sound
  Future<void> swipe() async {
    if (!_settings.soundEnabled) return;
    await _playSound('swipe', volume: 0.3);
  }

  /// Play popup open sound
  Future<void> popupOpen() async {
    if (!_settings.soundEnabled) return;
    await _playSound('popup_open', volume: 0.4);
  }

  /// Play popup close sound
  Future<void> popupClose() async {
    if (!_settings.soundEnabled) return;
    await _playSound('popup_close', volume: 0.3);
  }

  /// Play purchase sound (IAP)
  Future<void> purchase() async {
    if (!_settings.soundEnabled) return;
    await _playSound('purchase', volume: 0.8);
  }

  /// Play power-up activation sound
  Future<void> powerUpActivate() async {
    if (!_settings.soundEnabled) return;
    await _playSound('powerup_activate', volume: 0.7);
  }

  /// Play hint sound
  Future<void> hint() async {
    if (!_settings.soundEnabled) return;
    await _playSound('hint', volume: 0.5);
  }

  /// Play daily reward claim sound
  Future<void> dailyReward() async {
    if (!_settings.soundEnabled) return;
    await _playSound('daily_reward', volume: 0.8);
  }

  /// Play streak milestone sound
  Future<void> streakMilestone() async {
    if (!_settings.soundEnabled) return;
    await _playSound('streak_milestone', volume: 0.8);
  }

  /// Play whoosh sound (screen transition)
  Future<void> whoosh() async {
    if (!_settings.soundEnabled) return;
    await _playSound('whoosh', volume: 0.4);
  }

  /// Play tick sound (countdown, timer)
  Future<void> tick() async {
    if (!_settings.soundEnabled) return;
    await _playSound('tick', volume: 0.2);
  }

  /// Play ambient sound loop (gameplay music)
  Future<void> playAmbient() async {
    if (!_settings.soundEnabled) return;
    // TODO: Implement looping background music
    _logSound('ambient_start');
  }

  /// Stop ambient sound
  Future<void> stopAmbient() async {
    // TODO: Stop looping background music
    _logSound('ambient_stop');
  }

  /// Play random variation of a sound
  Future<void> playVariation(String baseSound, int variations) async {
    if (!_settings.soundEnabled) return;
    final variant = _random.nextInt(variations) + 1;
    await _playSound('${baseSound}_$variant', volume: 0.5);
  }

  /// Set master volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    // TODO: Update AudioPlayer volume
    _logSound('volume_changed', {'volume': volume});
  }

  /// Internal method to play sound
  Future<void> _playSound(String soundFile, {double volume = 0.5}) async {
    try {
      // TODO: Implement actual audio playback
      // final adjustedVolume = volume * _settings.volume;
      // await _player.play(AssetSource('sounds/$soundFile.mp3'), volume: adjustedVolume);

      _logSound(soundFile, {'volume': volume});
    } catch (e) {
      AnalyticsLogger.logEvent('sound_play_error', parameters: {
        'sound': soundFile,
        'error': e.toString(),
      });
    }
  }

  /// Preload common sounds for faster playback
  Future<void> _preloadSounds() async {
    // TODO: Preload frequently used sounds
    // final commonSounds = [
    //   'button_tap',
    //   'piece_pickup',
    //   'piece_placement',
    //   'star',
    //   'coin_collect',
    // ];
    //
    // for (final sound in commonSounds) {
    //   _cache[sound] = AudioCache(prefix: 'sounds/');
    //   await _cache[sound]!.load('$sound.mp3');
    // }
  }

  void _logSound(String sound, [Map<String, dynamic>? extra]) {
    // Only log occasionally to avoid spam (1% sampling)
    if (DateTime.now().millisecondsSinceEpoch % 100 == 0) {
      AnalyticsLogger.logEvent('sound_effect', parameters: {
        'sound': sound,
        ...?extra,
      });
    }
  }
}

/// Sound effect event names for reference
/// These correspond to audio files that should be created:
///
/// UI Sounds:
/// - button_tap.mp3
/// - swipe.mp3
/// - popup_open.mp3
/// - popup_close.mp3
/// - whoosh.mp3
///
/// Game Sounds:
/// - piece_pickup.mp3
/// - piece_placement.mp3
/// - sorting.mp3
/// - match.mp3
/// - combo_1.mp3 through combo_5.mp3
/// - tick.mp3
///
/// Achievement Sounds:
/// - star.mp3
/// - level_complete.mp3
/// - level_complete_perfect.mp3
/// - achievement_unlock.mp3
/// - tier_unlock.mp3
/// - coin_collect.mp3
/// - daily_reward.mp3
/// - streak_milestone.mp3
///
/// Feedback Sounds:
/// - error.mp3
/// - warning.mp3
/// - hint.mp3
///
/// Special Sounds:
/// - powerup_activate.mp3
/// - purchase.mp3
///
/// Ambient:
/// - ambient_gameplay.mp3 (looping)
/// - ambient_menu.mp3 (looping)
