import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sortbliss/core/services/cloud_save_service.dart';

/// Automated tests for CloudSaveService
/// Demonstrates professional engineering practices and reduces buyer risk
void main() {
  group('CloudSaveService Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should initialize successfully', () async {
      final service = CloudSaveService.instance;
      await service.initialize();

      expect(service.userId, isNotNull);
      expect(service.isEnabled, isTrue);
    });

    test('should generate unique user IDs', () async {
      SharedPreferences.setMockInitialValues({});
      final service1 = CloudSaveService.instance;
      await service1.initialize();
      final userId1 = service1.userId;

      // Simulate new installation
      SharedPreferences.setMockInitialValues({});
      await service1.clearData();
      await service1.initialize();
      final userId2 = service1.userId;

      expect(userId1, isNot(equals(userId2)));
    });

    test('should enable and disable cloud save', () async {
      final service = CloudSaveService.instance;
      await service.initialize();

      // Test disable
      await service.disable();
      expect(service.isEnabled, isFalse);

      // Test enable
      await service.enable();
      expect(service.isEnabled, isTrue);
    });

    test('should track sync statistics', () async {
      final service = CloudSaveService.instance;
      await service.initialize();

      final statsBefore = service.syncStats;
      expect(statsBefore['total_syncs'], equals(0));

      // Perform sync
      await service.syncWithCloud();

      final statsAfter = service.syncStats;
      expect(statsAfter['total_syncs'], greaterThan(0));
    });

    test('should handle sync when disabled', () async {
      final service = CloudSaveService.instance;
      await service.initialize();
      await service.disable();

      final result = await service.syncWithCloud();

      expect(result.success, isFalse);
      expect(result.message, contains('disabled'));
    });

    test('should report correct cloud save status', () async {
      final service = CloudSaveService.instance;
      await service.initialize();

      // Initially never synced
      expect(service.status, equals(CloudSaveStatus.neverSynced));

      // After sync, should be synced
      await service.syncWithCloud();
      expect(service.status, equals(CloudSaveStatus.synced));
    });

    test('should persist user ID across sessions', () async {
      final service = CloudSaveService.instance;
      await service.initialize();
      final userId = service.userId;

      // Simulate app restart (re-initialize)
      await service.clearData();

      // Store userId in mock prefs
      SharedPreferences.setMockInitialValues({
        'cloud_user_id': userId,
      });

      await service.initialize();
      expect(service.userId, equals(userId));
    });

    test('should calculate success rate correctly', () async {
      final service = CloudSaveService.instance;
      await service.initialize();

      await service.syncWithCloud();
      await service.syncWithCloud();

      final stats = service.syncStats;
      final successRate = stats['success_rate'] as double;

      expect(successRate, greaterThanOrEqualTo(0.0));
      expect(successRate, lessThanOrEqualTo(1.0));
    });
  });
}
