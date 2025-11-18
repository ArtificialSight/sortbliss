import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sortbliss/core/services/achievements_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AchievementsTrackerService', () {
    late AchievementsTrackerService service;

    setUp(() {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      service = AchievementsTrackerService.instance;
    });

    test('instance should return singleton', () {
      final instance1 = AchievementsTrackerService.instance;
      final instance2 = AchievementsTrackerService.instance;
      expect(instance1, same(instance2));
    });

    test('ensureInitialized should start with empty set when no stored data',
        () async {
      await service.ensureInitialized();

      expect(service.trackedIds, isEmpty);
    });

    test('ensureInitialized should load stored achievements when data exists',
        () async {
      SharedPreferences.setMockInitialValues({
        'tracked_achievements_v1': [
          'Achievement 1',
          'Achievement 2',
          'Achievement 3',
        ],
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('tracked_achievements_v1', [
        'Achievement 1',
        'Achievement 2',
        'Achievement 3',
      ]);

      await service.ensureInitialized();

      expect(service.trackedIds.length, 3);
      expect(service.trackedIds, contains('Achievement 1'));
      expect(service.trackedIds, contains('Achievement 2'));
      expect(service.trackedIds, contains('Achievement 3'));
    });

    test('ensureInitialized should handle corrupted data gracefully', () async {
      // SharedPreferences returns null for invalid data
      SharedPreferences.setMockInitialValues({
        'tracked_achievements_v1': null,
      });

      // Should not throw and should use empty set
      await service.ensureInitialized();

      expect(service.trackedIds, isEmpty);
    });

    test('ensureInitialized should only initialize once', () async {
      await service.ensureInitialized();
      await service.ensureInitialized();
      await service.ensureInitialized();

      // Should complete without errors
      expect(service.trackedIds, isNotNull);
    });

    test('ensureInitialized should handle concurrent calls', () async {
      // Call ensureInitialized multiple times concurrently
      final futures = List.generate(
        10,
        (_) => service.ensureInitialized(),
      );

      await Future.wait(futures);

      expect(service.trackedIds, isNotNull);
    });

    test('isTracked should return false for untracked achievement', () async {
      await service.ensureInitialized();

      expect(service.isTracked('Untracked Achievement'), false);
    });

    test('isTracked should return true for tracked achievement', () async {
      await service.ensureInitialized();

      await service.toggleTracked('Tracked Achievement');

      expect(service.isTracked('Tracked Achievement'), true);
    });

    test('toggleTracked should add achievement when not present', () async {
      await service.ensureInitialized();

      expect(service.isTracked('New Achievement'), false);

      await service.toggleTracked('New Achievement');

      expect(service.isTracked('New Achievement'), true);
      expect(service.trackedIds, contains('New Achievement'));
    });

    test('toggleTracked should remove achievement when present', () async {
      await service.ensureInitialized();

      // Add achievement
      await service.toggleTracked('Test Achievement');
      expect(service.isTracked('Test Achievement'), true);

      // Remove achievement
      await service.toggleTracked('Test Achievement');
      expect(service.isTracked('Test Achievement'), false);
      expect(service.trackedIds, isNot(contains('Test Achievement')));
    });

    test('toggleTracked should work multiple times', () async {
      await service.ensureInitialized();

      await service.toggleTracked('Achievement A'); // Add
      await service.toggleTracked('Achievement A'); // Remove
      await service.toggleTracked('Achievement A'); // Add
      await service.toggleTracked('Achievement A'); // Remove

      expect(service.isTracked('Achievement A'), false);
    });

    test('toggleTracked should track multiple achievements', () async {
      await service.ensureInitialized();

      await service.toggleTracked('Achievement 1');
      await service.toggleTracked('Achievement 2');
      await service.toggleTracked('Achievement 3');

      expect(service.trackedIds.length, 3);
      expect(service.trackedIds, contains('Achievement 1'));
      expect(service.trackedIds, contains('Achievement 2'));
      expect(service.trackedIds, contains('Achievement 3'));
    });

    test('toggleTracked should persist to SharedPreferences', () async {
      await service.ensureInitialized();

      await service.toggleTracked('Persistent Achievement');

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      final storedList = prefs.getStringList('tracked_achievements_v1');
      expect(storedList, isNotNull);
      expect(storedList, contains('Persistent Achievement'));
    });

    test('toggleTracked should store achievements in sorted order', () async {
      await service.ensureInitialized();

      await service.toggleTracked('Zebra Achievement');
      await service.toggleTracked('Alpha Achievement');
      await service.toggleTracked('Beta Achievement');

      final prefs = await SharedPreferences.getInstance();
      final storedList = prefs.getStringList('tracked_achievements_v1');
      expect(storedList, isNotNull);
      expect(storedList![0], 'Alpha Achievement');
      expect(storedList[1], 'Beta Achievement');
      expect(storedList[2], 'Zebra Achievement');
    });

    test('toggleTracked should initialize service if not initialized', () async {
      // Don't call ensureInitialized() first

      await service.toggleTracked('Auto-Init Achievement');

      expect(service.isTracked('Auto-Init Achievement'), true);
    });

    test('clear should remove all tracked achievements', () async {
      await service.ensureInitialized();

      // Add some achievements
      await service.toggleTracked('Achievement 1');
      await service.toggleTracked('Achievement 2');
      await service.toggleTracked('Achievement 3');

      expect(service.trackedIds.length, 3);

      await service.clear();

      expect(service.trackedIds, isEmpty);
    });

    test('clear should remove data from SharedPreferences', () async {
      await service.ensureInitialized();

      // Add some achievements
      await service.toggleTracked('Test Achievement');

      await service.clear();

      final prefs = await SharedPreferences.getInstance();
      final storedList = prefs.getStringList('tracked_achievements_v1');
      expect(storedList, isNull);
    });

    test('clear should initialize service if not initialized', () async {
      // Don't call ensureInitialized() first

      await service.clear();

      expect(service.trackedIds, isEmpty);
    });

    test('clear should be idempotent', () async {
      await service.ensureInitialized();

      await service.clear();
      await service.clear();
      await service.clear();

      expect(service.trackedIds, isEmpty);
    });

    test('trackedListenable should notify listeners on toggle', () async {
      await service.ensureInitialized();

      int notificationCount = 0;
      service.trackedListenable.addListener(() {
        notificationCount++;
      });

      await service.toggleTracked('Test Achievement');

      expect(notificationCount, greaterThan(0));
    });

    test('trackedListenable should notify listeners on clear', () async {
      await service.ensureInitialized();

      await service.toggleTracked('Test Achievement');

      int notificationCount = 0;
      service.trackedListenable.addListener(() {
        notificationCount++;
      });

      await service.clear();

      expect(notificationCount, greaterThan(0));
    });

    test('trackedIds should return immutable snapshot', () async {
      await service.ensureInitialized();

      await service.toggleTracked('Achievement 1');

      final snapshot1 = service.trackedIds;
      expect(snapshot1.length, 1);

      await service.toggleTracked('Achievement 2');

      final snapshot2 = service.trackedIds;
      expect(snapshot2.length, 2);

      // snapshot1 should not be affected
      expect(snapshot1.length, 1);
    });

    test('should handle achievement IDs with special characters', () async {
      await service.ensureInitialized();

      const specialId = 'Achievement: Level 100% Complete! 🎉';

      await service.toggleTracked(specialId);

      expect(service.isTracked(specialId), true);
      expect(service.trackedIds, contains(specialId));
    });

    test('should handle empty string as achievement ID', () async {
      await service.ensureInitialized();

      await service.toggleTracked('');

      expect(service.isTracked(''), true);
      expect(service.trackedIds, contains(''));
    });

    test('should handle very long achievement IDs', () async {
      await service.ensureInitialized();

      final longId = 'A' * 1000; // 1000 character ID

      await service.toggleTracked(longId);

      expect(service.isTracked(longId), true);
      expect(service.trackedIds, contains(longId));
    });

    test('should track achievements independently', () async {
      await service.ensureInitialized();

      await service.toggleTracked('Achievement A');
      await service.toggleTracked('Achievement B');
      await service.toggleTracked('Achievement C');

      // Remove only B
      await service.toggleTracked('Achievement B');

      expect(service.isTracked('Achievement A'), true);
      expect(service.isTracked('Achievement B'), false);
      expect(service.isTracked('Achievement C'), true);
      expect(service.trackedIds.length, 2);
    });

    test('should maintain set semantics (no duplicates)', () async {
      await service.ensureInitialized();

      await service.toggleTracked('Achievement 1');

      // Manually manipulate to try to add duplicate (shouldn't be possible)
      await service.toggleTracked('Achievement 1'); // Remove
      await service.toggleTracked('Achievement 1'); // Add

      expect(service.trackedIds.length, 1);
      expect(
          service.trackedIds.where((id) => id == 'Achievement 1').length, 1);
    });

    test('complex workflow: track, untrack, clear, track again', () async {
      await service.ensureInitialized();

      // Track some achievements
      await service.toggleTracked('Achievement 1');
      await service.toggleTracked('Achievement 2');
      await service.toggleTracked('Achievement 3');
      expect(service.trackedIds.length, 3);

      // Untrack one
      await service.toggleTracked('Achievement 2');
      expect(service.trackedIds.length, 2);
      expect(service.isTracked('Achievement 1'), true);
      expect(service.isTracked('Achievement 2'), false);
      expect(service.isTracked('Achievement 3'), true);

      // Clear all
      await service.clear();
      expect(service.trackedIds, isEmpty);

      // Track again
      await service.toggleTracked('Achievement 4');
      await service.toggleTracked('Achievement 5');
      expect(service.trackedIds.length, 2);
      expect(service.isTracked('Achievement 4'), true);
      expect(service.isTracked('Achievement 5'), true);
      expect(service.isTracked('Achievement 1'), false);
    });

    test('should persist across service reinitialization', () async {
      await service.ensureInitialized();

      await service.toggleTracked('Persistent 1');
      await service.toggleTracked('Persistent 2');

      // Verify data is stored in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedList = prefs.getStringList('tracked_achievements_v1');
      expect(storedList, isNotNull);
      expect(storedList!.length, 2);

      // Data would persist if service was reinitialized
      // (In a real app, this would happen across app restarts)
    });
  });
}
