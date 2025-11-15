import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sortbliss/core/services/player_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerProfile', () {
    test('defaults should have expected values', () {
      expect(PlayerProfile.defaults.levelsCompleted, 47);
      expect(PlayerProfile.defaults.currentStreak, 12);
      expect(PlayerProfile.defaults.coinsEarned, 2850);
      expect(PlayerProfile.defaults.currentLevel, 48);
      expect(PlayerProfile.defaults.levelProgress, 0.65);
      expect(PlayerProfile.defaults.unlockedAchievements,
          ['Speed Demon', 'Perfectionist']);
      expect(PlayerProfile.defaults.shareCount, 1);
      expect(PlayerProfile.defaults.audioCustomized, false);
      expect(PlayerProfile.defaults.showRatePrompt, true);
      expect(PlayerProfile.defaults.hasRemoveAdsPurchase, false);
      expect(PlayerProfile.defaults.dailyChallengeCompleted, false);
    });

    test('toJson should serialize all fields correctly', () {
      const profile = PlayerProfile(
        levelsCompleted: 10,
        currentStreak: 5,
        coinsEarned: 100,
        currentLevel: 11,
        levelProgress: 0.5,
        unlockedAchievements: ['Achievement 1', 'Achievement 2'],
        shareCount: 2,
        audioCustomized: true,
        showRatePrompt: false,
        hasRemoveAdsPurchase: true,
        dailyChallengeCompleted: true,
      );

      final json = profile.toJson();

      expect(json['levelsCompleted'], 10);
      expect(json['currentStreak'], 5);
      expect(json['coinsEarned'], 100);
      expect(json['currentLevel'], 11);
      expect(json['levelProgress'], 0.5);
      expect(json['unlockedAchievements'],
          ['Achievement 1', 'Achievement 2']);
      expect(json['shareCount'], 2);
      expect(json['audioCustomized'], true);
      expect(json['showRatePrompt'], false);
      expect(json['hasRemoveAdsPurchase'], true);
      expect(json['dailyChallengeCompleted'], true);
    });

    test('fromJson should deserialize all fields correctly', () {
      final json = {
        'levelsCompleted': 20,
        'currentStreak': 7,
        'coinsEarned': 500,
        'currentLevel': 21,
        'levelProgress': 0.75,
        'unlockedAchievements': ['Test Achievement'],
        'shareCount': 3,
        'audioCustomized': true,
        'showRatePrompt': false,
        'hasRemoveAdsPurchase': true,
        'dailyChallengeCompleted': true,
      };

      final profile = PlayerProfile.fromJson(json);

      expect(profile.levelsCompleted, 20);
      expect(profile.currentStreak, 7);
      expect(profile.coinsEarned, 500);
      expect(profile.currentLevel, 21);
      expect(profile.levelProgress, 0.75);
      expect(profile.unlockedAchievements, ['Test Achievement']);
      expect(profile.shareCount, 3);
      expect(profile.audioCustomized, true);
      expect(profile.showRatePrompt, false);
      expect(profile.hasRemoveAdsPurchase, true);
      expect(profile.dailyChallengeCompleted, true);
    });

    test('fromJson should use defaults for missing fields', () {
      final json = <String, dynamic>{};

      final profile = PlayerProfile.fromJson(json);

      expect(profile.levelsCompleted, PlayerProfile.defaults.levelsCompleted);
      expect(profile.currentStreak, PlayerProfile.defaults.currentStreak);
      expect(profile.coinsEarned, PlayerProfile.defaults.coinsEarned);
      expect(profile.currentLevel, PlayerProfile.defaults.currentLevel);
      expect(profile.levelProgress, PlayerProfile.defaults.levelProgress);
      expect(profile.unlockedAchievements,
          PlayerProfile.defaults.unlockedAchievements);
      expect(profile.shareCount, PlayerProfile.defaults.shareCount);
      expect(profile.audioCustomized, PlayerProfile.defaults.audioCustomized);
      expect(profile.showRatePrompt, PlayerProfile.defaults.showRatePrompt);
      expect(profile.hasRemoveAdsPurchase,
          PlayerProfile.defaults.hasRemoveAdsPurchase);
      expect(profile.dailyChallengeCompleted,
          PlayerProfile.defaults.dailyChallengeCompleted);
    });

    test('copyWith should update only specified fields', () {
      const original = PlayerProfile(
        levelsCompleted: 10,
        currentStreak: 5,
        coinsEarned: 100,
        currentLevel: 11,
        levelProgress: 0.5,
        unlockedAchievements: ['Achievement 1'],
        shareCount: 2,
        audioCustomized: false,
        showRatePrompt: true,
        hasRemoveAdsPurchase: false,
        dailyChallengeCompleted: false,
      );

      final updated = original.copyWith(
        levelsCompleted: 15,
        coinsEarned: 200,
        audioCustomized: true,
      );

      expect(updated.levelsCompleted, 15);
      expect(updated.currentStreak, 5); // unchanged
      expect(updated.coinsEarned, 200);
      expect(updated.currentLevel, 11); // unchanged
      expect(updated.levelProgress, 0.5); // unchanged
      expect(updated.unlockedAchievements, ['Achievement 1']); // unchanged
      expect(updated.shareCount, 2); // unchanged
      expect(updated.audioCustomized, true);
      expect(updated.showRatePrompt, true); // unchanged
      expect(updated.hasRemoveAdsPurchase, false); // unchanged
      expect(updated.dailyChallengeCompleted, false); // unchanged
    });

    test('copyWith should create new list for unlockedAchievements', () {
      const original = PlayerProfile(
        levelsCompleted: 10,
        currentStreak: 5,
        coinsEarned: 100,
        currentLevel: 11,
        levelProgress: 0.5,
        unlockedAchievements: ['Achievement 1'],
        shareCount: 2,
        audioCustomized: false,
        showRatePrompt: true,
        hasRemoveAdsPurchase: false,
        dailyChallengeCompleted: false,
      );

      final updated = original.copyWith();

      expect(updated.unlockedAchievements, isNot(same(original.unlockedAchievements)));
      expect(updated.unlockedAchievements, equals(original.unlockedAchievements));
    });

    test('toJson and fromJson should be symmetric', () {
      const original = PlayerProfile(
        levelsCompleted: 25,
        currentStreak: 8,
        coinsEarned: 750,
        currentLevel: 26,
        levelProgress: 0.9,
        unlockedAchievements: ['Achievement 1', 'Achievement 2', 'Achievement 3'],
        shareCount: 4,
        audioCustomized: true,
        showRatePrompt: false,
        hasRemoveAdsPurchase: true,
        dailyChallengeCompleted: true,
      );

      final json = original.toJson();
      final deserialized = PlayerProfile.fromJson(json);

      expect(deserialized.levelsCompleted, original.levelsCompleted);
      expect(deserialized.currentStreak, original.currentStreak);
      expect(deserialized.coinsEarned, original.coinsEarned);
      expect(deserialized.currentLevel, original.currentLevel);
      expect(deserialized.levelProgress, original.levelProgress);
      expect(deserialized.unlockedAchievements, original.unlockedAchievements);
      expect(deserialized.shareCount, original.shareCount);
      expect(deserialized.audioCustomized, original.audioCustomized);
      expect(deserialized.showRatePrompt, original.showRatePrompt);
      expect(deserialized.hasRemoveAdsPurchase, original.hasRemoveAdsPurchase);
      expect(deserialized.dailyChallengeCompleted,
          original.dailyChallengeCompleted);
    });
  });

  group('PlayerProfileService', () {
    late PlayerProfileService service;

    setUp(() {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});

      // Create a fresh service instance by accessing the singleton
      // Note: We can't easily reset the singleton, so we'll work with it
      service = PlayerProfileService.instance;
    });

    test('instance should return singleton', () {
      final instance1 = PlayerProfileService.instance;
      final instance2 = PlayerProfileService.instance;
      expect(instance1, same(instance2));
    });

    test('ensureInitialized should load default profile when no stored data',
        () async {
      await service.ensureInitialized();

      expect(service.currentProfile.levelsCompleted,
          PlayerProfile.defaults.levelsCompleted);
      expect(service.currentProfile.currentStreak,
          PlayerProfile.defaults.currentStreak);
      expect(service.currentProfile.coinsEarned,
          PlayerProfile.defaults.coinsEarned);
    });

    test('ensureInitialized should load stored profile when data exists',
        () async {
      const storedProfile = PlayerProfile(
        levelsCompleted: 30,
        currentStreak: 10,
        coinsEarned: 1000,
        currentLevel: 31,
        levelProgress: 0.8,
        unlockedAchievements: ['Custom Achievement'],
        shareCount: 5,
        audioCustomized: true,
        showRatePrompt: false,
        hasRemoveAdsPurchase: true,
        dailyChallengeCompleted: true,
      );

      SharedPreferences.setMockInitialValues({
        'player_profile_v1': jsonEncode(storedProfile.toJson()),
      });

      // Create a new test since we can't easily reset the singleton
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'player_profile_v1', jsonEncode(storedProfile.toJson()));

      await service.ensureInitialized();

      expect(service.currentProfile.levelsCompleted, 30);
      expect(service.currentProfile.currentStreak, 10);
      expect(service.currentProfile.coinsEarned, 1000);
      expect(service.currentProfile.currentLevel, 31);
      expect(service.currentProfile.levelProgress, 0.8);
      expect(service.currentProfile.unlockedAchievements, ['Custom Achievement']);
      expect(service.currentProfile.shareCount, 5);
      expect(service.currentProfile.audioCustomized, true);
      expect(service.currentProfile.showRatePrompt, false);
      expect(service.currentProfile.hasRemoveAdsPurchase, true);
      expect(service.currentProfile.dailyChallengeCompleted, true);
    });

    test('ensureInitialized should handle corrupted JSON gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'player_profile_v1': 'invalid json data',
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('player_profile_v1', 'invalid json data');

      // Should not throw and should use defaults
      await service.ensureInitialized();

      expect(service.currentProfile.levelsCompleted,
          PlayerProfile.defaults.levelsCompleted);
    });

    test('ensureInitialized should only initialize once', () async {
      await service.ensureInitialized();
      await service.ensureInitialized();
      await service.ensureInitialized();

      // Should complete without errors
      expect(service.currentProfile, isNotNull);
    });

    test('updateProfile should update entire profile', () async {
      await service.ensureInitialized();

      const newProfile = PlayerProfile(
        levelsCompleted: 50,
        currentStreak: 15,
        coinsEarned: 3000,
        currentLevel: 51,
        levelProgress: 0.25,
        unlockedAchievements: ['New Achievement'],
        shareCount: 10,
        audioCustomized: true,
        showRatePrompt: false,
        hasRemoveAdsPurchase: true,
        dailyChallengeCompleted: true,
      );

      await service.updateProfile(newProfile);

      expect(service.currentProfile.levelsCompleted, 50);
      expect(service.currentProfile.currentStreak, 15);
      expect(service.currentProfile.coinsEarned, 3000);
      expect(service.currentProfile.currentLevel, 51);
      expect(service.currentProfile.levelProgress, 0.25);
      expect(service.currentProfile.unlockedAchievements, ['New Achievement']);
      expect(service.currentProfile.shareCount, 10);
      expect(service.currentProfile.audioCustomized, true);
      expect(service.currentProfile.showRatePrompt, false);
      expect(service.currentProfile.hasRemoveAdsPurchase, true);
      expect(service.currentProfile.dailyChallengeCompleted, true);
    });

    test('updateProgress should update progress fields', () async {
      await service.ensureInitialized();

      await service.updateProgress(
        levelsCompleted: 60,
        currentStreak: 20,
        coinsEarned: 5000,
        currentLevel: 61,
        levelProgress: 0.5,
      );

      expect(service.currentProfile.levelsCompleted, 60);
      expect(service.currentProfile.currentStreak, 20);
      expect(service.currentProfile.coinsEarned, 5000);
      expect(service.currentProfile.currentLevel, 61);
      expect(service.currentProfile.levelProgress, 0.5);
    });

    test('updateProgress should only update specified fields', () async {
      await service.ensureInitialized();

      final originalCoins = service.currentProfile.coinsEarned;
      final originalLevel = service.currentProfile.currentLevel;

      await service.updateProgress(
        levelsCompleted: 100,
        currentStreak: 25,
      );

      expect(service.currentProfile.levelsCompleted, 100);
      expect(service.currentProfile.currentStreak, 25);
      expect(service.currentProfile.coinsEarned, originalCoins); // unchanged
      expect(service.currentProfile.currentLevel, originalLevel); // unchanged
    });

    test('unlockAchievement should add achievement to front of list', () async {
      await service.ensureInitialized();

      await service.unlockAchievement('New Achievement');

      expect(service.currentProfile.unlockedAchievements.first,
          'New Achievement');
    });

    test('unlockAchievement should remove duplicates', () async {
      await service.ensureInitialized();

      await service.unlockAchievement('Achievement A');
      await service.unlockAchievement('Achievement B');
      await service.unlockAchievement('Achievement A'); // Duplicate

      expect(service.currentProfile.unlockedAchievements.first,
          'Achievement A');
      expect(service.currentProfile.unlockedAchievements
          .where((a) => a == 'Achievement A')
          .length, 1);
    });

    test('unlockAchievement should limit to 6 achievements', () async {
      await service.ensureInitialized();

      for (int i = 1; i <= 10; i++) {
        await service.unlockAchievement('Achievement $i');
      }

      expect(service.currentProfile.unlockedAchievements.length, 6);
      expect(service.currentProfile.unlockedAchievements.first,
          'Achievement 10');
    });

    test('incrementShareCount should increase share count', () async {
      await service.ensureInitialized();

      final initialCount = service.currentProfile.shareCount;

      await service.incrementShareCount();

      expect(service.currentProfile.shareCount, initialCount + 1);
    });

    test('incrementShareCount should unlock Social Butterfly at 3 shares',
        () async {
      await service.ensureInitialized();

      // Reset to have less than 3 shares
      await service.updateProfile(
        service.currentProfile.copyWith(
          shareCount: 0,
          unlockedAchievements: [],
        ),
      );

      await service.incrementShareCount(); // 1
      expect(service.currentProfile.unlockedAchievements,
          isNot(contains('Social Butterfly')));

      await service.incrementShareCount(); // 2
      expect(service.currentProfile.unlockedAchievements,
          isNot(contains('Social Butterfly')));

      await service.incrementShareCount(); // 3
      expect(service.currentProfile.unlockedAchievements,
          contains('Social Butterfly'));
    });

    test('incrementShareCount should only unlock Social Butterfly once',
        () async {
      await service.ensureInitialized();

      // Setup with 2 shares
      await service.updateProfile(
        service.currentProfile.copyWith(
          shareCount: 2,
          unlockedAchievements: [],
        ),
      );

      await service.incrementShareCount(); // 3 - should unlock
      final achievementsAfterUnlock = service.currentProfile.unlockedAchievements;

      await service.incrementShareCount(); // 4 - should not duplicate

      expect(service.currentProfile.unlockedAchievements
          .where((a) => a == 'Social Butterfly')
          .length, 1);
    });

    test('markAudioCustomized should set flag and unlock Sound Maestro',
        () async {
      await service.ensureInitialized();

      // Reset audio customization
      await service.updateProfile(
        service.currentProfile.copyWith(
          audioCustomized: false,
          unlockedAchievements: [],
        ),
      );

      await service.markAudioCustomized();

      expect(service.currentProfile.audioCustomized, true);
      expect(service.currentProfile.unlockedAchievements,
          contains('Sound Maestro'));
    });

    test('markAudioCustomized should be idempotent', () async {
      await service.ensureInitialized();

      await service.markAudioCustomized();
      final achievementsAfterFirst = List<String>.from(
          service.currentProfile.unlockedAchievements);

      await service.markAudioCustomized();

      expect(service.currentProfile.unlockedAchievements,
          equals(achievementsAfterFirst));
    });

    test('markRatePromptShown should set showRatePrompt to false', () async {
      await service.ensureInitialized();

      // Ensure it's true first
      await service.updateProfile(
        service.currentProfile.copyWith(showRatePrompt: true),
      );

      await service.markRatePromptShown();

      expect(service.currentProfile.showRatePrompt, false);
    });

    test('markRatePromptShown should be idempotent', () async {
      await service.ensureInitialized();

      await service.markRatePromptShown();
      await service.markRatePromptShown();

      expect(service.currentProfile.showRatePrompt, false);
    });

    test('setRemoveAdsPurchased should update purchase status', () async {
      await service.ensureInitialized();

      await service.setRemoveAdsPurchased(true);
      expect(service.currentProfile.hasRemoveAdsPurchase, true);

      await service.setRemoveAdsPurchased(false);
      expect(service.currentProfile.hasRemoveAdsPurchase, false);
    });

    test('setRemoveAdsPurchased should be idempotent', () async {
      await service.ensureInitialized();

      await service.setRemoveAdsPurchased(true);
      await service.setRemoveAdsPurchased(true);

      expect(service.currentProfile.hasRemoveAdsPurchase, true);
    });

    test('recordDailyChallengeCompletion should update completion status',
        () async {
      await service.ensureInitialized();

      await service.recordDailyChallengeCompletion(true);
      expect(service.currentProfile.dailyChallengeCompleted, true);

      await service.recordDailyChallengeCompletion(false);
      expect(service.currentProfile.dailyChallengeCompleted, false);
    });

    test('recordDailyChallengeCompletion should be idempotent', () async {
      await service.ensureInitialized();

      await service.recordDailyChallengeCompletion(true);
      await service.recordDailyChallengeCompletion(true);

      expect(service.currentProfile.dailyChallengeCompleted, true);
    });

    test('resetProfile should restore defaults', () async {
      await service.ensureInitialized();

      // Make some changes
      await service.updateProgress(
        levelsCompleted: 100,
        currentStreak: 50,
        coinsEarned: 10000,
      );

      await service.resetProfile();

      expect(service.currentProfile.levelsCompleted,
          PlayerProfile.defaults.levelsCompleted);
      expect(service.currentProfile.currentStreak,
          PlayerProfile.defaults.currentStreak);
      expect(service.currentProfile.coinsEarned,
          PlayerProfile.defaults.coinsEarned);
    });

    test('profileListenable should notify listeners on updates', () async {
      await service.ensureInitialized();

      int notificationCount = 0;
      service.profileListenable.addListener(() {
        notificationCount++;
      });

      await service.updateProgress(levelsCompleted: 75);

      expect(notificationCount, greaterThan(0));
    });

    test('updates should persist to SharedPreferences', () async {
      await service.ensureInitialized();

      await service.updateProgress(
        levelsCompleted: 88,
        coinsEarned: 7777,
      );

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('player_profile_v1');
      expect(storedJson, isNotNull);

      final decoded = jsonDecode(storedJson!) as Map<String, dynamic>;
      expect(decoded['levelsCompleted'], 88);
      expect(decoded['coinsEarned'], 7777);
    });

    test('concurrent initialization calls should not cause issues', () async {
      // Call ensureInitialized multiple times concurrently
      final futures = List.generate(
        10,
        (_) => service.ensureInitialized(),
      );

      await Future.wait(futures);

      expect(service.currentProfile, isNotNull);
    });
  });
}
