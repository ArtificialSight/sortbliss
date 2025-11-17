import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';

/// Visual score card for sharing on social media
/// Can be captured as image via RepaintBoundary
class ShareCardWidget extends StatelessWidget {
  final int level;
  final int stars;
  final int score;
  final String? playerName;

  const ShareCardWidget({
    super.key,
    required this.level,
    required this.stars,
    required this.score,
    this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90.w,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primaryContainer,
            AppTheme.lightTheme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sort,
                size: 32.sp,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                'SortBliss',
                style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Level info
          Text(
            'Level $level Complete!',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
            ),
          ),

          SizedBox(height: 2.h),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Icon(
                index < stars ? Icons.star : Icons.star_border,
                size: 40.sp,
                color: index < stars
                    ? Colors.amber
                    : AppTheme.lightTheme.colorScheme.onPrimaryContainer.withOpacity(0.3),
              );
            }),
          ),

          SizedBox(height: 3.h),

          // Score
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Column(
              children: [
                Text(
                  'Score',
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$score',
                  style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Player name (optional)
          if (playerName != null) ...[
            Text(
              'by $playerName',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
              ),
            ),
            SizedBox(height: 2.h),
          ],

          // Call to action
          Text(
            'Can you beat my score?',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Referral card for inviting friends
class ReferralCardWidget extends StatelessWidget {
  final String referralCode;
  final int referralCount;

  const ReferralCardWidget({
    super.key,
    required this.referralCode,
    required this.referralCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90.w,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.tertiaryContainer,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard,
            size: 48.sp,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),

          Text(
            'Join SortBliss!',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
            ),
          ),

          SizedBox(height: 1.h),

          Text(
            'Get 100 bonus coins with my referral code',
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),

          SizedBox(height: 3.h),

          // Referral code display
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary,
                width: 2,
              ),
            ),
            child: Text(
              referralCode,
              style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.primary,
                letterSpacing: 4,
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Stats
          if (referralCount > 0) ...[
            Text(
              '$referralCount friends joined!',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Streak milestone card
class StreakCardWidget extends StatelessWidget {
  final int streakDays;

  const StreakCardWidget({
    super.key,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90.w,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700,
            Colors.deepOrange.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 64.sp,
            color: Colors.white,
          ),
          SizedBox(height: 2.h),

          Text(
            '$streakDays-Day Streak!',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 1.h),

          Text(
            'Consistency is key 🔥',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          SizedBox(height: 3.h),

          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, color: Colors.white, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'SortBliss',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
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
}
