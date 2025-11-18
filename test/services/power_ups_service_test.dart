import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sortbliss/core/services/power_ups_service.dart';
import 'package:sortbliss/core/monetization/monetization_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Clear preferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('PowerUpsService', () {
    test('should initialize successfully', () async {
      final service = PowerUpsService.instance;
      await service.initialize();

      expect(service.inventory, isEmpty);
      expect(service.activePowerUps, isEmpty);
    });

    test('should purchase power-up with sufficient coins', () async {
      SharedPreferences.setMockInitialValues({
        'coin_balance': 100, // Set initial coin balance
      });

      await MonetizationManager.instance.initialize();
      final service = PowerUpsService.instance;
      await service.initialize();

      final result = await service.purchase(PowerUpType.speedBoost);

      expect(result.success, isTrue);
      expect(service.getQuantity(PowerUpType.speedBoost), equals(1));
      expect(MonetizationManager.instance.coinBalance.value, equals(75)); // 100 - 25
    });

    test('should fail to purchase with insufficient coins', () async {
      SharedPreferences.setMockInitialValues({
        'coin_balance': 10, // Insufficient for any power-up
      });

      await MonetizationManager.instance.initialize();
      final service = PowerUpsService.instance;
      await service.initialize();

      final result = await service.purchase(PowerUpType.speedBoost);

      expect(result.success, isFalse);
      expect(result.message, contains('Insufficient coins'));
      expect(service.getQuantity(PowerUpType.speedBoost), equals(0));
    });

    test('should activate power-up from inventory', () async {
      SharedPreferences.setMockInitialValues({
        'coin_balance': 100,
      });

      await MonetizationManager.instance.initialize();
      final service = PowerUpsService.instance;
      await service.initialize();

      // Purchase first
      await service.purchase(PowerUpType.speedBoost);

      // Then activate
      final result = await service.activate(PowerUpType.speedBoost);

      expect(result.success, isTrue);
      expect(service.isActive(PowerUpType.speedBoost), isTrue);
      expect(service.getQuantity(PowerUpType.speedBoost), equals(0)); // Consumed
    });

    test('should fail to activate without inventory', () async {
      final service = PowerUpsService.instance;
      await service.initialize();

      final result = await service.activate(PowerUpType.speedBoost);

      expect(result.success, isFalse);
      expect(result.message, contains('No'));
      expect(service.isActive(PowerUpType.speedBoost), isFalse);
    });

    test('should fail to activate already active power-up', () async {
      SharedPreferences.setMockInitialValues({
        'coin_balance': 100,
      });

      await MonetizationManager.instance.initialize();
      final service = PowerUpsService.instance;
      await service.initialize();

      // Purchase 2
      await service.purchase(PowerUpType.speedBoost, quantity: 2);

      // Activate first
      await service.activate(PowerUpType.speedBoost);

      // Try to activate again
      final result = await service.activate(PowerUpType.speedBoost);

      expect(result.success, isFalse);
      expect(result.message, contains('already active'));
    });

    test('should track purchase statistics', () async {
      SharedPreferences.setMockInitialValues({
        'coin_balance': 200,
      });

      await MonetizationManager.instance.initialize();
      final service = PowerUpsService.instance;
      await service.initialize();

      await service.purchase(PowerUpType.speedBoost); // 25 coins
      await service.purchase(PowerUpType.accuracyBooster); // 30 coins

      final stats = service.purchaseStats;

      expect(stats['total_purchases'], equals(2));
      expect(stats['total_coins_spent'], equals(55)); // 25 + 30
      expect(stats['average_cost'], equals(27.5)); // 55 / 2
    });

    test('should purchase multiple quantities', () async {
      SharedPreferences.setMockInitialValues({
        'coin_balance': 150,
      });

      await MonetizationManager.instance.initialize();
      final service = PowerUpsService.instance;
      await service.initialize();

      final result = await service.purchase(PowerUpType.speedBoost, quantity: 3);

      expect(result.success, isTrue);
      expect(service.getQuantity(PowerUpType.speedBoost), equals(3));
      expect(MonetizationManager.instance.coinBalance.value, equals(75)); // 150 - 75
    });

    test('should persist inventory across sessions', () async {
      SharedPreferences.setMockInitialValues({
        'coin_balance': 100,
      });

      await MonetizationManager.instance.initialize();
      var service = PowerUpsService.instance;
      await service.initialize();

      // Purchase power-up
      await service.purchase(PowerUpType.speedBoost, quantity: 2);

      // Clear data to simulate app restart
      await service.clearData();

      // Manually set the stored data as if it was persisted
      SharedPreferences.setMockInitialValues({
        'power_up_speedBoost': 2,
        'power_ups_total_purchases': 2,
        'power_ups_coins_spent': 50,
        'coin_balance': 50,
      });

      // Re-initialize
      service = PowerUpsService.instance;
      await service.initialize();

      expect(service.getQuantity(PowerUpType.speedBoost), equals(2));
    });

    test('should clear all data', () async {
      SharedPreferences.setMockInitialValues({
        'coin_balance': 100,
      });

      await MonetizationManager.instance.initialize();
      final service = PowerUpsService.instance;
      await service.initialize();

      // Purchase and activate
      await service.purchase(PowerUpType.speedBoost);
      await service.activate(PowerUpType.speedBoost);

      // Clear
      await service.clearData();

      expect(service.inventory, isEmpty);
      expect(service.activePowerUps, isEmpty);
      expect(service.purchaseStats['total_purchases'], equals(0));
      expect(service.purchaseStats['total_coins_spent'], equals(0));
    });
  });

  group('PowerUpDefinition', () {
    test('should format duration text correctly', () {
      final speedBoost = PowerUpsService.catalog[PowerUpType.speedBoost]!;
      final hintPack = PowerUpsService.catalog[PowerUpType.hintPack]!;

      expect(speedBoost.durationText, equals('Lasts 3 minutes'));
      expect(hintPack.durationText, equals('Instant use'));
    });

    test('should have correct catalog entries', () {
      expect(PowerUpsService.catalog.length, equals(6));
      expect(PowerUpsService.catalog.containsKey(PowerUpType.speedBoost), isTrue);
      expect(PowerUpsService.catalog.containsKey(PowerUpType.accuracyBooster), isTrue);
      expect(PowerUpsService.catalog.containsKey(PowerUpType.comboMultiplier), isTrue);
      expect(PowerUpsService.catalog.containsKey(PowerUpType.coinMagnet), isTrue);
      expect(PowerUpsService.catalog.containsKey(PowerUpType.hintPack), isTrue);
      expect(PowerUpsService.catalog.containsKey(PowerUpType.undoMove), isTrue);
    });
  });
}
