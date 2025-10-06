import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import 'audio_asset_availability.dart';

class PremiumAudioManager {
  static final PremiumAudioManager _instance = PremiumAudioManager._internal();
  factory PremiumAudioManager() => _instance;
  PremiumAudioManager._internal();

  // Multiple audio players for layered effects
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _effectsPlayer = AudioPlayer();
  final AudioPlayer _spatialPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();

  final AudioAssetAvailability _assetAvailability =
      AudioAssetAvailability.instance;
  bool _missingAssetsDetected = false;

  // Audio state management
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _voiceEnabled = true;
  double _masterVolume = 0.8;
  double _musicVolume = 0.5;
  double _effectsVolume = 0.8;
  double _voiceVolume = 0.9;
  double _ambientVolume = 0.3;

  // Adaptive music system
  String _currentMusicTheme = 'peaceful';
  int _gameIntensity = 1; // 1-10 scale
  bool _isMusicPlaying = false;

  // Voice line system
  List<String> _celebratoryLines = [
    'Perfect!',
    'Amazing!',
    'Outstanding!',
    'Brilliant!',
    'Excellent!',
    'Fantastic!',
    'Superb!',
    'Wonderful!',
    'Incredible!',
    'Marvelous!'
  ];

  List<String> _encouragementLines = [
    'Keep going!',
    'You can do it!',
    'Great effort!',
    'Nice try!',
    'Almost there!',
    'Stay focused!',
    'You\'re improving!',
    'Good job!'
  ];

  // Spatial audio positions for container sounds
  Map<String, double> _containerPans = {
    'food': -0.7,
    'toys': 0.7,
    'home': -0.3,
    'animals': 0.3,
  };

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get voiceEnabled => _voiceEnabled;
  double get masterVolume => _masterVolume;
  double get musicVolume => _musicVolume;
  double get effectsVolume => _effectsVolume;

  // Initialize premium audio system
  Future<void> initialize() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _effectsPlayer.setReleaseMode(ReleaseMode.stop);
      await _spatialPlayer.setReleaseMode(ReleaseMode.stop);
      await _voicePlayer.setReleaseMode(ReleaseMode.stop);
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);

      // Set initial volumes
      await _updateAllVolumes();

      if (kDebugMode) {
        print('Premium Audio Manager initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Premium Audio Manager initialization error: $e');
      }
    }
  }

  // Adaptive background music that changes with gameplay
  Future<void> playAdaptiveBackgroundMusic(int gameSpeed, int level) async {
    if (!_musicEnabled || _isMusicPlaying) return;

    _gameIntensity = math.min(10, (gameSpeed * 2 + level / 5).round());

    String musicTrack = 'ambient_peaceful.mp3';
    if (_gameIntensity >= 8) {
      musicTrack = 'ambient_intense.mp3';
      _currentMusicTheme = 'intense';
    } else if (_gameIntensity >= 5) {
      musicTrack = 'ambient_energetic.mp3';
      _currentMusicTheme = 'energetic';
    } else {
      _currentMusicTheme = 'peaceful';
    }

    final musicAsset = 'audio/music/$musicTrack';
    if (!await _ensureAssetAvailable(musicAsset)) {
      return;
    }

    try {
      await _musicPlayer.play(
        AssetSource(musicAsset),
        volume: _musicVolume * _masterVolume,
      );
      _isMusicPlaying = true;
    } catch (e) {
      if (kDebugMode) {
        print('Adaptive background music error: $e - Continuing silently');
      }
      return;
    }

    final ambientAsset = 'audio/ambient/nature_base.mp3';
    if (!await _ensureAssetAvailable(ambientAsset)) {
      return;
    }

    try {
      await _ambientPlayer.play(
        AssetSource(ambientAsset),
        volume: _ambientVolume * _masterVolume,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Adaptive ambient layer error: $e');
      }
    }
  }

  // Dynamic music adjustment based on game state
  Future<void> adjustMusicIntensity(int newIntensity) async {
    if (!_musicEnabled || newIntensity == _gameIntensity) return;

    _gameIntensity = newIntensity;

    // Crossfade to appropriate intensity
    await _musicPlayer.setVolume(0.0);

    String newTrack = 'ambient_peaceful.mp3';
    if (_gameIntensity >= 8) {
      newTrack = 'ambient_intense.mp3';
      _currentMusicTheme = 'intense';
    } else if (_gameIntensity >= 5) {
      newTrack = 'ambient_energetic.mp3';
      _currentMusicTheme = 'energetic';
    } else {
      _currentMusicTheme = 'peaceful';
    }

    final assetPath = 'audio/music/$newTrack';
    if (!await _ensureAssetAvailable(assetPath)) {
      return;
    }

    try {
      await _musicPlayer.play(AssetSource(assetPath));

      // Fade in new track
      for (double volume = 0.0;
          volume <= _musicVolume * _masterVolume;
          volume += 0.05) {
        await _musicPlayer.setVolume(volume);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Music intensity adjustment error: $e');
      }
    }
  }

  // Spatial audio effects for different containers
  Future<void> playSpatialContainerSound(
      String containerId, String soundType) async {
    if (!_soundEnabled) return;

    final pan = _containerPans[containerId] ?? 0.0;
    String soundFile = 'container_${containerId}_$soundType.mp3';

    final spatialAsset = 'audio/spatial/$soundFile';
    if (await _ensureAssetAvailable(spatialAsset)) {
      try {
        await _spatialPlayer.play(
          AssetSource(spatialAsset),
          volume: _effectsVolume * _masterVolume,
          balance: pan,
        );
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Spatial sound error for $spatialAsset: $e');
        }
      }
    }

    final fallbackAsset = 'audio/effects/generic_$soundType.mp3';
    if (!await _ensureAssetAvailable(fallbackAsset)) {
      return;
    }

    try {
      await _spatialPlayer.play(
        AssetSource(fallbackAsset),
        volume: _effectsVolume * _masterVolume,
        balance: pan,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Fallback spatial sound error for $fallbackAsset: $e');
      }
    }
  }

  // Enhanced success sounds with celebration voices
  Future<void> playEnhancedSuccessSound(int streak, int starsEarned) async {
    if (!_soundEnabled) return;

    String effectSound = 'success_pop.mp3';
    if (starsEarned >= 3) {
      effectSound = 'success_perfect.mp3';
    } else if (streak >= 5) {
      effectSound = 'success_streak.mp3';
    }

    final effectAsset = 'audio/effects/$effectSound';
    if (!await _ensureAssetAvailable(effectAsset)) {
      return;
    }

    try {
      // Play sound effect
      await _effectsPlayer.play(
        AssetSource(effectAsset),
        volume: _effectsVolume * _masterVolume,
      );

      // Play celebration voice line
      if (_voiceEnabled && starsEarned >= 2) {
        await _playCelebrationVoiceLine(starsEarned, streak);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Enhanced success sound error: $e');
      }
    }
  }

  // Celebration voice lines with emotional resonance
  Future<void> _playCelebrationVoiceLine(int stars, int streak) async {
    if (!_voiceEnabled) return;

    String voiceLine;
    if (stars >= 3 && streak >= 10) {
      voiceLine = 'voice_amazing_streak.mp3';
    } else if (stars >= 3) {
      voiceLine = 'voice_perfect.mp3';
    } else if (streak >= 5) {
      voiceLine = 'voice_great_streak.mp3';
    } else {
      final randomLine =
          _celebratoryLines[math.Random().nextInt(_celebratoryLines.length)];
      voiceLine = 'voice_${randomLine.toLowerCase().replaceAll('!', '')}.mp3';
    }

    final assetPath = 'audio/voice/$voiceLine';
    if (!await _ensureAssetAvailable(assetPath)) {
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 200)); // Slight delay
      await _voicePlayer.play(
        AssetSource(assetPath),
        volume: _voiceVolume * _masterVolume,
      );
    } catch (e) {
      if (kDebugMode) {
        print(
            'Voice line error for $voiceLine: $e - Using text-to-speech fallback');
      }
      // TODO: Implement TTS fallback for voice lines
    }
  }

  // Encouraging voice lines for difficult moments
  Future<void> playEncouragementVoiceLine() async {
    if (!_voiceEnabled) return;

    final randomLine =
        _encouragementLines[math.Random().nextInt(_encouragementLines.length)];
    final voiceLine =
        'voice_${randomLine.toLowerCase().replaceAll('!', '').replaceAll(' ', '_')}.mp3';

    final assetPath = 'audio/voice/$voiceLine';
    if (!await _ensureAssetAvailable(assetPath)) {
      return;
    }

    try {
      await _voicePlayer.play(
        AssetSource(assetPath),
        volume: _voiceVolume * _masterVolume,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Encouragement voice line error: $e');
      }
    }
  }

  // Enhanced level complete fanfare with orchestral elements
  Future<void> playLevelCompleteFanfare(int stars, int level) async {
    if (!_soundEnabled) return;

    String fanfareTrack = 'level_complete_basic.mp3';
    if (stars >= 3) {
      fanfareTrack = 'level_complete_perfect.mp3';
    } else if (level % 10 == 0) {
      fanfareTrack = 'milestone_fanfare.mp3';
    } else if (level % 5 == 0) {
      fanfareTrack = 'level_complete_special.mp3';
    }

    final fanfareAsset = 'audio/fanfares/$fanfareTrack';
    if (!await _ensureAssetAvailable(fanfareAsset)) {
      return;
    }

    try {
      // Fade out background music
      for (double volume = _musicVolume * _masterVolume;
          volume >= 0.1;
          volume -= 0.05) {
        await _musicPlayer.setVolume(volume);
        await Future.delayed(const Duration(milliseconds: 30));
      }

      // Play fanfare
      await _effectsPlayer.play(
        AssetSource(fanfareAsset),
        volume: _effectsVolume * _masterVolume,
      );

      // Play victory voice line
      if (_voiceEnabled && stars >= 2) {
        const voiceAsset = 'audio/voice/voice_level_complete.mp3';
        if (!await _ensureAssetAvailable(voiceAsset)) {
          return;
        }
        await Future.delayed(const Duration(milliseconds: 800));
        await _voicePlayer.play(
          AssetSource(voiceAsset),
          volume: _voiceVolume * _masterVolume,
        );
      }

      // Restore background music after fanfare
      await Future.delayed(const Duration(seconds: 3));
      await _musicPlayer.setVolume(_musicVolume * _masterVolume);
    } catch (e) {
      if (kDebugMode) {
        print('Level complete fanfare error: $e');
      }
    }
  }

  // Contextual error sounds with spatial feedback
  Future<void> playContextualErrorSound(String containerId) async {
    if (!_soundEnabled) return;

    await playSpatialContainerSound(containerId, 'error');

    // Add a subtle shake sound for tactile feedback
    const shakeAsset = 'audio/effects/container_shake.mp3';
    if (!await _ensureAssetAvailable(shakeAsset)) {
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await _effectsPlayer.play(
        AssetSource(shakeAsset),
        volume: _effectsVolume * _masterVolume * 0.7,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Contextual error sound error: $e');
      }
    }
  }

  // Advanced whoosh sound with Doppler effect
  Future<void> playAdvancedWhooshSound(
      double velocity, String direction) async {
    if (!_soundEnabled) return;

    final pitch = math.max(0.8, math.min(1.2, 1.0 + (velocity - 1.0) * 0.3));
    final pan = direction == 'left'
        ? -0.5
        : direction == 'right'
            ? 0.5
            : 0.0;

    const dopplerAsset = 'audio/effects/whoosh_doppler.mp3';
    if (await _ensureAssetAvailable(dopplerAsset)) {
      try {
        await _spatialPlayer.play(
          AssetSource(dopplerAsset),
          volume: _effectsVolume * _masterVolume,
          balance: pan,
        );
        // Note: AudioPlayer doesn't support pitch adjustment directly in Flutter
        // This would require platform-specific implementation
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Advanced whoosh error: $e');
        }
      }
    }

    const fallbackAsset = 'audio/effects/whoosh_basic.mp3';
    if (!await _ensureAssetAvailable(fallbackAsset)) {
      return;
    }

    try {
      await _effectsPlayer.play(
        AssetSource(fallbackAsset),
        volume: _effectsVolume * _masterVolume,
        balance: pan,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Fallback whoosh error: $e');
      }
    }
  }

  // Multi-layered sparkle effects
  Future<void> playLayeredSparkleSound(int intensity) async {
    if (!_soundEnabled) return;

    const baseAsset = 'audio/effects/sparkle_base.mp3';
    if (!await _ensureAssetAvailable(baseAsset)) {
      return;
    }

    try {
      // Base sparkle
      await _effectsPlayer.play(
        AssetSource(baseAsset),
        volume: _effectsVolume * _masterVolume,
      );

      // Additional layers based on intensity
      if (intensity >= 2) {
        const layerTwoAsset = 'audio/effects/sparkle_layer2.mp3';
        if (!await _ensureAssetAvailable(layerTwoAsset)) {
          return;
        }
        await Future.delayed(const Duration(milliseconds: 150));
        await _spatialPlayer.play(
          AssetSource(layerTwoAsset),
          volume: _effectsVolume * _masterVolume * 0.8,
        );
      }

      if (intensity >= 3) {
        const layerThreeAsset = 'audio/effects/sparkle_layer3.mp3';
        if (!await _ensureAssetAvailable(layerThreeAsset)) {
          return;
        }
        await Future.delayed(const Duration(milliseconds: 100));
        await _ambientPlayer.play(
          AssetSource(layerThreeAsset),
          volume: _effectsVolume * _masterVolume * 0.6,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Layered sparkle sound error: $e');
      }
    }
  }

  // Dynamic button tap sounds with theme variations
  Future<void> playThemeTapSound(String theme) async {
    if (!_soundEnabled) return;

    String tapSound = 'tap_default.mp3';
    switch (theme) {
      case 'crystal':
        tapSound = 'tap_crystal.mp3';
        break;
      case 'neon':
        tapSound = 'tap_neon.mp3';
        break;
      case 'golden':
        tapSound = 'tap_golden.mp3';
        break;
      case 'metallic':
        tapSound = 'tap_metallic.mp3';
        break;
    }

    final themedAsset = 'audio/effects/themes/$tapSound';
    if (await _ensureAssetAvailable(themedAsset)) {
      try {
        await _effectsPlayer.play(
          AssetSource(themedAsset),
          volume: _effectsVolume * _masterVolume * 0.9,
        );
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Theme tap sound error for $themedAsset: $e');
        }
      }
    }

    const fallbackAsset = 'audio/effects/button_tap.mp3';
    if (!await _ensureAssetAvailable(fallbackAsset)) {
      return;
    }

    try {
      await _effectsPlayer.play(
        AssetSource('audio/effects/button_tap.mp3'),
        volume: _effectsVolume * _masterVolume,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Fallback tap sound error: $e');
      }
    }
  }

  // Stop all audio gracefully
  Future<void> stopAllAudio() async {
    try {
      await _musicPlayer.stop();
      await _effectsPlayer.stop();
      await _spatialPlayer.stop();
      await _voicePlayer.stop();
      await _ambientPlayer.stop();
      _isMusicPlaying = false;
    } catch (e) {
      if (kDebugMode) {
        print('Stop all audio error: $e');
      }
    }
  }

  // Advanced volume controls
  Future<void> _updateAllVolumes() async {
    try {
      await _musicPlayer.setVolume(_musicVolume * _masterVolume);
      await _effectsPlayer.setVolume(_effectsVolume * _masterVolume);
      await _spatialPlayer.setVolume(_effectsVolume * _masterVolume);
      await _voicePlayer.setVolume(_voiceVolume * _masterVolume);
      await _ambientPlayer.setVolume(_ambientVolume * _masterVolume);
    } catch (e) {
      if (kDebugMode) {
        print('Update volumes error: $e');
      }
    }
  }

  Future<bool> _ensureAssetAvailable(String assetPath) async {
    if (_missingAssetsDetected) {
      return false;
    }

    final exists = await _assetAvailability.exists(assetPath);
    if (!exists) {
      await _handleMissingAssets();
      return false;
    }

    return true;
  }

  Future<void> _handleMissingAssets() async {
    if (_missingAssetsDetected) {
      return;
    }

    _missingAssetsDetected = true;
    _soundEnabled = false;
    _musicEnabled = false;
    _voiceEnabled = false;
    _isMusicPlaying = false;

    try {
      await stopAllAudio();
    } catch (_) {}

    _assetAvailability.notifyMissingAssets(isPremium: true);
  }

  // Settings methods
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    await _updateAllVolumes();
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume * _masterVolume);
  }

  Future<void> setEffectsVolume(double volume) async {
    _effectsVolume = volume.clamp(0.0, 1.0);
    await _effectsPlayer.setVolume(_effectsVolume * _masterVolume);
    await _spatialPlayer.setVolume(_effectsVolume * _masterVolume);
  }

  Future<void> setVoiceVolume(double volume) async {
    _voiceVolume = volume.clamp(0.0, 1.0);
    await _voicePlayer.setVolume(_voiceVolume * _masterVolume);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    if (!enabled) {
      await _effectsPlayer.stop();
      await _spatialPlayer.stop();
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      await _musicPlayer.stop();
      await _ambientPlayer.stop();
      _isMusicPlaying = false;
    }
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    _voiceEnabled = enabled;
    if (!enabled) {
      await _voicePlayer.stop();
    }
  }

  // Cleanup
  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
      await _effectsPlayer.dispose();
      await _spatialPlayer.dispose();
      await _voicePlayer.dispose();
      await _ambientPlayer.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('Premium Audio Manager dispose error: $e');
      }
    }
  }
}
