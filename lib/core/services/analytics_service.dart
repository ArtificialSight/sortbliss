import 'dart:async';
import 'package:flutter/foundation.dart';

/// A simple analytics service for tracking app events
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  // Stream controller for analytics events
  final StreamController<Map<String, dynamic>> _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of analytics events
  Stream<Map<String, dynamic>> get eventStream => _eventStreamController.stream;

  /// Log an analytics event
  void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    if (kDebugMode) {
      print('Analytics Event: $eventName');
      if (parameters != null && parameters.isNotEmpty) {
        print('Parameters: $parameters');
      }
    }

    // Emit event to stream
    _eventStreamController.add({
      'event': eventName,
      'parameters': parameters ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Dispose of resources
  void dispose() {
    _eventStreamController.close();
  }
}
