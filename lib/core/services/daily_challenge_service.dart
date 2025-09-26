import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';

/// Lightweight representation of a reward attached to a daily challenge or
/// weekly event.
class ChallengeReward {
  const ChallengeReward({
    required this.type,
    required this.amount,
    this.asset,
    this.isExclusive = false,
  });

  final String type;
  final int amount;
  final String? asset;
  final bool isExclusive;

  factory ChallengeReward.fromJson(Map<String, dynamic> json) {
    return ChallengeReward(
      type: json['type'] as String? ?? 'coins',
      amount: json['amount'] as int? ?? 0,
      asset: json['asset'] as String?,
      isExclusive: json['is_exclusive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      if (asset != null) 'asset': asset,
      'is_exclusive': isExclusive,
    };
  }
}

/// Configuration for a one-off level tailored for the current challenge.
class DailyChallengeLevelConfig {
  const DailyChallengeLevelConfig({
    required this.layoutId,
    required this.difficulty,
    required this.modifiers,
    required this.metadata,
  });

  final String layoutId;
  final int difficulty;
  final List<String> modifiers;
  final Map<String, dynamic> metadata;

  factory DailyChallengeLevelConfig.fromJson(Map<String, dynamic> json) {
    return DailyChallengeLevelConfig(
      layoutId: json['layout_id'] as String? ?? 'default_layout',
      difficulty: json['difficulty'] as int? ?? 3,
      modifiers: (json['modifiers'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'layout_id': layoutId,
      'difficulty': difficulty,
      'modifiers': modifiers,
      'metadata': metadata,
    };
  }
}

/// Representation of the daily challenge payload returned from Supabase or
/// generated locally.
class DailyChallengePayload {
  const DailyChallengePayload({
    required this.id,
    required this.title,
    required this.description,
    required this.targetStars,
    required this.currentStars,
    required this.resetAt,
    required this.rewards,
    required this.levelConfig,
    required this.rewardsClaimed,
  });

  final String id;
  final String title;
  final String description;
  final int targetStars;
  final int currentStars;
  final DateTime resetAt;
  final List<ChallengeReward> rewards;
  final DailyChallengeLevelConfig levelConfig;
  final bool rewardsClaimed;

  bool get isCompleted => currentStars >= targetStars;

  Duration get timeUntilReset {
    final duration = resetAt.difference(DateTime.now().toUtc());
    return duration.isNegative ? Duration.zero : duration;
  }

  double get progressRatio {
    if (targetStars <= 0) {
      return 0;
    }
    return (currentStars / targetStars).clamp(0.0, 1.0);
  }

  DailyChallengePayload copyWith({
    String? id,
    String? title,
    String? description,
    int? targetStars,
    int? currentStars,
    DateTime? resetAt,
    List<ChallengeReward>? rewards,
    DailyChallengeLevelConfig? levelConfig,
    bool? rewardsClaimed,
  }) {
    return DailyChallengePayload(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetStars: targetStars ?? this.targetStars,
      currentStars: currentStars ?? this.currentStars,
      resetAt: resetAt ?? this.resetAt,
      rewards: rewards ?? this.rewards,
      levelConfig: levelConfig ?? this.levelConfig,
      rewardsClaimed: rewardsClaimed ?? this.rewardsClaimed,
    );
  }

  factory DailyChallengePayload.fromJson(Map<String, dynamic> json) {
    return DailyChallengePayload(
      id: json['id']?.toString() ?? 'local-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Daily Challenge',
      description: json['description'] as String? ?? '',
      targetStars: json['target_stars'] as int? ?? 10,
      currentStars: json['current_stars'] as int? ?? 0,
      resetAt: DateTime.tryParse(json['reset_at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(hours: 24)),
      rewards: (json['rewards'] as List<dynamic>? ?? const [])
          .map((dynamic item) =>
              ChallengeReward.fromJson(item as Map<String, dynamic>))
          .toList(),
      levelConfig: DailyChallengeLevelConfig.fromJson(
        json['level_config'] as Map<String, dynamic>? ?? const {},
      ),
      rewardsClaimed: json['rewards_claimed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_stars': targetStars,
      'current_stars': currentStars,
      'reset_at': resetAt.toIso8601String(),
      'rewards': rewards.map((reward) => reward.toJson()).toList(),
      'level_config': levelConfig.toJson(),
      'rewards_claimed': rewardsClaimed,
    };
  }
}

/// Representation of a themed live-ops event that repeats weekly.
class WeeklyEvent {
  const WeeklyEvent({
    required this.id,
    required this.name,
    required this.theme,
    required this.startAt,
    required this.endAt,
    required this.rewards,
    required this.leaderboardId,
  });

  final String id;
  final String name;
  final String theme;
  final DateTime startAt;
  final DateTime endAt;
  final List<ChallengeReward> rewards;
  final String leaderboardId;

  factory WeeklyEvent.fromJson(Map<String, dynamic> json) {
    return WeeklyEvent(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Weekly Event',
      theme: json['theme'] as String? ?? 'classic',
      startAt: DateTime.tryParse(json['start_at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      endAt: DateTime.tryParse(json['end_at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(days: 7)),
      rewards: (json['rewards'] as List<dynamic>? ?? const [])
          .map((dynamic item) =>
              ChallengeReward.fromJson(item as Map<String, dynamic>))
          .toList(),
      leaderboardId: json['leaderboard_id'] as String? ?? 'weekly-leaderboard',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'theme': theme,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'rewards': rewards.map((reward) => reward.toJson()).toList(),
      'leaderboard_id': leaderboardId,
    };
  }
}

class WeeklyEventSchedule {
  const WeeklyEventSchedule({
    required this.generatedAt,
    required this.events,
  });

  final DateTime generatedAt;
  final List<WeeklyEvent> events;

  WeeklyEvent? get currentEvent {
    final now = DateTime.now().toUtc();
    return events.firstWhereOrNull(
      (event) => now.isAfter(event.startAt) && now.isBefore(event.endAt),
    );
  }

  WeeklyEvent? get nextEvent {
    final now = DateTime.now().toUtc();
    return events
        .where((event) => event.startAt.isAfter(now))
        .sorted((a, b) => a.startAt.compareTo(b.startAt))
        .firstOrNull;
  }
}

/// Service responsible for loading and updating daily challenges as well as
/// orchestrating weekly live-ops cadence.
class DailyChallengeService {
  DailyChallengeService({
    Dio? httpClient,
    this.supabaseRestEndpoint,
    this.supabaseAnonKey,
    this.remoteConfigLoader,
    this.cacheDuration = const Duration(minutes: 5),
    this.weeklyEventCacheDuration = const Duration(hours: 6),
    this.remoteConfigCacheDuration = const Duration(minutes: 2),
  }) : _httpClient = httpClient ?? Dio();

  final Dio _httpClient;
  final String? supabaseRestEndpoint;
  final String? supabaseAnonKey;
  final Future<Map<String, dynamic>> Function()? remoteConfigLoader;
  final Duration cacheDuration;
  final Duration weeklyEventCacheDuration;
  final Duration remoteConfigCacheDuration;

  DailyChallengePayload? _cachedChallenge;
  DateTime? _lastChallengeFetch;

  WeeklyEventSchedule? _cachedSchedule;
  DateTime? _lastScheduleFetch;

  Map<String, dynamic>? _cachedRemoteConfig;
  DateTime? _lastRemoteConfigFetch;

  bool _isDisposed = false;

  final StreamController<DailyChallengePayload> _challengeController =
      StreamController<DailyChallengePayload>.broadcast();

  Stream<DailyChallengePayload> get challengeStream =>
      _challengeController.stream;

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('DailyChallengeService has been disposed');
    }
  }

  void _emitChallenge(DailyChallengePayload payload) {
    if (!_challengeController.isClosed) {
      _challengeController.add(payload);
    }
  }

  Future<DailyChallengePayload> loadDailyChallenge({
    bool forceRefresh = false,
  }) async {
    _ensureNotDisposed();
    final now = DateTime.now();
    final cacheIsValid =
        !forceRefresh &&
        _cachedChallenge != null &&
        _lastChallengeFetch != null &&
        now.difference(_lastChallengeFetch!) < cacheDuration;

    if (cacheIsValid) {
      return _cachedChallenge!;
    }

    DailyChallengePayload? payload;
    try {
      payload = await _fetchDailyChallengeFromSupabase();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch daily challenge from Supabase',
        error: error,
        stackTrace: stackTrace,
        name: 'DailyChallengeService',
      );
    }

    if (payload == null) {
      payload = await _loadRemoteConfigOverride();
    }

    payload ??= _generateLocalChallenge();

    _cachedChallenge = payload;
    _lastChallengeFetch = now;
    _emitChallenge(payload);
    return payload;
  }

  Future<WeeklyEventSchedule> loadWeeklyEvents({
    bool forceRefresh = false,
  }) async {
    _ensureNotDisposed();
    final now = DateTime.now();
    final cacheIsValid =
        !forceRefresh &&
        _cachedSchedule != null &&
        _lastScheduleFetch != null &&
        now.difference(_lastScheduleFetch!) < weeklyEventCacheDuration;

    if (cacheIsValid) {
      return _cachedSchedule!;
    }

    WeeklyEventSchedule? schedule;
    try {
      schedule = await _fetchWeeklyEventsFromSupabase();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch weekly events from Supabase',
        error: error,
        stackTrace: stackTrace,
        name: 'DailyChallengeService',
      );
    }

    schedule ??= await _loadRemoteConfigWeeklyEvents();
    schedule ??= _generateWeeklySchedule();

    _cachedSchedule = schedule;
    _lastScheduleFetch = now;
    return schedule;
  }

  Stream<Duration> countdownStream(DateTime resetAt) {
    Duration computeRemaining() {
      final diff = resetAt.toUtc().difference(DateTime.now().toUtc());
      return diff.isNegative ? Duration.zero : diff;
    }

    return Stream<Duration>.periodic(
      const Duration(seconds: 1),
      (_) => computeRemaining(),
    ).startWith(computeRemaining());
  }

  Future<DailyChallengePayload> recordProgress({required int starsEarned}) async {
    _ensureNotDisposed();
    final challenge = await loadDailyChallenge();
    final updated = challenge.copyWith(
      currentStars: min(challenge.currentStars + starsEarned, challenge.targetStars),
    );
    _cachedChallenge = updated;
    _emitChallenge(updated);
    return updated;
  }

  Future<DailyChallengePayload> claimRewards() async {
    _ensureNotDisposed();
    final challenge = await loadDailyChallenge();
    if (!challenge.isCompleted) {
      return challenge;
    }

    if (!challenge.rewardsClaimed) {
      final updated = challenge.copyWith(rewardsClaimed: true);
      _cachedChallenge = updated;
      _emitChallenge(updated);
      return updated;
    }
    return challenge;
  }

  void clearCache() {
    _cachedChallenge = null;
    _lastChallengeFetch = null;
    _cachedSchedule = null;
    _lastScheduleFetch = null;
    _cachedRemoteConfig = null;
    _lastRemoteConfigFetch = null;
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _challengeController.close();
    await _httpClient.close(force: true);
  }

  Future<DailyChallengePayload?> _fetchDailyChallengeFromSupabase() async {
    if (supabaseRestEndpoint == null || supabaseRestEndpoint!.isEmpty) {
      return null;
    }

    final response = await _httpClient.get<List<dynamic>>(
      supabaseRestEndpoint!,
      options: Options(
        headers: {
          if (supabaseAnonKey != null) 'apikey': supabaseAnonKey,
          if (supabaseAnonKey != null) 'Authorization': 'Bearer $supabaseAnonKey',
          'Accept': 'application/json',
        },
      ),
    );

    final data = response.data;
    if (data == null || data.isEmpty) {
      return null;
    }

    final payload = data.firstWhereOrNull((item) {
      if (item is! Map<String, dynamic>) {
        return false;
      }
      final resetAt = DateTime.tryParse(item['reset_at']?.toString() ?? '');
      if (resetAt == null) {
        return false;
      }
      return resetAt.toUtc().isAfter(DateTime.now().toUtc());
    });

    if (payload is Map<String, dynamic>) {
      return DailyChallengePayload.fromJson(payload);
    }
    return null;
  }

  Future<WeeklyEventSchedule?> _fetchWeeklyEventsFromSupabase() async {
    if (supabaseRestEndpoint == null || supabaseRestEndpoint!.isEmpty) {
      return null;
    }

    final uri = Uri.parse(supabaseRestEndpoint!);
    final path = uri.replace(path: '${uri.path}/weekly_events').toString();
    final response = await _httpClient.get<List<dynamic>>(
      path,
      options: Options(
        headers: {
          if (supabaseAnonKey != null) 'apikey': supabaseAnonKey,
          if (supabaseAnonKey != null) 'Authorization': 'Bearer $supabaseAnonKey',
          'Accept': 'application/json',
        },
      ),
    );

    final data = response.data;
    if (data == null || data.isEmpty) {
      return null;
    }

    final events = data
        .whereType<Map<String, dynamic>>()
        .map(WeeklyEvent.fromJson)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    if (events.isEmpty) {
      return null;
    }

    return WeeklyEventSchedule(
      generatedAt: DateTime.now().toUtc(),
      events: events,
    );
  }

  Future<DailyChallengePayload?> _loadRemoteConfigOverride() async {
    if (remoteConfigLoader == null) {
      return null;
    }

    final remoteData = await _loadRemoteConfigData();
    if (remoteData.isEmpty) {
      return null;
    }
    final challengeJson = remoteData['daily_challenge'];
    if (challengeJson is Map<String, dynamic>) {
      return DailyChallengePayload.fromJson(challengeJson);
    }
    if (challengeJson is List && challengeJson.isNotEmpty) {
      final first = challengeJson.first;
      if (first is Map<String, dynamic>) {
        return DailyChallengePayload.fromJson(first);
      }
    }
    return DailyChallengePayload.fromJson(remoteData);
  }

  Future<WeeklyEventSchedule?> _loadRemoteConfigWeeklyEvents() async {
    if (remoteConfigLoader == null) {
      return null;
    }
    final remoteData = await _loadRemoteConfigData();
    final eventsJson = remoteData['weekly_events'];
    if (eventsJson is! List<dynamic> || eventsJson.isEmpty) {
      return null;
    }
    final events = eventsJson
        .whereType<Map<String, dynamic>>()
        .map(WeeklyEvent.fromJson)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    if (events.isEmpty) {
      return null;
    }

    return WeeklyEventSchedule(
      generatedAt: DateTime.now().toUtc(),
      events: events,
    );
  }

  Future<Map<String, dynamic>> _loadRemoteConfigData() async {
    if (remoteConfigLoader == null) {
      return const <String, dynamic>{};
    }

    final now = DateTime.now();
    final cacheIsValid =
        _cachedRemoteConfig != null &&
        _lastRemoteConfigFetch != null &&
        now.difference(_lastRemoteConfigFetch!) < remoteConfigCacheDuration;
    if (cacheIsValid) {
      return _cachedRemoteConfig!;
    }

    try {
      final data = await remoteConfigLoader!.call();
      _cachedRemoteConfig = data.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(data);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load remote config override',
        error: error,
        stackTrace: stackTrace,
        name: 'DailyChallengeService',
      );
      _cachedRemoteConfig = <String, dynamic>{};
    }
    _lastRemoteConfigFetch = now;
    return _cachedRemoteConfig!;
  }

  DailyChallengePayload _generateLocalChallenge() {
    final now = DateTime.now().toUtc();
    final seed = now.day + now.month * 31 + now.year * 372;
    final random = Random(seed);
    final targetStars = 9 + random.nextInt(6); // 9 - 14 stars
    final earned = min(random.nextInt(targetStars), targetStars - 1);

    final modifiers = <String>[
      if (random.nextBool()) 'limited_moves',
      if (random.nextBool()) 'combo_multiplier',
      if (random.nextBool()) 'color_lock',
    ];

    final rewards = <ChallengeReward>[
      ChallengeReward(
        type: 'coins',
        amount: 100 + random.nextInt(200),
      ),
      ChallengeReward(
        type: 'exclusive_skin',
        amount: 1,
        asset: 'assets/images/daily_reward_${now.weekday}.png',
        isExclusive: true,
      ),
    ];

    return DailyChallengePayload(
      id: 'auto-$seed',
      title: 'Daily Blitz: ${_weekdayLabel(now.weekday)}',
      description:
          'Score $targetStars stars before the timer resets to earn exclusive loot.',
      targetStars: targetStars,
      currentStars: earned,
      resetAt: now.add(const Duration(hours: 24)),
      rewards: rewards,
      levelConfig: DailyChallengeLevelConfig(
        layoutId: 'layout_${now.weekday}',
        difficulty: 3 + random.nextInt(3),
        modifiers: modifiers,
        metadata: {
          'item_quota': 12 + random.nextInt(5),
          'time_limit_seconds': 600 - random.nextInt(120),
        },
      ),
      rewardsClaimed: false,
    );
  }

  WeeklyEventSchedule _generateWeeklySchedule() {
    final now = DateTime.now().toUtc();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final events = List<WeeklyEvent>.generate(4, (index) {
      final start = startOfWeek.add(Duration(days: 7 * index));
      final end = start.add(const Duration(days: 7));
      final theme = _weeklyThemes[index % _weeklyThemes.length];
      return WeeklyEvent(
        id: 'auto-week-${index + 1}',
        name: 'Weekly $theme Rush',
        theme: theme,
        startAt: start,
        endAt: end,
        rewards: [
          const ChallengeReward(type: 'coins', amount: 500),
          ChallengeReward(
            type: 'themed_loot',
            amount: 1,
            asset: 'assets/images/weekly_${theme.toLowerCase()}.png',
            isExclusive: true,
          ),
        ],
        leaderboardId: 'leaderboard_${theme.toLowerCase()}_${start.year}${start.month}${start.day}',
      );
    });

    return WeeklyEventSchedule(
      generatedAt: now,
      events: events,
    );
  }

  static const List<String> _weeklyThemes = <String>[
    'Aurora',
    'Mystic',
    'Retro',
    'Zen',
    'Festival',
  ];

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Momentum';
      case DateTime.tuesday:
        return 'Triumph';
      case DateTime.wednesday:
        return 'Wonders';
      case DateTime.thursday:
        return 'Thrill';
      case DateTime.friday:
        return 'Fiesta';
      case DateTime.saturday:
        return 'Showdown';
      case DateTime.sunday:
      default:
        return 'Serenity';
    }
  }
}

extension _StartWithExtension<T> on Stream<T> {
  Stream<T> startWith(T initialValue) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;

    controller = StreamController<T>(
      onListen: () {
        controller.add(initialValue);
        subscription = listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () async {
        await subscription?.cancel();
      },
      sync: true,
    );

    return controller.stream;
  }
}
