import 'package:flutter/foundation.dart';
import '../services/user_settings_service.dart';
import '../services/coin_economy_service.dart';
import '../services/statistics_service.dart';
import '../services/achievement_service.dart';
import '../services/powerup_service.dart';

/// Global app state manager
///
/// Coordinates state across the entire app using ChangeNotifier.
/// Use this for cross-cutting concerns that affect multiple screens.
///
/// Usage:
/// ```dart
/// // Provide at app root
/// ChangeNotifierProvider(
///   create: (_) => AppStateManager.instance,
///   child: MyApp(),
/// )
///
/// // Access in widgets
/// final appState = Provider.of<AppStateManager>(context);
/// final appState = context.watch<AppStateManager>(); // rebuilds
/// final appState = context.read<AppStateManager>(); // no rebuild
/// ```
class AppStateManager extends ChangeNotifier {
  static final AppStateManager instance = AppStateManager._();
  AppStateManager._();

  // Services
  final UserSettingsService _settings = UserSettingsService.instance;
  final CoinEconomyService _coins = CoinEconomyService.instance;
  final StatisticsService _stats = StatisticsService.instance;
  final AchievementService _achievements = AchievementService.instance;
  final PowerUpService _powerUps = PowerUpService.instance;

  // App state
  bool _initialized = false;
  bool _isOnline = true;
  bool _isPaused = false;
  String? _currentLevel;

  // User state
  int _coinBalance = 0;
  int _currentStreak = 0;
  bool _hasUnclaimedReward = false;

  // Getters
  bool get initialized => _initialized;
  bool get isOnline => _isOnline;
  bool get isPaused => _isPaused;
  String? get currentLevel => _currentLevel;
  int get coinBalance => _coinBalance;
  int get currentStreak => _currentStreak;
  bool get hasUnclaimedReward => _hasUnclaimedReward;

  /// Initialize app state
  Future<void> initialize() async {
    if (_initialized) return;

    // Load initial state from services
    await _loadInitialState();

    _initialized = true;
    notifyListeners();

    debugPrint('✅ App State Manager initialized');
  }

  /// Load initial state from services
  Future<void> _loadInitialState() async {
    _coinBalance = _coins.getBalance();
    // TODO: Load streak from daily rewards service
    _currentStreak = 0;
    // TODO: Check for unclaimed rewards
    _hasUnclaimedReward = false;
  }

  /// Update online status
  void setOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();
      debugPrint('📡 Network status: ${isOnline ? 'online' : 'offline'}');
    }
  }

  /// Update pause status
  void setPaused(bool isPaused) {
    if (_isPaused != isPaused) {
      _isPaused = isPaused;
      notifyListeners();
    }
  }

  /// Set current level
  void setCurrentLevel(String? levelId) {
    _currentLevel = levelId;
    notifyListeners();
  }

  /// Update coin balance
  void updateCoinBalance(int newBalance) {
    if (_coinBalance != newBalance) {
      _coinBalance = newBalance;
      notifyListeners();
    }
  }

  /// Award coins (convenience method)
  Future<void> awardCoins(int amount, CoinSource source) async {
    await _coins.earnCoins(amount, source);
    _coinBalance = _coins.getBalance();
    notifyListeners();
  }

  /// Spend coins (convenience method)
  Future<bool> spendCoins(int amount, CoinSink sink) async {
    final success = await _coins.spendCoins(amount, sink);
    if (success) {
      _coinBalance = _coins.getBalance();
      notifyListeners();
    }
    return success;
  }

  /// Update streak
  void updateStreak(int newStreak) {
    if (_currentStreak != newStreak) {
      _currentStreak = newStreak;
      notifyListeners();
    }
  }

  /// Mark reward as claimed/unclaimed
  void setHasUnclaimedReward(bool hasReward) {
    if (_hasUnclaimedReward != hasReward) {
      _hasUnclaimedReward = hasReward;
      notifyListeners();
    }
  }

  /// Refresh all state from services
  Future<void> refresh() async {
    await _loadInitialState();
    notifyListeners();
  }

  /// Reset app state (for testing/debug)
  Future<void> reset() async {
    _initialized = false;
    _isOnline = true;
    _isPaused = false;
    _currentLevel = null;
    _coinBalance = 0;
    _currentStreak = 0;
    _hasUnclaimedReward = false;

    notifyListeners();

    debugPrint('🔄 App state reset');
  }
}

/// Game state manager (for active gameplay)
class GameStateManager extends ChangeNotifier {
  static final GameStateManager instance = GameStateManager._();
  GameStateManager._();

  // Game state
  bool _isPlaying = false;
  bool _isPaused = false;
  int _currentScore = 0;
  int _movesUsed = 0;
  int _currentCombo = 0;
  int _starsEarned = 0;
  List<String> _moveHistory = [];

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  int get currentScore => _currentScore;
  int get movesUsed => _movesUsed;
  int get currentCombo => _currentCombo;
  int get starsEarned => _starsEarned;
  List<String> get moveHistory => List.unmodifiable(_moveHistory);
  bool get canUndo => _moveHistory.isNotEmpty;

  /// Start new game
  void startGame() {
    _isPlaying = true;
    _isPaused = false;
    _currentScore = 0;
    _movesUsed = 0;
    _currentCombo = 0;
    _starsEarned = 0;
    _moveHistory.clear();

    notifyListeners();
    debugPrint('🎮 Game started');
  }

  /// Pause game
  void pauseGame() {
    if (_isPlaying) {
      _isPaused = true;
      notifyListeners();
      debugPrint('⏸️ Game paused');
    }
  }

  /// Resume game
  void resumeGame() {
    if (_isPlaying && _isPaused) {
      _isPaused = false;
      notifyListeners();
      debugPrint('▶️ Game resumed');
    }
  }

  /// End game
  void endGame({required bool won}) {
    _isPlaying = false;
    _isPaused = false;

    notifyListeners();
    debugPrint(won ? '🎉 Game won!' : '💔 Game lost');
  }

  /// Record move
  void recordMove(String moveData) {
    _moveHistory.add(moveData);
    _movesUsed++;
    notifyListeners();
  }

  /// Undo last move
  String? undoMove() {
    if (_moveHistory.isEmpty) return null;

    final lastMove = _moveHistory.removeLast();
    _movesUsed = _movesUsed > 0 ? _movesUsed - 1 : 0;

    notifyListeners();
    return lastMove;
  }

  /// Update score
  void updateScore(int newScore) {
    _currentScore = newScore;
    notifyListeners();
  }

  /// Update combo
  void updateCombo(int newCombo) {
    _currentCombo = newCombo;
    notifyListeners();
  }

  /// Reset combo
  void resetCombo() {
    _currentCombo = 0;
    notifyListeners();
  }

  /// Update stars
  void updateStars(int stars) {
    _starsEarned = stars;
    notifyListeners();
  }

  /// Reset game state
  void reset() {
    _isPlaying = false;
    _isPaused = false;
    _currentScore = 0;
    _movesUsed = 0;
    _currentCombo = 0;
    _starsEarned = 0;
    _moveHistory.clear();

    notifyListeners();
    debugPrint('🔄 Game state reset');
  }
}

/// UI state manager (for UI-specific state)
class UIStateManager extends ChangeNotifier {
  static final UIStateManager instance = UIStateManager._();
  UIStateManager._();

  // UI state
  bool _showLoadingOverlay = false;
  String? _loadingMessage;
  bool _showBottomNav = true;
  int _selectedNavIndex = 0;

  // Getters
  bool get showLoadingOverlay => _showLoadingOverlay;
  String? get loadingMessage => _loadingMessage;
  bool get showBottomNav => _showBottomNav;
  int get selectedNavIndex => _selectedNavIndex;

  /// Show loading overlay
  void showLoading({String? message}) {
    _showLoadingOverlay = true;
    _loadingMessage = message;
    notifyListeners();
  }

  /// Hide loading overlay
  void hideLoading() {
    _showLoadingOverlay = false;
    _loadingMessage = null;
    notifyListeners();
  }

  /// Set bottom nav visibility
  void setBottomNavVisibility(bool visible) {
    if (_showBottomNav != visible) {
      _showBottomNav = visible;
      notifyListeners();
    }
  }

  /// Set selected nav index
  void setSelectedNavIndex(int index) {
    if (_selectedNavIndex != index) {
      _selectedNavIndex = index;
      notifyListeners();
    }
  }

  /// Reset UI state
  void reset() {
    _showLoadingOverlay = false;
    _loadingMessage = null;
    _showBottomNav = true;
    _selectedNavIndex = 0;

    notifyListeners();
    debugPrint('🔄 UI state reset');
  }
}
