import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Audio players for different types of sounds
  final AudioPlayer _soundEffectsPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  // Sound state management
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 0.8;
  double _musicVolume = 0.4;

  // Background music controller
  bool _isMusicPlaying = false;

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;

  // Initialize audio system
  Future<void> initialize() async {
    try {
      await _soundEffectsPlayer.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);

      // Set initial volumes
      await _soundEffectsPlayer.setVolume(_soundVolume);
      await _musicPlayer.setVolume(_musicVolume);

      if (kDebugMode) {
        print('Audio Manager initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Audio Manager initialization error: $e');
      }
    }
  }

  // Play background music
  Future<void> playBackgroundMusic() async {
    if (!_musicEnabled || _isMusicPlaying) return;

    try {
      // Using asset source for ambient game music
      // Note: In a real app, you'd add these audio files to assets/audio/
      await _musicPlayer.play(
        AssetSource('audio/ambient_background.mp3'),
        volume: _musicVolume,
      );
      _isMusicPlaying = true;
    } catch (e) {
      if (kDebugMode) {
        print('Background music play error: $e - Using silent mode');
      }
    }
  }

  // Stop background music
  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
      _isMusicPlaying = false;
    } catch (e) {
      if (kDebugMode) {
        print('Background music stop error: $e');
      }
    }
  }

  // Sound effect methods with fallback silence
  Future<void> playSuccessSound() async {
    if (!_soundEnabled) return;
    await _playSoundEffect('success_pop.mp3');
  }

  Future<void> playDropSound() async {
    if (!_soundEnabled) return;
    await _playSoundEffect('item_drop.mp3');
  }

  Future<void> playLevelCompleteSound() async {
    if (!_soundEnabled) return;
    await _playSoundEffect('level_complete.mp3');
  }

  Future<void> playButtonTapSound() async {
    if (!_soundEnabled) return;
    await _playSoundEffect('button_tap.mp3');
  }

  Future<void> playWhooshSound() async {
    if (!_soundEnabled) return;
    await _playSoundEffect('whoosh.mp3');
  }

  Future<void> playSparkleSound() async {
    if (!_soundEnabled) return;
    await _playSoundEffect('sparkle.mp3');
  }

  // Private helper method for sound effects
  Future<void> _playSoundEffect(String soundFile) async {
    try {
      await _soundEffectsPlayer.play(
        AssetSource('audio/$soundFile'),
        volume: _soundVolume,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Sound effect error for $soundFile: $e - Continuing silently');
      }
      // Fail gracefully - game continues without sound
    }
  }

  // Settings methods
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    if (!enabled) {
      await _soundEffectsPlayer.stop();
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      await stopBackgroundMusic();
    } else if (!_isMusicPlaying) {
      await playBackgroundMusic();
    }
  }

  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    await _soundEffectsPlayer.setVolume(_soundVolume);
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
  }

  // Cleanup
  Future<void> dispose() async {
    try {
      await _soundEffectsPlayer.dispose();
      await _musicPlayer.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('Audio Manager dispose error: $e');
      }
    }
  }
}
