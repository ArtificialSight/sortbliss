import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sortbliss/core/services/user_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserSettings', () {
    test('defaults should have expected values', () {
      expect(UserSettings.defaults.soundEffectsEnabled, true);
      expect(UserSettings.defaults.musicEnabled, true);
      expect(UserSettings.defaults.hapticsEnabled, true);
      expect(UserSettings.defaults.notificationsEnabled, true);
      expect(UserSettings.defaults.voiceCommandsEnabled, false);
      expect(UserSettings.defaults.difficulty, 0.5);
    });

    test('toJson should serialize all fields correctly', () {
      const settings = UserSettings(
        soundEffectsEnabled: false,
        musicEnabled: false,
        hapticsEnabled: false,
        notificationsEnabled: false,
        voiceCommandsEnabled: true,
        difficulty: 0.75,
      );

      final json = settings.toJson();

      expect(json['soundEffectsEnabled'], false);
      expect(json['musicEnabled'], false);
      expect(json['hapticsEnabled'], false);
      expect(json['notificationsEnabled'], false);
      expect(json['voiceCommandsEnabled'], true);
      expect(json['difficulty'], 0.75);
    });

    test('fromJson should deserialize all fields correctly', () {
      final json = {
        'soundEffectsEnabled': false,
        'musicEnabled': false,
        'hapticsEnabled': false,
        'notificationsEnabled': false,
        'voiceCommandsEnabled': true,
        'difficulty': 0.25,
      };

      final settings = UserSettings.fromJson(json);

      expect(settings.soundEffectsEnabled, false);
      expect(settings.musicEnabled, false);
      expect(settings.hapticsEnabled, false);
      expect(settings.notificationsEnabled, false);
      expect(settings.voiceCommandsEnabled, true);
      expect(settings.difficulty, 0.25);
    });

    test('fromJson should use defaults for missing fields', () {
      final json = <String, dynamic>{};

      final settings = UserSettings.fromJson(json);

      expect(settings.soundEffectsEnabled, true);
      expect(settings.musicEnabled, true);
      expect(settings.hapticsEnabled, true);
      expect(settings.notificationsEnabled, true);
      expect(settings.voiceCommandsEnabled, false);
      expect(settings.difficulty, 0.5);
    });

    test('copyWith should update only specified fields', () {
      const original = UserSettings(
        soundEffectsEnabled: true,
        musicEnabled: true,
        hapticsEnabled: true,
        notificationsEnabled: true,
        voiceCommandsEnabled: false,
        difficulty: 0.5,
      );

      final updated = original.copyWith(
        soundEffectsEnabled: false,
        difficulty: 0.8,
      );

      expect(updated.soundEffectsEnabled, false);
      expect(updated.musicEnabled, true); // unchanged
      expect(updated.hapticsEnabled, true); // unchanged
      expect(updated.notificationsEnabled, true); // unchanged
      expect(updated.voiceCommandsEnabled, false); // unchanged
      expect(updated.difficulty, 0.8);
    });

    test('toJson and fromJson should be symmetric', () {
      const original = UserSettings(
        soundEffectsEnabled: false,
        musicEnabled: true,
        hapticsEnabled: false,
        notificationsEnabled: true,
        voiceCommandsEnabled: true,
        difficulty: 0.33,
      );

      final json = original.toJson();
      final deserialized = UserSettings.fromJson(json);

      expect(deserialized.soundEffectsEnabled, original.soundEffectsEnabled);
      expect(deserialized.musicEnabled, original.musicEnabled);
      expect(deserialized.hapticsEnabled, original.hapticsEnabled);
      expect(deserialized.notificationsEnabled, original.notificationsEnabled);
      expect(deserialized.voiceCommandsEnabled, original.voiceCommandsEnabled);
      expect(deserialized.difficulty, original.difficulty);
    });

    test('should handle integer difficulty in JSON', () {
      final json = {'difficulty': 1}; // Integer instead of double

      final settings = UserSettings.fromJson(json);

      expect(settings.difficulty, 1.0);
    });

    test('should handle extreme difficulty values', () {
      const settings = UserSettings(
        soundEffectsEnabled: true,
        musicEnabled: true,
        hapticsEnabled: true,
        notificationsEnabled: true,
        voiceCommandsEnabled: false,
        difficulty: 0.0,
      );

      expect(settings.difficulty, 0.0);

      const settings2 = UserSettings(
        soundEffectsEnabled: true,
        musicEnabled: true,
        hapticsEnabled: true,
        notificationsEnabled: true,
        voiceCommandsEnabled: false,
        difficulty: 1.0,
      );

      expect(settings2.difficulty, 1.0);
    });
  });

  group('UserSettingsService', () {
    late UserSettingsService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = UserSettingsService.instance;
    });

    test('instance should return singleton', () {
      final instance1 = UserSettingsService.instance;
      final instance2 = UserSettingsService.instance;
      expect(instance1, same(instance2));
    });

    test('should start with default settings', () {
      expect(service.settings.value.soundEffectsEnabled, true);
      expect(service.settings.value.musicEnabled, true);
      expect(service.settings.value.hapticsEnabled, true);
      expect(service.settings.value.notificationsEnabled, true);
      expect(service.settings.value.voiceCommandsEnabled, false);
      expect(service.settings.value.difficulty, 0.5);
    });

    test('ensureInitialized should load default settings when no stored data',
        () async {
      await service.ensureInitialized();

      expect(service.settings.value.soundEffectsEnabled, true);
      expect(service.settings.value.musicEnabled, true);
      expect(service.settings.value.hapticsEnabled, true);
      expect(service.settings.value.notificationsEnabled, true);
      expect(service.settings.value.voiceCommandsEnabled, false);
      expect(service.settings.value.difficulty, 0.5);
    });

    test('ensureInitialized should load stored settings when data exists',
        () async {
      const storedSettings = UserSettings(
        soundEffectsEnabled: false,
        musicEnabled: false,
        hapticsEnabled: false,
        notificationsEnabled: false,
        voiceCommandsEnabled: true,
        difficulty: 0.9,
      );

      SharedPreferences.setMockInitialValues({
        'user_settings_v1': jsonEncode(storedSettings.toJson()),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'user_settings_v1', jsonEncode(storedSettings.toJson()));

      await service.ensureInitialized();

      expect(service.settings.value.soundEffectsEnabled, false);
      expect(service.settings.value.musicEnabled, false);
      expect(service.settings.value.hapticsEnabled, false);
      expect(service.settings.value.notificationsEnabled, false);
      expect(service.settings.value.voiceCommandsEnabled, true);
      expect(service.settings.value.difficulty, 0.9);
    });

    test('ensureInitialized should handle corrupted JSON gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'user_settings_v1': 'invalid json data',
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_settings_v1', 'invalid json data');

      await service.ensureInitialized();

      // Should fall back to defaults and remove invalid data
      expect(service.settings.value.soundEffectsEnabled, true);
      expect(service.settings.value.musicEnabled, true);
      expect(service.settings.value.hapticsEnabled, true);
    });

    test('ensureInitialized should only initialize once', () async {
      await service.ensureInitialized();
      await service.ensureInitialized();
      await service.ensureInitialized();

      expect(service.settings.value, isNotNull);
    });

    test('updateSettings should update all settings', () async {
      await service.ensureInitialized();

      const newSettings = UserSettings(
        soundEffectsEnabled: false,
        musicEnabled: false,
        hapticsEnabled: false,
        notificationsEnabled: false,
        voiceCommandsEnabled: true,
        difficulty: 0.7,
      );

      await service.updateSettings(newSettings);

      expect(service.settings.value.soundEffectsEnabled, false);
      expect(service.settings.value.musicEnabled, false);
      expect(service.settings.value.hapticsEnabled, false);
      expect(service.settings.value.notificationsEnabled, false);
      expect(service.settings.value.voiceCommandsEnabled, true);
      expect(service.settings.value.difficulty, 0.7);
    });

    test('setSoundEffectsEnabled should toggle sound effects', () async {
      await service.ensureInitialized();

      await service.setSoundEffectsEnabled(false);
      expect(service.settings.value.soundEffectsEnabled, false);

      await service.setSoundEffectsEnabled(true);
      expect(service.settings.value.soundEffectsEnabled, true);
    });

    test('setMusicEnabled should toggle music', () async {
      await service.ensureInitialized();

      await service.setMusicEnabled(false);
      expect(service.settings.value.musicEnabled, false);

      await service.setMusicEnabled(true);
      expect(service.settings.value.musicEnabled, true);
    });

    test('setHapticsEnabled should toggle haptics', () async {
      await service.ensureInitialized();

      await service.setHapticsEnabled(false);
      expect(service.settings.value.hapticsEnabled, false);

      await service.setHapticsEnabled(true);
      expect(service.settings.value.hapticsEnabled, true);
    });

    test('setNotificationsEnabled should toggle notifications', () async {
      await service.ensureInitialized();

      await service.setNotificationsEnabled(false);
      expect(service.settings.value.notificationsEnabled, false);

      await service.setNotificationsEnabled(true);
      expect(service.settings.value.notificationsEnabled, true);
    });

    test('setVoiceCommandsEnabled should toggle voice commands', () async {
      await service.ensureInitialized();

      await service.setVoiceCommandsEnabled(true);
      expect(service.settings.value.voiceCommandsEnabled, true);

      await service.setVoiceCommandsEnabled(false);
      expect(service.settings.value.voiceCommandsEnabled, false);
    });

    test('setDifficulty should update difficulty', () async {
      await service.ensureInitialized();

      await service.setDifficulty(0.0);
      expect(service.settings.value.difficulty, 0.0);

      await service.setDifficulty(0.5);
      expect(service.settings.value.difficulty, 0.5);

      await service.setDifficulty(1.0);
      expect(service.settings.value.difficulty, 1.0);
    });

    test('resetToDefaults should restore default settings', () async {
      await service.ensureInitialized();

      // Change all settings
      await service.setSoundEffectsEnabled(false);
      await service.setMusicEnabled(false);
      await service.setHapticsEnabled(false);
      await service.setNotificationsEnabled(false);
      await service.setVoiceCommandsEnabled(true);
      await service.setDifficulty(0.9);

      await service.resetToDefaults();

      expect(service.settings.value.soundEffectsEnabled, true);
      expect(service.settings.value.musicEnabled, true);
      expect(service.settings.value.hapticsEnabled, true);
      expect(service.settings.value.notificationsEnabled, true);
      expect(service.settings.value.voiceCommandsEnabled, false);
      expect(service.settings.value.difficulty, 0.5);
    });

    test('settings should notify listeners on update', () async {
      await service.ensureInitialized();

      int notificationCount = 0;
      service.settings.addListener(() {
        notificationCount++;
      });

      await service.setSoundEffectsEnabled(false);

      expect(notificationCount, greaterThan(0));
    });

    test('updates should persist to SharedPreferences', () async {
      await service.ensureInitialized();

      await service.setSoundEffectsEnabled(false);
      await service.setDifficulty(0.75);

      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('user_settings_v1');
      expect(storedJson, isNotNull);

      final decoded = jsonDecode(storedJson!) as Map<String, dynamic>;
      expect(decoded['soundEffectsEnabled'], false);
      expect(decoded['difficulty'], 0.75);
    });

    test('individual setters should not affect other settings', () async {
      await service.ensureInitialized();

      await service.setSoundEffectsEnabled(false);

      expect(service.settings.value.soundEffectsEnabled, false);
      expect(service.settings.value.musicEnabled, true); // unchanged
      expect(service.settings.value.hapticsEnabled, true); // unchanged
      expect(service.settings.value.notificationsEnabled, true); // unchanged
      expect(service.settings.value.voiceCommandsEnabled, false); // unchanged
      expect(service.settings.value.difficulty, 0.5); // unchanged
    });

    test('complex workflow: multiple setting changes', () async {
      await service.ensureInitialized();

      await service.setSoundEffectsEnabled(false);
      await service.setMusicEnabled(false);
      await service.setHapticsEnabled(false);
      await service.setDifficulty(0.8);

      expect(service.settings.value.soundEffectsEnabled, false);
      expect(service.settings.value.musicEnabled, false);
      expect(service.settings.value.hapticsEnabled, false);
      expect(service.settings.value.difficulty, 0.8);
      expect(service.settings.value.notificationsEnabled, true); // unchanged
      expect(service.settings.value.voiceCommandsEnabled, false); // unchanged
    });

    test('updateSettings should initialize if not initialized', () async {
      // Don't call ensureInitialized() first

      const newSettings = UserSettings(
        soundEffectsEnabled: false,
        musicEnabled: false,
        hapticsEnabled: false,
        notificationsEnabled: false,
        voiceCommandsEnabled: true,
        difficulty: 0.6,
      );

      await service.updateSettings(newSettings);

      expect(service.settings.value.soundEffectsEnabled, false);
      expect(service.settings.value.difficulty, 0.6);
    });

    test('should handle rapid consecutive updates', () async {
      await service.ensureInitialized();

      await service.setSoundEffectsEnabled(false);
      await service.setSoundEffectsEnabled(true);
      await service.setSoundEffectsEnabled(false);
      await service.setSoundEffectsEnabled(true);

      expect(service.settings.value.soundEffectsEnabled, true);
    });

    test('should persist settings across service lifecycle', () async {
      await service.ensureInitialized();

      await service.setSoundEffectsEnabled(false);
      await service.setDifficulty(0.85);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('user_settings_v1');
      expect(storedJson, isNotNull);

      // Settings would persist across app restarts
      final decoded = jsonDecode(storedJson!) as Map<String, dynamic>;
      final restored = UserSettings.fromJson(decoded);

      expect(restored.soundEffectsEnabled, false);
      expect(restored.difficulty, 0.85);
    });
  });
}
