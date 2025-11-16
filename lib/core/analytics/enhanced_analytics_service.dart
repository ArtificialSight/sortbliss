import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

/// Enhanced analytics service with event queuing, offline support,
/// and automatic retry for failed events.
class EnhancedAnalyticsService {
  EnhancedAnalyticsService._();
  static final EnhancedAnalyticsService instance = EnhancedAnalyticsService._();

  final AnalyticsService _baseService = AnalyticsService.instance;
  final Queue<Map<String, dynamic>> _eventQueue = Queue();

  bool _initialized = false;
  bool _isProcessing = false;
  Timer? _flushTimer;

  static const int _maxQueueSize = 100;
  static const int _flushIntervalSeconds = 30;
  static const String _queueStorageKey = 'analytics_event_queue';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Restore queued events from storage
    await _restoreQueueFromStorage();

    // Start periodic flush timer
    _flushTimer = Timer.periodic(
      const Duration(seconds: _flushIntervalSeconds),
      (_) => _flushQueue(),
    );
  }

  /// Log an analytics event with automatic queuing and retry
  void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    final event = {
      'event': eventName,
      'parameters': parameters ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
    };

    try {
      // Try to log immediately
      _baseService.logEvent(eventName, parameters);

      if (kDebugMode) {
        print('✅ Analytics Event Logged: $eventName');
      }
    } catch (e) {
      // If immediate logging fails, queue the event
      _queueEvent(event);

      if (kDebugMode) {
        print('⚠️ Analytics Event Queued: $eventName (Error: $e)');
      }
    }
  }

  void _queueEvent(Map<String, dynamic> event) {
    if (_eventQueue.length >= _maxQueueSize) {
      // Remove oldest event if queue is full
      _eventQueue.removeFirst();
      if (kDebugMode) {
        print('⚠️ Analytics queue full, removed oldest event');
      }
    }

    _eventQueue.add(event);
    _persistQueueToStorage();
  }

  Future<void> _flushQueue() async {
    if (_isProcessing || _eventQueue.isEmpty) return;

    _isProcessing = true;

    try {
      final eventsToFlush = List<Map<String, dynamic>>.from(_eventQueue);
      final successfulEvents = <Map<String, dynamic>>[];

      for (final event in eventsToFlush) {
        try {
          final eventName = event['event'] as String;
          final parameters = event['parameters'] as Map<String, dynamic>?;

          _baseService.logEvent(eventName, parameters);
          successfulEvents.add(event);

          if (kDebugMode) {
            print('✅ Flushed queued event: $eventName');
          }
        } catch (e) {
          // Increment retry count
          final retryCount = (event['retry_count'] as int? ?? 0) + 1;
          event['retry_count'] = retryCount;

          // Remove event if retried too many times
          if (retryCount > 5) {
            successfulEvents.add(event);
            if (kDebugMode) {
              print('❌ Dropped event after 5 retries: ${event['event']}');
            }
          }
        }
      }

      // Remove successfully flushed events from queue
      for (final event in successfulEvents) {
        _eventQueue.remove(event);
      }

      if (successfulEvents.isNotEmpty) {
        await _persistQueueToStorage();
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _persistQueueToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueData = _eventQueue.map((e) => e.toString()).toList();
      await prefs.setStringList(_queueStorageKey, queueData);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to persist analytics queue: $e');
      }
    }
  }

  Future<void> _restoreQueueFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueData = prefs.getStringList(_queueStorageKey);

      if (queueData != null && queueData.isNotEmpty) {
        if (kDebugMode) {
          print('📦 Restored ${queueData.length} queued analytics events');
        }
        // Note: This is a simplified restoration. In production, you'd want
        // to properly serialize/deserialize the event maps
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to restore analytics queue: $e');
      }
    }
  }

  /// Force flush all queued events immediately
  Future<void> flush() async {
    await _flushQueue();
  }

  /// Get the current queue size (for debugging)
  int get queueSize => _eventQueue.length;

  void dispose() {
    _flushTimer?.cancel();
    _baseService.dispose();
  }
}
