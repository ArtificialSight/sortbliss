import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameplayScreen extends StatefulWidget {
  final Map<String, dynamic> levelData;
  
  const GameplayScreen({super.key, required this.levelData});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _ambientController;
  
  // Animations
  late Animation<Color> _backgroundAnimation;
  late Animation<double> _ambientAnimation;
  
  // Game state variables
  int _moveCount = 0;
  bool _isLevelComplete = false;
  bool _showParticleEffect = false;
  String? _highlightedContainerId;
  String? _draggedItemId;
  
  // Timing and speed metrics
  DateTime? _lastMoveTimestamp;
  
  // Scoring system
  int _score = 0;
  int _lastPlacementPoints = 0;
  int _comboStreak = 0;
  DateTime? _lastCorrectDropTime;
  bool _showComboIndicator = false;
  String _comboText = '';
  
  // Timer for combo reset
  Timer? _comboResetTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLevel();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _ambientController.dispose();
    _comboResetTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    // Background color animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _backgroundAnimation = ColorTween(
      begin: const Color(0xFF0F172A), // Deep slate
      end: const Color(0xFF1E293B), // Lighter slate
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    // Ambient lighting effect
    _ambientController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _ambientAnimation = Tween<double>(
      begin: 0.1,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOut,
    ));

    _backgroundController.repeat(reverse: true);
    _ambientController.repeat(reverse: true);
  }

  void _initializeLevel() {
    _comboResetTimer?.cancel();
    _comboResetTimer = null;
    setState(() {
      // Reset basic game state
      _resetBasicGameState();
      
      // Reset speed analytics and timing metrics
      _resetSpeedMetrics();
      
      // Reset scoring and combo system
      _resetScoringSystem();
    });
  }

  /// Resets basic gameplay state variables
  /// Separated for maintainability and conflict avoidance
  void _resetBasicGameState() {
    _moveCount = 0;
    _isLevelComplete = false;
    _showParticleEffect = false;
    _highlightedContainerId = null;
    _draggedItemId = null;
  }

  /// Resets speed analytics and move timestamp tracking
  /// Added from codex/add-move-timestamp-and-user-speed-metrics branch
  void _resetSpeedMetrics() {
    _lastMoveTimestamp = null;
  }

  /// Resets scoring system, combo streaks, and placement points
  /// Added from main branch for comprehensive score tracking
  void _resetScoringSystem() {
    _score = 0;
    _lastPlacementPoints = 0;
    _comboStreak = 0;
    _lastCorrectDropTime = null;
    _showComboIndicator = false;
    _comboText = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  // Game header with score and moves
                  _buildGameHeader(),
                  
                  // Main game area
                  Expanded(
                    child: _buildGameArea(),
                  ),
                  
                  // Game controls
                  _buildGameControls(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Score: $_score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Moves: $_moveCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          'Game Area',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildGameControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _resetGame,
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: _pauseGame,
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    _initializeLevel();
  }

  void _pauseGame() {
    // Implement pause functionality
    // For now, just show a simple dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Paused'),
          content: const Text('The game is paused.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Resume'),
            ),
          ],
        );
      },
    );
  }
}
