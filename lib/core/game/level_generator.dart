import 'dart:math';
import 'package:flutter/foundation.dart';

/// Level generator for SortBliss
///
/// Generates procedural sorting puzzles with configurable difficulty.
/// Ensures all levels are solvable and appropriately challenging.
///
/// Difficulty Factors:
/// - Number of colors (3-8)
/// - Number of items per color (2-6)
/// - Number of containers (colors + 1-2 empty)
/// - Shuffle complexity (random moves from solved state)
///
/// Level Structure:
/// - Early levels (1-10): 3-4 colors, 3 items each, simple shuffles
/// - Mid levels (11-50): 4-6 colors, 4 items each, moderate shuffles
/// - Late levels (51+): 6-8 colors, 5-6 items each, complex shuffles
class LevelGenerator {
  static final LevelGenerator instance = LevelGenerator._();
  LevelGenerator._();

  final Random _random = Random();

  /// Generate level based on level number
  Level generateLevel(int levelNumber) {
    final difficulty = _calculateDifficulty(levelNumber);

    final level = Level(
      id: 'level_$levelNumber',
      number: levelNumber,
      colors: difficulty.colors,
      itemsPerColor: difficulty.itemsPerColor,
      emptyContainers: difficulty.emptyContainers,
      maxMoves: difficulty.maxMoves,
      threeStarMoves: difficulty.threeStarMoves,
      twoStarMoves: difficulty.twoStarMoves,
    );

    // Generate initial state (solved)
    _generateSolvedState(level);

    // Shuffle to create puzzle
    _shuffleLevel(level, difficulty.shuffleMoves);

    return level;
  }

  /// Calculate difficulty parameters for level
  DifficultyParams _calculateDifficulty(int levelNumber) {
    if (levelNumber <= 10) {
      // Tutorial levels - very easy
      return DifficultyParams(
        colors: 3,
        itemsPerColor: 3,
        emptyContainers: 2,
        maxMoves: 20,
        threeStarMoves: 10,
        twoStarMoves: 15,
        shuffleMoves: 8,
      );
    } else if (levelNumber <= 30) {
      // Easy levels
      final colors = 3 + ((levelNumber - 10) / 5).floor();
      return DifficultyParams(
        colors: colors.clamp(3, 5),
        itemsPerColor: 3,
        emptyContainers: 2,
        maxMoves: 25 + ((levelNumber - 10) / 2).floor(),
        threeStarMoves: 12 + ((levelNumber - 10) / 3).floor(),
        twoStarMoves: 18 + ((levelNumber - 10) / 2).floor(),
        shuffleMoves: 10 + (levelNumber - 10) ~/ 4,
      );
    } else if (levelNumber <= 60) {
      // Medium levels
      final colors = 5 + ((levelNumber - 30) / 10).floor();
      return DifficultyParams(
        colors: colors.clamp(5, 6),
        itemsPerColor: 4,
        emptyContainers: 2,
        maxMoves: 40 + ((levelNumber - 30) / 2).floor(),
        threeStarMoves: 20 + ((levelNumber - 30) / 3).floor(),
        twoStarMoves: 30 + ((levelNumber - 30) / 2).floor(),
        shuffleMoves: 15 + (levelNumber - 30) ~/ 3,
      );
    } else {
      // Hard levels
      final colors = 6 + ((levelNumber - 60) / 20).floor();
      return DifficultyParams(
        colors: colors.clamp(6, 8),
        itemsPerColor: 5,
        emptyContainers: 2,
        maxMoves: 60 + ((levelNumber - 60) / 2).floor(),
        threeStarMoves: 30 + ((levelNumber - 60) / 4).floor(),
        twoStarMoves: 45 + ((levelNumber - 60) / 3).floor(),
        shuffleMoves: 20 + (levelNumber - 60) ~/ 2,
      );
    }
  }

  /// Generate solved state (all items sorted)
  void _generateSolvedState(Level level) {
    level.containers.clear();

    // Create containers with sorted colors
    for (int i = 0; i < level.colors; i++) {
      final container = Container(
        id: 'container_$i',
        maxCapacity: level.itemsPerColor,
      );

      // Fill with same color
      for (int j = 0; j < level.itemsPerColor; j++) {
        container.items.add(ColorItem(color: i));
      }

      level.containers.add(container);
    }

    // Add empty containers
    for (int i = 0; i < level.emptyContainers; i++) {
      level.containers.add(
        Container(
          id: 'container_empty_$i',
          maxCapacity: level.itemsPerColor,
        ),
      );
    }
  }

  /// Shuffle level by making random valid moves
  void _shuffleLevel(Level level, int moves) {
    for (int i = 0; i < moves; i++) {
      final validMoves = _getValidMoves(level);

      if (validMoves.isEmpty) break;

      // Pick random valid move
      final move = validMoves[_random.nextInt(validMoves.length)];

      // Execute move
      _executeMove(level, move.from, move.to);
    }
  }

  /// Get all valid moves for current state
  List<GameMove> _getValidMoves(Level level) {
    final moves = <GameMove>[];

    for (int from = 0; from < level.containers.length; from++) {
      final fromContainer = level.containers[from];

      if (fromContainer.isEmpty) continue;

      for (int to = 0; to < level.containers.length; to++) {
        if (from == to) continue;

        final toContainer = level.containers[to];

        if (_isValidMove(fromContainer, toContainer)) {
          moves.add(GameMove(from: from, to: to));
        }
      }
    }

    return moves;
  }

  /// Check if move is valid
  bool _isValidMove(Container from, Container to) {
    if (from.isEmpty) return false;
    if (to.isFull) return false;

    // Can always move to empty container
    if (to.isEmpty) return true;

    // Can only move if top colors match
    return from.topColor == to.topColor;
  }

  /// Execute move
  void _executeMove(Level level, int fromIndex, int toIndex) {
    final from = level.containers[fromIndex];
    final to = level.containers[toIndex];

    if (!_isValidMove(from, to)) return;

    // Move items
    final item = from.items.removeLast();
    to.items.add(item);
  }
}

/// Difficulty parameters
class DifficultyParams {
  final int colors;
  final int itemsPerColor;
  final int emptyContainers;
  final int maxMoves;
  final int threeStarMoves;
  final int twoStarMoves;
  final int shuffleMoves;

  DifficultyParams({
    required this.colors,
    required this.itemsPerColor,
    required this.emptyContainers,
    required this.maxMoves,
    required this.threeStarMoves,
    required this.twoStarMoves,
    required this.shuffleMoves,
  });
}

/// Level data model
class Level {
  final String id;
  final int number;
  final int colors;
  final int itemsPerColor;
  final int emptyContainers;
  final int maxMoves;
  final int threeStarMoves;
  final int twoStarMoves;

  final List<Container> containers = [];

  Level({
    required this.id,
    required this.number,
    required this.colors,
    required this.itemsPerColor,
    required this.emptyContainers,
    required this.maxMoves,
    required this.threeStarMoves,
    required this.twoStarMoves,
  });

  int get totalContainers => colors + emptyContainers;

  bool get isSolved {
    int fullSortedContainers = 0;

    for (final container in containers) {
      if (container.isEmpty) continue;

      if (container.isSorted && container.items.length == itemsPerColor) {
        fullSortedContainers++;
      }
    }

    return fullSortedContainers == colors;
  }

  int calculateStars(int movesUsed) {
    if (movesUsed <= threeStarMoves) return 3;
    if (movesUsed <= twoStarMoves) return 2;
    if (movesUsed <= maxMoves) return 1;
    return 0;
  }

  Level clone() {
    final cloned = Level(
      id: id,
      number: number,
      colors: colors,
      itemsPerColor: itemsPerColor,
      emptyContainers: emptyContainers,
      maxMoves: maxMoves,
      threeStarMoves: threeStarMoves,
      twoStarMoves: twoStarMoves,
    );

    for (final container in containers) {
      cloned.containers.add(container.clone());
    }

    return cloned;
  }
}

/// Container (tube/bottle) holding colored items
class Container {
  final String id;
  final int maxCapacity;
  final List<ColorItem> items = [];

  Container({
    required this.id,
    required this.maxCapacity,
  });

  bool get isEmpty => items.isEmpty;
  bool get isFull => items.length >= maxCapacity;
  int? get topColor => items.isEmpty ? null : items.last.color;

  bool get isSorted {
    if (items.isEmpty) return true;

    final firstColor = items.first.color;
    return items.every((item) => item.color == firstColor);
  }

  Container clone() {
    final cloned = Container(id: id, maxCapacity: maxCapacity);
    cloned.items.addAll(items.map((i) => ColorItem(color: i.color)));
    return cloned;
  }
}

/// Colored item (ball/liquid)
class ColorItem {
  final int color; // 0-7 representing different colors

  ColorItem({required this.color});
}

/// Game move
class GameMove {
  final int from;
  final int to;

  GameMove({required this.from, required this.to});

  @override
  String toString() => 'Move($from -> $to)';
}

/// Hint system
class HintSystem {
  /// Get hint for current level state
  static GameMove? getHint(Level level) {
    // Strategy 1: Complete any container that can be completed
    final completeMove = _findCompletableMove(level);
    if (completeMove != null) return completeMove;

    // Strategy 2: Move to empty container if it helps
    final emptyMove = _findEmptyContainerMove(level);
    if (emptyMove != null) return emptyMove;

    // Strategy 3: Consolidate colors
    final consolidateMove = _findConsolidationMove(level);
    if (consolidateMove != null) return consolidateMove;

    // No good hint available
    return null;
  }

  static GameMove? _findCompletableMove(Level level) {
    for (int from = 0; from < level.containers.length; from++) {
      final fromContainer = level.containers[from];
      if (fromContainer.isEmpty || !fromContainer.isSorted) continue;

      for (int to = 0; to < level.containers.length; to++) {
        if (from == to) continue;

        final toContainer = level.containers[to];
        if (toContainer.isEmpty) continue;
        if (!toContainer.isSorted) continue;
        if (toContainer.topColor != fromContainer.topColor) continue;

        // Check if this would complete a container
        final spaceNeeded = level.itemsPerColor - toContainer.items.length;
        if (spaceNeeded > 0 && fromContainer.items.length >= spaceNeeded) {
          return GameMove(from: from, to: to);
        }
      }
    }

    return null;
  }

  static GameMove? _findEmptyContainerMove(Level level) {
    for (int from = 0; from < level.containers.length; from++) {
      final fromContainer = level.containers[from];
      if (fromContainer.isEmpty || fromContainer.isSorted) continue;

      for (int to = 0; to < level.containers.length; to++) {
        final toContainer = level.containers[to];
        if (!toContainer.isEmpty) continue;

        return GameMove(from: from, to: to);
      }
    }

    return null;
  }

  static GameMove? _findConsolidationMove(Level level) {
    for (int from = 0; from < level.containers.length; from++) {
      final fromContainer = level.containers[from];
      if (fromContainer.isEmpty) continue;

      final topColor = fromContainer.topColor!;

      for (int to = 0; to < level.containers.length; to++) {
        if (from == to) continue;

        final toContainer = level.containers[to];
        if (toContainer.isFull) continue;
        if (toContainer.isEmpty) continue;
        if (toContainer.topColor != topColor) continue;

        return GameMove(from: from, to: to);
      }
    }

    return null;
  }
}
