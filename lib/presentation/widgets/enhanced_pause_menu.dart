import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/powerup_service.dart';
import '../../core/services/statistics_service.dart';
import '../../core/services/user_settings_service.dart';
import '../../core/theme/app_theme.dart';

/// Enhanced pause menu for in-game pause state
///
/// Features:
/// - Resume/Quit buttons
/// - Current level info
/// - Power-ups quick access
/// - Settings quick toggles (sound, haptics)
/// - Statistics preview
/// - Beautiful blur background
/// - Smooth animations
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (context) => EnhancedPauseMenu(
///     level: currentLevel,
///     currentScore: score,
///     movesUsed: moves,
///     onResume: () => Navigator.pop(context),
///     onQuit: () => Navigator.of(context).popUntil((route) => route.isFirst),
///   ),
/// );
/// ```
class EnhancedPauseMenu extends StatefulWidget {
  final int level;
  final int currentScore;
  final int movesUsed;
  final VoidCallback onResume;
  final VoidCallback onQuit;
  final VoidCallback? onRestart;

  const EnhancedPauseMenu({
    Key? key,
    required this.level,
    required this.currentScore,
    required this.movesUsed,
    required this.onResume,
    required this.onQuit,
    this.onRestart,
  }) : super(key: key);

  @override
  State<EnhancedPauseMenu> createState() => _EnhancedPauseMenuState();
}

class _EnhancedPauseMenuState extends State<EnhancedPauseMenu>
    with SingleTickerProviderStateMixin {
  final PowerUpService _powerUps = PowerUpService.instance;
  final StatisticsService _stats = StatisticsService.instance;
  final UserSettingsService _settings = UserSettingsService.instance;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from dismissing
        return false;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: BoxConstraints(maxWidth: 90.w, maxHeight: 80.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildHeader(),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(5.w),
                      child: Column(
                        children: [
                          // Level info
                          _buildLevelInfo(),

                          SizedBox(height: 3.h),

                          // Power-ups section
                          _buildPowerUpsSection(),

                          SizedBox(height: 3.h),

                          // Quick settings
                          _buildQuickSettings(),

                          SizedBox(height: 3.h),

                          // Action buttons
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.primaryColor,
            Colors.purple.shade600,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(5.w),
          topRight: Radius.circular(5.w),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle, color: Colors.white, size: 8.w),
          SizedBox(width: 2.w),
          Text(
            'Game Paused',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        children: [
          Text(
            'Level ${widget.level}',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.stars,
                'Score',
                widget.currentScore.toString(),
                Colors.amber,
              ),
              _buildStatItem(
                Icons.touch_app,
                'Moves',
                widget.movesUsed.toString(),
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 6.w),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPowerUpsSection() {
    final inventory = _powerUps.getInventory();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Power-Ups',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/powerups');
              },
              child: Text('Shop'),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _buildPowerUpButton(
                'Undo',
                '↩️',
                inventory['undo'] ?? 0,
                () => _usePowerUp('undo'),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildPowerUpButton(
                'Hint',
                '💡',
                inventory['hint'] ?? 0,
                () => _usePowerUp('hint'),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildPowerUpButton(
                'Shuffle',
                '🔀',
                inventory['shuffle'] ?? 0,
                () => _usePowerUp('shuffle'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPowerUpButton(
    String name,
    String emoji,
    int count,
    VoidCallback onTap,
  ) {
    final hasInventory = count > 0;

    return GestureDetector(
      onTap: hasInventory ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: hasInventory
              ? Colors.purple.withOpacity(0.1)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(
            color: hasInventory
                ? Colors.purple.withOpacity(0.3)
                : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 6.w,
                color: hasInventory ? null : Colors.grey,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: hasInventory ? Colors.purple : Colors.grey,
              ),
            ),
            SizedBox(height: 0.3.h),
            Text(
              name,
              style: TextStyle(
                fontSize: 10.sp,
                color: hasInventory ? Colors.grey[700] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSettings() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Settings',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 1.h),
          _buildSettingToggle(
            'Sound Effects',
            Icons.volume_up,
            _settings.getSoundEnabled(),
            (value) {
              _settings.setSoundEnabled(value);
              setState(() {});
            },
          ),
          SizedBox(height: 1.h),
          _buildSettingToggle(
            'Haptic Feedback',
            Icons.vibration,
            _settings.getHapticEnabled(),
            (value) {
              _settings.setHapticEnabled(value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, size: 5.w, color: Colors.grey[600]),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[800],
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.lightTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Resume button
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton.icon(
            onPressed: () async {
              await _animationController.reverse();
              widget.onResume();
            },
            icon: Icon(Icons.play_arrow, size: 6.w),
            label: Text(
              'Resume Game',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.w),
              ),
              elevation: 2,
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Restart button (if provided)
        if (widget.onRestart != null)
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await _showConfirmDialog(
                  'Restart Level?',
                  'Your current progress will be lost.',
                );
                if (confirm == true) {
                  await _animationController.reverse();
                  widget.onRestart!();
                }
              },
              icon: Icon(Icons.refresh, size: 6.w),
              label: Text(
                'Restart Level',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade700, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
              ),
            ),
          ),

        if (widget.onRestart != null) SizedBox(height: 2.h),

        // Quit button
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await _showConfirmDialog(
                'Quit Game?',
                'Your current progress will be lost.',
              );
              if (confirm == true) {
                await _animationController.reverse();
                widget.onQuit();
              }
            },
            icon: Icon(Icons.exit_to_app, size: 6.w),
            label: Text(
              'Quit to Menu',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade700, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.w),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _usePowerUp(String powerUpId) {
    // Close pause menu and signal power-up usage to game
    Navigator.of(context).pop({'usePowerUp': powerUpId});
  }
}

/// Compact pause button widget for game screen
class PauseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PauseButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(3.w),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(3.w),
        child: Container(
          padding: EdgeInsets.all(2.w),
          child: Icon(
            Icons.pause,
            size: 7.w,
            color: AppTheme.lightTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
