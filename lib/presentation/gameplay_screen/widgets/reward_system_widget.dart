import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../core/premium_audio_manager.dart';
import '../../../core/haptic_manager.dart';

class RewardSystemWidget extends StatefulWidget {
  final int currentLevel;
  final int totalScore;
  final int streak;
  final List<String> achievements;
  final List<String> unlockedBadges;
  final Function(String) onRewardClaimed;
  final bool showJackpot;
  final int jackpotAmount;

  const RewardSystemWidget({
    Key? key,
    required this.currentLevel,
    required this.totalScore,
    required this.streak,
    required this.achievements,
    required this.unlockedBadges,
    required this.onRewardClaimed,
    this.showJackpot = false,
    this.jackpotAmount = 0,
  }) : super(key: key);

  @override
  State<RewardSystemWidget> createState() => _RewardSystemWidgetState();
}

class _RewardSystemWidgetState extends State<RewardSystemWidget>
    with TickerProviderStateMixin {
  late AnimationController _trophyController;
  late AnimationController _badgeController;
  late AnimationController _jackpotController;
  late AnimationController _leaderboardController;

  late Animation<double> _trophyScaleAnimation;
  late Animation<double> _trophyRotationAnimation;
  late Animation<double> _badgeSlideAnimation;
  late Animation<double> _jackpotPulseAnimation;
  late Animation<double> _leaderboardFadeAnimation;

  final PremiumAudioManager _audioManager = PremiumAudioManager();
  final HapticManager _hapticManager = HapticManager();

  bool _showTrophyRoom = false;
  bool _showLeaderboard = false;
  bool _showDailyPrizes = false;
  int _selectedTrophyIndex = 0;

  // Mock data for demonstration
  final List<Map<String, dynamic>> _trophyRoom = [
    {
      'id': 'first_level',
      'name': 'First Steps',
      'description': 'Complete your first level',
      'icon': Icons.play_arrow,
      'rarity': 'common',
      'unlocked': true,
    },
    {
      'id': 'perfect_score',
      'name': 'Perfect Score',
      'description': 'Get 3 stars on a level',
      'icon': Icons.star,
      'rarity': 'rare',
      'unlocked': true,
    },
    {
      'id': 'speed_demon',
      'name': 'Speed Demon',
      'description': 'Complete a level in under 30 seconds',
      'icon': Icons.flash_on,
      'rarity': 'epic',
      'unlocked': false,
    },
    {
      'id': 'master_sorter',
      'name': 'Master Sorter',
      'description': 'Reach level 50',
      'icon': Icons.emoji_events,
      'rarity': 'legendary',
      'unlocked': false,
    },
  ];

  late final List<Map<String, dynamic>> _leaderboardData;

  @override
  void initState() {
    super.initState();
    _leaderboardData = [
      {'rank': 1, 'name': 'SortMaster', 'score': 125000, 'level': 87},
      {'rank': 2, 'name': 'QuickSort', 'score': 118500, 'level': 82},
      {'rank': 3, 'name': 'PuzzlePro', 'score': 95000, 'level': 65},
      {
        'rank': 4,
        'name': 'You',
        'score': widget.totalScore,
        'level': widget.currentLevel
      },
    ];
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _jackpotController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _leaderboardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _trophyScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _trophyController,
      curve: Curves.elasticOut,
    ));

    _trophyRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _trophyController,
      curve: Curves.easeInOut,
    ));

    _badgeSlideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.easeOutBack,
    ));

    _jackpotPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _jackpotController,
      curve: Curves.easeInOut,
    ));

    _leaderboardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _leaderboardController,
      curve: Curves.easeIn,
    ));

    if (widget.showJackpot) {
      _jackpotController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _trophyController.dispose();
    _badgeController.dispose();
    _jackpotController.dispose();
    _leaderboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade900.withValues(alpha: 0.3),
            Colors.blue.shade900.withValues(alpha: 0.2),
            Colors.purple.shade800.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with reward system title and stats
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: Colors.amber.shade400,
                size: 8.w,
              ).animate().rotate(duration: 2000.ms),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rewards & Progress',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Level ${widget.currentLevel} • ${widget.totalScore} points',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Streak indicator
              if (widget.streak > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.red.shade400],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 5.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${widget.streak}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(
                      duration: 300.ms,
                      curve: Curves.elasticOut,
                    ),
            ],
          ),

          SizedBox(height: 2.h),

          // Jackpot display
          if (widget.showJackpot)
            AnimatedBuilder(
              animation: _jackpotPulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _jackpotPulseAnimation.value,
                  child: GestureDetector(
                    onTap: _claimJackpot,
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade400,
                            Colors.orange.shade500,
                            Colors.red.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.6),
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.stars,
                            color: Colors.white,
                            size: 8.w,
                          ),
                          SizedBox(width: 3.w),
                          Column(
                            children: [
                              Text(
                                'JACKPOT!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${widget.jackpotAmount} POINTS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ).animate().slideX(duration: 600.ms, begin: 1.0),

          SizedBox(height: 2.h),

          // Action buttons for different reward screens
          Expanded(
            child: Row(
              children: [
                // Trophy Room
                Expanded(
                  child: _buildActionButton(
                    'Trophy Room',
                    Icons.emoji_events,
                    Colors.amber,
                    () => _showTrophyRoomModal(),
                  ),
                ),

                SizedBox(width: 2.w),

                // Leaderboard
                Expanded(
                  child: _buildActionButton(
                    'Leaderboard',
                    Icons.leaderboard,
                    Colors.blue,
                    () => _showLeaderboardModal(),
                  ),
                ),

                SizedBox(width: 2.w),

                // Daily Prizes
                Expanded(
                  child: _buildActionButton(
                    'Daily Prize',
                    Icons.card_giftcard,
                    Colors.purple,
                    () => _showDailyPrizesModal(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(
          begin: 0.3,
          duration: 800.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        _hapticManager.lightTap();
        _audioManager.playThemeTapSound('default');
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 8.w,
            ).animate().scale(
                  delay: 200.ms,
                  duration: 400.ms,
                ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
                  delay: 400.ms,
                ),
          ],
        ),
      ),
    ).animate().slideY(
          begin: 0.5,
          duration: 600.ms,
          curve: Curves.easeOutBack,
        );
  }

  void _claimJackpot() {
    _hapticManager.celebrationImpact();
    _audioManager.playEnhancedSuccessSound(10, 3);

    widget.onRewardClaimed('jackpot_${widget.jackpotAmount}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade400,
                Colors.orange.shade500,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars,
                color: Colors.white,
                size: 20.w,
              ).animate().rotate(duration: 2000.ms),
              SizedBox(height: 2.h),
              Text(
                'JACKPOT WON!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '+${widget.jackpotAmount} Points',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.amber.shade600,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                ),
                child: Text(
                  'Collect',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrophyRoomModal() {
    _trophyController.forward();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.indigo.shade900,
                Colors.purple.shade900,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 2.h),
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber.shade400,
                      size: 8.w,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Trophy Room',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // Trophies grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.all(4.w),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _trophyRoom.length,
                  itemBuilder: (context, index) =>
                      _buildTrophyCard(_trophyRoom[index], index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrophyCard(Map<String, dynamic> trophy, int index) {
    final isUnlocked = trophy['unlocked'] as bool;
    final rarity = trophy['rarity'] as String;

    Color rarityColor = Colors.grey;
    switch (rarity) {
      case 'common':
        rarityColor = Colors.green;
        break;
      case 'rare':
        rarityColor = Colors.blue;
        break;
      case 'epic':
        rarityColor = Colors.purple;
        break;
      case 'legendary':
        rarityColor = Colors.amber;
        break;
    }

    return AnimatedBuilder(
      animation: _trophyScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _trophyScaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUnlocked
                    ? [
                        rarityColor.withValues(alpha: 0.8),
                        rarityColor.withValues(alpha: 0.6)
                      ]
                    : [Colors.grey.shade800, Colors.grey.shade600],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isUnlocked ? rarityColor : Colors.grey,
                width: 2,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    trophy['icon'] as IconData,
                    color: isUnlocked ? Colors.white : Colors.grey.shade400,
                    size: 12.w,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    trophy['name'] as String,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.grey.shade400,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    trophy['description'] as String,
                    style: TextStyle(
                      color: isUnlocked
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey.shade500,
                      fontSize: 9.sp,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isUnlocked) ...[
                    SizedBox(height: 1.h),
                    Icon(
                      Icons.lock,
                      color: Colors.grey.shade500,
                      size: 5.w,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    )
        .animate(delay: Duration(milliseconds: index * 200))
        .slideY(begin: 0.5, curve: Curves.easeOutBack)
        .fadeIn();
  }

  void _showLeaderboardModal() {
    _leaderboardController.forward();
    // Implementation for animated leaderboard modal
    print('Show leaderboard modal');
  }

  void _showDailyPrizesModal() {
    // Implementation for daily prizes modal
    print('Show daily prizes modal');
  }
}