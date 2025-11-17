import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Beautiful empty state widgets for various scenarios
///
/// Provides consistent, engaging empty states across the app
/// with illustrations, messages, and call-to-action buttons.
///
/// Types:
/// - NoAchievements
/// - NoEvents
/// - NoLeaderboardData
/// - NoPowerUps
/// - NoStatistics
/// - Generic (customizable)
///
/// Usage:
/// ```dart
/// EmptyStateWidget.noAchievements(
///   onAction: () => Navigator.pushNamed(context, '/game'),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customIllustration;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor = Colors.grey,
    this.actionText,
    this.onAction,
    this.customIllustration,
  }) : super(key: key);

  // Predefined empty states

  factory EmptyStateWidget.noAchievements({VoidCallback? onAction}) {
    return EmptyStateWidget(
      title: 'No Achievements Yet',
      subtitle: 'Start playing to unlock amazing achievements!',
      icon: Icons.emoji_events,
      iconColor: Colors.amber,
      actionText: 'Start Playing',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.noEvents({VoidCallback? onAction}) {
    return EmptyStateWidget(
      title: 'No Active Events',
      subtitle: 'Check back soon for exciting seasonal events!',
      icon: Icons.celebration,
      iconColor: Colors.orange,
      actionText: 'Play While Waiting',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.noLeaderboard({VoidCallback? onAction}) {
    return EmptyStateWidget(
      title: 'No Rankings Yet',
      subtitle: 'Be the first to set a record!',
      icon: Icons.leaderboard,
      iconColor: Colors.green,
      actionText: 'Play Now',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.noPowerUps({VoidCallback? onAction}) {
    return EmptyStateWidget(
      title: 'No Power-Ups',
      subtitle: 'Get power-ups from the shop or earn coins by playing!',
      icon: Icons.power,
      iconColor: Colors.purple,
      actionText: 'Visit Shop',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.noStatistics({VoidCallback? onAction}) {
    return EmptyStateWidget(
      title: 'No Stats Yet',
      subtitle: 'Complete some levels to see your statistics!',
      icon: Icons.bar_chart,
      iconColor: Colors.blue,
      actionText: 'Start Playing',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.noSearchResults({String? searchQuery}) {
    return EmptyStateWidget(
      title: 'No Results Found',
      subtitle: searchQuery != null
          ? 'No results for "$searchQuery"'
          : 'Try adjusting your search',
      icon: Icons.search_off,
      iconColor: Colors.grey,
    );
  }

  factory EmptyStateWidget.offline({VoidCallback? onAction}) {
    return EmptyStateWidget(
      title: 'You\'re Offline',
      subtitle: 'Some features require an internet connection',
      icon: Icons.wifi_off,
      iconColor: Colors.red,
      actionText: 'Retry',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.error({VoidCallback? onAction}) {
    return EmptyStateWidget(
      title: 'Something Went Wrong',
      subtitle: 'We couldn\'t load this content. Please try again.',
      icon: Icons.error_outline,
      iconColor: Colors.red,
      actionText: 'Retry',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.comingSoon() {
    return const EmptyStateWidget(
      title: 'Coming Soon',
      subtitle: 'This feature is under development. Stay tuned!',
      icon: Icons.construction,
      iconColor: Colors.orange,
    );
  }

  factory EmptyStateWidget.noNotifications({VoidCallback? onAction}) {
    return EmptyStateWidget(
      title: 'No Notifications',
      subtitle: 'You\'re all caught up!',
      icon: Icons.notifications_none,
      iconColor: Colors.blue,
      actionText: 'Play Now',
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration or icon
            if (customIllustration != null)
              customIllustration!
            else
              _buildIconIllustration(),

            SizedBox(height: 4.h),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 1.h),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionText != null && onAction != null) ...[
              SizedBox(height: 4.h),
              SizedBox(
                width: 60.w,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3.w),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    actionText!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconIllustration() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20.w,
          color: iconColor,
        ),
      ),
    );
  }
}

/// Animated empty state with pulsing effect
class AnimatedEmptyState extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? actionText;
  final VoidCallback? onAction;

  const AnimatedEmptyState({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor = Colors.grey,
    this.actionText,
    this.onAction,
  }) : super(key: key);

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 20.w,
                    color: widget.iconColor,
                  ),
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Title
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 1.h),

            // Subtitle
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (widget.actionText != null && widget.onAction != null) ...[
              SizedBox(height: 4.h),
              SizedBox(
                width: 60.w,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: widget.onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.iconColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3.w),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    widget.actionText!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading state placeholder
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            SizedBox(height: 2.h),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// List empty state with illustration
class ListEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String? actionText;
  final VoidCallback? onAction;

  const ListEmptyState({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.actionText,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji illustration
            Text(
              emoji,
              style: TextStyle(fontSize: 30.w),
            ),

            SizedBox(height: 3.h),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 1.h),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionText != null && onAction != null) ...[
              SizedBox(height: 4.h),
              SizedBox(
                width: 60.w,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3.w),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    actionText!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
