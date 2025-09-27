import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/services/daily_challenge_service.dart';

class DailyChallengeWidget extends StatelessWidget {
  final DailyChallengePayload? challenge;
  final Duration? timeRemaining;
  final bool isLoading;
  final VoidCallback? onPressed;

  const DailyChallengeWidget({
    super.key,
    required this.challenge,
    required this.timeRemaining,
    required this.isLoading,
    this.onPressed,
  });

  bool get _isCompleted => challenge?.isCompleted ?? false;

  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return '--';
    }
    final capped = duration.isNegative ? Duration.zero : duration;
    final hours = capped.inHours;
    final minutes = capped.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    final seconds = capped.inSeconds.remainder(60);
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasData = challenge != null;
    final bool isInteractive = hasData && !isLoading && onPressed != null;
    final borderColor = _isCompleted
        ? colorScheme.tertiary
        : hasData
            ? colorScheme.primary
            : colorScheme.outline;
    final containerColor = colorScheme.surface;
    final progressLabel = hasData
        ? '${challenge!.currentStars}/${challenge!.targetStars} ⭐ earned today'
        : 'Check back soon for a new goal';
    final subtitle = isLoading
        ? 'Syncing latest challenge...'
        : !hasData
            ? 'Daily challenge unavailable'
            : _isCompleted
                ? 'Completed • Claim before reset'
                : 'Resets in ${_formatDuration(timeRemaining)}';

    final progressValue = hasData ? challenge!.progressRatio : 0.0;

    return Opacity(
      opacity: isInteractive ? 1.0 : 0.85,
      child: GestureDetector(
        onTap: isInteractive ? onPressed : null,
        child: Container(
          width: 90.w,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: (_isCompleted
                          ? colorScheme.tertiary
                          : hasData
                              ? colorScheme.primary
                              : colorScheme.outline)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 6.w,
                        height: 6.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      )
                    : CustomIconWidget(
                        iconName: _isCompleted
                            ? 'check_circle'
                            : hasData
                                ? 'today'
                                : 'hourglass_empty',
                        color: _isCompleted
                            ? colorScheme.tertiary
                            : hasData
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                        size: 6.w,
                      ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge?.title ?? 'Daily Challenge',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 0.9.h,
                        backgroundColor: colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isCompleted
                              ? colorScheme.tertiary
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      progressLabel,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              CustomIconWidget(
                iconName: isInteractive ? 'chevron_right' : 'lock',
                color: colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
