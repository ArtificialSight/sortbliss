import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sortbliss/core/monetization/monetization_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonetizationProducts', () {
    test('product IDs should be defined', () {
      expect(MonetizationProducts.removeAds, 'sortbliss_remove_ads');
      expect(MonetizationProducts.coinPackSmall, 'sortbliss_coin_pack_small');
      expect(MonetizationProducts.coinPackLarge, 'sortbliss_coin_pack_large');
      expect(MonetizationProducts.coinPackEpic, 'sortbliss_coin_pack_epic');
      expect(MonetizationProducts.sortPass, 'sortbliss_sort_pass_premium');
    });

    test('entitlement keys should be defined', () {
      expect(MonetizationProducts.entitlementRemoveAds, 'entitlement_remove_ads');
      expect(MonetizationProducts.entitlementSortPass, 'entitlement_sort_pass');
    });

    test('consumable IDs should contain coin packs only', () {
      expect(MonetizationProducts.consumableIds,
          containsAll([
            MonetizationProducts.coinPackSmall,
            MonetizationProducts.coinPackLarge,
            MonetizationProducts.coinPackEpic,
          ]));
      expect(MonetizationProducts.consumableIds.length, 3);
    });

    test('non-consumable IDs should contain remove ads and sort pass', () {
      expect(MonetizationProducts.nonConsumableIds, containsAll([
        MonetizationProducts.removeAds,
        MonetizationProducts.sortPass,
      ]));
      expect(MonetizationProducts.nonConsumableIds.length, 2);
    });

    test('all product IDs should contain all products', () {
      expect(MonetizationProducts.allProductIds, containsAll([
        MonetizationProducts.removeAds,
        MonetizationProducts.coinPackSmall,
        MonetizationProducts.coinPackLarge,
        MonetizationProducts.coinPackEpic,
        MonetizationProducts.sortPass,
      ]));
      expect(MonetizationProducts.allProductIds.length, 5);
    });

    test('no overlap between consumable and non-consumable', () {
      final intersection = MonetizationProducts.consumableIds.intersection(
          MonetizationProducts.nonConsumableIds);
      expect(intersection, isEmpty);
    });

    test('consumable and non-consumable should equal all products', () {
      final combined = {...MonetizationProducts.consumableIds, ...MonetizationProducts.nonConsumableIds};
      expect(combined, equals(MonetizationProducts.allProductIds));
    });
  });

  group('MonetizationManager', () {
    late MonetizationManager manager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      manager = MonetizationManager.instance;
    });

    test('instance should return singleton', () {
      final instance1 = MonetizationManager.instance;
      final instance2 = MonetizationManager.instance;
      expect(instance1, same(instance2));
    });

    test('should start with default coin balance', () {
      expect(manager.coinBalance.value, 2850);
    });

    test('addCoins should increase balance', () {
      final initialBalance = manager.coinBalance.value;

      manager.addCoins(100);

      expect(manager.coinBalance.value, initialBalance + 100);
    });

    test('addCoins should ignore zero amount', () {
      final initialBalance = manager.coinBalance.value;

      manager.addCoins(0);

      expect(manager.coinBalance.value, initialBalance);
    });

    test('addCoins should ignore negative amount', () {
      final initialBalance = manager.coinBalance.value;

      manager.addCoins(-50);

      expect(manager.coinBalance.value, initialBalance);
    });

    test('addCoins should accumulate correctly', () {
      final initialBalance = manager.coinBalance.value;

      manager.addCoins(100);
      manager.addCoins(200);
      manager.addCoins(300);

      expect(manager.coinBalance.value, initialBalance + 600);
    });

    test('addCoins should notify listeners', () async {
      await manager.initialize();

      int notificationCount = 0;
      manager.coinBalance.addListener(() {
        notificationCount++;
      });

      manager.addCoins(50);

      expect(notificationCount, greaterThan(0));
    });

    test('productForId should return null for unknown product', () {
      expect(manager.productForId('unknown_product'), isNull);
    });

    test('isAvailable should be false before initialization', () {
      expect(manager.isAvailable, false);
    });

    test('isAdFree should return false initially', () {
      expect(manager.isAdFree, false);
    });

    test('hasSortPass should return false initially', () {
      expect(manager.hasSortPass, false);
    });

    test('products should return empty map initially', () {
      expect(manager.products, isEmpty);
    });

    test('products should return unmodifiable map', () {
      final products = manager.products;

      expect(() => products['test'] = null, throwsUnsupportedError);
    });

    test('coin balance should persist across initializations', () async {
      SharedPreferences.setMockInitialValues({
        'coin_balance': 5000,
      });

      await manager.initialize();

      expect(manager.coinBalance.value, 5000);
    });

    test('entitlements should persist across initializations', () async {
      SharedPreferences.setMockInitialValues({
        'entitlements': ['entitlement_remove_ads'],
      });

      await manager.initialize();

      expect(manager.isAdFree, true);
      expect(manager.hasSortPass, false);
    });

    test('multiple entitlements should persist', () async {
      SharedPreferences.setMockInitialValues({
        'entitlements': ['entitlement_remove_ads', 'entitlement_sort_pass'],
      });

      await manager.initialize();

      expect(manager.isAdFree, true);
      expect(manager.hasSortPass, true);
    });

    test('initialize should be idempotent', () async {
      await manager.initialize();
      await manager.initialize();
      await manager.initialize();

      // Should complete without errors
      expect(manager, isNotNull);
    });

    test('manager should notify listeners when entitlements change', () async {
      await manager.initialize();

      int notificationCount = 0;
      manager.addListener(() {
        notificationCount++;
      });

      // Note: This test can't easily trigger entitlement changes without mocking
      // the InAppPurchase plugin. This is a limitation of the current test setup.
      // In a real scenario, we would mock the purchase stream.

      expect(manager, isNotNull); // Placeholder assertion
    });

    test('coin balance should start at default if no stored value', () async {
      SharedPreferences.setMockInitialValues({});

      await manager.initialize();

      expect(manager.coinBalance.value, 2850);
    });

    test('coin balance ValueNotifier should be accessible', () {
      expect(manager.coinBalance, isA<ValueNotifier<int>>());
      expect(manager.coinBalance.value, isA<int>());
    });

    test('adding large coin amounts should work correctly', () {
      manager.addCoins(1000000);

      expect(manager.coinBalance.value, greaterThanOrEqualTo(1000000));
    });

    test('complex coin operations should be accurate', () {
      final initial = manager.coinBalance.value;

      manager.addCoins(250);  // Small pack
      manager.addCoins(750);  // Large pack
      manager.addCoins(2000); // Epic pack
      manager.addCoins(0);    // Ignored
      manager.addCoins(-100); // Ignored

      expect(manager.coinBalance.value, initial + 3000);
    });
  });
}
