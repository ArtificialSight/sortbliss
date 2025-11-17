import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/analytics_logger.dart';

/// Tracks combo chains and score multipliers during gameplay
///
/// Combo system:
/// - Combo increases for consecutive successful moves
/// - Combo breaks on invalid move or timeout (5 seconds)
/// - Multiplier scales with combo: x1.5 at 3, x2 at 5, x3 at 10, x5 at 20
/// - Bonus coins awarded at milestones
/// - Visual and haptic feedback for combos
class ComboTrackerService extends ChangeNotifier {
  static final ComboTrackerService instance = ComboTrackerService._();
  ComboTrackerService._();

  int _currentCombo = 0;
  int _maxCombo = 0;
  int _totalCombos = 0;
  double _currentMultiplier = 1.0;
  Timer? _comboTimer;

  static const int comboTimeout = 5; // seconds
  static const int comboThreshold = 3; // minimum for multiplier

  /// Get current combo count
  int get currentCombo => _currentCombo;

  /// Get max combo achieved in current session
  int get maxCombo => _maxCombo;

  /// Get total combos triggered
  int get totalCombos => _totalCombos;

  /// Get current score multiplier
  double get currentMultiplier => _currentMultiplier;

  /// Check if combo is active
  bool get isComboActive => _currentCombo >= comboThreshold;

  /// Initialize combo tracker
  void initialize() {
    _currentCombo = 0;
    _maxCombo = 0;
    _totalCombos = 0;
    _currentMultiplier = 1.0;
    _comboTimer?.cancel();

    AnalyticsLogger.logEvent('combo_tracker_initialized');
  }

  /// Register successful move (increases combo)
  void registerSuccess() {
    _currentCombo++;

    // Update max combo
    if (_currentCombo > _maxCombo) {
      _maxCombo = _currentCombo;
    }

    // Update multiplier
    _updateMultiplier();

    // Reset timer
    _resetComboTimer();

    // Log milestone combos
    if (_isMilestoneCombo(_currentCombo)) {
      _totalCombos++;

      AnalyticsLogger.logEvent('combo_milestone', parameters: {
        'combo': _currentCombo,
        'multiplier': _currentMultiplier,
      });
    }

    notifyListeners();
  }

  /// Register failed move (breaks combo)
  void registerFailure() {
    if (_currentCombo > 0) {
      _breakCombo('failure');
    }
  }

  /// Break combo (timeout or failure)
  void _breakCombo(String reason) {
    final previousCombo = _currentCombo;

    _currentCombo = 0;
    _currentMultiplier = 1.0;
    _comboTimer?.cancel();

    AnalyticsLogger.logEvent('combo_broken', parameters: {
      'combo': previousCombo,
      'reason': reason,
    });

    notifyListeners();
  }

  /// Reset combo (level start)
  void reset() {
    _currentCombo = 0;
    _currentMultiplier = 1.0;
    _comboTimer?.cancel();
    notifyListeners();
  }

  /// Reset all statistics (new game)
  void resetStatistics() {
    _currentCombo = 0;
    _maxCombo = 0;
    _totalCombos = 0;
    _currentMultiplier = 1.0;
    _comboTimer?.cancel();
    notifyListeners();
  }

  /// Update multiplier based on combo count
  void _updateMultiplier() {
    if (_currentCombo >= 20) {
      _currentMultiplier = 5.0;
    } else if (_currentCombo >= 15) {
      _currentMultiplier = 4.0;
    } else if (_currentCombo >= 10) {
      _currentMultiplier = 3.0;
    } else if (_currentCombo >= 7) {
      _currentMultiplier = 2.5;
    } else if (_currentCombo >= 5) {
      _currentMultiplier = 2.0;
    } else if (_currentCombo >= 3) {
      _currentMultiplier = 1.5;
    } else {
      _currentMultiplier = 1.0;
    }
  }

  /// Reset combo timer (5 second timeout)
  void _resetComboTimer() {
    _comboTimer?.cancel();
    _comboTimer = Timer(const Duration(seconds: comboTimeout), () {
      if (_currentCombo > 0) {
        _breakCombo('timeout');
      }
    });
  }

  /// Calculate score with multiplier
  int calculateScore(int baseScore) {
    return (baseScore * _currentMultiplier).round();
  }

  /// Get bonus coins for combo milestone
  int getComboBonus() {
    if (_currentCombo >= 20) {
      return 100;
    } else if (_currentCombo >= 15) {
      return 50;
    } else if (_currentCombo >= 10) {
      return 25;
    } else if (_currentCombo >= 7) {
      return 15;
    } else if (_currentCombo >= 5) {
      return 10;
    } else if (_currentCombo >= 3) {
      return 5;
    }
    return 0;
  }

  /// Check if combo count is a milestone
  bool _isMilestoneCombo(int combo) {
    return combo == 3 ||
        combo == 5 ||
        combo == 7 ||
        combo == 10 ||
        combo == 15 ||
        combo == 20 ||
        combo % 10 == 0; // Every 10 after 20
  }

  /// Get combo tier (for visual feedback)
  /// Returns: 0 (none), 1 (bronze), 2 (silver), 3 (gold), 4 (platinum), 5 (diamond)
  int getComboTier() {
    if (_currentCombo >= 20) return 5;
    if (_currentCombo >= 15) return 4;
    if (_currentCombo >= 10) return 3;
    if (_currentCombo >= 5) return 2;
    if (_currentCombo >= 3) return 1;
    return 0;
  }

  /// Get combo tier name
  String getComboTierName() {
    switch (getComboTier()) {
      case 5:
        return 'DIAMOND';
      case 4:
        return 'PLATINUM';
      case 3:
        return 'GOLD';
      case 2:
        return 'SILVER';
      case 1:
        return 'BRONZE';
      default:
        return '';
    }
  }

  /// Get combo statistics
  Map<String, dynamic> getStatistics() {
    return {
      'current_combo': _currentCombo,
      'max_combo': _maxCombo,
      'total_combos': _totalCombos,
      'current_multiplier': _currentMultiplier,
      'combo_tier': getComboTier(),
      'is_active': isComboActive,
    };
  }

  @override
  void dispose() {
    _comboTimer?.cancel();
    super.dispose();
  }
}
