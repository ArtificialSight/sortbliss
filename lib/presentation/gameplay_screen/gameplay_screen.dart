import 'dart:async';
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

/// Main gameplay screen for SortBliss
///
/// Displays the sorting puzzle with drag-and-drop mechanics.
/// Tracks moves, shows progress, detects win condition, and awards coins.
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

  // Animation controllers
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;

  // UI state
  int? _selectedContainerIndex;
  bool _showHint = false;
  GameMove? _currentHint;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLevel();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
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
    });

    AnalyticsLogger.logEvent(AppConstants.eventLevelStarted, parameters: {
      'level': widget.levelNumber,
      'colors': _level.colors,
      'max_moves': _level.maxMoves,
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showExitDialog();
        return shouldPop ?? false;
      },
      child: Scaffold(
        body: AnimatedBuilder(
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
                    const SizedBox(height: 16),
                    _buildProgressBar(),
                    const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Moves: $_moveCount / ${_level.maxMoves}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: List.generate(3, (index) {
                  final starThreshold = index == 0
                      ? _level.threeStarMoves
                      : index == 1
                          ? _level.twoStarMoves
                          : _level.maxMoves;
                  final isActive = _moveCount <= starThreshold;

                  return Padding(
                    padding: EdgeInsets.only(left: 1.w),
                    child: Icon(
                      isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isActive ? Colors.amber : Colors.white.withOpacity(0.3),
                      size: 20.sp,
                    ),
                  );
                }),
              ),
            ],
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
              minHeight: 8,
            ),
          ),
        ],
      ),
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
      onTap: () => _onContainerTapped(index),
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
        ),
        padding: EdgeInsets.all(1.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Items in container
            ...List.generate(container.items.length, (itemIndex) {
              final item = container.items[itemIndex];
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getColorForItem(item.color),
                    borderRadius: BorderRadius.circular(8),
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
            onPressed: null, // TODO: Implement undo
            cost: AppConstants.powerUpUndoCost,
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
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
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
                color: Colors.white.withOpacity(0.7),
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
        }
      } else if (_selectedContainerIndex == index) {
        // Deselect
        _selectedContainerIndex = null;
      } else {
        // Try to move
        _attemptMove(_selectedContainerIndex!, index);
        _selectedContainerIndex = null;
      }
      _showHint = false;
    });
  }

  void _attemptMove(int from, int to) {
    final fromContainer = _level.containers[from];
    final toContainer = _level.containers[to];

    // Validate move
    if (fromContainer.isEmpty) return;
    if (toContainer.isFull) return;

    // Check if colors match (can only stack same colors)
    if (!toContainer.isEmpty && toContainer.topColor != fromContainer.topColor) {
      _showError('Colors must match!');
      return;
    }

    // Execute move
    final item = fromContainer.items.removeLast();
    toContainer.items.add(item);
    _moveCount++;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Check win condition
    if (_level.isSolved) {
      _onLevelComplete();
    }

    setState(() {});
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

    // Calculate coins
    int coinsEarned = AppConstants.levelCompletionCoinsBase;
    coinsEarned += stars * AppConstants.levelCompletionCoinsPerStar;
    if (stars == 3) {
      coinsEarned += AppConstants.perfectLevelBonus;
    }

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
    });

    // Show completion dialog
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showCompletionDialog(stars, coinsEarned);
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
