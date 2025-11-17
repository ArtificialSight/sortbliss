import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../core/game/level_generator.dart';
import '../../core/state/app_state_manager.dart';
import '../../core/services/coin_economy_service.dart';
import '../../core/services/level_progression_service.dart';
import '../../core/services/achievements_service.dart';
import '../../core/utils/analytics_logger.dart';
import '../../core/config/app_constants.dart';

/// Enhanced gameplay screen for SortBliss
///
/// Features:
/// - Smooth item animations
/// - Complete undo system with move history
/// - Combo multiplier system
/// - Visual feedback and warnings
/// - Celebration effects
/// - Sound integration hooks
/// - Tutorial hints
class GameplayScreen extends StatefulWidget {
  final int levelNumber;

  const GameplayScreen({
    super.key,
    required this.levelNumber,
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with TickerProviderStateMixin {

  // Level data
  late Level _level;
  int _moveCount = 0;
  bool _isLevelComplete = false;
  DateTime? _levelStartTime;

  // Move history for undo
  final List<GameMove> _moveHistory = [];
  final List<Level> _levelSnapshots = [];

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _moveAnimationController;
  late AnimationController _comboAnimationController;
  late AnimationController _celebrationController;

  late Animation<Color?> _backgroundAnimation;
  late Animation<double> _moveAnimation;
  late Animation<double> _comboScaleAnimation;

  // UI state
  int? _selectedContainerIndex;
  bool _showHint = false;
  GameMove? _currentHint;
  bool _isAnimating = false;

  // Combo system
  int _comboCount = 0;
  double _comboMultiplier = 1.0;
  Timer? _comboResetTimer;
  bool _showComboText = false;

  // Celebration
  bool _showCelebration = false;
  final List<_Confetti> _confettiParticles = [];

  // Tutorial
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLevel();
    _checkTutorial();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _moveAnimationController.dispose();
    _comboAnimationController.dispose();
    _celebrationController.dispose();
    _comboResetTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    // Background animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _backgroundAnimation = ColorTween(
      begin: const Color(0xFF0F172A),
      end: const Color(0xFF1E293B),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    _backgroundController.repeat(reverse: true);

    // Move animation
    _moveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _moveAnimation = CurvedAnimation(
      parent: _moveAnimationController,
      curve: Curves.easeInOut,
    );

    // Combo animation
    _comboAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _comboScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _comboAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Celebration animation
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  void _initializeLevel() {
    setState(() {
      _level = LevelGenerator.instance.generateLevel(widget.levelNumber);
      _moveCount = 0;
      _isLevelComplete = false;
      _selectedContainerIndex = null;
      _showHint = false;
      _currentHint = null;
      _levelStartTime = DateTime.now();
      _moveHistory.clear();
      _levelSnapshots.clear();
      _comboCount = 0;
      _comboMultiplier = 1.0;
      _showComboText = false;

      // Save initial state for undo
      _levelSnapshots.add(_level.clone());
    });

    AnalyticsLogger.logEvent(AppConstants.eventLevelStarted, parameters: {
      'level': widget.levelNumber,
      'colors': _level.colors,
      'max_moves': _level.maxMoves,
    });
  }

  void _checkTutorial() {
    if (widget.levelNumber == 1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showTutorial = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showExitDialog();
        return shouldPop ?? false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Main game UI
            AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _backgroundAnimation.value ?? const Color(0xFF0F172A),
                        const Color(0xFF1E293B),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 8),
                        _buildProgressBar(),
                        if (_showComboText) _buildComboDisplay(),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildGameArea(),
                        ),
                        _buildControls(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Celebration overlay
            if (_showCelebration)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ConfettiPainter(_confettiParticles),
                  ),
                ),
              ),

            // Tutorial overlay
            if (_showTutorial)
              _buildTutorialOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final movesRemaining = _level.maxMoves - _moveCount;
    final isLowOnMoves = movesRemaining <= 5 && movesRemaining > 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            onPressed: () async {
              final shouldPop = await _showExitDialog();
              if (shouldPop == true && mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),

          // Level number
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              'Level ${widget.levelNumber}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Moves counter with warning
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: isLowOnMoves
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLowOnMoves
                    ? Colors.red
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: isLowOnMoves ? Colors.red : Colors.white,
                  size: 18.sp,
                ),
                SizedBox(width: 1.w),
                Text(
                  '$_moveCount/${_level.maxMoves}',
                  style: TextStyle(
                    color: isLowOnMoves ? Colors.red : Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Menu button
          IconButton(
            onPressed: _showPauseMenu,
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final starThreshold = index == 0
                  ? _level.threeStarMoves
                  : index == 1
                      ? _level.twoStarMoves
                      : _level.maxMoves;
              final isActive = _moveCount <= starThreshold;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.w),
                child: AnimatedScale(
                  scale: isActive ? 1.0 : 0.8,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isActive ? Colors.amber : Colors.white.withOpacity(0.3),
                    size: 28.sp,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _moveCount / _level.maxMoves,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _moveCount <= _level.threeStarMoves
                    ? Colors.green
                    : _moveCount <= _level.twoStarMoves
                        ? Colors.orange
                        : Colors.red,
              ),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboDisplay() {
    return AnimatedBuilder(
      animation: _comboScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _comboScaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.pink.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.whatshot_rounded, color: Colors.white),
                SizedBox(width: 2.w),
                Text(
                  'COMBO x${_comboCount}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  '+${((_comboMultiplier - 1) * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameArea() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          children: [
            // Containers grid
            Wrap(
              spacing: 3.w,
              runSpacing: 2.h,
              alignment: WrapAlignment.center,
              children: List.generate(_level.containers.length, (index) {
                return _buildContainer(index);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainer(int index) {
    final container = _level.containers[index];
    final isSelected = _selectedContainerIndex == index;
    final isHinted = _showHint &&
        (_currentHint?.from == index || _currentHint?.to == index);

    return GestureDetector(
      onTap: _isAnimating ? null : () => _onContainerTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 18.w,
        height: 25.h,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHinted
                ? Colors.yellow
                : isSelected
                    ? Colors.blue
                    : Colors.white.withOpacity(0.2),
            width: isHinted || isSelected ? 3 : 2,
          ),
          boxShadow: isSelected || isHinted
              ? [
                  BoxShadow(
                    color: (isHinted ? Colors.yellow : Colors.blue)
                        .withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.all(1.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Items in container with animation
            ...List.generate(container.items.length, (itemIndex) {
              final item = container.items[itemIndex];
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(bottom: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getColorForItem(item.color),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _getColorForItem(item.color).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Empty spaces
            ...List.generate(
              container.maxCapacity - container.items.length,
              (emptyIndex) => Expanded(child: Container()),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForItem(int colorIndex) {
    const colors = [
      Color(0xFFE53935), // Red
      Color(0xFF1E88E5), // Blue
      Color(0xFF43A047), // Green
      Color(0xFFFB8C00), // Orange
      Color(0xFF8E24AA), // Purple
      Color(0xFFFFEB3B), // Yellow
      Color(0xFF00ACC1), // Cyan
      Color(0xFFE91E63), // Pink
    ];
    return colors[colorIndex % colors.length];
  }

  Widget _buildControls() {
    final canUndo = _moveHistory.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.refresh_rounded,
            label: 'Reset',
            onPressed: _resetLevel,
          ),
          _buildControlButton(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            onPressed: _useHint,
            cost: AppConstants.powerUpHintCost,
          ),
          _buildControlButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onPressed: canUndo ? _undoMove : null,
            cost: AppConstants.powerUpUndoCost,
            badge: canUndo ? _moveHistory.length : null,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    int? cost,
    int? badge,
  }) {
    final isEnabled = onPressed != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
                foregroundColor: isEnabled ? Colors.white : Colors.white.withOpacity(0.3),
                shape: const CircleBorder(),
                padding: EdgeInsets.all(3.w),
              ),
              child: Icon(icon, size: 24.sp),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled
                        ? Colors.white.withOpacity(0.7)
                        : Colors.white.withOpacity(0.3),
                    fontSize: 12.sp,
                  ),
                ),
                if (cost != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 12.sp,
                  ),
                  Text(
                    '$cost',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTutorialOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(6.w),
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.touch_app_rounded,
                color: Colors.blue,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'How to Play',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTutorialStep(
                '1',
                'Tap a container to select it',
                Icons.touch_app_rounded,
              ),
              const SizedBox(height: 12),
              _buildTutorialStep(
                '2',
                'Tap another container to move the top item',
                Icons.swap_vert_rounded,
              ),
              const SizedBox(height: 12),
              _buildTutorialStep(
                '3',
                'Sort all colors into separate containers',
                Icons.color_lens_rounded,
              ),
              const SizedBox(height: 12),
              _buildTutorialStep(
                '4',
                'Complete in fewer moves for more stars!',
                Icons.star_rounded,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _showTutorial = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                ),
                child: const Text(
                  'Got it! Let\'s Play',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialStep(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: Colors.blue.shade300, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _onContainerTapped(int index) {
    if (_isLevelComplete) return;

    setState(() {
      if (_selectedContainerIndex == null) {
        // Select first container
        final container = _level.containers[index];
        if (container.items.isNotEmpty) {
          _selectedContainerIndex = index;
          HapticFeedback.selectionClick();
        }
      } else if (_selectedContainerIndex == index) {
        // Deselect
        _selectedContainerIndex = null;
        HapticFeedback.selectionClick();
      } else {
        // Try to move
        _attemptMove(_selectedContainerIndex!, index);
        _selectedContainerIndex = null;
      }
      _showHint = false;
    });
  }

  Future<void> _attemptMove(int from, int to) async {
    final fromContainer = _level.containers[from];
    final toContainer = _level.containers[to];

    // Validate move
    if (fromContainer.isEmpty) return;
    if (toContainer.isFull) {
      _showError('Container is full!');
      HapticFeedback.heavyImpact();
      return;
    }

    // Check if colors match
    if (!toContainer.isEmpty && toContainer.topColor != fromContainer.topColor) {
      _showError('Colors must match!');
      HapticFeedback.heavyImpact();
      return;
    }

    // Save state for undo
    _levelSnapshots.add(_level.clone());
    _moveHistory.add(GameMove(from: from, to: to));

    // Execute move with animation
    setState(() => _isAnimating = true);
    await _moveAnimationController.forward(from: 0.0);

    final item = fromContainer.items.removeLast();
    toContainer.items.add(item);
    _moveCount++;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Update combo
    _updateCombo();

    // Check win condition
    if (_level.isSolved) {
      await _onLevelComplete();
    }

    setState(() => _isAnimating = false);
  }

  void _updateCombo() {
    _comboResetTimer?.cancel();

    setState(() {
      _comboCount++;
      _comboMultiplier = 1.0 + (_comboCount * 0.1).clamp(0.0, 1.0);
      _showComboText = _comboCount >= 3;
    });

    if (_comboCount >= 3) {
      _comboAnimationController.forward(from: 0.0);
    }

    // Reset combo after 3 seconds of inactivity
    _comboResetTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _comboCount = 0;
        _comboMultiplier = 1.0;
        _showComboText = false;
      });
    });
  }

  void _undoMove() {
    if (_moveHistory.isEmpty) return;

    final balance = CoinEconomyService.instance.getBalance();
    if (balance < AppConstants.powerUpUndoCost) {
      _showError('Not enough coins!');
      return;
    }

    // Deduct coins
    CoinEconomyService.instance.spendCoins(
      AppConstants.powerUpUndoCost,
      SpendSource.powerUpUndo,
    );

    setState(() {
      // Remove last move
      _moveHistory.removeLast();
      _moveCount--;

      // Restore previous state
      if (_levelSnapshots.isNotEmpty) {
        _level = _levelSnapshots.removeLast();
      }

      // Reset combo
      _comboCount = 0;
      _comboMultiplier = 1.0;
      _showComboText = false;
    });

    HapticFeedback.mediumImpact();

    AnalyticsLogger.logEvent(AppConstants.eventPowerUpUsed, parameters: {
      'type': 'undo',
      'level': widget.levelNumber,
      'moves_remaining': _moveHistory.length,
    });
  }

  void _resetLevel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Level?'),
        content: const Text('This will restart the level from the beginning.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeLevel();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _useHint() {
    final balance = CoinEconomyService.instance.getBalance();
    if (balance < AppConstants.powerUpHintCost) {
      _showError('Not enough coins!');
      return;
    }

    final hint = HintSystem.getHint(_level);
    if (hint == null) {
      _showError('No hint available!');
      return;
    }

    // Deduct coins
    CoinEconomyService.instance.spendCoins(
      AppConstants.powerUpHintCost,
      SpendSource.powerUpHint,
    );

    setState(() {
      _currentHint = hint;
      _showHint = true;
    });

    // Hide hint after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showHint = false;
        });
      }
    });

    AnalyticsLogger.logEvent(AppConstants.eventPowerUpUsed, parameters: {
      'type': 'hint',
      'level': widget.levelNumber,
    });
  }

  Future<void> _onLevelComplete() async {
    final stars = _level.calculateStars(_moveCount);
    final duration = DateTime.now().difference(_levelStartTime!);

    setState(() {
      _isLevelComplete = true;
    });

    // Start celebration
    _startCelebration();

    // Calculate coins with combo bonus
    int coinsEarned = AppConstants.levelCompletionCoinsBase;
    coinsEarned += stars * AppConstants.levelCompletionCoinsPerStar;
    if (stars == 3) {
      coinsEarned += AppConstants.perfectLevelBonus;
    }
    coinsEarned = (coinsEarned * _comboMultiplier).round();

    // Award coins
    AppStateManager.instance.awardCoins(
      coinsEarned,
      CoinSource.levelCompletion,
    );

    // Save progress
    await LevelProgressionService.instance.completeLevel(
      level: widget.levelNumber,
      starsEarned: stars,
      baseScore: coinsEarned,
      isPerfect: stars == 3,
    );

    // Check achievements
    AchievementsService.instance.checkLevelAchievements(widget.levelNumber);

    // Log analytics
    AnalyticsLogger.logEvent(AppConstants.eventLevelCompleted, parameters: {
      'level': widget.levelNumber,
      'stars': stars,
      'moves': _moveCount,
      'duration_seconds': duration.inSeconds,
      'coins_earned': coinsEarned,
      'combo_multiplier': _comboMultiplier,
      'combo_count': _comboCount,
    });

    // Show completion dialog
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _showCompletionDialog(stars, coinsEarned);
    }
  }

  void _startCelebration() {
    setState(() {
      _showCelebration = true;
      _confettiParticles.clear();

      // Generate confetti particles
      final random = Random();
      for (int i = 0; i < 50; i++) {
        _confettiParticles.add(_Confetti(
          position: Offset(
            random.nextDouble() * MediaQuery.of(context).size.width,
            -50,
          ),
          color: _getColorForItem(random.nextInt(8)),
          velocity: Offset(
            random.nextDouble() * 4 - 2,
            random.nextDouble() * 5 + 3,
          ),
          rotation: random.nextDouble() * 2 * pi,
          rotationSpeed: random.nextDouble() * 0.2 - 0.1,
        ));
      }
    });

    _celebrationController.forward(from: 0.0);

    // Animate confetti
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_showCelebration || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        for (var particle in _confettiParticles) {
          particle.position += particle.velocity;
          particle.rotation += particle.rotationSpeed;
          particle.velocity = Offset(
            particle.velocity.dx,
            particle.velocity.dy + 0.2, // Gravity
          );
        }
      });

      if (timer.tick > 100) {
        timer.cancel();
        setState(() => _showCelebration = false);
      }
    });
  }

  void _showCompletionDialog(int stars, int coinsEarned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: Colors.amber,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Level Complete!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: index < stars ? Colors.amber : Colors.white.withOpacity(0.3),
                  size: 40,
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Moves: $_moveCount',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (_comboCount >= 3) ...[
              const SizedBox(height: 8),
              Text(
                'Max Combo: ${_comboCount}x',
                style: const TextStyle(color: Colors.purple, fontSize: 14),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  '+$coinsEarned coins',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to level select
            },
            child: const Text('Level Select'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Load next level
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GameplayScreen(
                    levelNumber: widget.levelNumber + 1,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Next Level'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Level?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showPauseMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Paused', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: Colors.white),
              title: const Text('Reset Level', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _resetLevel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
              title: const Text('Exit to Menu', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final shouldExit = await _showExitDialog();
                if (shouldExit == true && mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Confetti particle class
class _Confetti {
  Offset position;
  Color color;
  Offset velocity;
  double rotation;
  double rotationSpeed;

  _Confetti({
    required this.position,
    required this.color,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });
}

// Confetti painter
class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation);

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        const Rect.fromLTWH(-5, -5, 10, 10),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
