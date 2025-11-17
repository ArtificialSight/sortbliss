import 'package:shared_preferences/shared_preferences.dart';
import '../utils/analytics_logger.dart';

/// Manages power-ups/boosters inventory and usage
///
/// Power-ups available:
/// - Undo: Undo last move (3 coins or IAP)
/// - Hint: Show optimal next move (5 coins or IAP)
/// - Shuffle: Rearrange pieces randomly (10 coins or IAP)
/// - Auto-Sort: Automatically solve next sequence (15 coins or IAP)
/// - Extra Moves: Add 5 moves to level (20 coins or IAP)
///
/// Power-ups can be:
/// - Purchased with coins
/// - Purchased with real money (IAP bundles)
/// - Earned through achievements/daily rewards
class PowerUpService {
  static final PowerUpService instance = PowerUpService._();
  PowerUpService._();

  static const String _keyUndoCount = 'powerup_undo_count';
  static const String _keyHintCount = 'powerup_hint_count';
  static const String _keyShuffleCount = 'powerup_shuffle_count';
  static const String _keyAutoSortCount = 'powerup_autosort_count';
  static const String _keyExtraMovesCount = 'powerup_extramoves_count';

  // Coin costs
  static const int undoCost = 3;
  static const int hintCost = 5;
  static const int shuffleCost = 10;
  static const int autoSortCost = 15;
  static const int extraMovesCost = 20;

  SharedPreferences? _prefs;

  /// Initialize power-up service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    AnalyticsLogger.logEvent('powerup_service_initialized', parameters: {
      'undo_count': getUndoCount(),
      'hint_count': getHintCount(),
      'shuffle_count': getShuffleCount(),
      'autosort_count': getAutoSortCount(),
      'extramoves_count': getExtraMovesCount(),
    });
  }

  // ========== Undo Power-Up ==========

  /// Get undo power-up count
  int getUndoCount() {
    return _prefs?.getInt(_keyUndoCount) ?? 0;
  }

  /// Add undo power-ups
  Future<void> addUndo(int count) async {
    final current = getUndoCount();
    await _prefs?.setInt(_keyUndoCount, current + count);

    AnalyticsLogger.logEvent('powerup_added', parameters: {
      'type': 'undo',
      'count': count,
      'new_total': current + count,
    });
  }

  /// Use undo power-up
  Future<bool> useUndo() async {
    final current = getUndoCount();
    if (current <= 0) return false;

    await _prefs?.setInt(_keyUndoCount, current - 1);

    AnalyticsLogger.logEvent('powerup_used', parameters: {
      'type': 'undo',
      'remaining': current - 1,
    });

    return true;
  }

  /// Check if user has undo power-ups
  bool hasUndo() => getUndoCount() > 0;

  // ========== Hint Power-Up ==========

  /// Get hint power-up count
  int getHintCount() {
    return _prefs?.getInt(_keyHintCount) ?? 0;
  }

  /// Add hint power-ups
  Future<void> addHint(int count) async {
    final current = getHintCount();
    await _prefs?.setInt(_keyHintCount, current + count);

    AnalyticsLogger.logEvent('powerup_added', parameters: {
      'type': 'hint',
      'count': count,
      'new_total': current + count,
    });
  }

  /// Use hint power-up
  Future<bool> useHint() async {
    final current = getHintCount();
    if (current <= 0) return false;

    await _prefs?.setInt(_keyHintCount, current - 1);

    AnalyticsLogger.logEvent('powerup_used', parameters: {
      'type': 'hint',
      'remaining': current - 1,
    });

    return true;
  }

  /// Check if user has hint power-ups
  bool hasHint() => getHintCount() > 0;

  // ========== Shuffle Power-Up ==========

  /// Get shuffle power-up count
  int getShuffleCount() {
    return _prefs?.getInt(_keyShuffleCount) ?? 0;
  }

  /// Add shuffle power-ups
  Future<void> addShuffle(int count) async {
    final current = getShuffleCount();
    await _prefs?.setInt(_keyShuffleCount, current + count);

    AnalyticsLogger.logEvent('powerup_added', parameters: {
      'type': 'shuffle',
      'count': count,
      'new_total': current + count,
    });
  }

  /// Use shuffle power-up
  Future<bool> useShuffle() async {
    final current = getShuffleCount();
    if (current <= 0) return false;

    await _prefs?.setInt(_keyShuffleCount, current - 1);

    AnalyticsLogger.logEvent('powerup_used', parameters: {
      'type': 'shuffle',
      'remaining': current - 1,
    });

    return true;
  }

  /// Check if user has shuffle power-ups
  bool hasShuffle() => getShuffleCount() > 0;

  // ========== Auto-Sort Power-Up ==========

  /// Get auto-sort power-up count
  int getAutoSortCount() {
    return _prefs?.getInt(_keyAutoSortCount) ?? 0;
  }

  /// Add auto-sort power-ups
  Future<void> addAutoSort(int count) async {
    final current = getAutoSortCount();
    await _prefs?.setInt(_keyAutoSortCount, current + count);

    AnalyticsLogger.logEvent('powerup_added', parameters: {
      'type': 'autosort',
      'count': count,
      'new_total': current + count,
    });
  }

  /// Use auto-sort power-up
  Future<bool> useAutoSort() async {
    final current = getAutoSortCount();
    if (current <= 0) return false;

    await _prefs?.setInt(_keyAutoSortCount, current - 1);

    AnalyticsLogger.logEvent('powerup_used', parameters: {
      'type': 'autosort',
      'remaining': current - 1,
    });

    return true;
  }

  /// Check if user has auto-sort power-ups
  bool hasAutoSort() => getAutoSortCount() > 0;

  // ========== Extra Moves Power-Up ==========

  /// Get extra moves power-up count
  int getExtraMovesCount() {
    return _prefs?.getInt(_keyExtraMovesCount) ?? 0;
  }

  /// Add extra moves power-ups
  Future<void> addExtraMoves(int count) async {
    final current = getExtraMovesCount();
    await _prefs?.setInt(_keyExtraMovesCount, current + count);

    AnalyticsLogger.logEvent('powerup_added', parameters: {
      'type': 'extramoves',
      'count': count,
      'new_total': current + count,
    });
  }

  /// Use extra moves power-up
  Future<bool> useExtraMoves() async {
    final current = getExtraMovesCount();
    if (current <= 0) return false;

    await _prefs?.setInt(_keyExtraMovesCount, current - 1);

    AnalyticsLogger.logEvent('powerup_used', parameters: {
      'type': 'extramoves',
      'remaining': current - 1,
    });

    return true;
  }

  /// Check if user has extra moves power-ups
  bool hasExtraMoves() => getExtraMovesCount() > 0;

  // ========== Power-Up Bundles (IAP) ==========

  /// Get power-up bundle products
  static List<PowerUpBundle> getBundles() {
    return [
      PowerUpBundle(
        id: 'powerup_starter',
        name: 'Starter Pack',
        description: '5 of each power-up',
        price: 2.99,
        items: {
          'undo': 5,
          'hint': 5,
          'shuffle': 5,
          'autosort': 5,
          'extramoves': 5,
        },
        savings: 30,
      ),
      PowerUpBundle(
        id: 'powerup_pro',
        name: 'Pro Pack',
        description: '15 of each power-up',
        price: 6.99,
        items: {
          'undo': 15,
          'hint': 15,
          'shuffle': 15,
          'autosort': 15,
          'extramoves': 15,
        },
        savings: 50,
      ),
      PowerUpBundle(
        id: 'powerup_ultimate',
        name: 'Ultimate Pack',
        description: '50 of each power-up',
        price: 14.99,
        items: {
          'undo': 50,
          'hint': 50,
          'shuffle': 50,
          'autosort': 50,
          'extramoves': 50,
        },
        savings: 70,
      ),
      PowerUpBundle(
        id: 'powerup_undo_bulk',
        name: 'Undo Pack',
        description: '50 undo power-ups',
        price: 1.99,
        items: {'undo': 50},
        savings: 40,
      ),
      PowerUpBundle(
        id: 'powerup_hint_bulk',
        name: 'Hint Pack',
        description: '30 hint power-ups',
        price: 2.99,
        items: {'hint': 30},
        savings: 40,
      ),
    ];
  }

  /// Apply power-up bundle (after IAP purchase)
  Future<void> applyBundle(PowerUpBundle bundle) async {
    for (final entry in bundle.items.entries) {
      switch (entry.key) {
        case 'undo':
          await addUndo(entry.value);
          break;
        case 'hint':
          await addHint(entry.value);
          break;
        case 'shuffle':
          await addShuffle(entry.value);
          break;
        case 'autosort':
          await addAutoSort(entry.value);
          break;
        case 'extramoves':
          await addExtraMoves(entry.value);
          break;
      }
    }

    AnalyticsLogger.logEvent('powerup_bundle_applied', parameters: {
      'bundle_id': bundle.id,
      'bundle_name': bundle.name,
      'price': bundle.price,
    });
  }

  /// Get total power-up count
  int getTotalPowerUpCount() {
    return getUndoCount() +
        getHintCount() +
        getShuffleCount() +
        getAutoSortCount() +
        getExtraMovesCount();
  }

  /// Get power-up usage statistics
  Map<String, int> getUsageStatistics() {
    return {
      'undo': getUndoCount(),
      'hint': getHintCount(),
      'shuffle': getShuffleCount(),
      'autosort': getAutoSortCount(),
      'extramoves': getExtraMovesCount(),
      'total': getTotalPowerUpCount(),
    };
  }
}

/// Power-up bundle data class
class PowerUpBundle {
  final String id;
  final String name;
  final String description;
  final double price;
  final Map<String, int> items; // powerup_type -> count
  final int savings; // Percentage savings

  const PowerUpBundle({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.items,
    required this.savings,
  });
}
