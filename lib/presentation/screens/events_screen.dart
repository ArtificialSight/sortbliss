import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/seasonal_events_service.dart';
import '../../core/theme/app_theme.dart';

/// Seasonal events screen showing active and upcoming events
///
/// Features:
/// - Active events with progress tracking
/// - Upcoming events preview
/// - Event details and rewards
/// - Challenge progress bars
/// - Countdown timers
/// - Beautiful event cards with themes
class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final SeasonalEventsService _events = SeasonalEventsService.instance;

  @override
  Widget build(BuildContext context) {
    final activeEvents = _events.getActiveEvents();
    final upcomingEvents = _events.getUpcomingEvents();

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Seasonal Events'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active events
            if (activeEvents.isNotEmpty) ...[
              _buildSectionHeader('Active Events', Icons.celebration),
              SizedBox(height: 2.h),
              ...activeEvents.map((event) => Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: _buildEventCard(event, isActive: true),
                  )),
              SizedBox(height: 4.h),
            ],

            // Upcoming events
            if (upcomingEvents.isNotEmpty) ...[
              _buildSectionHeader('Upcoming Events', Icons.schedule),
              SizedBox(height: 2.h),
              ...upcomingEvents.map((event) => Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: _buildEventCard(event, isActive: false),
                  )),
            ],

            // No events state
            if (activeEvents.isEmpty && upcomingEvents.isEmpty) ...[
              _buildNoEventsState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 6.w, color: AppTheme.lightTheme.primaryColor),
        SizedBox(width: 2.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(SeasonalEvent event, {required bool isActive}) {
    final progress = _events.getEventProgress(event.id);
    final completedChallenges = event.challenges.where((c) {
      final challengeProgress = progress.progress[c.id] ?? 0;
      return challengeProgress >= c.goal;
    }).length;

    final themeColors = _getEventThemeColors(event.theme);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: themeColors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Event content
          Padding(
            padding: EdgeInsets.all(5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            event.description,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _getEventEmoji(event.theme),
                      style: TextStyle(fontSize: 15.w),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Time remaining or starts in
                if (isActive) ...[
                  _buildTimeRemaining(event.timeRemaining),
                  SizedBox(height: 3.h),
                ] else ...[
                  _buildStartsIn(event.startDate),
                  SizedBox(height: 3.h),
                ],

                // Challenges
                Text(
                  'Challenges ($completedChallenges/${event.challenges.length})',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 2.h),

                ...event.challenges.map((challenge) {
                  final challengeProgress = progress.progress[challenge.id] ?? 0;
                  final isCompleted = challengeProgress >= challenge.goal;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: _buildChallenge(
                      challenge,
                      challengeProgress,
                      isCompleted,
                      isActive,
                    ),
                  );
                }),

                // Rewards
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 6.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Rewards: ${event.rewardCoins} coins',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Completed badge
          if (_events.hasCompletedEvent(event.id))
            Positioned(
              top: 4.w,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(5.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 4.w),
                    SizedBox(width: 1.w),
                    Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallenge(
    EventChallenge challenge,
    int progress,
    bool isCompleted,
    bool isActive,
  ) {
    final progressPercent = isActive ? (progress / challenge.goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isCompleted)
                Icon(Icons.check_circle, color: Colors.green, size: 5.w)
              else
                Icon(Icons.radio_button_unchecked,
                    color: Colors.white.withOpacity(0.5), size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          if (isActive && !isCompleted) ...[
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 1.h,
              borderRadius: BorderRadius.circular(0.5.h),
            ),
            SizedBox(height: 0.5.h),
            Text(
              '$progress / ${challenge.goal}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRemaining(Duration remaining) {
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    String timeText;
    if (days > 0) {
      timeText = '$days day${days > 1 ? 's' : ''} $hours hour${hours > 1 ? 's' : ''}';
    } else if (hours > 0) {
      timeText = '$hours hour${hours > 1 ? 's' : ''} $minutes min';
    } else {
      timeText = '$minutes minute${minutes > 1 ? 's' : ''}';
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: Colors.white, size: 5.w),
          SizedBox(width: 2.w),
          Text(
            'Ends in $timeText',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartsIn(DateTime startDate) {
    final now = DateTime.now();
    final diff = startDate.difference(now);
    final days = diff.inDays;

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, color: Colors.white, size: 5.w),
          SizedBox(width: 2.w),
          Text(
            'Starts in $days day${days > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEventsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10.h),
            Icon(Icons.event_busy, size: 20.w, color: Colors.grey[400]),
            SizedBox(height: 3.h),
            Text(
              'No Events Right Now',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Check back soon for special seasonal events with bonus rewards!',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getEventThemeColors(EventTheme theme) {
    switch (theme) {
      case EventTheme.newYear:
        return [Colors.purple.shade600, Colors.blue.shade600];
      case EventTheme.valentines:
        return [Colors.pink.shade400, Colors.red.shade400];
      case EventTheme.spring:
        return [Colors.green.shade400, Colors.teal.shade400];
      case EventTheme.summer:
        return [Colors.orange.shade400, Colors.amber.shade600];
      case EventTheme.halloween:
        return [Colors.orange.shade700, Colors.deepOrange.shade900];
      case EventTheme.thanksgiving:
        return [Colors.brown.shade400, Colors.orange.shade700];
      case EventTheme.christmas:
        return [Colors.red.shade600, Colors.green.shade700];
    }
  }

  String _getEventEmoji(EventTheme theme) {
    switch (theme) {
      case EventTheme.newYear:
        return '🎉';
      case EventTheme.valentines:
        return '💝';
      case EventTheme.spring:
        return '🌸';
      case EventTheme.summer:
        return '☀️';
      case EventTheme.halloween:
        return '🎃';
      case EventTheme.thanksgiving:
        return '🦃';
      case EventTheme.christmas:
        return '🎄';
    }
  }
}
