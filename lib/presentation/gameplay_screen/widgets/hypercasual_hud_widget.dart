import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Clean minimalist HUD matching profitable hypercasual game design
class HypercasualHudWidget extends StatefulWidget {
  final int levelNumber;
  final Function() onPausePressed;
  final Duration? gameTimer;
  final bool showTimer;
  final VoidCallback? onTimerComplete;

  const HypercasualHudWidget({
    Key? key,
    required this.levelNumber,
    required this.onPausePressed,
    this.gameTimer,
    this.showTimer = true,
    this.onTimerComplete,
  }) : super(key: key);

  @override
  State<HypercasualHudWidget> createState() => _HypercasualHudWidgetState();
}

class _HypercasualHudWidgetState extends State<HypercasualHudWidget>
    with TickerProviderStateMixin {
  late Timer _gameTimer;
  Duration _currentTime = const Duration(minutes: 15); // Default 15 minutes
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.showTimer) {
      _startGameTimer();
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startGameTimer() {
    _currentTime = widget.gameTimer ?? const Duration(minutes: 15);
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime.inSeconds > 0) {
        setState(() {
          _currentTime = Duration(seconds: _currentTime.inSeconds - 1);
        });
      } else {
        timer.cancel();
        widget.onTimerComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime = _currentTime.inSeconds <= 60;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        top: MediaQuery.of(context).padding.top + 1.h,
        bottom: 2.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level indicator - left side
          _buildLevelIndicator(),

          // Timer - center
          if (widget.showTimer) _buildGameTimer(isLowTime),

          // Pause button - right side
          _buildPauseButton(),
        ],
      ),
    ).animate().slideY(begin: -1.0, duration: 800.ms);
  }

  Widget _buildLevelIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.98 + 0.02,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightTheme.primaryColor,
                  AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'emoji_events',
                  color: Colors.white,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'LEVEL ${widget.levelNumber}',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 3.5.w,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameTimer(bool isLowTime) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isLowTime ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: isLowTime
                  ? Colors.red.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isLowTime
                    ? Colors.red.shade300
                    : Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isLowTime ? Colors.red : Colors.black)
                      .withValues(alpha: 0.4),
                  blurRadius: isLowTime ? 20 : 10,
                  offset: const Offset(0, 4),
                  spreadRadius: isLowTime ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'timer',
                  color: Colors.white,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  _formatTime(_currentTime),
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 4.5.w,
                    letterSpacing: 1.0,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: widget.onPausePressed,
      child: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: 'pause',
            color: Colors.black87,
            size: 6.w,
          ),
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .shimmer(
          duration: 3000.ms,
          color: Colors.white.withValues(alpha: 0.1),
        );
  }
}
