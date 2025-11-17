import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_logger.dart';

/// Dynamic pricing service for A/B testing and regional price optimization
/// Maximizes revenue by finding optimal price points per user segment
class DynamicPricingService {
  DynamicPricingService._();
  static final DynamicPricingService instance = DynamicPricingService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  static const String _keyPricingGroup = 'pricing_group';
  static const String _keyCountryCode = 'country_code';

  // Base prices (USD)
  static const Map<String, double> _basePrices = {
    'coins_small': 0.99,
    'coins_medium': 1.99,
    'coins_large': 4.99,
    'coins_mega': 9.99,
    'remove_ads': 2.99,
    'skin_premium': 0.99,
    'skin_bundle': 3.99,
    'starter_pack': 1.99,
    'premium_bundle': 9.99,
  };

  // A/B test price variants
  static const Map<String, Map<String, double>> _priceVariants = {
    'control': _basePrices,
    'variant_a': {  // 20% lower prices
      'coins_small': 0.79,
      'coins_medium': 1.59,
      'coins_large': 3.99,
      'coins_mega': 7.99,
      'remove_ads': 2.39,
      'skin_premium': 0.79,
      'skin_bundle': 3.19,
      'starter_pack': 1.59,
      'premium_bundle': 7.99,
    },
    'variant_b': {  // 20% higher prices
      'coins_small': 1.19,
      'coins_medium': 2.39,
      'coins_large': 5.99,
      'coins_mega': 11.99,
      'remove_ads': 3.59,
      'skin_premium': 1.19,
      'skin_bundle': 4.79,
      'starter_pack': 2.39,
      'premium_bundle': 11.99,
    },
  };

  // Regional price multipliers (Purchasing Power Parity)
  static const Map<String, double> _regionalMultipliers = {
    // Tier 1: Full price
    'US': 1.0, 'CA': 1.0, 'GB': 1.0, 'AU': 1.0, 'DE': 1.0, 'FR': 1.0,
    'NL': 1.0, 'SE': 1.0, 'NO': 1.0, 'DK': 1.0, 'CH': 1.0,

    // Tier 2: 80% price
    'ES': 0.8, 'IT': 0.8, 'JP': 0.8, 'KR': 0.8, 'SG': 0.8,

    // Tier 3: 50% price
    'MX': 0.5, 'BR': 0.5, 'RU': 0.5, 'IN': 0.5, 'CN': 0.5,
    'TR': 0.5, 'AR': 0.5, 'CL': 0.5, 'CO': 0.5,

    // Tier 4: 60% price (default for unlisted countries)
  };

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();

    // Assign pricing group if not already assigned
    if (!_prefs.containsKey(_keyPricingGroup)) {
      final group = _assignPricingGroup();
      await _prefs.setString(_keyPricingGroup, group);

      AnalyticsLogger.logEvent('pricing_group_assigned', parameters: {
        'group': group,
      });
    }
  }

  /// Assign user to pricing group for A/B testing
  String _assignPricingGroup() {
    // Simple random assignment (33% each group)
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    if (random < 33) return 'control';
    if (random < 66) return 'variant_a';
    return 'variant_b';
  }

  /// Get price for product
  double getPrice(String productId) {
    if (!_initialized) {
      debugPrint('DynamicPricingService not initialized, returning base price');
      return _basePrices[productId] ?? 0.99;
    }

    // Get base price for user's pricing group
    final group = getPricingGroup();
    final basePrice = _priceVariants[group]?[productId] ?? _basePrices[productId] ?? 0.99;

    // Apply regional multiplier
    final regionalPrice = _applyRegionalPricing(basePrice);

    AnalyticsLogger.logEvent('price_calculated', parameters: {
      'product_id': productId,
      'pricing_group': group,
      'base_price': basePrice,
      'regional_price': regionalPrice,
      'country_code': getCountryCode(),
    });

    return regionalPrice;
  }

  /// Apply regional pricing multiplier
  double _applyRegionalPricing(double basePrice) {
    final countryCode = getCountryCode();
    final multiplier = _regionalMultipliers[countryCode] ?? 0.6; // Default tier 4
    return (basePrice * multiplier * 100).round() / 100; // Round to 2 decimals
  }

  /// Get user's pricing group
  String getPricingGroup() {
    return _prefs.getString(_keyPricingGroup) ?? 'control';
  }

  /// Get or detect country code
  String getCountryCode() {
    // Try to get stored country code
    final stored = _prefs.getString(_keyCountryCode);
    if (stored != null) return stored;

    // TODO: Detect country code via IP geolocation or device locale
    // For now, default to US
    return 'US';
  }

  /// Set country code (called after detection)
  Future<void> setCountryCode(String countryCode) async {
    await _prefs.setString(_keyCountryCode, countryCode.toUpperCase());

    AnalyticsLogger.logEvent('country_code_set', parameters: {
      'country_code': countryCode,
      'regional_multiplier': _regionalMultipliers[countryCode] ?? 0.6,
    });
  }

  /// Get product catalog with prices
  Map<String, ProductInfo> getProductCatalog() {
    return {
      'coins_small': ProductInfo(
        id: 'coins_small',
        name: 'Small Coin Pack',
        price: getPrice('coins_small'),
        coins: 500,
        description: '500 coins',
      ),
      'coins_medium': ProductInfo(
        id: 'coins_medium',
        name: 'Medium Coin Pack',
        price: getPrice('coins_medium'),
        coins: 1200,
        description: '1,200 coins (20% bonus)',
        bonus: 0.20,
      ),
      'coins_large': ProductInfo(
        id: 'coins_large',
        name: 'Large Coin Pack',
        price: getPrice('coins_large'),
        coins: 3000,
        description: '3,000 coins (50% bonus)',
        bonus: 0.50,
      ),
      'coins_mega': ProductInfo(
        id: 'coins_mega',
        name: 'Mega Coin Pack',
        price: getPrice('coins_mega'),
        coins: 7500,
        description: '7,500 coins (100% bonus)',
        bonus: 1.00,
      ),
      'remove_ads': ProductInfo(
        id: 'remove_ads',
        name: 'Remove Ads',
        price: getPrice('remove_ads'),
        description: 'Enjoy ad-free gameplay forever',
      ),
      'starter_pack': ProductInfo(
        id: 'starter_pack',
        name: 'Starter Pack',
        price: getPrice('starter_pack'),
        coins: 1000,
        description: '1,000 coins + Remove Ads (70% off)',
        includesAdRemoval: true,
        discountPercent: 0.70,
      ),
      'premium_bundle': ProductInfo(
        id: 'premium_bundle',
        name: 'Premium Bundle',
        price: getPrice('premium_bundle'),
        coins: 10000,
        description: '10,000 coins + Ad removal + All skins (80% off)',
        includesAdRemoval: true,
        includesAllSkins: true,
        discountPercent: 0.80,
      ),
    };
  }

  /// Calculate discount percentage
  double calculateDiscount(String productId, double salePrice) {
    final basePrice = _basePrices[productId] ?? 0.99;
    return ((basePrice - salePrice) / basePrice * 100).round() / 100;
  }

  /// Get value proposition (coins per dollar)
  double getValueScore(String productId) {
    final product = getProductCatalog()[productId];
    if (product == null || product.coins == null) return 0;

    return product.coins! / product.price;
  }

  /// Reset for testing
  Future<void> resetForTesting() async {
    await _prefs.remove(_keyPricingGroup);
    await _prefs.remove(_keyCountryCode);

    // Reassign pricing group
    final group = _assignPricingGroup();
    await _prefs.setString(_keyPricingGroup, group);
  }
}

/// Product information model
class ProductInfo {
  const ProductInfo({
    required this.id,
    required this.name,
    required this.price,
    this.coins,
    required this.description,
    this.bonus,
    this.discountPercent,
    this.includesAdRemoval = false,
    this.includesAllSkins = false,
  });

  final String id;
  final String name;
  final double price;
  final int? coins;
  final String description;
  final double? bonus;
  final double? discountPercent;
  final bool includesAdRemoval;
  final bool includesAllSkins;

  String get displayPrice => '\$${price.toStringAsFixed(2)}';

  String get displayBonus {
    if (bonus == null) return '';
    return '+${(bonus! * 100).toInt()}% bonus';
  }

  String get displayDiscount {
    if (discountPercent == null) return '';
    return '${(discountPercent! * 100).toInt()}% OFF';
  }
}
