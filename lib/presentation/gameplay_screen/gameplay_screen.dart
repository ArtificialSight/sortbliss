import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/audio_manager.dart';
import '../../core/game_items_data.dart';
import '../../core/gesture_controller.dart';
import '../../core/haptic_manager.dart';
import '../../core/premium_audio_manager.dart';
import '../../theme/app_theme.dart';
import './widgets/adaptive_tutorial_widget.dart';
import './widgets/advanced_confetti_widget.dart';
import './widgets/animated_achievement_widget.dart';
import './widgets/camera_parallax_widget.dart';
import './widgets/enhanced_adaptive_tutorial_widget.dart';
import './widgets/floating_ui_panel_widget.dart';
import './widgets/level_complete_modal_widget.dart';
import './widgets/progress_transition_widget.dart';
import './widgets/sparkle_particle_widget.dart';
import './widgets/central_pile_widget.dart';
import './widgets/hypercasual_hud_widget.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({Key? key}) : super(key: key);

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with TickerProviderStateMixin {
  // Game state variables
  int _currentLevel = 1;
  int _moveCount = 0;
  int _maxMoves = 15;
  int _score = 0;
  bool _isLevelComplete = false;
  bool _showParticleEffect = false;
  String? _highlightedContainerId;
  String? _draggedItemId;

  // Enhanced audio and haptic managers
  final AudioManager _audioManager = AudioManager();
  final HapticManager _hapticManager = HapticManager();

  // Enhanced particle and animation states
  bool _showAdvancedConfetti = false;
  bool _showSparkles = false;
  Offset _sparklePosition = Offset.zero;
  bool _showAchievement = false;
  String _achievementTitle = '';
  String _achievementDescription = '';
  IconData _achievementIcon = Icons.star;
  Color _achievementColor = Colors.blue;

  // Progress transition state
  bool _showProgressTransition = false;
  List<String> _unlockedFeatures = [];

  // Floating panels
  bool _showPausePanel = false;
  bool _showSettingsPanel = false;

  // Animation controllers for enhanced visual effects
  late AnimationController _backgroundController;
  late AnimationController _ambientController;
  late Animation<Color?> _backgroundAnimation;
  late Animation<double> _ambientAnimation;

  // Enhanced game data with realistic 3D items
  late List<Map<String, dynamic>> _gameContainers;
  List<Map<String, dynamic>> _unsortedItems = [];

  // Enhanced premium systems
  final PremiumAudioManager _premiumAudioManager = PremiumAudioManager();
  final GestureController _gestureController = GestureController();

  // Advanced game state
  bool _showTutorial = false;
  bool _showRewardSystem = false;
  List<String> _unlockedAchievements = [];
  List<String> _collectedBadges = [];
  int _perfectLevelsCount = 0;
  int _totalGameScore = 12500;
  double _userSpeed = 1.0;
  List<String> _completedTutorialActions = [];
  String _currentTheme = 'default';

  // Camera and visual enhancements
  bool _enableCameraEffects = true;
  bool _enableParallax = true;
  double _cameraIntensity = 1.0;

  // Reward system state
  bool _showJackpot = false;
  int _jackpotAmount = 0;
  int _winStreak = 0;

  // Enhanced tutorial state tracking
  bool _tutorialDragStarted = false;
  bool _tutorialDropCompleted = false;
  int _tutorialActionsCount = 0;
  bool _tutorialNextStepEnabled = false;

  // New timer state for hypercasual design
  Duration _gameTimer = const Duration(minutes: 15);
  bool _timerExpired = false;

  @override
  void initState() {
    super.initState();
    _initializeGameContainers();
    _initializeAnimations();
    _initializePremiumSystems();
    _initializeLevel();
    _checkFirstTimeUser();
  }

  Future<void> _initializePremiumSystems() async {
    await _premiumAudioManager.initialize();
    await _gestureController.initialize();

    // Set up gesture callbacks
    _gestureController.setVoiceCommandCallback(_handleVoiceCommand);
    _gestureController.setGestureDetectedCallback(_handleGestureDetected);
    _gestureController.setTiltChangedCallback(_handleTiltChanged);

    // Start adaptive background music
    await _premiumAudioManager.playAdaptiveBackgroundMusic(1, _currentLevel);
  }

  void _checkFirstTimeUser() {
    // In a real app, check SharedPreferences
    final isFirstTime = _currentLevel == 1 && _completedTutorialActions.isEmpty;
    if (isFirstTime) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  void _initializeGameContainers() {
    final categories = GameItemsData.getAllCategories();
    _gameContainers = categories.map((category) {
      final config = GameItemsData.getContainerConfig(category);
      return {
        "id": category,
        "name": config['name'],
        "emoji": config['emoji'],
        "color": config['color'],
        "gradient": config['gradient'],
        "description": config['description'],
        "items": <Map<String, dynamic>>[],
      };
    }).toList();
  }

  void _initializeAnimations() {
    // Enhanced background animation with deeper colors
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
    setState(() {
      _moveCount = 0;
      _isLevelComplete = false;
      _showParticleEffect = false;
      _highlightedContainerId = null;
      _draggedItemId = null;

      // Reset containers
      for (var container in _gameContainers) {
        (container["items"] as List).clear();
      }

      // Generate realistic 3D items for the level
      _generateLevel3DItems();

      // Update theme based on level
      _currentTheme = _getUnlockedTheme();

      // Check for jackpot eligibility
      _checkJackpotEligibility();
    });

    // Announce level start for accessibility
    _gestureController.announceGameEvent('level_start');

    // Adjust music intensity based on level
    _premiumAudioManager
        .adjustMusicIntensity(math.min(10, _currentLevel ~/ 5 + 1));
  }

  String _getUnlockedTheme() {
    if (_currentLevel >= 20) return 'crystal';
    if (_currentLevel >= 15) return 'neon';
    if (_currentLevel >= 10) return 'golden';
    if (_currentLevel >= 5) return 'metallic';
    return 'default';
  }

  void _checkJackpotEligibility() {
    if (_winStreak >= 5 && _currentLevel % 10 == 0) {
      setState(() {
        _showJackpot = true;
        _jackpotAmount = 1000 + (_winStreak * 200);
      });
    }
  }

  void _generateLevel3DItems() {
    try {
      // Use the enhanced GameItemsData to generate diverse, realistic items
      _unsortedItems = GameItemsData.generateLevelItems(_currentLevel);

      print(
          'Level $_currentLevel initialized with ${_unsortedItems.length} realistic 3D items:');
      for (var item in _unsortedItems) {
        print(
            '- ${item['name']} (${item['category']}) -> ${item['targetContainer']}');
      }
    } catch (e) {
      print('Error generating 3D level items: $e');
      // Fallback to basic generation
      _unsortedItems = GameItemsData.generateLevelItems(_currentLevel);
    }
  }

  void _onDragStarted(String itemId) {
    setState(() {
      _draggedItemId = itemId;
      // Track tutorial progress
      if (_showTutorial && !_tutorialDragStarted) {
        _tutorialDragStarted = true;
        _onTutorialUserAction('drag');
      }
    });

    // Enhanced feedback
    _audioManager.playWhooshSound();
    _hapticManager.lightTap();
  }

  void _onDragEnd(String itemId) {
    setState(() {
      _draggedItemId = null;
      _highlightedContainerId = null;
    });
  }

  void _onItemDropped(String itemId, String containerId) {
    final item = _unsortedItems.firstWhere(
      (item) => item["id"] == itemId,
      orElse: () => <String, dynamic>{},
    );

    if (item.isEmpty) return;

    final container = _gameContainers.firstWhere(
      (container) => container["id"] == containerId,
    );

    final isCorrectPlacement =
        GameItemsData.itemBelongsToCategory(item, containerId);

    setState(() {
      _moveCount++;
      (container["items"] as List).add(item);
      _unsortedItems.removeWhere((i) => i["id"] == itemId);
      _highlightedContainerId = null;

      // Track tutorial progress
      if (_showTutorial) {
        if (isCorrectPlacement) {
          _tutorialDropCompleted = true;
          _tutorialActionsCount++;
          _tutorialNextStepEnabled = true;
          _onTutorialUserAction('drop');
        }
      }
    });

    // Enhanced premium audiovisual feedback
    if (isCorrectPlacement) {
      _premiumAudioManager.playSpatialContainerSound(containerId, 'success');
      _hapticManager.successImpact();
      _showSuccessEffects(item);
      _checkForAchievements();
      _gestureController.announceGameEvent('correct_placement');

      // Update user speed analytics
      _updateUserSpeed();
    } else {
      _premiumAudioManager.playContextualErrorSound(containerId);
      _hapticManager.errorFeedback();
      _gestureController.announceGameEvent('incorrect_placement');
    }

    _checkLevelComplete();
  }

  // New method to handle timer expiration
  void _onTimerExpired() {
    setState(() {
      _timerExpired = true;
    });

    // Show time's up dialog or transition to game over
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Time's Up!",
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Great effort! Try again to beat your best time.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeLevel(); // Restart level
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.primaryColor,
            ),
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onMainMenu();
            },
            child: Text(
              'Main Menu',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  // New method to build compact containers for bottom area
  Widget _buildCompactContainer(Map<String, dynamic> container, int index) {
    final isHighlighted = _highlightedContainerId == container["id"];

    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => data != null,
      onAcceptWithDetails: (details) => _onItemDropped(details.data, container["id"] as String),
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(container["color"] as int)
                    .withValues(alpha: isHighlighted ? 0.8 : 0.6),
                Color(container["color"] as int)
                    .withValues(alpha: isHighlighted ? 0.6 : 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHighlighted
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.3),
              width: isHighlighted ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: isHighlighted ? 15 : 8,
                offset: const Offset(0, 4),
                spreadRadius: isHighlighted ? 2 : 0,
              ),
              if (isHighlighted)
                BoxShadow(
                  color:
                      Color(container["color"] as int).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
            ],
          ),
          child: Stack(
            children: [
              // Container content
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      container["emoji"] as String,
                      style: TextStyle(fontSize: 6.w),
                    ),
                    SizedBox(width: 2.w),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          container["name"] as String,
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${(container["items"] as List).length} items',
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Drop indicator
              if (candidateData.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.yellow,
                      width: 3,
                    ),
                    color: Colors.yellow.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
        )
            .animate(
              delay: Duration(milliseconds: index * 150),
            )
            .slideY(begin: 1.0, duration: 600.ms)
            .fadeIn();
      },
    );
  }

  // New method to handle tutorial user actions
  void _onTutorialUserAction(String action) {
    // Access the tutorial widget state directly through the key if using regular tutorial
    if (_tutorialWidgetKey.currentState != null) {
      final tutorialState = _tutorialWidgetKey.currentState;
      // Remove the invalid type checks and use dynamic approach
      try {
        if (tutorialState.runtimeType
            .toString()
            .contains('AdaptiveTutorialWidget')) {
          (tutorialState as dynamic).onUserAction(action);
        } else if (tutorialState.runtimeType
            .toString()
            .contains('EnhancedAdaptiveTutorialWidget')) {
          (tutorialState as dynamic).onUserAction(action);
        }
      } catch (e) {
        // Handle any type casting errors gracefully
        print('Tutorial state access error: $e');
      }
    }
  }

  AdaptiveTutorialWidget? _getCurrentTutorialWidget() {
    // Access the current tutorial widget if active - this method is no longer needed
    // but kept for compatibility
    return null;
  }

  final GlobalKey _tutorialWidgetKey = GlobalKey();

  void _updateUserSpeed() {
    final expectedTime = _maxMoves * 2.0; // 2 seconds per move expected
    final actualTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    // Calculate based on move efficiency
    _userSpeed =
        (expectedTime / math.max(1.0, actualTime)) * 0.1 + _userSpeed * 0.9;
  }

  void _showSuccessEffects(Map<String, dynamic> item) {
    // Show sparkles at item position
    setState(() {
      _sparklePosition = Offset(50.w, 40.h); // Center of game area
      _showSparkles = true;
    });

    // Hide sparkles after animation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showSparkles = false;
        });
      }
    });

    // Play sparkle sound
    _audioManager.playSparkleSound();
  }

  void _checkForAchievements() {
    // Check for various achievements
    final totalItemsPlaced = _gameContainers
        .map((c) => (c["items"] as List).length)
        .fold(0, (sum, count) => sum + count);

    if (totalItemsPlaced == 5 && !_showAchievement) {
      _showAchievementNotification(
        'Quick Sorter!',
        'Placed 5 items correctly',
        Icons.flash_on,
        Colors.orange,
      );
    } else if (_moveCount <= 10 && totalItemsPlaced >= 8 && !_showAchievement) {
      _showAchievementNotification(
        'Efficiency Master!',
        'Perfect sorting in minimal moves',
        Icons.emoji_events,
        Colors.amber,
      );
    }
  }

  void _showAchievementNotification(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    setState(() {
      _showAchievement = true;
      _achievementTitle = title;
      _achievementDescription = description;
      _achievementIcon = icon;
      _achievementColor = color;
    });

    _audioManager.playSparkleSound();
    _hapticManager.selectionFeedback();
  }

  void _hideAchievementNotification() {
    setState(() {
      _showAchievement = false;
    });
  }

  void _onContainerTap(String containerId) {
    setState(() {
      _highlightedContainerId =
          _highlightedContainerId == containerId ? null : containerId;
    });
    _hapticManager.selectionFeedback();
    _audioManager.playButtonTapSound();
  }

  void _checkLevelComplete() {
    if (_unsortedItems.isEmpty) {
      final efficiency = (_maxMoves - _moveCount) / _maxMoves;
      final stars = efficiency > 0.8
          ? 3
          : efficiency > 0.5
              ? 2
              : 1;

      if (stars >= 3) {
        _perfectLevelsCount++;
        _winStreak++;
      } else {
        _winStreak = 0;
      }

      final itemVarietyBonus = _gameContainers
              .map((c) => (c["items"] as List).length)
              .where((count) => count > 0)
              .length *
          100;

      _score = (1000 * efficiency).round() + (stars * 500) + itemVarietyBonus;
      _totalGameScore += _score;

      // Generate unlocked features based on performance
      _unlockedFeatures.clear();
      if (stars >= 3) {
        _unlockedFeatures.add('Perfect Score Bonus');
      }
      if (_currentLevel % 5 == 0) {
        _unlockedFeatures.add('New Theme Unlocked: $_currentLevel');
      }
      if (_moveCount <= _maxMoves * 0.5) {
        _unlockedFeatures.add('Efficiency Master Badge');
        _collectedBadges.add('efficiency_master_${_currentLevel}');
      }

      setState(() {
        _isLevelComplete = true;
        _showAdvancedConfetti = true;
        _showProgressTransition = true;
        _showRewardSystem = stars >= 2;
      });

      // Enhanced celebration with premium audio
      _premiumAudioManager.playLevelCompleteFanfare(stars, _currentLevel);
      _hapticManager.celebrationImpact();
      _gestureController.announceGameEvent('level_complete');

      // Hide confetti after animation
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _showAdvancedConfetti = false;
          });
        }
      });
    }
  }

  void _onPausePressed() {
    _audioManager.playButtonTapSound();
    _hapticManager.lightTap();
    setState(() {
      _showPausePanel = true;
    });
  }

  void _onHintPressed() {
    if (_unsortedItems.isNotEmpty) {
      final item = _unsortedItems.first;
      final targetContainer = item["targetContainer"] as String;

      setState(() {
        _highlightedContainerId = targetContainer;
      });

      _audioManager.playButtonTapSound();
      _hapticManager.selectionFeedback();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedContainerId = null;
          });
        }
      });
    }
  }

  void _onRestartPressed() {
    _audioManager.playButtonTapSound();
    _hapticManager.lightTap();

    setState(() {
      _showPausePanel = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Restart Level?',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will reset your current progress.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeLevel();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _onNextLevel() {
    setState(() {
      _currentLevel++;
      _maxMoves = 15 + (_currentLevel * 2);
      _isLevelComplete = false;
      _showProgressTransition = false;
    });
    _initializeLevel();
  }

  void _onLevelRestart() {
    setState(() {
      _isLevelComplete = false;
      _showProgressTransition = false;
    });
    _initializeLevel();
  }

  void _onMainMenu() {
    _audioManager.stopBackgroundMusic();
    Navigator.pushReplacementNamed(context, '/main-menu');
  }

  void _onProgressTransitionComplete() {
    setState(() {
      _showProgressTransition = false;
    });
  }

  // Voice command handler
  void _handleVoiceCommand(String command) {
    switch (command) {
      case 'hint':
        _onHintPressed();
        break;
      case 'pause':
        _onPausePressed();
        break;
      case 'restart':
        _onRestartPressed();
        break;
      case 'menu':
        _onMainMenu();
        break;
      case 'settings':
        _onPausePressed(); // Show settings in pause panel
        break;
      case 'volume_up':
        _premiumAudioManager.setMasterVolume(
          math.min(1.0, _premiumAudioManager.masterVolume + 0.1),
        );
        break;
      case 'volume_down':
        _premiumAudioManager.setMasterVolume(
          math.max(0.0, _premiumAudioManager.masterVolume - 0.1),
        );
        break;
    }
  }

  // Gesture detection handler
  void _handleGestureDetected(String gesture) {
    switch (gesture) {
      case 'shake':
        // Shake to shuffle items or get hint
        if (_unsortedItems.length > 3) {
          setState(() {
            _unsortedItems.shuffle();
          });
          _hapticManager.lightTap();
        }
        break;
    }
  }

  // Tilt control handler
  void _handleTiltChanged(double tiltX, double tiltY) {
    // Highlight containers based on tilt direction
    String? targetContainer;
    if (tiltX > 0.5 && _gameContainers.length >= 2) {
      targetContainer = _gameContainers[1]['id'];
    } else if (tiltX < -0.5 && _gameContainers.length >= 1) {
      targetContainer = _gameContainers[0]['id'];
    } else if (tiltY > 0.5 && _gameContainers.length >= 4) {
      targetContainer = _gameContainers[3]['id'];
    } else if (tiltY < -0.5 && _gameContainers.length >= 3) {
      targetContainer = _gameContainers[2]['id'];
    }

    if (targetContainer != null && targetContainer != _highlightedContainerId) {
      setState(() {
        _highlightedContainerId = targetContainer;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _highlightedContainerId == targetContainer) {
          setState(() {
            _highlightedContainerId = null;
          });
        }
      });
    }
  }

  // Add this method to handle reward claims
  void _onRewardClaimed(String rewardType) {
    // Handle reward claim logic with reward type parameter
    _hapticManager.successImpact();
    _audioManager.playSparkleSound();

    // Handle different reward types
    switch (rewardType) {
      case 'bonus_points':
        _score += 500;
        break;
      case 'extra_moves':
        _maxMoves += 3;
        break;
      case 'jackpot':
        _score += _jackpotAmount;
        setState(() {
          _showJackpot = false;
          _jackpotAmount = 0;
        });
        break;
      default:
        // Default reward handling
        break;
    }

    setState(() {
      _totalGameScore += _score;
    });
  }

  // Enhanced tutorial callbacks with proper state management
  void _onTutorialActionCompleted(String action) {
    _completedTutorialActions.add(action);

    // Enable next step progression based on action
    setState(() {
      switch (action) {
        case 'drag_item':
          _tutorialNextStepEnabled = _tutorialDragStarted;
          break;
        case 'match_category':
          _tutorialNextStepEnabled = _tutorialDropCompleted;
          break;
        case 'try_again':
          _tutorialNextStepEnabled = _tutorialActionsCount >= 3;
          break;
        default:
          _tutorialNextStepEnabled = true;
      }
    });
  }

  void _onTutorialCompleted() {
    setState(() {
      _showTutorial = false;
      _tutorialDragStarted = false;
      _tutorialDropCompleted = false;
      _tutorialActionsCount = 0;
      _tutorialNextStepEnabled = false;
    });
  }

  // Enhanced tutorial dismissal method
  void _dismissTutorial() {
    setState(() {
      _showTutorial = false;
    });
    _hapticManager.lightTap();
    _audioManager.playButtonTapSound();

    // Optional: Show brief confirmation that tutorial was dismissed
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Tutorial dismissed. You can restart it from settings.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.lightTheme.primaryColor,
        ),
      );
    }
  }

  // Add method to manually restart tutorial for testing
  void _restartTutorial() {
    setState(() {
      _showTutorial = true;
      _tutorialDragStarted = false;
      _tutorialDropCompleted = false;
      _tutorialActionsCount = 0;
      _tutorialNextStepEnabled = false;
      _completedTutorialActions.clear();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _ambientController.dispose();
    _premiumAudioManager.dispose();
    _gestureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraParallaxWidget(
        intensity: _cameraIntensity,
        enableGyroscope: _enableCameraEffects,
        enableParallax: _enableParallax,
        child: AnimatedBuilder(
          animation:
              Listenable.merge([_backgroundAnimation, _ambientAnimation]),
          builder: (context, child) {
            return Container(
              // Professional dark background matching profitable games
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D1117), // Deep dark background
                    const Color(0xFF161B22), // Slightly lighter
                    const Color(0xFF21262D), // Bottom gradient
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Main game layout with central pile design
                  Column(
                    children: [
                      // Clean hypercasual HUD - Level indicator, Timer, Pause button
                      HypercasualHudWidget(
                        levelNumber: _currentLevel,
                        onPausePressed: _showTutorial ? () {} : _onPausePressed,
                        gameTimer: _gameTimer,
                        showTimer: true,
                        onTimerComplete: _onTimerExpired,
                      ),

                      // Central pile gameplay area - main focus
                      Expanded(
                        flex: 4, // Increased space for central pile
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          child: CentralPileWidget(
                            items: _unsortedItems,
                            onDragStarted: _onDragStarted,
                            onDragEnd: _onDragEnd,
                            enableTutorialMode: _showTutorial,
                            highlightedItemId: _highlightedContainerId,
                          ),
                        ),
                      ),

                      // Sorting containers - bottom area
                      Expanded(
                        flex: 2, // Reduced space to focus on central pile
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(2.w),
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.2, // Flatter containers
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _gameContainers.length,
                            itemBuilder: (context, index) {
                              final container = _gameContainers[index];
                              return _buildCompactContainer(container, index);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Enhanced particle effects system - reduced during tutorial
                  if (!_showTutorial)
                    AdvancedConfettiWidget(
                      isActive: _showAdvancedConfetti,
                      primaryColor: AppTheme.lightTheme.primaryColor,
                      secondaryColor: Colors.yellow.shade400,
                      particleCount: 40,
                    ),

                  // Sparkle effects - reduced during tutorial
                  if (!_showTutorial)
                    SparkleParticleWidget(
                      isActive: _showSparkles,
                      position: _sparklePosition,
                      color: Colors.yellow.shade400,
                    ),

                  // Achievement notification - only when tutorial inactive
                  if (!_showTutorial)
                    AnimatedAchievementWidget(
                      isVisible: _showAchievement,
                      title: _achievementTitle,
                      description: _achievementDescription,
                      icon: _achievementIcon,
                      color: _achievementColor,
                      onTap: _hideAchievementNotification,
                    ),

                  // Floating pause panel - disabled during tutorial
                  if (!_showTutorial)
                    FloatingUIPanelWidget(
                      isVisible: _showPausePanel,
                      title: 'Game Paused',
                      onClose: () => setState(() => _showPausePanel = false),
                      content: Column(
                        children: [
                          Text(
                            'Take a break! Your progress is saved.',
                            style: AppTheme.lightTheme.textTheme.bodyMedium,
                          ),
                          SizedBox(height: 3.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _showPausePanel = false);
                                  _onMainMenu();
                                },
                                child: const Text('Main Menu'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    setState(() => _showPausePanel = false),
                                child: const Text('Resume'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Progress transition overlay - disabled during tutorial
                  if (_showProgressTransition && !_showTutorial)
                    ProgressTransitionWidget(
                      isVisible: _showProgressTransition,
                      currentLevel: _currentLevel,
                      nextLevel: _currentLevel + 1,
                      score: _score,
                      stars: _moveCount <= _maxMoves * 0.6
                          ? 3
                          : _moveCount <= _maxMoves * 0.8
                              ? 2
                              : 1,
                      achievement: _currentLevel % 5 == 0
                          ? 'Milestone Reached!'
                          : _moveCount <= _maxMoves * 0.5
                              ? 'Efficiency Master!'
                              : '',
                      unlockedFeatures: _unlockedFeatures,
                      onComplete: _onProgressTransitionComplete,
                    ),

                  // Level complete modal - disabled during tutorial
                  if (_isLevelComplete && !_showTutorial)
                    LevelCompleteModalWidget(
                      levelNumber: _currentLevel,
                      score: _score,
                      stars: _moveCount <= _maxMoves * 0.6
                          ? 3
                          : _moveCount <= _maxMoves * 0.8
                              ? 2
                              : 1,
                      moveCount: _moveCount,
                      maxMoves: _maxMoves,
                      onNextLevel: _onNextLevel,
                      onRestart: _onLevelRestart,
                      onMainMenu: _onMainMenu,
                    ),

                  // Critical Fix: Non-blocking Enhanced Adaptive Tutorial Overlay
                  if (_showTutorial)
                    EnhancedAdaptiveTutorialWidget(
                      key: _tutorialWidgetKey,
                      currentLevel: _currentLevel,
                      isFirstTime: _completedTutorialActions.isEmpty,
                      userSpeed: _userSpeed,
                      completedActions: _completedTutorialActions,
                      onActionCompleted: _onTutorialActionCompleted,
                      onTutorialCompleted: _onTutorialCompleted,
                      onTutorialDismissed: _dismissTutorial,
                      nextStepEnabled: _tutorialNextStepEnabled,
                      dragStarted: _tutorialDragStarted,
                      dropCompleted: _tutorialDropCompleted,
                      actionsCount: _tutorialActionsCount,
                    ),

                  // DEBUG: Tutorial restart button (only visible during development/testing)
                  if (kDebugMode && !_showTutorial)
                    Positioned(
                      top: 4.h,
                      left: 2.w,
                      child: FloatingActionButton.small(
                        onPressed: _restartTutorial,
                        backgroundColor: Colors.blue.withValues(alpha: 0.7),
                        child: const Icon(Icons.school, color: Colors.white),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}