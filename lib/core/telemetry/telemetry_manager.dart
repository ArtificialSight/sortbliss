import 'dart:async';
import 'package:flutter/foundation.dart';
import '../analytics/analytics_logger.dart';
// TODO: Uncomment after Firebase setup (P0.5)
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:firebase_performance/firebase_performance.dart';

/// Telemetry manager for performance monitoring, crash reporting,
/// and business metrics validation.
///
/// This provides integration points for services like:
/// - Firebase Crashlytics
/// - Firebase Performance Monitoring
/// - Sentry
/// - Custom telemetry backends
class TelemetryManager {
  TelemetryManager._();
  static final TelemetryManager instance = TelemetryManager._();

  bool _initialized = false;
  final Map<String, dynamic> _sessionMetrics = {};
  DateTime? _sessionStartTime;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _sessionStartTime = DateTime.now();

    // Log app initialization
    AnalyticsLogger.logEvent('telemetry_initialized', parameters: {
      'platform': defaultTargetPlatform.toString(),
      'debug_mode': kDebugMode,
    });

    // TODO: Uncomment after Firebase setup (P0.5) - Step 1 of 2
    // Enable Crashlytics collection (disabled in debug mode to avoid test crashes)
    // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

    // TODO: Uncomment after Firebase setup (P0.5) - Step 2 of 2
    // Initialize Firebase Performance Monitoring
    // final _ = FirebasePerformance.instance; // Activates performance monitoring
  }

  // ============ CRASH REPORTING ============

  /// Record a non-fatal error for crash analytics
  void recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  }) {
    AnalyticsLogger.logEvent('error_recorded', parameters: {
      'error': exception.toString(),
      'reason': reason,
      if (context != null) ...context,
    });

    if (kDebugMode) {
      print('🔴 Error Recorded: $exception');
      if (reason != null) print('   Reason: $reason');
      if (stackTrace != null) print('   Stack: $stackTrace');
    }

    // TODO: Uncomment after Firebase setup (P0.5)
    // Send error to Firebase Crashlytics for tracking and analysis
    // await FirebaseCrashlytics.instance.recordError(
    //   exception,
    //   stackTrace,
    //   reason: reason,
    //   information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
    //   fatal: false, // Mark as non-fatal error
    // );
  }

  /// Set user identifier for crash reports (anonymized)
  void setUserIdentifier(String userId) {
    AnalyticsLogger.logEvent('user_identified', parameters: {
      'user_id_hash': userId.hashCode.toString(), // Never log actual user ID
    });

    // TODO: Uncomment after Firebase setup (P0.5)
    // Set user ID in Crashlytics for crash attribution
    // FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Set custom key-value pairs for crash context
  void setCustomKey(String key, dynamic value) {
    _sessionMetrics[key] = value;

    // TODO: Uncomment after Firebase setup (P0.5)
    // Set custom key in Crashlytics for crash debugging context
    // FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  // ============ PERFORMANCE MONITORING ============

  /// Start a performance trace
  PerformanceTrace startTrace(String traceName) {
    return PerformanceTrace._(traceName);
  }

  /// Record a specific metric value
  void recordMetric(String metricName, num value, {String? unit}) {
    AnalyticsLogger.logEvent('performance_metric', parameters: {
      'metric': metricName,
      'value': value,
      if (unit != null) 'unit': unit,
    });

    _sessionMetrics[metricName] = value;
  }

  // ============ BUSINESS METRICS VALIDATION ============

  /// Validate and record IAP revenue
  void recordRevenue({
    required String productId,
    required double amount,
    required String currency,
    bool isTest = false,
  }) {
    AnalyticsLogger.logEvent('revenue_recorded', parameters: {
      'product_id': productId,
      'amount': amount,
      'currency': currency,
      'is_test': isTest,
    });

    // Track cumulative revenue
    final key = 'total_revenue_$currency';
    final currentRevenue = _sessionMetrics[key] as double? ?? 0.0;
    _sessionMetrics[key] = currentRevenue + amount;
  }

  /// Record ad impression with estimated earnings
  void recordAdImpression({
    required String adType,
    required String adUnitId,
    double estimatedEarnings = 0.0,
  }) {
    AnalyticsLogger.logEvent('ad_impression_recorded', parameters: {
      'ad_type': adType,
      'ad_unit_id': adUnitId,
      'estimated_earnings': estimatedEarnings,
    });

    // Track ad performance
    final impressionKey = 'ad_impressions_$adType';
    final earningsKey = 'ad_earnings_$adType';

    _sessionMetrics[impressionKey] = (_sessionMetrics[impressionKey] as int? ?? 0) + 1;
    _sessionMetrics[earningsKey] = (_sessionMetrics[earningsKey] as double? ?? 0.0) + estimatedEarnings;
  }

  /// Record user engagement metric
  void recordEngagement({
    required String metricType,
    required int value,
    Map<String, dynamic>? metadata,
  }) {
    AnalyticsLogger.logEvent('engagement_metric', parameters: {
      'metric_type': metricType,
      'value': value,
      if (metadata != null) ...metadata,
    });

    _sessionMetrics[metricType] = value;
  }

  // ============ SESSION MANAGEMENT ============

  /// Get current session duration in seconds
  int getSessionDuration() {
    if (_sessionStartTime == null) return 0;
    return DateTime.now().difference(_sessionStartTime!).inSeconds;
  }

  /// Get all session metrics
  Map<String, dynamic> getSessionMetrics() {
    return {
      ..._sessionMetrics,
      'session_duration_seconds': getSessionDuration(),
      'session_start': _sessionStartTime?.toIso8601String(),
    };
  }

  /// Log session summary (call on app pause/exit)
  void logSessionSummary() {
    final metrics = getSessionMetrics();

    AnalyticsLogger.logEvent('session_summary', parameters: metrics);

    if (kDebugMode) {
      print('📊 Session Summary:');
      metrics.forEach((key, value) {
        print('   $key: $value');
      });
    }
  }

  void dispose() {
    logSessionSummary();
  }
}

/// Performance trace for measuring operation duration
class PerformanceTrace {
  PerformanceTrace._(this.name) : _startTime = DateTime.now() {
    if (kDebugMode) {
      print('⏱️  Started trace: $name');
    }
  }

  final String name;
  final DateTime _startTime;
  final Map<String, num> _metrics = {};
  bool _stopped = false;

  /// Add a custom metric to this trace
  void setMetric(String metricName, num value) {
    _metrics[metricName] = value;
  }

  /// Increment a counter metric
  void incrementMetric(String metricName, [int incrementBy = 1]) {
    _metrics[metricName] = (_metrics[metricName] as int? ?? 0) + incrementBy;
  }

  /// Stop the trace and record duration
  void stop() {
    if (_stopped) return;
    _stopped = true;

    final duration = DateTime.now().difference(_startTime);

    AnalyticsLogger.logEvent('performance_trace', parameters: {
      'trace_name': name,
      'duration_ms': duration.inMilliseconds,
      ..._metrics,
    });

    if (kDebugMode) {
      print('⏱️  Stopped trace: $name (${duration.inMilliseconds}ms)');
      if (_metrics.isNotEmpty) {
        print('   Metrics: $_metrics');
      }
    }

    // TODO: Uncomment after Firebase setup (P0.5)
    // Send performance trace to Firebase Performance Monitoring
    // final firebaseTrace = FirebasePerformance.instance.newTrace(name);
    // await firebaseTrace.start();
    // _metrics.forEach((key, value) {
    //   firebaseTrace.setMetric(key, value.toInt());
    // });
    // await firebaseTrace.stop();
  }
}
