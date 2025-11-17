import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/analytics_logger.dart';

/// Seasonal events service for limited-time challenges and rewards
///
/// Features:
/// - Holiday events (Christmas, Halloween, New Year, etc.)
/// - Special challenges with bonus rewards
/// - Limited-time offers
/// - Event progress tracking
/// - Event-exclusive content
///
/// Events automatically activate based on date ranges
class SeasonalEventsService {
  static final SeasonalEventsService instance = SeasonalEventsService._();
  SeasonalEventsService._();

  SharedPreferences? _prefs;

  static const String _keyEventProgress = 'events_progress'; // JSON
  static const String _keyEventCompletions = 'events_completions'; // JSON array
  static const String _keyLastChecked = 'events_last_checked';

  /// Initialize seasonal events service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkForNewEvents();

    AnalyticsLogger.logEvent('events_service_initialized', parameters: {
      'active_events': getActiveEvents().length,
    });
  }

  /// Get all predefined events
  List<SeasonalEvent> getAllEvents() {
    final now = DateTime.now();
    final year = now.year;

    return [
      // New Year Event
      SeasonalEvent(
        id: 'new_year_$year',
        name: 'New Year Celebration',
        description: 'Ring in the new year with special challenges!',
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 1, 7),
        rewardCoins: 500,
        rewardType: 'coins',
        challenges: [
          EventChallenge(id: 'ny_1', description: 'Complete 10 levels', goal: 10),
          EventChallenge(id: 'ny_2', description: 'Earn 20 stars', goal: 20),
          EventChallenge(id: 'ny_3', description: 'Achieve a 10x combo', goal: 10),
        ],
        theme: EventTheme.newYear,
      ),

      // Valentine's Day Event
      SeasonalEvent(
        id: 'valentines_$year',
        name: 'Love is in the Air',
        description: 'Spread the love with heart-themed levels!',
        startDate: DateTime(year, 2, 10),
        endDate: DateTime(year, 2, 17),
        rewardCoins: 300,
        rewardType: 'coins',
        challenges: [
          EventChallenge(id: 'val_1', description: 'Share 3 scores', goal: 3),
          EventChallenge(id: 'val_2', description: 'Complete 5 levels with 3 stars', goal: 5),
        ],
        theme: EventTheme.valentines,
      ),

      // Spring Event
      SeasonalEvent(
        id: 'spring_$year',
        name: 'Spring Bloom',
        description: 'Celebrate spring with blooming challenges!',
        startDate: DateTime(year, 3, 20),
        endDate: DateTime(year, 4, 5),
        rewardCoins: 400,
        rewardType: 'coins',
        challenges: [
          EventChallenge(id: 'spr_1', description: 'Complete 15 levels', goal: 15),
          EventChallenge(id: 'spr_2', description: 'Collect 1000 coins', goal: 1000),
        ],
        theme: EventTheme.spring,
      ),

      // Summer Event
      SeasonalEvent(
        id: 'summer_$year',
        name: 'Summer Fun',
        description: 'Hot summer challenges with cool rewards!',
        startDate: DateTime(year, 6, 21),
        endDate: DateTime(year, 7, 10),
        rewardCoins: 500,
        rewardType: 'coins',
        challenges: [
          EventChallenge(id: 'sum_1', description: 'Play 7 days in a row', goal: 7),
          EventChallenge(id: 'sum_2', description: 'Complete 20 levels', goal: 20),
        ],
        theme: EventTheme.summer,
      ),

      // Halloween Event
      SeasonalEvent(
        id: 'halloween_$year',
        name: 'Spooky Sorting',
        description: 'Trick or treat! Complete spooky challenges!',
        startDate: DateTime(year, 10, 25),
        endDate: DateTime(year, 11, 2),
        rewardCoins: 666,
        rewardType: 'coins',
        challenges: [
          EventChallenge(id: 'hal_1', description: 'Complete 13 levels', goal: 13),
          EventChallenge(id: 'hal_2', description: 'Achieve a 13x combo', goal: 13),
          EventChallenge(id: 'hal_3', description: 'Earn 31 stars', goal: 31),
        ],
        theme: EventTheme.halloween,
      ),

      // Thanksgiving Event
      SeasonalEvent(
        id: 'thanksgiving_$year',
        name: 'Harvest Festival',
        description: 'Give thanks with rewarding challenges!',
        startDate: DateTime(year, 11, 20),
        endDate: DateTime(year, 11, 27),
        rewardCoins: 400,
        rewardType: 'coins',
        challenges: [
          EventChallenge(id: 'tha_1', description: 'Complete 10 perfect levels', goal: 10),
          EventChallenge(id: 'tha_2', description: 'Share 5 scores', goal: 5),
        ],
        theme: EventTheme.thanksgiving,
      ),

      // Christmas Event
      SeasonalEvent(
        id: 'christmas_$year',
        name: 'Winter Wonderland',
        description: 'Celebrate the holidays with festive challenges!',
        startDate: DateTime(year, 12, 18),
        endDate: DateTime(year, 12, 27),
        rewardCoins: 1000,
        rewardType: 'coins',
        challenges: [
          EventChallenge(id: 'xmas_1', description: 'Complete 25 levels', goal: 25),
          EventChallenge(id: 'xmas_2', description: 'Earn 50 stars', goal: 50),
          EventChallenge(id: 'xmas_3', description: 'Use 10 power-ups', goal: 10),
          EventChallenge(id: 'xmas_4', description: 'Claim daily rewards 7 days', goal: 7),
        ],
        theme: EventTheme.christmas,
      ),
    ];
  }

  /// Get currently active events
  List<SeasonalEvent> getActiveEvents() {
    final now = DateTime.now();
    return getAllEvents().where((event) {
      return now.isAfter(event.startDate) && now.isBefore(event.endDate);
    }).toList();
  }

  /// Get upcoming events (next 30 days)
  List<SeasonalEvent> getUpcomingEvents() {
    final now = DateTime.now();
    final future = now.add(const Duration(days: 30));

    return getAllEvents().where((event) {
      return event.startDate.isAfter(now) && event.startDate.isBefore(future);
    }).toList();
  }

  /// Check if event is active
  bool isEventActive(String eventId) {
    return getActiveEvents().any((e) => e.id == eventId);
  }

  /// Get event progress
  EventProgress getEventProgress(String eventId) {
    final progressJson = _prefs?.getString(_keyEventProgress);
    if (progressJson == null) return EventProgress(eventId: eventId, progress: {});

    final allProgress = jsonDecode(progressJson) as Map<String, dynamic>;
    final eventData = allProgress[eventId] as Map<String, dynamic>?;

    if (eventData == null) return EventProgress(eventId: eventId, progress: {});

    return EventProgress(
      eventId: eventId,
      progress: Map<String, int>.from(eventData),
    );
  }

  /// Update event challenge progress
  Future<void> updateChallengeProgress(
    String eventId,
    String challengeId,
    int progress,
  ) async {
    final currentProgress = getEventProgress(eventId);
    currentProgress.progress[challengeId] = progress;

    final progressJson = _prefs?.getString(_keyEventProgress) ?? '{}';
    final allProgress = jsonDecode(progressJson) as Map<String, dynamic>;
    allProgress[eventId] = currentProgress.progress;

    await _prefs?.setString(_keyEventProgress, jsonEncode(allProgress));

    // Check if event completed
    final event = getAllEvents().firstWhere((e) => e.id == eventId);
    if (_isEventComplete(event, currentProgress)) {
      await _completeEvent(eventId);
    }

    AnalyticsLogger.logEvent('event_challenge_progress', parameters: {
      'event_id': eventId,
      'challenge_id': challengeId,
      'progress': progress,
    });
  }

  /// Check if event is complete
  bool _isEventComplete(SeasonalEvent event, EventProgress progress) {
    for (final challenge in event.challenges) {
      final currentProgress = progress.progress[challenge.id] ?? 0;
      if (currentProgress < challenge.goal) return false;
    }
    return true;
  }

  /// Complete event and award rewards
  Future<void> _completeEvent(String eventId) async {
    // Record completion
    final completionsJson = _prefs?.getString(_keyEventCompletions) ?? '[]';
    final completions = jsonDecode(completionsJson) as List;
    completions.add({
      'event_id': eventId,
      'completed_at': DateTime.now().toIso8601String(),
    });
    await _prefs?.setString(_keyEventCompletions, jsonEncode(completions));

    AnalyticsLogger.logEvent('event_completed', parameters: {
      'event_id': eventId,
    });

    // TODO: Award rewards (coins, power-ups, etc.)
    // This would integrate with CurrencyService/PowerUpService
  }

  /// Check if event has been completed
  bool hasCompletedEvent(String eventId) {
    final completionsJson = _prefs?.getString(_keyEventCompletions);
    if (completionsJson == null) return false;

    final completions = jsonDecode(completionsJson) as List;
    return completions.any((c) => c['event_id'] == eventId);
  }

  /// Get completed events
  List<String> getCompletedEvents() {
    final completionsJson = _prefs?.getString(_keyEventCompletions);
    if (completionsJson == null) return [];

    final completions = jsonDecode(completionsJson) as List;
    return completions.map((c) => c['event_id'] as String).toList();
  }

  /// Check for new events (call on app start)
  Future<void> _checkForNewEvents() async {
    final lastChecked = _prefs?.getString(_keyLastChecked);
    final now = DateTime.now();

    // Check at most once per day
    if (lastChecked != null) {
      final lastDate = DateTime.parse(lastChecked);
      if (now.difference(lastDate).inHours < 24) return;
    }

    await _prefs?.setString(_keyLastChecked, now.toIso8601String());

    final activeEvents = getActiveEvents();
    if (activeEvents.isNotEmpty) {
      AnalyticsLogger.logEvent('events_active', parameters: {
        'event_ids': activeEvents.map((e) => e.id).join(','),
        'count': activeEvents.length,
      });
    }
  }

  /// Get event summary for display
  EventSummary getEventSummary() {
    return EventSummary(
      activeEvents: getActiveEvents().length,
      upcomingEvents: getUpcomingEvents().length,
      completedEvents: getCompletedEvents().length,
    );
  }
}

/// Seasonal event data class
class SeasonalEvent {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int rewardCoins;
  final String rewardType;
  final List<EventChallenge> challenges;
  final EventTheme theme;

  SeasonalEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.rewardCoins,
    required this.rewardType,
    required this.challenges,
    required this.theme,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  Duration get timeRemaining => endDate.difference(DateTime.now());
}

/// Event challenge data class
class EventChallenge {
  final String id;
  final String description;
  final int goal;

  EventChallenge({
    required this.id,
    required this.description,
    required this.goal,
  });
}

/// Event progress data class
class EventProgress {
  final String eventId;
  final Map<String, int> progress; // challengeId -> progress

  EventProgress({
    required this.eventId,
    required this.progress,
  });
}

/// Event theme enum
enum EventTheme {
  newYear,
  valentines,
  spring,
  summer,
  halloween,
  thanksgiving,
  christmas,
}

/// Event summary data class
class EventSummary {
  final int activeEvents;
  final int upcomingEvents;
  final int completedEvents;

  EventSummary({
    required this.activeEvents,
    required this.upcomingEvents,
    required this.completedEvents,
  });
}
