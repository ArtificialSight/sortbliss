import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/level_progression_service.dart';
import '../../../theme/app_theme.dart';

/// Enhanced level card showing lock status, stars, and difficulty
class LevelCardWidget extends StatelessWidget {
  final int level;
  final bool isUnlocked;
  final int stars;
  final LevelDifficulty difficulty;
  final bool isRecommended;
  final VoidCallback? onTap;

  const LevelCardWidget({
    super.key,
    required this.level,
    required this.isUnlocked,
    required this.stars,
    required this.difficulty,
    this.isRecommended = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
                  colors: isRecommended
                      ? [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ]
                      : [
                          colorScheme.surface,
                          colorScheme.surface,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUnlocked ? null : colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4.w),
          border: isRecommended
              ? Border.all(
                  color: colorScheme.primary,
                  width: 2,
                )
              : null,
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: isRecommended
                        ? colorScheme.primary.withOpacity(0.3)
                        : colorScheme.shadow.withOpacity(0.1),
                    blurRadius: isRecommended ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock icon or level number
                  if (!isUnlocked)
                    Icon(
                      Icons.lock,
                      size: 32.sp,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    )
                  else
                    Text(
                      '$level',
                      style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isRecommended
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),

                  SizedBox(height: 1.h),

                  // Stars (only if unlocked)
                  if (isUnlocked) _buildStars(colorScheme),

                  SizedBox(height: 0.5.h),

                  // Difficulty badge
                  if (isUnlocked)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(colorScheme),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        difficulty.displayName,
                        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Recommended badge
            if (isRecommended && isUnlocked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4.w),
                      bottomLeft: Radius.circular(2.w),
                    ),
                  ),
                  child: Text(
                    'NEXT',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate(
      onPlay: (controller) {
        if (isRecommended) {
          controller.repeat(reverse: true);
        }
      },
    ).shimmer(
      duration: 2000.ms,
      color: isRecommended ? Colors.white.withOpacity(0.3) : Colors.transparent,
    );
  }

  Widget _buildStars(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final earned = index < stars;
        return Icon(
          earned ? Icons.star : Icons.star_border,
          color: earned ? Colors.amber : colorScheme.onSurfaceVariant.withOpacity(0.3),
          size: 16.sp,
        );
      }),
    );
  }

  Color _getDifficultyColor(ColorScheme colorScheme) {
    switch (difficulty) {
      case LevelDifficulty.easy:
        return Colors.green;
      case LevelDifficulty.medium:
        return Colors.orange;
      case LevelDifficulty.hard:
        return Colors.red;
      case LevelDifficulty.expert:
        return Colors.purple;
    }
  }
}

/// Tier unlock progress card
class TierUnlockProgressWidget extends StatelessWidget {
  final int starsEarned;
  final int starsRequired;
  final int nextTierStart;

  const TierUnlockProgressWidget({
    super.key,
    required this.starsEarned,
    required this.starsRequired,
    required this.nextTierStart,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = starsRequired > 0 ? (starsEarned / starsRequired).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_open,
                color: colorScheme.onPrimaryContainer,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Unlock Levels $nextTierStart-${nextTierStart + 9}',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Progress bar
          Container(
            height: 1.5.h,
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1.h),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1.h),
                ),
              ),
            ),
          ),

          SizedBox(height: 1.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16.sp,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '$starsEarned / $starsRequired',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Player XP progress widget
class PlayerXPWidget extends StatelessWidget {
  final int playerLevel;
  final int xp;
  final double progressToNext;

  const PlayerXPWidget({
    super.key,
    required this.playerLevel,
    required this.xp,
    required this.progressToNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Level badge
          Container(
            width: 14.w,
            height: 14.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ),
            ),
            child: Center(
              child: Text(
                '$playerLevel',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // XP info and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $playerLevel',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$xp XP',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Container(
                  height: 0.8.h,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(0.5.h),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressToNext,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(0.5.h),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
