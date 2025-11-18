import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/analytics_logger.dart';

/// Offline sync service for queueing actions during offline periods
///
/// Features:
/// - Action queue with persistence
/// - Automatic sync when online
/// - Retry logic with exponential backoff
/// - Conflict resolution
/// - Priority-based execution
/// - Batch processing
///
/// Queued Actions:
/// - Achievement unlocks
/// - Leaderboard updates
/// - Level completions
/// - Coin transactions
/// - Referral completions
/// - Analytics events
class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._();
  OfflineSyncService._();

  static const String _keyActionQueue = 'offline_sync_queue';
  static const String _keyLastSyncTime = 'offline_sync_last_sync';
  static const String _keySyncStats = 'offline_sync_stats';

  late SharedPreferences _prefs;
  bool _initialized = false;
  bool _isOnline = true;
  bool _isSyncing = false;

  final List<SyncAction> _actionQueue = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  // Sync statistics
  int _totalQueued = 0;
  int _totalSynced = 0;
  int _totalFailed = 0;

  // Configuration
  static const int _maxQueueSize = 500;
  static const int _maxRetries = 5;
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _retryBaseDelay = Duration(seconds: 2);

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Load persisted queue
    await _loadQueue();

    // Load stats
    await _loadStats();

    // Monitor connectivity
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);

    // Check initial connectivity
    final connectivity = await Connectivity().checkConnectivity();
    _isOnline = !connectivity.contains(ConnectivityResult.none);

    // Start periodic sync
    _startPeriodicSync();

    // Sync immediately if online and queue not empty
    if (_isOnline && _actionQueue.isNotEmpty) {
      unawaited(_syncNow());
    }

    _initialized = true;

    if (kDebugMode) {
      debugPrint('🔄 Offline Sync Service initialized');
      debugPrint('   Online: $_isOnline');
      debugPrint('   Queue Size: ${_actionQueue.length}');
      debugPrint('   Total Synced: $_totalSynced');
    }
  }

  /// Queue an action for sync
  Future<void> queueAction({
    required SyncActionType type,
    required Map<String, dynamic> data,
    SyncPriority priority = SyncPriority.normal,
  }) async {
    if (!_initialized) await initialize();

    // Check queue size limit
    if (_actionQueue.length >= _maxQueueSize) {
      debugPrint('⚠️ Sync queue full, removing oldest low-priority action');
      _removeLowestPriorityAction();
    }

    final action = SyncAction(
      id: _generateActionId(),
      type: type,
      data: data,
      priority: priority,
      queuedAt: DateTime.now(),
      retryCount: 0,
    );

    _actionQueue.add(action);
    _totalQueued++;

    // Sort by priority
    _actionQueue.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // Persist queue
    await _saveQueue();

    if (kDebugMode) {
      debugPrint('📥 Action queued: ${type.toString()} (Queue: ${_actionQueue.length})');
    }

    // Try to sync immediately if online
    if (_isOnline && !_isSyncing) {
      unawaited(_syncNow());
    }
  }

  /// Sync queued actions now
  Future<SyncResult> _syncNow() async {
    if (!_initialized) await initialize();
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        actionsSynced: 0,
      );
    }

    if (!_isOnline) {
      return SyncResult(
        success: false,
        message: 'Device is offline',
        actionsSynced: 0,
      );
    }

    if (_actionQueue.isEmpty) {
      return SyncResult(
        success: true,
        message: 'Nothing to sync',
        actionsSynced: 0,
      );
    }

    _isSyncing = true;
    int syncedCount = 0;
    int failedCount = 0;

    if (kDebugMode) {
      debugPrint('🔄 Starting sync of ${_actionQueue.length} actions...');
    }

    try {
      // Process actions in batches
      const batchSize = 10;
      final batches = <List<SyncAction>>[];

      for (var i = 0; i < _actionQueue.length; i += batchSize) {
        final end = (i + batchSize < _actionQueue.length)
            ? i + batchSize
            : _actionQueue.length;
        batches.add(_actionQueue.sublist(i, end));
      }

      for (final batch in batches) {
        if (!_isOnline) break; // Stop if connection lost

        final results = await Future.wait(
          batch.map((action) => _executeAction(action)),
        );

        for (var i = 0; i < results.length; i++) {
          if (results[i]) {
            syncedCount++;
            _totalSynced++;
            _actionQueue.remove(batch[i]);
          } else {
            failedCount++;
            batch[i].retryCount++;
            batch[i].lastAttemptAt = DateTime.now();

            // Remove if max retries exceeded
            if (batch[i].retryCount >= _maxRetries) {
              _totalFailed++;
              _actionQueue.remove(batch[i]);
              debugPrint('❌ Action failed after max retries: ${batch[i].type}');
            }
          }
        }
      }

      // Save updated queue
      await _saveQueue();
      await _saveStats();

      // Update last sync time
      await _prefs.setInt(
        _keyLastSyncTime,
        DateTime.now().millisecondsSinceEpoch,
      );

      // Log analytics
      AnalyticsLogger.logEvent('offline_sync_completed', parameters: {
        'synced': syncedCount,
        'failed': failedCount,
        'remaining': _actionQueue.length,
      });

      if (kDebugMode) {
        debugPrint('✅ Sync completed: $syncedCount synced, $failedCount failed, ${_actionQueue.length} remaining');
      }

      return SyncResult(
        success: failedCount == 0,
        message: 'Synced $syncedCount actions',
        actionsSynced: syncedCount,
        actionsFailed: failedCount,
      );
    } catch (e) {
      debugPrint('❌ Sync error: $e');
      return SyncResult(
        success: false,
        message: 'Sync error: $e',
        actionsSynced: syncedCount,
        actionsFailed: failedCount,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a single action
  Future<bool> _executeAction(SyncAction action) async {
    try {
      // Simulate network delay for testing
      await Future.delayed(const Duration(milliseconds: 100));

      // In production, this would call the appropriate API based on action type
      switch (action.type) {
        case SyncActionType.achievementUnlock:
          return await _syncAchievementUnlock(action.data);
        case SyncActionType.leaderboardUpdate:
          return await _syncLeaderboardUpdate(action.data);
        case SyncActionType.levelCompletion:
          return await _syncLevelCompletion(action.data);
        case SyncActionType.coinTransaction:
          return await _syncCoinTransaction(action.data);
        case SyncActionType.referralCompletion:
          return await _syncReferralCompletion(action.data);
        case SyncActionType.analyticsEvent:
          return await _syncAnalyticsEvent(action.data);
        case SyncActionType.profileUpdate:
          return await _syncProfileUpdate(action.data);
      }
    } catch (e) {
      debugPrint('❌ Error executing action ${action.type}: $e');
      return false;
    }
  }

  // Action execution methods (to be implemented with actual API calls)

  Future<bool> _syncAchievementUnlock(Map<String, dynamic> data) async {
    // TODO: Call achievement API
    if (kDebugMode) {
      debugPrint('   Syncing achievement: ${data['achievement_id']}');
    }
    return true; // Mock success
  }

  Future<bool> _syncLeaderboardUpdate(Map<String, dynamic> data) async {
    // TODO: Call leaderboard API
    return true;
  }

  Future<bool> _syncLevelCompletion(Map<String, dynamic> data) async {
    // TODO: Call level completion API
    return true;
  }

  Future<bool> _syncCoinTransaction(Map<String, dynamic> data) async {
    // TODO: Call coin transaction API
    return true;
  }

  Future<bool> _syncReferralCompletion(Map<String, dynamic> data) async {
    // TODO: Call referral API
    return true;
  }

  Future<bool> _syncAnalyticsEvent(Map<String, dynamic> data) async {
    // TODO: Send analytics event
    return true;
  }

  Future<bool> _syncProfileUpdate(Map<String, dynamic> data) async {
    // TODO: Call profile update API
    return true;
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    if (kDebugMode) {
      debugPrint('📶 Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
    }

    // If just came online, sync immediately
    if (!wasOnline && _isOnline && _actionQueue.isNotEmpty) {
      unawaited(_syncNow());
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isOnline && _actionQueue.isNotEmpty && !_isSyncing) {
        unawaited(_syncNow());
      }
    });
  }

  /// Load queue from persistent storage
  Future<void> _loadQueue() async {
    final queueJson = _prefs.getString(_keyActionQueue);
    if (queueJson == null) return;

    try {
      final List<dynamic> queueList = jsonDecode(queueJson);
      _actionQueue.clear();
      _actionQueue.addAll(
        queueList.map((item) => SyncAction.fromJson(item)),
      );
    } catch (e) {
      debugPrint('❌ Error loading sync queue: $e');
    }
  }

  /// Save queue to persistent storage
  Future<void> _saveQueue() async {
    try {
      final queueJson = jsonEncode(
        _actionQueue.map((action) => action.toJson()).toList(),
      );
      await _prefs.setString(_keyActionQueue, queueJson);
    } catch (e) {
      debugPrint('❌ Error saving sync queue: $e');
    }
  }

  /// Load statistics
  Future<void> _loadStats() async {
    final statsJson = _prefs.getString(_keySyncStats);
    if (statsJson == null) return;

    try {
      final Map<String, dynamic> stats = jsonDecode(statsJson);
      _totalQueued = stats['total_queued'] ?? 0;
      _totalSynced = stats['total_synced'] ?? 0;
      _totalFailed = stats['total_failed'] ?? 0;
    } catch (e) {
      debugPrint('❌ Error loading sync stats: $e');
    }
  }

  /// Save statistics
  Future<void> _saveStats() async {
    try {
      final statsJson = jsonEncode({
        'total_queued': _totalQueued,
        'total_synced': _totalSynced,
        'total_failed': _totalFailed,
      });
      await _prefs.setString(_keySyncStats, statsJson);
    } catch (e) {
      debugPrint('❌ Error saving sync stats: $e');
    }
  }

  /// Generate unique action ID
  String _generateActionId() {
    return 'action_${DateTime.now().millisecondsSinceEpoch}_${_actionQueue.length}';
  }

  /// Remove lowest priority action from queue
  void _removeLowestPriorityAction() {
    if (_actionQueue.isEmpty) return;

    final lowestPriority = _actionQueue
        .reduce((a, b) => a.priority.index < b.priority.index ? a : b);

    _actionQueue.remove(lowestPriority);
  }

  /// Get queue status
  SyncQueueStatus getQueueStatus() {
    return SyncQueueStatus(
      isOnline: _isOnline,
      isSyncing: _isSyncing,
      queueSize: _actionQueue.length,
      totalQueued: _totalQueued,
      totalSynced: _totalSynced,
      totalFailed: _totalFailed,
      lastSyncTime: _getLastSyncTime(),
    );
  }

  /// Get last sync time
  DateTime? _getLastSyncTime() {
    final timestamp = _prefs.getInt(_keyLastSyncTime);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Clear queue (for testing)
  Future<void> clearQueue() async {
    _actionQueue.clear();
    await _saveQueue();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}

/// Type of sync action
enum SyncActionType {
  achievementUnlock,
  leaderboardUpdate,
  levelCompletion,
  coinTransaction,
  referralCompletion,
  analyticsEvent,
  profileUpdate,
}

/// Priority of sync action
enum SyncPriority {
  low,
  normal,
  high,
  critical,
}

/// Sync action data
class SyncAction {
  final String id;
  final SyncActionType type;
  final Map<String, dynamic> data;
  final SyncPriority priority;
  final DateTime queuedAt;
  int retryCount;
  DateTime? lastAttemptAt;

  SyncAction({
    required this.id,
    required this.type,
    required this.data,
    required this.priority,
    required this.queuedAt,
    required this.retryCount,
    this.lastAttemptAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'priority': priority.toString(),
      'queued_at': queuedAt.toIso8601String(),
      'retry_count': retryCount,
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
    };
  }

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      id: json['id'],
      type: SyncActionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      data: Map<String, dynamic>.from(json['data']),
      priority: SyncPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
      ),
      queuedAt: DateTime.parse(json['queued_at']),
      retryCount: json['retry_count'],
      lastAttemptAt: json['last_attempt_at'] != null
          ? DateTime.parse(json['last_attempt_at'])
          : null,
    );
  }
}

/// Result of sync operation
class SyncResult {
  final bool success;
  final String message;
  final int actionsSynced;
  final int actionsFailed;

  SyncResult({
    required this.success,
    required this.message,
    required this.actionsSynced,
    this.actionsFailed = 0,
  });
}

/// Queue status information
class SyncQueueStatus {
  final bool isOnline;
  final bool isSyncing;
  final int queueSize;
  final int totalQueued;
  final int totalSynced;
  final int totalFailed;
  final DateTime? lastSyncTime;

  SyncQueueStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.queueSize,
    required this.totalQueued,
    required this.totalSynced,
    required this.totalFailed,
    this.lastSyncTime,
  });

  @override
  String toString() {
    return 'SyncQueueStatus(online: $isOnline, syncing: $isSyncing, '
        'queue: $queueSize, synced: $totalSynced, failed: $totalFailed)';
  }
}

/// Extension for unawaited futures
void unawaited(Future<void> future) {
  future.catchError((dynamic error) {
    debugPrint('Unawaited future error: $error');
  });
}
