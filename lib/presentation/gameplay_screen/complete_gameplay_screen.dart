import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sortbliss/core/game_items_data.dart';
import 'package:sortbliss/core/services/player_profile_service.dart';
import 'package:sortbliss/core/analytics/gameplay_analytics_service.dart';
import 'package:sortbliss/core/analytics/analytics_logger.dart';
import 'package:sortbliss/core/services/audio_manager.dart';
import 'package:sortbliss/core/services/haptic_manager.dart';

/// Complete gameplay implementation with drag-and-drop sorting mechanics
/// This is the CRITICAL PATH feature that unlocks all market validation
class CompleteGameplayScreen extends StatefulWidget {
  final int levelNumber;

  const CompleteGameplayScreen({
    super.key,
    required this.levelNumber,
  });

  @override
  State<CompleteGameplayScreen> createState() => _CompleteGameplayScreenState();
}

class _CompleteGameplayScreenState extends State<CompleteGameplayScreen>
    with TickerProviderStateMixin {

  // Game state
  late List<GameItem> _unsortedItems;
  late Map<String, List<GameItem>> _containers;
  late List<String> _containerOrder;

  // Gameplay metrics
  int _moveCount = 0;
  int _score = 0;
  int _comboStreak = 0;
  DateTime? _levelStartTime;
  DateTime? _lastCorrectDropTime;
  bool _isLevelComplete = false;

  // Drag state
  GameItem? _draggedItem;
  String? _highlightedContainer;

  // Animations
  late AnimationController _backgroundController;
  late AnimationController _scorePopupController;
  late Animation<double> _scorePopupAnimation;

  // Timer
  Timer? _comboResetTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLevel();
    _trackLevelStart();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _scorePopupController.dispose();
    _comboResetTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _scorePopupController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scorePopupAnimation = CurvedAnimation(
      parent: _scorePopupController,
      curve: Curves.elasticOut,
    );
  }

  void _initializeLevel() {
    // Generate items for this level
    final levelItems = GameItemsData.generateLevelItems(widget.levelNumber);

    // Create game items from data
    _unsortedItems = levelItems.map((item) => GameItem(
      id: '${item['name']}_${DateTime.now().millisecondsSinceEpoch}',
      name: item['name'] as String,
      emoji: item['emoji'] as String,
      category: item['category'] as String,
      mainCategory: _getMainCategory(item['category'] as String),
    )).toList();

    // Initialize containers (4 main categories)
    _containerOrder = ['food', 'toys', 'home', 'animals'];
    _containers = {
      'food': [],
      'toys': [],
      'home': [],
      'animals': [],
    };

    _levelStartTime = DateTime.now();
    _score = 0;
    _moveCount = 0;
    _comboStreak = 0;
    _isLevelComplete = false;
  }

  String _getMainCategory(String subCategory) {
    // Map sub-categories to main categories
    const categoryMap = {
      // Food
      'fruit': 'food',
      'meal': 'food',
      'dessert': 'food',
      // Toys
      'plush': 'toys',
      'sport': 'toys',
      'vehicle': 'toys',
      'tech': 'toys',
      'brain': 'toys',
      'outdoor': 'toys',
      'classic': 'toys',
      'music': 'toys',
      // Home
      'furniture': 'home',
      'lighting': 'home',
      'decor': 'home',
      'kitchen': 'home',
      'bath': 'home',
      'office': 'home',
      // Animals
      'pet': 'animals',
      'wild': 'animals',
      'farm': 'animals',
      'bird': 'animals',
      'aquatic': 'animals',
    };

    return categoryMap[subCategory] ?? 'food';
  }

  void _trackLevelStart() {
    // Track analytics
    GameplayAnalyticsService.instance.trackLevelStart(
      levelNumber: widget.levelNumber,
      difficulty: _calculateDifficulty(),
    );

    AnalyticsLogger.logEvent('level_started', parameters: {
      'level_number': widget.levelNumber,
      'item_count': _unsortedItems.length,
    });
  }

  String _calculateDifficulty() {
    if (widget.levelNumber <= 10) return 'Easy';
    if (widget.levelNumber <= 30) return 'Medium';
    if (widget.levelNumber <= 60) return 'Hard';
    return 'Expert';
  }

  void _onItemDragStart(GameItem item) {
    setState(() {
      _draggedItem = item;
    });

    // Haptic feedback
    HapticManager.lightTap();

    // Audio feedback
    AudioManager.playSoundEffect('tap');
  }

  void _onItemDragEnd(DraggableDetails details) {
    setState(() {
      _draggedItem = null;
      _highlightedContainer = null;
    });
  }

  void _onContainerDragEnter(String containerKey) {
    setState(() {
      _highlightedContainer = containerKey;
    });
  }

  void _onContainerDragLeave() {
    setState(() {
      _highlightedContainer = null;
    });
  }

  void _onItemDropped(GameItem item, String containerKey) {
    setState(() {
      // Remove from unsorted
      _unsortedItems.remove(item);

      // Add to container
      _containers[containerKey]!.add(item);

      // Increment move count
      _moveCount++;

      // Check if correct placement
      final isCorrect = item.mainCategory == containerKey;

      if (isCorrect) {
        _handleCorrectPlacement(item);
      } else {
        _handleIncorrectPlacement(item);
      }

      // Clear drag state
      _draggedItem = null;
      _highlightedContainer = null;

      // Check win condition
      if (_unsortedItems.isEmpty) {
        _checkWinCondition();
      }
    });
  }

  void _handleCorrectPlacement(GameItem item) {
    // Calculate points
    final now = DateTime.now();
    int points = 100;

    // Combo bonus
    if (_lastCorrectDropTime != null) {
      final timeSinceLastDrop = now.difference(_lastCorrectDropTime!);
      if (timeSinceLastDrop.inSeconds <= 3) {
        _comboStreak++;
        points += (_comboStreak * 25); // 25 bonus per combo level
      } else {
        _comboStreak = 0;
      }
    }

    _lastCorrectDropTime = now;
    _score += points;

    // Reset combo timer
    _comboResetTimer?.cancel();
    _comboResetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _comboStreak = 0;
        });
      }
    });

    // Feedback
    HapticManager.successPattern();
    AudioManager.playSoundEffect('success');

    // Show score popup
    _scorePopupController.forward(from: 0);
  }

  void _handleIncorrectPlacement(GameItem item) {
    // Feedback
    HapticManager.errorPattern();
    AudioManager.playSoundEffect('error');
  }

  void _checkWinCondition() {
    // Check if all items are correctly sorted
    int correctItems = 0;
    int totalItems = 0;

    _containers.forEach((category, items) {
      totalItems += items.length;
      for (final item in items) {
        if (item.mainCategory == category) {
          correctItems++;
        }
      }
    });

    final accuracy = totalItems > 0 ? (correctItems / totalItems) : 0.0;
    final isPerfect = accuracy == 1.0;

    if (accuracy >= 1.0) {
      // Level complete!
      _completeLevel(isPerfect: true);
    } else if (accuracy >= 0.8) {
      // Allow completion with 80% accuracy (user-friendly)
      _completeLevel(isPerfect: false);
    } else {
      // Too many mistakes - fail condition
      _failLevel();
    }
  }

  Future<void> _completeLevel({required bool isPerfect}) async {
    if (_isLevelComplete) return;

    setState(() {
      _isLevelComplete = true;
    });

    // Calculate time
    final timeSeconds = DateTime.now().difference(_levelStartTime!).inSeconds.toDouble();

    // Calculate stars (1-3)
    int stars = 1;
    if (isPerfect && _moveCount <= (_unsortedItems.length + _containers.length)) {
      stars = 3; // Perfect with minimal moves
    } else if (isPerfect) {
      stars = 2; // Perfect but more moves
    }

    // Bonus for speed
    if (timeSeconds < 60 && isPerfect) {
      _score += 500; // Speed bonus
    }

    // Bonus for efficiency
    final optimalMoves = _calculateOptimalMoves();
    if (_moveCount <= optimalMoves) {
      _score += 300; // Efficiency bonus
    }

    // Calculate coins earned (10% of score)
    final coinsEarned = (_score / 10).round();

    // Track analytics
    await GameplayAnalyticsService.instance.trackLevelComplete(
      levelNumber: widget.levelNumber,
      score: _score,
      moves: _moveCount,
      timeSeconds: timeSeconds,
      perfectScore: isPerfect,
      starsEarned: stars,
      coinsEarned: coinsEarned,
    );

    // Update player profile
    final currentProfile = PlayerProfileService.instance.currentProfile;
    await PlayerProfileService.instance.updateProgress(
      levelsCompleted: currentProfile.levelsCompleted + 1,
      coinsEarned: currentProfile.coinsEarned + coinsEarned,
      currentLevel: widget.levelNumber + 1,
      levelProgress: 0.0,
    );

    // Celebrate!
    HapticManager.celebrationPattern();
    AudioManager.playSoundEffect('level_complete');

    // Show completion screen
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        '/level-complete',
        arguments: {
          'level': widget.levelNumber,
          'score': _score,
          'moves': _moveCount,
          'time': timeSeconds,
          'stars': stars,
          'coins': coinsEarned,
          'perfect': isPerfect,
        },
      );
    }
  }

  void _failLevel() {
    // Track failure
    GameplayAnalyticsService.instance.trackLevelFailed(
      levelNumber: widget.levelNumber,
      moves: _moveCount,
      timeSeconds: DateTime.now().difference(_levelStartTime!).inSeconds.toDouble(),
      failureReason: 'Too many incorrect placements',
    );

    // Show retry dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Oops!'),
        content: const Text('Too many items in wrong containers. Try again?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Back to level select
            },
            child: const Text('Give Up'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _initializeLevel();
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  int _calculateOptimalMoves() {
    // Optimal moves = number of items (each item moved once)
    return _containers.values.fold(0, (sum, items) => sum + items.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildGameArea(),
              ),
              _buildContainers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // Level info
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Level ${widget.levelNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_unsortedItems.length} items remaining',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Score display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: _unsortedItems.isEmpty
          ? const Center(
              child: Text(
                'Drag all items to containers!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _unsortedItems.length,
              itemBuilder: (context, index) {
                final item = _unsortedItems[index];
                return _buildDraggableItem(item);
              },
            ),
    );
  }

  Widget _buildDraggableItem(GameItem item) {
    final isDragging = _draggedItem?.id == item.id;

    return Draggable<GameItem>(
      data: item,
      onDragStarted: () => _onItemDragStart(item),
      onDragEnd: _onItemDragEnd,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              item.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDragging ? Colors.white.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            item.emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildContainers() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: _containerOrder.map((category) {
          final items = _containers[category]!;
          final isHighlighted = _highlightedContainer == category;

          return Expanded(
            child: _buildContainer(
              category: category,
              items: items,
              isHighlighted: isHighlighted,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContainer({
    required String category,
    required List<GameItem> items,
    required bool isHighlighted,
  }) {
    return DragTarget<GameItem>(
      onWillAccept: (data) {
        _onContainerDragEnter(category);
        return true;
      },
      onLeave: (data) {
        _onContainerDragLeave();
      },
      onAccept: (data) {
        _onItemDropped(data, category);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.green.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? Colors.green
                  : Colors.white.withOpacity(0.3),
              width: isHighlighted ? 3 : 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getCategoryEmoji(category),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                _getCategoryName(category),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${items.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Show small preview of items
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 2,
                    children: items.take(3).map((item) {
                      return Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 14),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getCategoryEmoji(String category) {
    const emojis = {
      'food': '🍎',
      'toys': '🧸',
      'home': '🏠',
      'animals': '🐶',
    };
    return emojis[category] ?? '📦';
  }

  String _getCategoryName(String category) {
    const names = {
      'food': 'Food',
      'toys': 'Toys',
      'home': 'Home',
      'animals': 'Animals',
    };
    return names[category] ?? category;
  }
}

class GameItem {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String mainCategory;

  GameItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.mainCategory,
  });
}
