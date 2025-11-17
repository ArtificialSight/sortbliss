import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound effects service for SortBliss
///
/// Manages all game sound effects and music.
/// Ready for integration with audioplayers or just_audio package.
///
/// Sound Events:
/// - Move sounds (tap, pour, success)
/// - UI sounds (button clicks, menu open/close)
/// - Celebration sounds (level complete, achievement unlock)
/// - Feedback sounds (error, warning, hint)
/// - Background music
///
/// Usage:
/// ```dart
/// SoundService.instance.playSound(SoundEffect.move);
/// SoundService.instance.playMusic(MusicTrack.gameplay);
/// SoundService.instance.setVolume(0.8);
/// ```
class SoundService {
  static final SoundService instance = SoundService._();
  SoundService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Settings keys
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyMusicEnabled = 'music_enabled';
  static const String _keySoundVolume = 'sound_volume';
  static const String _keyMusicVolume = 'music_volume';

  // State
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 0.8;
  double _musicVolume = 0.6;

  // TODO: Add audio player instances when package is added
  // AudioPlayer? _musicPlayer;
  // AudioCache? _soundEffects;

  /// Initialize sound service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Load settings
    _soundEnabled = _prefs.getBool(_keySoundEnabled) ?? true;
    _musicEnabled = _prefs.getBool(_keyMusicEnabled) ?? true;
    _soundVolume = _prefs.getDouble(_keySoundVolume) ?? 0.8;
    _musicVolume = _prefs.getDouble(_keyMusicVolume) ?? 0.6;

    // TODO: Initialize audio players
    // _musicPlayer = AudioPlayer();
    // _soundEffects = AudioCache();

    _initialized = true;

    if (kDebugMode) {
      debugPrint('🔊 Sound Service initialized');
      debugPrint('   Sound: $_soundEnabled (${(_soundVolume * 100).toInt()}%)');
      debugPrint('   Music: $_musicEnabled (${(_musicVolume * 100).toInt()}%)');
    }
  }

  /// Play sound effect
  void playSound(SoundEffect effect) {
    if (!_initialized || !_soundEnabled || _soundVolume == 0) return;

    if (kDebugMode) {
      debugPrint('🔊 Playing sound: ${effect.name}');
    }

    // TODO: Implement actual sound playback
    // _soundEffects?.play(effect.fileName, volume: _soundVolume);
  }

  /// Play background music
  void playMusic(MusicTrack track) {
    if (!_initialized || !_musicEnabled || _musicVolume == 0) return;

    if (kDebugMode) {
      debugPrint('🎵 Playing music: ${track.name}');
    }

    // TODO: Implement actual music playback
    // _musicPlayer?.play(AssetSource(track.fileName));
    // _musicPlayer?.setVolume(_musicVolume);
    // _musicPlayer?.setReleaseMode(ReleaseMode.loop);
  }

  /// Stop music
  void stopMusic() {
    if (!_initialized) return;

    if (kDebugMode) {
      debugPrint('🎵 Stopping music');
    }

    // TODO: Implement music stop
    // _musicPlayer?.stop();
  }

  /// Pause music
  void pauseMusic() {
    if (!_initialized) return;

    if (kDebugMode) {
      debugPrint('🎵 Pausing music');
    }

    // TODO: Implement music pause
    // _musicPlayer?.pause();
  }

  /// Resume music
  void resumeMusic() {
    if (!_initialized) return;

    if (kDebugMode) {
      debugPrint('🎵 Resuming music');
    }

    // TODO: Implement music resume
    // _musicPlayer?.resume();
  }

  /// Enable/disable sound effects
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _prefs.setBool(_keySoundEnabled, enabled);

    if (kDebugMode) {
      debugPrint('🔊 Sound effects: ${enabled ? "enabled" : "disabled"}');
    }
  }

  /// Enable/disable background music
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _prefs.setBool(_keyMusicEnabled, enabled);

    if (!enabled) {
      stopMusic();
    }

    if (kDebugMode) {
      debugPrint('🎵 Music: ${enabled ? "enabled" : "disabled"}');
    }
  }

  /// Set sound effects volume (0.0 - 1.0)
  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    await _prefs.setDouble(_keySoundVolume, _soundVolume);

    if (kDebugMode) {
      debugPrint('🔊 Sound volume: ${(_soundVolume * 100).toInt()}%');
    }
  }

  /// Set music volume (0.0 - 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _prefs.setDouble(_keyMusicVolume, _musicVolume);

    // TODO: Update music player volume
    // _musicPlayer?.setVolume(_musicVolume);

    if (kDebugMode) {
      debugPrint('🎵 Music volume: ${(_musicVolume * 100).toInt()}%');
    }
  }

  /// Getters
  bool get isSoundEnabled => _soundEnabled;
  bool get isMusicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
}

/// Sound effect types
enum SoundEffect {
  // UI sounds
  buttonClick('button_click.mp3'),
  buttonHover('button_hover.mp3'),
  menuOpen('menu_open.mp3'),
  menuClose('menu_close.mp3'),

  // Gameplay sounds
  containerSelect('container_select.mp3'),
  itemMove('item_move.mp3'),
  itemPour('item_pour.mp3'),
  moveSuccess('move_success.mp3'),
  moveError('move_error.mp3'),

  // Power-up sounds
  hintActivate('hint_activate.mp3'),
  undoActivate('undo_activate.mp3'),
  shuffleActivate('shuffle_activate.mp3'),

  // Achievement sounds
  levelComplete('level_complete.mp3'),
  levelPerfect('level_perfect.mp3'),
  achievementUnlock('achievement_unlock.mp3'),
  starEarned('star_earned.mp3'),

  // Combo sounds
  comboStart('combo_start.mp3'),
  comboIncrease('combo_increase.mp3'),
  comboMax('combo_max.mp3'),

  // Reward sounds
  coinsEarned('coins_earned.mp3'),
  dailyReward('daily_reward.mp3'),
  levelUnlock('level_unlock.mp3'),

  // Feedback sounds
  warningLow('warning_low.mp3'),
  errorSound('error.mp3'),
  success('success.mp3'),
  ;

  const SoundEffect(this.fileName);
  final String fileName;

  String get assetPath => 'assets/sounds/$fileName';
}

/// Background music tracks
enum MusicTrack {
  mainMenu('music_main_menu.mp3'),
  gameplay('music_gameplay.mp3'),
  gameplayCalm('music_gameplay_calm.mp3'),
  gameplayIntense('music_gameplay_intense.mp3'),
  victory('music_victory.mp3'),
  ;

  const MusicTrack(this.fileName);
  final String fileName;

  String get assetPath => 'assets/music/$fileName';
}

/// Sound integration helper
///
/// Call this from gameplay screen to play sounds at appropriate times.
class SoundHelper {
  static final SoundService _sound = SoundService.instance;

  // Gameplay events
  static void onContainerTap() => _sound.playSound(SoundEffect.containerSelect);
  static void onItemMove() => _sound.playSound(SoundEffect.itemMove);
  static void onMoveSuccess() => _sound.playSound(SoundEffect.moveSuccess);
  static void onMoveError() => _sound.playSound(SoundEffect.moveError);

  // Power-ups
  static void onHint() => _sound.playSound(SoundEffect.hintActivate);
  static void onUndo() => _sound.playSound(SoundEffect.undoActivate);
  static void onShuffle() => _sound.playSound(SoundEffect.shuffleActivate);

  // Level completion
  static void onLevelComplete(int stars) {
    if (stars == 3) {
      _sound.playSound(SoundEffect.levelPerfect);
    } else {
      _sound.playSound(SoundEffect.levelComplete);
    }
  }

  static void onStarEarned() => _sound.playSound(SoundEffect.starEarned);
  static void onCoinsEarned() => _sound.playSound(SoundEffect.coinsEarned);

  // Combo
  static void onComboStart() => _sound.playSound(SoundEffect.comboStart);
  static void onComboIncrease(int count) {
    if (count >= 10) {
      _sound.playSound(SoundEffect.comboMax);
    } else {
      _sound.playSound(SoundEffect.comboIncrease);
    }
  }

  // UI
  static void onButtonClick() => _sound.playSound(SoundEffect.buttonClick);
  static void onMenuOpen() => _sound.playSound(SoundEffect.menuOpen);
  static void onMenuClose() => _sound.playSound(SoundEffect.menuClose);

  // Warnings
  static void onLowMoves() => _sound.playSound(SoundEffect.warningLow);
  static void onError() => _sound.playSound(SoundEffect.errorSound);
  static void onSuccess() => _sound.playSound(SoundEffect.success);

  // Music
  static void startGameplayMusic() => _sound.playMusic(MusicTrack.gameplay);
  static void startMenuMusic() => _sound.playMusic(MusicTrack.mainMenu);
  static void stopMusic() => _sound.stopMusic();
  static void pauseMusic() => _sound.pauseMusic();
  static void resumeMusic() => _sound.resumeMusic();
}
