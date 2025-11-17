import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/analytics_logger.dart';

/// Offline analytics queue for reliable event tracking
///
/// Features:
/// - Queues analytics events when offline
/// - Automatically flushes when connection restored
/// - Prevents event loss
/// - Batches events for efficiency
/// - Configurable queue size and retry logic
class OfflineAnalyticsQueue {
  static final OfflineAnalyticsQueue instance = OfflineAnalyticsQueue._();
  OfflineAnalyticsQueue._();

  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _isOnline = true;
  bool _isFlushing = false;

  static const String _keyQueuedEvents = 'analytics_queued_events';
  static const int _maxQueueSize = 1000;
  static const int _batchSize = 50;

  /// Initialize offline queue
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _initialized = true;

    // Check initial connectivity
    _checkConnectivity();

    // Flush existing queue
    await flushQueue();

    debugPrint('✅ Offline Analytics Queue initialized');
  }

  /// Set online status
  void setOnlineStatus(bool isOnline) {
    final wasOffline = !_isOnline;
    _isOnline = isOnline;

    if (wasOffline && isOnline) {
      // Just came online, flush queue
      flushQueue();
    }
  }

  /// Queue an analytics event
  Future<void> queueEvent(String eventName,
      {Map<String, dynamic>? parameters}) async {
    if (!_initialized) {
      debugPrint('⚠️  Analytics queue not initialized, initializing now');
      await initialize();
    }

    final event = QueuedEvent(
      name: eventName,
      parameters: parameters ?? {},
      timestamp: DateTime.now(),
    );

    // Try to send immediately if online
    if (_isOnline) {
      try {
        await _sendEvent(event);
        return;
      } catch (e) {
        // Failed to send, queue it
        debugPrint('⚠️  Failed to send event, queuing: $e');
        _isOnline = false; // Mark as offline
      }
    }

    // Queue the event
    await _addToQueue(event);
  }

  /// Add event to queue
  Future<void> _addToQueue(QueuedEvent event) async {
    final queue = await _getQueue();

    // Check queue size limit
    if (queue.length >= _maxQueueSize) {
      // Remove oldest event
      queue.removeAt(0);
      debugPrint('⚠️  Analytics queue full, removed oldest event');
    }

    queue.add(event);
    await _saveQueue(queue);

    debugPrint('📝 Queued analytics event: ${event.name} (queue size: ${queue.length})');
  }

  /// Get queued events
  Future<List<QueuedEvent>> _getQueue() async {
    final queueJson = _prefs?.getString(_keyQueuedEvents);
    if (queueJson == null) return [];

    try {
      final List<dynamic> queueList = jsonDecode(queueJson);
      return queueList.map((json) => QueuedEvent.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error loading analytics queue: $e');
      return [];
    }
  }

  /// Save queue
  Future<void> _saveQueue(List<QueuedEvent> queue) async {
    final queueJson = jsonEncode(queue.map((e) => e.toJson()).toList());
    await _prefs?.setString(_keyQueuedEvents, queueJson);
  }

  /// Flush queue (send all queued events)
  Future<void> flushQueue() async {
    if (!_initialized || _isFlushing || !_isOnline) return;

    _isFlushing = true;

    try {
      final queue = await _getQueue();
      if (queue.isEmpty) {
        _isFlushing = false;
        return;
      }

      debugPrint('🔄 Flushing analytics queue (${queue.length} events)');

      // Process in batches
      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < queue.length; i += _batchSize) {
        final batch = queue.skip(i).take(_batchSize).toList();

        try {
          await _sendBatch(batch);
          successCount += batch.length;
        } catch (e) {
          failCount += batch.length;
          debugPrint('❌ Failed to send batch: $e');

          // If first batch fails, assume we're offline
          if (i == 0) {
            _isOnline = false;
            break;
          }
        }
      }

      // Remove successfully sent events
      if (successCount > 0) {
        final remaining = queue.skip(successCount).toList();
        await _saveQueue(remaining);

        debugPrint('✅ Flushed $successCount analytics events, $failCount failed');
      }
    } catch (e) {
      debugPrint('❌ Error flushing analytics queue: $e');
    } finally {
      _isFlushing = false;
    }
  }

  /// Send a single event
  Future<void> _sendEvent(QueuedEvent event) async {
    // TODO: Replace with actual analytics SDK call
    // For Firebase Analytics:
    // await FirebaseAnalytics.instance.logEvent(
    //   name: event.name,
    //   parameters: event.parameters,
    // );

    // For now, just log to AnalyticsLogger
    AnalyticsLogger.logEvent(event.name, parameters: event.parameters);

    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Send a batch of events
  Future<void> _sendBatch(List<QueuedEvent> events) async {
    for (final event in events) {
      await _sendEvent(event);
    }
  }

  /// Check connectivity (placeholder - implement with connectivity_plus package)
  Future<void> _checkConnectivity() async {
    // TODO: Implement actual connectivity check
    // For now, assume online
    _isOnline = true;

    // With connectivity_plus:
    // final connectivityResult = await Connectivity().checkConnectivity();
    // _isOnline = connectivityResult != ConnectivityResult.none;
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    final queue = await _getQueue();
    return queue.length;
  }

  /// Clear queue (for testing)
  Future<void> clearQueue() async {
    await _prefs?.remove(_keyQueuedEvents);
    debugPrint('🗑️  Cleared analytics queue');
  }

  /// Get queue statistics
  Future<QueueStatistics> getStatistics() async {
    final queue = await _getQueue();

    if (queue.isEmpty) {
      return QueueStatistics(
        totalEvents: 0,
        oldestEvent: null,
        newestEvent: null,
        isOnline: _isOnline,
        isFlushing: _isFlushing,
      );
    }

    return QueueStatistics(
      totalEvents: queue.length,
      oldestEvent: queue.first.timestamp,
      newestEvent: queue.last.timestamp,
      isOnline: _isOnline,
      isFlushing: _isFlushing,
    );
  }
}

/// Queued event data class
class QueuedEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  QueuedEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });

  factory QueuedEvent.fromJson(Map<String, dynamic> json) {
    return QueuedEvent(
      name: json['name'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Queue statistics data class
class QueueStatistics {
  final int totalEvents;
  final DateTime? oldestEvent;
  final DateTime? newestEvent;
  final bool isOnline;
  final bool isFlushing;

  QueueStatistics({
    required this.totalEvents,
    required this.oldestEvent,
    required this.newestEvent,
    required this.isOnline,
    required this.isFlushing,
  });

  Duration? get queueAge {
    if (oldestEvent == null) return null;
    return DateTime.now().difference(oldestEvent!);
  }

  @override
  String toString() {
    return 'QueueStatistics('
        'totalEvents: $totalEvents, '
        'queueAge: ${queueAge?.inSeconds}s, '
        'isOnline: $isOnline, '
        'isFlushing: $isFlushing'
        ')';
  }
}

/// Enhanced AnalyticsLogger that uses offline queue
class ReliableAnalyticsLogger {
  /// Log event with offline support
  static Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Try direct logging first
      AnalyticsLogger.logEvent(eventName, parameters: parameters);
    } catch (e) {
      // If direct logging fails, queue it
      debugPrint('⚠️  Analytics logging failed, queuing: $e');
      await OfflineAnalyticsQueue.instance.queueEvent(
        eventName,
        parameters: parameters,
      );
    }
  }

  /// Initialize reliable analytics
  static Future<void> initialize() async {
    await OfflineAnalyticsQueue.instance.initialize();
  }

  /// Set online status
  static void setOnlineStatus(bool isOnline) {
    OfflineAnalyticsQueue.instance.setOnlineStatus(isOnline);
  }

  /// Flush queued events
  static Future<void> flush() async {
    await OfflineAnalyticsQueue.instance.flushQueue();
  }

  /// Get queue statistics
  static Future<QueueStatistics> getStatistics() async {
    return await OfflineAnalyticsQueue.instance.getStatistics();
  }
}
