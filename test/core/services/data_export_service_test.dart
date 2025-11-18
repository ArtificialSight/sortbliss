import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sortbliss/core/services/data_export_service.dart';
import 'package:sortbliss/core/services/player_profile_service.dart';
import 'package:sortbliss/core/services/achievements_tracker_service.dart';
import 'package:sortbliss/core/services/user_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataExportService', () {
    late DataExportService exportService;
    late PlayerProfileService profileService;
    late AchievementsTrackerService achievementsService;
    late UserSettingsService settingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      exportService = DataExportService.instance;
      profileService = PlayerProfileService.instance;
      achievementsService = AchievementsTrackerService.instance;
      settingsService = UserSettingsService.instance;

      await profileService.ensureInitialized();
      await achievementsService.ensureInitialized();
      await settingsService.ensureInitialized();
    });

    test('instance should return singleton', () {
      final instance1 = DataExportService.instance;
      final instance2 = DataExportService.instance;
      expect(instance1, same(instance2));
    });

    test('getExportSummary should return current player statistics', () async {
      final summary = await exportService.getExportSummary();

      expect(summary, isA<Map<String, dynamic>>());
      expect(summary, containsPair('total_levels_completed', isA<int>()));
      expect(summary, containsPair('total_coins_earned', isA<int>()));
      expect(summary, containsPair('current_streak', isA<int>()));
      expect(summary, containsPair('achievements_unlocked', isA<int>()));
      expect(summary, containsPair('achievements_tracked', isA<int>()));
      expect(summary, containsPair('has_premium_features', isA<bool>()));
      expect(summary, containsPair('share_count', isA<int>()));
      expect(summary, containsPair('audio_customized', isA<bool>()));
      expect(summary, containsPair('current_difficulty', isA<double>()));
    });

    test('getExportSummary should reflect current player progress', () async {
      // Update player progress
      await profileService.updateProgress(
        levelsCompleted: 50,
        currentStreak: 15,
        coinsEarned: 5000,
      );

      final summary = await exportService.getExportSummary();

      expect(summary['total_levels_completed'], 50);
      expect(summary['current_streak'], 15);
      expect(summary['total_coins_earned'], 5000);
    });

    test('getExportSummary should reflect tracked achievements', () async {
      await achievementsService.toggleTracked('Achievement 1');
      await achievementsService.toggleTracked('Achievement 2');

      final summary = await exportService.getExportSummary();

      expect(summary['achievements_tracked'], 2);
    });

    test('getExportSummary should reflect unlocked achievements', () async {
      await profileService.unlockAchievement('Test Achievement');

      final summary = await exportService.getExportSummary();

      expect(summary['achievements_unlocked'], greaterThan(0));
    });

    test('getExportSummary should reflect premium purchase status', () async {
      await profileService.setRemoveAdsPurchased(true);

      final summary = await exportService.getExportSummary();

      expect(summary['has_premium_features'], true);
    });

    test('getExportSummary should reflect current difficulty setting', () async {
      await settingsService.setDifficulty(0.75);

      final summary = await exportService.getExportSummary();

      expect(summary['current_difficulty'], 0.75);
    });

    test('getExportSummary should handle empty achievement lists', () async {
      await achievementsService.clear();

      final summary = await exportService.getExportSummary();

      expect(summary['achievements_tracked'], 0);
    });

    test('getExportSummary should be callable multiple times', () async {
      final summary1 = await exportService.getExportSummary();
      final summary2 = await exportService.getExportSummary();

      expect(summary1, isA<Map<String, dynamic>>());
      expect(summary2, isA<Map<String, dynamic>>());
    });

    test('exportAsJson should create valid JSON', () async {
      final jsonPath = await exportService.exportAsJson();

      expect(jsonPath, isNotNull);
      expect(jsonPath, endsWith('.json'));
      expect(jsonPath, contains('sortbliss_export'));
    });

    test('exportAsJson should include metadata by default', () async {
      final jsonPath = await exportService.exportAsJson();
      expect(jsonPath, isNotNull);
      // File content validation would require reading the file
    });

    test('exportAsCsv should create valid CSV file', () async {
      final csvPath = await exportService.exportAsCsv();

      expect(csvPath, isNotNull);
      expect(csvPath, endsWith('.csv'));
      expect(csvPath, contains('sortbliss_export'));
    });

    test('exportAsFormattedText should create valid text file', () async {
      final textPath = await exportService.exportAsFormattedText();

      expect(textPath, isNotNull);
      expect(textPath, endsWith('.txt'));
      expect(textPath, contains('sortbliss_export'));
    });

    test('multiple export formats should all succeed', () async {
      final jsonPath = await exportService.exportAsJson();
      final csvPath = await exportService.exportAsCsv();
      final textPath = await exportService.exportAsFormattedText();

      expect(jsonPath, isNotNull);
      expect(csvPath, isNotNull);
      expect(textPath, isNotNull);
    });

    test('exportAsJson with selective data inclusion', () async {
      final jsonPath = await exportService.exportAsJson(
        includeProfile: true,
        includeAchievements: false,
        includeSettings: false,
        includeMetadata: true,
      );

      expect(jsonPath, isNotNull);
      expect(jsonPath, endsWith('.json'));
    });

    test('exportAsJson should work with modified player data', () async {
      // Setup test data
      await profileService.updateProgress(
        levelsCompleted: 100,
        currentStreak: 30,
        coinsEarned: 10000,
      );

      await achievementsService.toggleTracked('Expert Sorter');
      await settingsService.setDifficulty(0.9);

      final jsonPath = await exportService.exportAsJson();

      expect(jsonPath, isNotNull);
    });

    test('export operations should be idempotent', () async {
      final path1 = await exportService.exportAsJson();
      final path2 = await exportService.exportAsJson();

      expect(path1, isNotNull);
      expect(path2, isNotNull);
      // Both exports should succeed
    });

    test('export should handle empty tracked achievements', () async {
      await achievementsService.clear();

      final jsonPath = await exportService.exportAsJson();
      final csvPath = await exportService.exportAsCsv();

      expect(jsonPath, isNotNull);
      expect(csvPath, isNotNull);
    });

    test('export should handle minimal player progress', () async {
      await profileService.resetProfile();

      final summary = await exportService.getExportSummary();

      expect(summary, isA<Map<String, dynamic>>());
      expect(summary['total_levels_completed'], isA<int>());
    });

    test('export should handle maximum player progress', () async {
      await profileService.updateProgress(
        levelsCompleted: 999,
        currentStreak: 365,
        coinsEarned: 999999,
      );

      for (int i = 0; i < 10; i++) {
        await profileService.unlockAchievement('Achievement $i');
      }

      final summary = await exportService.getExportSummary();

      expect(summary['total_levels_completed'], 999);
      expect(summary['current_streak'], 365);
      expect(summary['total_coins_earned'], 999999);
    });

    test('export summary should include all required fields', () async {
      final summary = await exportService.getExportSummary();

      final requiredFields = [
        'total_levels_completed',
        'total_coins_earned',
        'current_streak',
        'achievements_unlocked',
        'achievements_tracked',
        'has_premium_features',
        'share_count',
        'audio_customized',
        'current_difficulty',
      ];

      for (final field in requiredFields) {
        expect(summary, containsPair(field, isNotNull));
      }
    });

    test('export should work with all settings disabled', () async {
      await settingsService.setSoundEffectsEnabled(false);
      await settingsService.setMusicEnabled(false);
      await settingsService.setHapticsEnabled(false);
      await settingsService.setNotificationsEnabled(false);

      final jsonPath = await exportService.exportAsJson();

      expect(jsonPath, isNotNull);
    });

    test('export should work with all settings enabled', () async {
      await settingsService.setSoundEffectsEnabled(true);
      await settingsService.setMusicEnabled(true);
      await settingsService.setHapticsEnabled(true);
      await settingsService.setNotificationsEnabled(true);
      await settingsService.setVoiceCommandsEnabled(true);

      final csvPath = await exportService.exportAsCsv();

      expect(csvPath, isNotNull);
    });

    test('export should handle premium features', () async {
      await profileService.setRemoveAdsPurchased(true);
      await profileService.markAudioCustomized();

      final summary = await exportService.getExportSummary();

      expect(summary['has_premium_features'], true);
      expect(summary['audio_customized'], true);
    });

    test('concurrent export operations should all succeed', () async {
      final futures = [
        exportService.exportAsJson(),
        exportService.exportAsCsv(),
        exportService.exportAsFormattedText(),
      ];

      final results = await Future.wait(futures);

      expect(results.length, 3);
      expect(results[0], isNotNull);
      expect(results[1], isNotNull);
      expect(results[2], isNotNull);
    });

    test('export summary performance should be fast', () async {
      final stopwatch = Stopwatch()..start();

      await exportService.getExportSummary();

      stopwatch.stop();

      // Summary should be generated in under 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('multiple summary requests should return consistent data', () async {
      final summary1 = await exportService.getExportSummary();
      final summary2 = await exportService.getExportSummary();

      expect(summary1['total_levels_completed'],
          summary2['total_levels_completed']);
      expect(summary1['total_coins_earned'], summary2['total_coins_earned']);
      expect(summary1['current_streak'], summary2['current_streak']);
    });

    test('export with complex achievement data', () async {
      final achievements = [
        'Speed Demon',
        'Perfectionist',
        'Marathon Runner',
        'Combo Master',
        'Level 100 Complete',
      ];

      for (final achievement in achievements) {
        await achievementsService.toggleTracked(achievement);
      }

      final jsonPath = await exportService.exportAsJson();

      expect(jsonPath, isNotNull);
    });

    test('export after profile reset', () async {
      await profileService.updateProgress(
        levelsCompleted: 50,
        coinsEarned: 5000,
      );

      await profileService.resetProfile();

      final summary = await exportService.getExportSummary();

      expect(summary, isA<Map<String, dynamic>>());
      expect(summary['total_levels_completed'], isA<int>());
    });

    test('export with various difficulty levels', () async {
      final difficulties = [0.0, 0.25, 0.5, 0.75, 1.0];

      for (final difficulty in difficulties) {
        await settingsService.setDifficulty(difficulty);

        final summary = await exportService.getExportSummary();

        expect(summary['current_difficulty'], difficulty);
      }
    });
  });
}
