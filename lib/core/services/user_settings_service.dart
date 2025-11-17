import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized persistent storage for user configurable settings.
///
/// This service exposes a [ValueListenable] that notifies listeners whenever
/// a setting changes so that screens can update reactively without having to
/// manually fetch from [SharedPreferences] each rebuild.
class UserSettingsService {
  UserSettingsService._();

  static final UserSettingsService instance = UserSettingsService._();

  static const String _settingsKey = 'user_settings_v1';

  final ValueNotifier<UserSettings> _settingsNotifier =
      ValueNotifier(UserSettings.defaults);

  SharedPreferences? _preferences;
  bool _initialized = false;

  /// Read-only listenable for UI widgets.
  ValueListenable<UserSettings> get settings => _settingsNotifier;

  /// Performs lazy initialization of [SharedPreferences] and loads persisted
  /// settings when available.
  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    try {
      _preferences ??= await SharedPreferences.getInstance();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Failed to initialize SharedPreferences for user settings: '
          '$error\n$stackTrace',
        );
      }
      _initialized = true;
      return;
    }
    final jsonString = _preferences?.getString(_settingsKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        _settingsNotifier.value = UserSettings.fromJson(decoded);
      } catch (_) {
        // If decoding fails fall back to defaults and remove the invalid data.
        await _preferences?.remove(_settingsKey);
        _settingsNotifier.value = UserSettings.defaults;
      }
    }
    _initialized = true;
  }

  /// Persists the new [settings] and notifies listeners.
  Future<void> updateSettings(UserSettings settings) async {
    _settingsNotifier.value = settings;
    if (!_initialized) {
      await ensureInitialized();
    }
    await _preferences?.setString(
      _settingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  Future<void> setSoundEffectsEnabled(bool value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(soundEffectsEnabled: value),
    );
  }

  Future<void> setMusicEnabled(bool value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(musicEnabled: value),
    );
  }

  Future<void> setHapticsEnabled(bool value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(hapticsEnabled: value),
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(notificationsEnabled: value),
    );
  }

  Future<void> setVoiceCommandsEnabled(bool value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(voiceCommandsEnabled: value),
    );
  }

  Future<void> setDifficulty(double value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(difficulty: value),
    );
  }

  Future<void> setTextScale(double value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(textScale: value),
    );
  }

  Future<void> setReduceMotion(bool value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(reduceMotion: value),
    );
  }

  Future<void> setHighContrastMode(bool value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(highContrastMode: value),
    );
  }

  Future<void> setParticleEffectsEnabled(bool value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(particleEffectsEnabled: value),
    );
  }

  Future<void> setPerformanceMode(bool value) async {
    await updateSettings(
      _settingsNotifier.value.copyWith(performanceMode: value),
    );
  }

  Future<void> resetToDefaults() async {
    await updateSettings(UserSettings.defaults);
  }
}

/// Immutable representation of the player's configurable settings.
class UserSettings {
  const UserSettings({
    required this.soundEffectsEnabled,
    required this.musicEnabled,
    required this.hapticsEnabled,
    required this.notificationsEnabled,
    required this.voiceCommandsEnabled,
    required this.difficulty,
    required this.textScale,
    required this.reduceMotion,
    required this.highContrastMode,
    required this.particleEffectsEnabled,
    required this.performanceMode,
  });

  final bool soundEffectsEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;
  final bool notificationsEnabled;
  final bool voiceCommandsEnabled;
  final double difficulty;
  final double textScale;
  final bool reduceMotion;
  final bool highContrastMode;
  final bool particleEffectsEnabled;
  final bool performanceMode;

  static const UserSettings defaults = UserSettings(
    soundEffectsEnabled: true,
    musicEnabled: true,
    hapticsEnabled: true,
    notificationsEnabled: true,
    voiceCommandsEnabled: false,
    difficulty: 0.5,
    textScale: 1.0,
    reduceMotion: false,
    highContrastMode: false,
    particleEffectsEnabled: true,
    performanceMode: false,
  );

  UserSettings copyWith({
    bool? soundEffectsEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    bool? notificationsEnabled,
    bool? voiceCommandsEnabled,
    double? difficulty,
    double? textScale,
    bool? reduceMotion,
    bool? highContrastMode,
    bool? particleEffectsEnabled,
    bool? performanceMode,
  }) {
    return UserSettings(
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      voiceCommandsEnabled:
          voiceCommandsEnabled ?? this.voiceCommandsEnabled,
      difficulty: difficulty ?? this.difficulty,
      textScale: textScale ?? this.textScale,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      particleEffectsEnabled: particleEffectsEnabled ?? this.particleEffectsEnabled,
      performanceMode: performanceMode ?? this.performanceMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundEffectsEnabled': soundEffectsEnabled,
      'musicEnabled': musicEnabled,
      'hapticsEnabled': hapticsEnabled,
      'notificationsEnabled': notificationsEnabled,
      'voiceCommandsEnabled': voiceCommandsEnabled,
      'difficulty': difficulty,
      'textScale': textScale,
      'reduceMotion': reduceMotion,
      'highContrastMode': highContrastMode,
      'particleEffectsEnabled': particleEffectsEnabled,
      'performanceMode': performanceMode,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      soundEffectsEnabled: json['soundEffectsEnabled'] as bool? ?? defaults.soundEffectsEnabled,
      musicEnabled: json['musicEnabled'] as bool? ?? defaults.musicEnabled,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? defaults.hapticsEnabled,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? defaults.notificationsEnabled,
      voiceCommandsEnabled: json['voiceCommandsEnabled'] as bool? ?? defaults.voiceCommandsEnabled,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? defaults.difficulty,
      textScale: (json['textScale'] as num?)?.toDouble() ?? defaults.textScale,
      reduceMotion: json['reduceMotion'] as bool? ?? defaults.reduceMotion,
      highContrastMode: json['highContrastMode'] as bool? ?? defaults.highContrastMode,
      particleEffectsEnabled: json['particleEffectsEnabled'] as bool? ?? defaults.particleEffectsEnabled,
      performanceMode: json['performanceMode'] as bool? ?? defaults.performanceMode,
    );
  }
}
