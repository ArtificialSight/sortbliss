import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coin_economy_service.dart';
import '../utils/analytics_logger.dart';

/// Cosmetics and customization service for personalization and monetization
///
/// Features:
/// - Container skins (visual themes)
/// - Particle effects (celebrations, trails)
/// - Sound packs (different audio themes)
/// - Background themes
/// - Profile frames and badges
/// - Unlock via coins, battle pass, or IAP
///
/// Monetization Potential:
/// - Premium cosmetic packs: $4.99-$9.99
/// - Limited edition skins: $2.99-$14.99
/// - Seasonal bundles: $19.99
/// - Expected: $20,000-$40,000 annually from cosmetics
///
/// Engagement Impact:
/// - Personalization increases retention by 25-35%
/// - Collection completionists drive engagement
/// - Social status and flex appeal
class CosmeticsService {
  static final CosmeticsService instance = CosmeticsService._();
  CosmeticsService._();

  static const String _keyOwnedSkins = 'cosmetics_owned_skins';
  static const String _keyActiveSkin = 'cosmetics_active_skin';
  static const String _keyOwnedEffects = 'cosmetics_owned_effects';
  static const String _keyActiveEffect = 'cosmetics_active_effect';
  static const String _keyOwnedThemes = 'cosmetics_owned_themes';
  static const String _keyActiveTheme = 'cosmetics_active_theme';
  static const String _keyOwnedFrames = 'cosmetics_owned_frames';
  static const String _keyActiveFrame = 'cosmetics_active_frame';

  late SharedPreferences _prefs;
  bool _initialized = false;

  final Set<String> _ownedSkins = {};
  final Set<String> _ownedEffects = {};
  final Set<String> _ownedThemes = {};
  final Set<String> _ownedFrames = {};

  String? _activeSkin;
  String? _activeEffect;
  String? _activeTheme;
  String? _activeFrame;

  /// Initialize service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Load owned items
    _ownedSkins.addAll(_prefs.getStringList(_keyOwnedSkins) ?? ['default']);
    _ownedEffects.addAll(_prefs.getStringList(_keyOwnedEffects) ?? ['default']);
    _ownedThemes.addAll(_prefs.getStringList(_keyOwnedThemes) ?? ['default']);
    _ownedFrames.addAll(_prefs.getStringList(_keyOwnedFrames) ?? ['default']);

    // Load active items
    _activeSkin = _prefs.getString(_keyActiveSkin) ?? 'default';
    _activeEffect = _prefs.getString(_keyActiveEffect) ?? 'default';
    _activeTheme = _prefs.getString(_keyActiveTheme) ?? 'default';
    _activeFrame = _prefs.getString(_keyActiveFrame) ?? 'default';

    _initialized = true;

    if (kDebugMode) {
      debugPrint('🎨 Cosmetics Service initialized');
      debugPrint('   Skins owned: ${_ownedSkins.length}');
      debugPrint('   Effects owned: ${_ownedEffects.length}');
      debugPrint('   Themes owned: ${_ownedThemes.length}');
    }
  }

  /// Get all available skins
  List<CosmeticSkin> getAllSkins() {
    return [
      // Free/Default
      CosmeticSkin(
        id: 'default',
        name: 'Classic',
        description: 'The original SortBliss style',
        rarity: CosmeticRarity.common,
        price: 0,
        unlockMethod: UnlockMethod.free,
        primaryColor: const Color(0xFF6200EE),
        secondaryColor: const Color(0xFF3700B3),
      ),

      // Common (Coin Purchase)
      CosmeticSkin(
        id: 'ocean',
        name: 'Ocean Waves',
        description: 'Calming blue ocean theme',
        rarity: CosmeticRarity.common,
        price: 1000,
        unlockMethod: UnlockMethod.coins,
        primaryColor: const Color(0xFF0077BE),
        secondaryColor: const Color(0xFF00A8E8),
      ),
      CosmeticSkin(
        id: 'forest',
        name: 'Forest Glade',
        description: 'Fresh green forest vibes',
        rarity: CosmeticRarity.common,
        price: 1000,
        unlockMethod: UnlockMethod.coins,
        primaryColor: const Color(0xFF2E7D32),
        secondaryColor: const Color(0xFF66BB6A),
      ),
      CosmeticSkin(
        id: 'sunset',
        name: 'Sunset Blaze',
        description: 'Warm orange and pink sunset',
        rarity: CosmeticRarity.common,
        price: 1000,
        unlockMethod: UnlockMethod.coins,
        primaryColor: const Color(0xFFFF6B35),
        secondaryColor: const Color(0xFFF7931E),
      ),

      // Rare (Higher Coin Price)
      CosmeticSkin(
        id: 'galaxy',
        name: 'Galaxy Dreams',
        description: 'Cosmic purple and blue nebula',
        rarity: CosmeticRarity.rare,
        price: 3000,
        unlockMethod: UnlockMethod.coins,
        primaryColor: const Color(0xFF7B2CBF),
        secondaryColor: const Color(0xFFC77DFF),
      ),
      CosmeticSkin(
        id: 'neon',
        name: 'Neon Nights',
        description: 'Vibrant cyberpunk aesthetic',
        rarity: CosmeticRarity.rare,
        price: 3000,
        unlockMethod: UnlockMethod.coins,
        primaryColor: const Color(0xFFFF00FF),
        secondaryColor: const Color(0xFF00FFFF),
      ),
      CosmeticSkin(
        id: 'gold_rush',
        name: 'Gold Rush',
        description: 'Luxurious gold and bronze',
        rarity: CosmeticRarity.rare,
        price: 3500,
        unlockMethod: UnlockMethod.coins,
        primaryColor: const Color(0xFFFFD700),
        secondaryColor: const Color(0xFFCD7F32),
      ),

      // Epic (Battle Pass)
      CosmeticSkin(
        id: 'inferno',
        name: 'Inferno Blaze',
        description: 'Fiery red and orange flames',
        rarity: CosmeticRarity.epic,
        price: 0,
        unlockMethod: UnlockMethod.battlePass,
        battlePassTier: 15,
        primaryColor: const Color(0xFFD32F2F),
        secondaryColor: const Color(0xFFFF6F00),
        hasParticleEffect: true,
      ),
      CosmeticSkin(
        id: 'ice_crystal',
        name: 'Ice Crystal',
        description: 'Frozen blue and white ice',
        rarity: CosmeticRarity.epic,
        price: 0,
        unlockMethod: UnlockMethod.battlePass,
        battlePassTier: 25,
        primaryColor: const Color(0xFF0288D1),
        secondaryColor: const Color(0xFF81D4FA),
        hasParticleEffect: true,
      ),

      // Legendary (Premium IAP)
      CosmeticSkin(
        id: 'dragon_scale',
        name: 'Dragon Scale',
        description: 'Legendary dragon-themed skin',
        rarity: CosmeticRarity.legendary,
        price: 499, // $4.99 IAP
        unlockMethod: UnlockMethod.iap,
        primaryColor: const Color(0xFF8B0000),
        secondaryColor: const Color(0xFFFFD700),
        hasParticleEffect: true,
        hasAnimatedBackground: true,
      ),
      CosmeticSkin(
        id: 'rainbow_prism',
        name: 'Rainbow Prism',
        description: 'Animated rainbow spectrum',
        rarity: CosmeticRarity.legendary,
        price: 699, // $6.99 IAP
        unlockMethod: UnlockMethod.iap,
        primaryColor: const Color(0xFFFF0000),
        secondaryColor: const Color(0xFF0000FF),
        hasParticleEffect: true,
        hasAnimatedBackground: true,
        isAnimated: true,
      ),

      // Exclusive (Limited Time/Events)
      CosmeticSkin(
        id: 'winter_wonderland',
        name: 'Winter Wonderland',
        description: 'Festive winter holiday theme',
        rarity: CosmeticRarity.exclusive,
        price: 999, // $9.99 IAP
        unlockMethod: UnlockMethod.limitedEvent,
        primaryColor: const Color(0xFF1976D2),
        secondaryColor: const Color(0xFFFFFFFF),
        hasParticleEffect: true,
        hasAnimatedBackground: true,
        isAnimated: true,
        isLimitedEdition: true,
      ),
    ];
  }

  /// Get all available particle effects
  List<CosmeticEffect> getAllEffects() {
    return [
      CosmeticEffect(
        id: 'default',
        name: 'Classic Confetti',
        description: 'Standard celebration effect',
        rarity: CosmeticRarity.common,
        price: 0,
        unlockMethod: UnlockMethod.free,
        particleCount: 50,
        colors: [Colors.red, Colors.blue, Colors.yellow, Colors.green],
      ),
      CosmeticEffect(
        id: 'stars',
        name: 'Starfall',
        description: 'Golden stars rain down',
        rarity: CosmeticRarity.rare,
        price: 2000,
        unlockMethod: UnlockMethod.coins,
        particleCount: 30,
        colors: [Colors.amber, Colors.yellow],
      ),
      CosmeticEffect(
        id: 'hearts',
        name: 'Love Burst',
        description: 'Hearts everywhere!',
        rarity: CosmeticRarity.rare,
        price: 2000,
        unlockMethod: UnlockMethod.coins,
        particleCount: 40,
        colors: [Colors.pink, Colors.red],
      ),
      CosmeticEffect(
        id: 'fireworks',
        name: 'Fireworks Show',
        description: 'Spectacular fireworks display',
        rarity: CosmeticRarity.epic,
        price: 0,
        unlockMethod: UnlockMethod.battlePass,
        battlePassTier: 35,
        particleCount: 100,
        colors: [Colors.red, Colors.blue, Colors.yellow, Colors.purple],
        hasSound: true,
      ),
      CosmeticEffect(
        id: 'aurora',
        name: 'Aurora Borealis',
        description: 'Northern lights effect',
        rarity: CosmeticRarity.legendary,
        price: 399, // $3.99 IAP
        unlockMethod: UnlockMethod.iap,
        particleCount: 150,
        colors: [Colors.cyan, Colors.green, Colors.purple],
        hasSound: true,
        isAnimated: true,
      ),
    ];
  }

  /// Get all available background themes
  List<CosmeticTheme> getAllThemes() {
    return [
      CosmeticTheme(
        id: 'default',
        name: 'Classic',
        description: 'Original SortBliss background',
        rarity: CosmeticRarity.common,
        price: 0,
        unlockMethod: UnlockMethod.free,
        backgroundColor: const Color(0xFFF5F5F5),
        accentColor: const Color(0xFF6200EE),
      ),
      CosmeticTheme(
        id: 'dark_mode',
        name: 'Dark Mode',
        description: 'Easy on the eyes',
        rarity: CosmeticRarity.common,
        price: 500,
        unlockMethod: UnlockMethod.coins,
        backgroundColor: const Color(0xFF121212),
        accentColor: const Color(0xFFBB86FC),
      ),
      CosmeticTheme(
        id: 'synthwave',
        name: 'Synthwave',
        description: 'Retro 80s vibes',
        rarity: CosmeticRarity.epic,
        price: 0,
        unlockMethod: UnlockMethod.battlePass,
        battlePassTier: 45,
        backgroundColor: const Color(0xFF1A1A2E),
        accentColor: const Color(0xFFFF00FF),
        isAnimated: true,
      ),
    ];
  }

  /// Get all available profile frames
  List<CosmeticFrame> getAllFrames() {
    return [
      CosmeticFrame(
        id: 'default',
        name: 'Standard Frame',
        description: 'Basic profile frame',
        rarity: CosmeticRarity.common,
        price: 0,
        unlockMethod: UnlockMethod.free,
        borderColor: Colors.grey,
      ),
      CosmeticFrame(
        id: 'gold',
        name: 'Golden Frame',
        description: 'Prestigious gold border',
        rarity: CosmeticRarity.epic,
        price: 5000,
        unlockMethod: UnlockMethod.coins,
        borderColor: const Color(0xFFFFD700),
        isAnimated: true,
      ),
      CosmeticFrame(
        id: 'diamond',
        name: 'Diamond Frame',
        description: 'Ultra rare diamond frame',
        rarity: CosmeticRarity.legendary,
        price: 0,
        unlockMethod: UnlockMethod.battlePass,
        battlePassTier: 50,
        borderColor: const Color(0xFFB9F2FF),
        isAnimated: true,
        hasParticleEffect: true,
      ),
    ];
  }

  /// Purchase cosmetic with coins
  Future<bool> purchaseCosmetic(String id, CosmeticType type) async {
    if (!_initialized) await initialize();

    // Find cosmetic
    dynamic cosmetic;
    switch (type) {
      case CosmeticType.skin:
        cosmetic = getAllSkins().firstWhere((s) => s.id == id);
        break;
      case CosmeticType.effect:
        cosmetic = getAllEffects().firstWhere((e) => e.id == id);
        break;
      case CosmeticType.theme:
        cosmetic = getAllThemes().firstWhere((t) => t.id == id);
        break;
      case CosmeticType.frame:
        cosmetic = getAllFrames().firstWhere((f) => f.id == id);
        break;
    }

    // Check if already owned
    if (isOwned(id, type)) {
      return false;
    }

    // Check if purchasable with coins
    if (cosmetic.unlockMethod != UnlockMethod.coins) {
      return false;
    }

    // Check balance
    final balance = CoinEconomyService.instance.getBalance();
    if (balance < cosmetic.price) {
      return false;
    }

    // Purchase
    CoinEconomyService.instance.spendCoins(cosmetic.price, SpendSource.cosmeticPurchase);

    // Unlock
    await unlockCosmetic(id, type);

    AnalyticsLogger.logEvent('cosmetic_purchased', parameters: {
      'id': id,
      'type': type.toString(),
      'price': cosmetic.price,
      'rarity': cosmetic.rarity.toString(),
    });

    return true;
  }

  /// Unlock cosmetic (from battle pass, achievement, etc.)
  Future<void> unlockCosmetic(String id, CosmeticType type) async {
    if (!_initialized) await initialize();

    switch (type) {
      case CosmeticType.skin:
        _ownedSkins.add(id);
        await _prefs.setStringList(_keyOwnedSkins, _ownedSkins.toList());
        break;
      case CosmeticType.effect:
        _ownedEffects.add(id);
        await _prefs.setStringList(_keyOwnedEffects, _ownedEffects.toList());
        break;
      case CosmeticType.theme:
        _ownedThemes.add(id);
        await _prefs.setStringList(_keyOwnedThemes, _ownedThemes.toList());
        break;
      case CosmeticType.frame:
        _ownedFrames.add(id);
        await _prefs.setStringList(_keyOwnedFrames, _ownedFrames.toList());
        break;
    }

    AnalyticsLogger.logEvent('cosmetic_unlocked', parameters: {
      'id': id,
      'type': type.toString(),
    });
  }

  /// Equip cosmetic
  Future<void> equipCosmetic(String id, CosmeticType type) async {
    if (!_initialized) await initialize();

    if (!isOwned(id, type)) return;

    switch (type) {
      case CosmeticType.skin:
        _activeSkin = id;
        await _prefs.setString(_keyActiveSkin, id);
        break;
      case CosmeticType.effect:
        _activeEffect = id;
        await _prefs.setString(_keyActiveEffect, id);
        break;
      case CosmeticType.theme:
        _activeTheme = id;
        await _prefs.setString(_keyActiveTheme, id);
        break;
      case CosmeticType.frame:
        _activeFrame = id;
        await _prefs.setString(_keyActiveFrame, id);
        break;
    }

    AnalyticsLogger.logEvent('cosmetic_equipped', parameters: {
      'id': id,
      'type': type.toString(),
    });
  }

  /// Check if cosmetic is owned
  bool isOwned(String id, CosmeticType type) {
    switch (type) {
      case CosmeticType.skin:
        return _ownedSkins.contains(id);
      case CosmeticType.effect:
        return _ownedEffects.contains(id);
      case CosmeticType.theme:
        return _ownedThemes.contains(id);
      case CosmeticType.frame:
        return _ownedFrames.contains(id);
    }
  }

  /// Get active cosmetics
  String? getActiveSkin() => _activeSkin;
  String? getActiveEffect() => _activeEffect;
  String? getActiveTheme() => _activeTheme;
  String? getActiveFrame() => _activeFrame;

  /// Get collection completion percentage
  double getCollectionPercentage() {
    final total = getAllSkins().length +
        getAllEffects().length +
        getAllThemes().length +
        getAllFrames().length;

    final owned = _ownedSkins.length +
        _ownedEffects.length +
        _ownedThemes.length +
        _ownedFrames.length;

    return owned / total;
  }
}

/// Cosmetic skin
class CosmeticSkin {
  final String id;
  final String name;
  final String description;
  final CosmeticRarity rarity;
  final int price;
  final UnlockMethod unlockMethod;
  final int? battlePassTier;
  final Color primaryColor;
  final Color secondaryColor;
  final bool hasParticleEffect;
  final bool hasAnimatedBackground;
  final bool isAnimated;
  final bool isLimitedEdition;

  CosmeticSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.price,
    required this.unlockMethod,
    this.battlePassTier,
    required this.primaryColor,
    required this.secondaryColor,
    this.hasParticleEffect = false,
    this.hasAnimatedBackground = false,
    this.isAnimated = false,
    this.isLimitedEdition = false,
  });
}

/// Cosmetic effect
class CosmeticEffect {
  final String id;
  final String name;
  final String description;
  final CosmeticRarity rarity;
  final int price;
  final UnlockMethod unlockMethod;
  final int? battlePassTier;
  final int particleCount;
  final List<Color> colors;
  final bool hasSound;
  final bool isAnimated;

  CosmeticEffect({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.price,
    required this.unlockMethod,
    this.battlePassTier,
    required this.particleCount,
    required this.colors,
    this.hasSound = false,
    this.isAnimated = false,
  });
}

/// Cosmetic theme
class CosmeticTheme {
  final String id;
  final String name;
  final String description;
  final CosmeticRarity rarity;
  final int price;
  final UnlockMethod unlockMethod;
  final int? battlePassTier;
  final Color backgroundColor;
  final Color accentColor;
  final bool isAnimated;

  CosmeticTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.price,
    required this.unlockMethod,
    this.battlePassTier,
    required this.backgroundColor,
    required this.accentColor,
    this.isAnimated = false,
  });
}

/// Cosmetic frame
class CosmeticFrame {
  final String id;
  final String name;
  final String description;
  final CosmeticRarity rarity;
  final int price;
  final UnlockMethod unlockMethod;
  final int? battlePassTier;
  final Color borderColor;
  final bool isAnimated;
  final bool hasParticleEffect;

  CosmeticFrame({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.price,
    required this.unlockMethod,
    this.battlePassTier,
    required this.borderColor,
    this.isAnimated = false,
    this.hasParticleEffect = false,
  });
}

/// Cosmetic rarity
enum CosmeticRarity {
  common,
  rare,
  epic,
  legendary,
  exclusive,
}

/// Unlock method
enum UnlockMethod {
  free,
  coins,
  battlePass,
  iap,
  achievement,
  limitedEvent,
}

/// Cosmetic type
enum CosmeticType {
  skin,
  effect,
  theme,
  frame,
}
