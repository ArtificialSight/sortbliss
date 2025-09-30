import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sortbliss/core/constants/app_theme.dart';
import 'package:sortbliss/core/utils/dialog_utils.dart';
import 'package:sortbliss/data/models/level_data.dart';
import 'package:sortbliss/presentation/common/widgets/action_buttons_widget.dart';
import 'package:sortbliss/presentation/level_complete_screen/widgets/achievement_widget.dart';
import 'package:sortbliss/presentation/level_complete_screen/widgets/stats_widget.dart';
import 'package:sortbliss/presentation/providers/game_provider.dart';

class LevelCompleteScreen extends StatefulWidget {
  final Map<String, dynamic> levelData;
  final VoidCallback? onNextLevel;
  final VoidCallback? onRestart;

  const LevelCompleteScreen({
    Key? key,
    required this.levelData,
    this.onNextLevel,
    this.onRestart,
  }) : super(key: key);

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late Animation<double> _backgroundOpacity;
  late Animation<double> _contentScale;
  late Animation<Offset> _contentSlide;
  
  // Thread-safe dialog state management using Completer
  Completer<void>? _dialogClosedCompleter;
  bool _showActionButtons = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _contentScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
  }

  Future<void> _startAnimationSequence() async {
    await _backgroundController.forward();
    await _contentController.forward();
    
    // Show action buttons after animations complete
    if (mounted) {
      setState(() {
        _showActionButtons = true;
      });
    }
  }

  Future<void> _navigateToNextLevel(BuildContext context) async {
    try {
      // Initialize dialog completer for thread-safe state management
      _dialogClosedCompleter = Completer<void>();
      
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      
      // Show loading dialog
      DialogUtils.showLoadingDialog(context, 'Loading next level...');
      
      // Navigate to next level
      await gameProvider.loadNextLevel();
      
      // Complete the dialog completer to signal completion
      if (!_dialogClosedCompleter!.isCompleted) {
        _dialogClosedCompleter!.complete();
      }
      
      // Wait for dialog to be properly closed
      await _dialogClosedCompleter!.future;
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        widget.onNextLevel?.call();
      }
    } catch (error) {
      // Complete completer even on error
      if (_dialogClosedCompleter != null && !_dialogClosedCompleter!.isCompleted) {
        _dialogClosedCompleter!.complete();
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        DialogUtils.showErrorDialog(context, 'Failed to load next level: $error');
      }
    }
  }

  Future<void> _restartLevel(BuildContext context) async {
    try {
      // Initialize dialog completer for thread-safe state management
      _dialogClosedCompleter = Completer<void>();
      
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      
      // Show loading dialog
      DialogUtils.showLoadingDialog(context, 'Restarting level...');
      
      // Restart current level
      await gameProvider.restartCurrentLevel();
      
      // Complete the dialog completer to signal completion
      if (!_dialogClosedCompleter!.isCompleted) {
        _dialogClosedCompleter!.complete();
      }
      
      // Wait for dialog to be properly closed
      await _dialogClosedCompleter!.future;
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        widget.onRestart?.call();
      }
    } catch (error) {
      // Complete completer even on error
      if (_dialogClosedCompleter != null && !_dialogClosedCompleter!.isCompleted) {
        _dialogClosedCompleter!.complete();
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        DialogUtils.showErrorDialog(context, 'Failed to restart level: $error');
      }
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    
    // Clean up dialog completer if it exists
    if (_dialogClosedCompleter != null && !_dialogClosedCompleter!.isCompleted) {
      _dialogClosedCompleter!.complete();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: AnimatedBuilder(
        animation: Listenable.merge([_backgroundController, _contentController]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(_backgroundOpacity.value * 0.3),
                  Colors.purple.withOpacity(_backgroundOpacity.value * 0.5),
                  Colors.black.withOpacity(_backgroundOpacity.value * 0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 32.h,
                  ),
                  child: SlideTransition(
                    position: _contentSlide,
                    child: ScaleTransition(
                      scale: _contentScale,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Level Complete Title
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 32.w,
                              vertical: 16.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.withOpacity(0.8),
                                  Colors.orange.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 20.r,
                                  spreadRadius: 2.r,
                                ),
                              ],
                            ),
                            child: Text(
                              'Level Complete!',
                              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 32.h),
                          
                          // Stats Widget
                          StatsWidget(
                            levelData: widget.levelData,
                            animationController: _contentController,
                          ),
                          
                          SizedBox(height: 24.h),
                          
                          // Achievement Widget (if achievement unlocked)
                          if (widget.levelData["achievementUnlocked"] != null)
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 16.h),
                              padding: EdgeInsets.all(20.r),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.8),
                                    Colors.teal.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 15.r,
                                    spreadRadius: 1.r,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: 32.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Achievement Unlocked!',
                                          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          widget.levelData["achievementUnlocked"],
                                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          SizedBox(height: 32.h),
                          
                          // Action buttons
                          if (_showActionButtons)
                            ActionButtonsWidget(
                              onNextLevel: () => _navigateToNextLevel(context),
                              onRestart: () => _restartLevel(context),
                              showNextLevel: widget.onNextLevel != null,
                              showRestart: widget.onRestart != null,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
