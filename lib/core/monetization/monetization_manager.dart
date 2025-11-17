import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_logger.dart';
// TODO: Uncomment after Firebase setup (P0.5)
// import 'package:cloud_functions/cloud_functions.dart';

/// Product identifiers used across the storefront and entitlement system.
class MonetizationProducts {
  static const removeAds = 'sortbliss_remove_ads';
  static const coinPackSmall = 'sortbliss_coin_pack_small';
  static const coinPackLarge = 'sortbliss_coin_pack_large';
  static const coinPackEpic = 'sortbliss_coin_pack_epic';
  static const sortPass = 'sortbliss_sort_pass_premium';
  static const entitlementRemoveAds = 'entitlement_remove_ads';
  static const entitlementSortPass = 'entitlement_sort_pass';

  static const consumableIds = {
    coinPackSmall,
    coinPackLarge,
    coinPackEpic,
  };

  static const nonConsumableIds = {
    removeAds,
    sortPass,
  };

  static const allProductIds = {
    removeAds,
    coinPackSmall,
    coinPackLarge,
    coinPackEpic,
    sortPass,
  };
}

/// Manages the in-app purchase flow, entitlement persistence, and shared coin
/// balance used throughout the game.
class MonetizationManager extends ChangeNotifier {
  MonetizationManager._();
  static final MonetizationManager instance = MonetizationManager._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _initialized = false;
  bool _available = false;
  final Map<String, ProductDetails> _products = {};
  final Set<String> _entitlements = <String>{};
  late SharedPreferences _preferences;

  // Named constant for default coin balance to replace magic number
  static const int _defaultCoinBalance = 2850;
  final ValueNotifier<int> coinBalance = ValueNotifier<int>(_defaultCoinBalance);

  bool get isAvailable => _available;
  bool get isAdFree =>
      _entitlements.contains(MonetizationProducts.entitlementRemoveAds);
  bool get hasSortPass =>
      _entitlements.contains(MonetizationProducts.entitlementSortPass);
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _preferences = await SharedPreferences.getInstance();
    _restoreFromStorage();

    _available = await _iap.isAvailable();
    if (!_available) {
      AnalyticsLogger.logEvent('iap_unavailable');
      notifyListeners();
      return;
    }

    final response =
        await _iap.queryProductDetails(MonetizationProducts.allProductIds);
    if (response.error != null) {
      AnalyticsLogger.logEvent('iap_query_failed',
          parameters: {'message': response.error!.message});
    }

    for (final details in response.productDetails) {
      _products[details.id] = details;
    }

    notifyListeners();

    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdates,
        onError: (Object error) {
      AnalyticsLogger.logEvent('iap_purchase_stream_error',
          parameters: {'error': '$error'});
    });

    await _iap.restorePurchases();
  }

  Future<void> buyProduct(String productId) async {
    if (!_available) {
      AnalyticsLogger.logEvent('iap_not_available_on_purchase_attempt',
          parameters: {'productId': productId});
      return;
    }

    final product = _products[productId];
    if (product == null) {
      AnalyticsLogger.logEvent('iap_product_missing',
          parameters: {'productId': productId});
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    AnalyticsLogger.logEvent('iap_purchase_initiated',
        parameters: {'productId': productId});

    if (MonetizationProducts.consumableIds.contains(productId)) {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    AnalyticsLogger.logEvent('iap_restore_attempted');
    await _iap.restorePurchases();
  }

  ProductDetails? productForId(String productId) => _products[productId];

  void addCoins(int amount) {
    if (amount <= 0) return;
    coinBalance.value += amount;
    _preferences.setInt('coin_balance', coinBalance.value);
    AnalyticsLogger.logEvent('coin_balance_updated',
        parameters: {'delta': amount, 'balance': coinBalance.value});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    coinBalance.dispose();
    super.dispose();
  }

  void _restoreFromStorage() {
    final coins = _preferences.getInt('coin_balance');
    if (coins != null) {
      coinBalance.value = coins;
    }

    final storedEntitlements =
        _preferences.getStringList('entitlements') ?? const <String>[];
    _entitlements.addAll(storedEntitlements);
  }

  void _persistEntitlements() {
    _preferences.setStringList('entitlements', _entitlements.toList());
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          AnalyticsLogger.logEvent('iap_purchase_pending',
              parameters: {'productId': purchaseDetails.productID});
          break;
        case PurchaseStatus.error:
          AnalyticsLogger.logEvent('iap_purchase_error', parameters: {
            'productId': purchaseDetails.productID,
            'error': purchaseDetails.error?.message,
          });
          break;
        case PurchaseStatus.canceled:
          AnalyticsLogger.logEvent('iap_purchase_canceled',
              parameters: {'productId': purchaseDetails.productID});
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliverProduct(purchaseDetails);
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  /// Validates a purchase receipt with Firebase Cloud Functions
  ///
  /// This prevents IAP fraud by verifying purchases server-side with Apple/Google APIs.
  /// Returns true if validation succeeds, false if it fails.
  Future<bool> _validateReceipt(PurchaseDetails purchaseDetails) async {
    // TODO: Uncomment after Firebase setup (P0.5)
    /*
    try {
      final functions = FirebaseFunctions.instance;

      // Determine platform
      final platform = Platform.isIOS ? 'ios' : 'android';

      // Extract receipt data based on platform
      String receiptData;
      if (Platform.isIOS) {
        // For iOS, verificationData.serverVerificationData contains the receipt
        receiptData = purchaseDetails.verificationData.serverVerificationData;
      } else {
        // For Android, use the purchase token
        receiptData = purchaseDetails.verificationData.serverVerificationData;
      }

      // Call Cloud Function to validate receipt
      final result = await functions.httpsCallable('validateReceipt').call({
        'platform': platform,
        'receiptData': receiptData,
        'productId': purchaseDetails.productID,
        'transactionId': purchaseDetails.purchaseID,
      });

      final validationData = result.data as Map<String, dynamic>;
      final isValid = validationData['valid'] as bool;

      if (isValid) {
        AnalyticsLogger.logEvent('iap_receipt_validated', parameters: {
          'productId': purchaseDetails.productID,
          'transactionId': purchaseDetails.purchaseID,
        });
        return true;
      } else {
        final error = validationData['error'] as String?;
        AnalyticsLogger.logEvent('iap_receipt_validation_failed', parameters: {
          'productId': purchaseDetails.productID,
          'error': error ?? 'Unknown error',
        });
        return false;
      }
    } catch (e) {
      AnalyticsLogger.logEvent('iap_receipt_validation_error', parameters: {
        'productId': purchaseDetails.productID,
        'error': e.toString(),
      });

      // In production, you might want to fail-safe by denying the purchase
      // For now, we'll allow it but log the error
      debugPrint('Receipt validation error: $e');
      return false;
    }
    */

    // TEMPORARY: Allow all purchases until Firebase is set up
    // This should be removed once Cloud Functions are deployed
    debugPrint('WARNING: Receipt validation disabled - Firebase not configured');
    AnalyticsLogger.logEvent('iap_receipt_validation_skipped', parameters: {
      'productId': purchaseDetails.productID,
      'reason': 'Firebase not configured',
    });
    return true;
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final productId = purchaseDetails.productID;

    // Validate receipt with server-side verification
    final isValid = await _validateReceipt(purchaseDetails);

    if (!isValid) {
      AnalyticsLogger.logEvent('iap_purchase_rejected_invalid_receipt',
          parameters: {'productId': productId});

      // Don't deliver product if receipt validation fails
      debugPrint('Purchase rejected: Invalid receipt for $productId');
      return;
    }

    AnalyticsLogger.logEvent('iap_purchase_delivered',
        parameters: {'productId': productId});

    if (productId == MonetizationProducts.removeAds) {
      _entitlements.add(MonetizationProducts.entitlementRemoveAds);
      _persistEntitlements();
      notifyListeners();
    } else if (productId == MonetizationProducts.sortPass) {
      _entitlements.add(MonetizationProducts.entitlementSortPass);
      _persistEntitlements();
      notifyListeners();
    } else if (productId == MonetizationProducts.coinPackSmall) {
      addCoins(250);
    } else if (productId == MonetizationProducts.coinPackLarge) {
      addCoins(750);
    } else if (productId == MonetizationProducts.coinPackEpic) {
      addCoins(2000);
    }
  }
}
