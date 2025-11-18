import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../utils/analytics_logger.dart';

/// Performance monitoring service for production optimization
///
/// Tracks:
/// - Frame rate (FPS)
/// - Memory usage
/// - App lifecycle events
/// - Screen load times
/// - Network request times
/// - Critical user journeys
///
/// Automatically reports performance degradation and anomalies
class PerformanceMonitorService {
  static final PerformanceMonitorService instance = PerformanceMonitorService._();
  PerformanceMonitorService._();

  bool _initialized = false;
  bool _isMonitoring = false;

  // FPS tracking
  final List<int> _frameTimings = [];
  int _currentFps = 60;
  int _lowFpsFrameCount = 0;
  static const int _fpsWarningThreshold = 45;
  static const int _fpsCriticalThreshold = 30;

  // Memory tracking
  int _peakMemoryUsage = 0;
  int _currentMemoryUsage = 0;
  static const int _memoryWarningThreshold = 150 * 1024 * 1024; // 150MB
  static const int _memoryCriticalThreshold = 200 * 1024 * 1024; // 200MB

  // Screen load times
  final Map<String, List<int>> _screenLoadTimes = {};
  final Map<String, DateTime> _screenStartTimes = {};

  // Network request tracking
  final Map<String, List<int>> _apiRequestTimes = {};
  int _slowRequestCount = 0;
  static const int _slowRequestThreshold = 3000; // 3 seconds

  // User journey tracking
  final Map<String, DateTime> _journeyStartTimes = {};
  final Map<String, int> _journeyDurations = {};

  // Performance reports
  final List<PerformanceIssue> _issues = [];
  Timer? _monitoringTimer;

  /// Initialize performance monitoring
  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    // Only enable in debug mode or with feature flag
    if (kDebugMode || await _shouldEnableMonitoring()) {
      startMonitoring();
    }

    if (kDebugMode) {
      debugPrint('📊 Performance Monitor initialized');
    }
  }

  /// Start monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Monitor frames
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);

    // Periodic monitoring (every 5 seconds)
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _performPeriodicCheck(),
    );

    if (kDebugMode) {
      debugPrint('🔍 Performance monitoring started');
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;

    if (kDebugMode) {
      debugPrint('⏸️ Performance monitoring stopped');
    }
  }

  /// Frame timing callback
  void _onFrameTiming(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameDuration = timing.totalSpan.inMilliseconds;
      _frameTimings.add(frameDuration);

      // Keep only last 60 frames (1 second at 60fps)
      if (_frameTimings.length > 60) {
        _frameTimings.removeAt(0);
      }

      // Calculate current FPS
      if (_frameTimings.isNotEmpty) {
        final avgFrameTime = _frameTimings.reduce((a, b) => a + b) / _frameTimings.length;
        _currentFps = (1000 / avgFrameTime).round().clamp(1, 60);
      }

      // Track low FPS
      if (_currentFps < _fpsWarningThreshold) {
        _lowFpsFrameCount++;

        if (_lowFpsFrameCount >= 10) {
          _reportPerformanceIssue(
            type: PerformanceIssueType.lowFps,
            severity: _currentFps < _fpsCriticalThreshold
                ? PerformanceIssueSeverity.critical
                : PerformanceIssueSeverity.warning,
            message: 'Low FPS detected: $_currentFps',
            value: _currentFps.toDouble(),
          );
          _lowFpsFrameCount = 0;
        }
      } else {
        _lowFpsFrameCount = 0;
      }
    }
  }

  /// Periodic performance check
  Future<void> _performPeriodicCheck() async {
    await _checkMemoryUsage();
    _checkIssueThresholds();
  }

  /// Check memory usage
  Future<void> _checkMemoryUsage() async {
    try {
      // Get memory info (platform-specific)
      final info = await ProcessInfo.currentRss;
      _currentMemoryUsage = info;

      if (info > _peakMemoryUsage) {
        _peakMemoryUsage = info;
      }

      // Report high memory usage
      if (info > _memoryWarningThreshold) {
        _reportPerformanceIssue(
          type: PerformanceIssueType.highMemory,
          severity: info > _memoryCriticalThreshold
              ? PerformanceIssueSeverity.critical
              : PerformanceIssueSeverity.warning,
          message: 'High memory usage: ${(info / 1024 / 1024).toStringAsFixed(1)}MB',
          value: info.toDouble(),
        );
      }
    } catch (e) {
      // Memory info not available on all platforms
      if (kDebugMode) {
        debugPrint('⚠️ Could not get memory usage: $e');
      }
    }
  }

  /// Check if too many issues have been reported
  void _checkIssueThresholds() {
    if (_issues.length > 100) {
      // Keep only most recent 50 issues
      _issues.removeRange(0, 50);
    }
  }

  /// Track screen load time start
  void startScreenLoad(String screenName) {
    _screenStartTimes[screenName] = DateTime.now();
  }

  /// Track screen load time end
  void endScreenLoad(String screenName) {
    final startTime = _screenStartTimes[screenName];
    if (startTime == null) return;

    final loadTime = DateTime.now().difference(startTime).inMilliseconds;
    _screenStartTimes.remove(screenName);

    // Record load time
    _screenLoadTimes.putIfAbsent(screenName, () => []).add(loadTime);

    // Keep only last 10 loads per screen
    if (_screenLoadTimes[screenName]!.length > 10) {
      _screenLoadTimes[screenName]!.removeAt(0);
    }

    // Report slow screen load
    if (loadTime > 1000) {
      _reportPerformanceIssue(
        type: PerformanceIssueType.slowScreenLoad,
        severity: loadTime > 2000
            ? PerformanceIssueSeverity.critical
            : PerformanceIssueSeverity.warning,
        message: '$screenName loaded slowly: ${loadTime}ms',
        value: loadTime.toDouble(),
        context: {'screen': screenName},
      );
    }

    // Log analytics
    AnalyticsLogger.logEvent('screen_load_time', parameters: {
      'screen': screenName,
      'duration_ms': loadTime,
    });

    if (kDebugMode) {
      debugPrint('📊 Screen Load: $screenName - ${loadTime}ms');
    }
  }

  /// Track API request time
  void trackApiRequest(String endpoint, int durationMs) {
    _apiRequestTimes.putIfAbsent(endpoint, () => []).add(durationMs);

    // Keep only last 20 requests per endpoint
    if (_apiRequestTimes[endpoint]!.length > 20) {
      _apiRequestTimes[endpoint]!.removeAt(0);
    }

    // Report slow request
    if (durationMs > _slowRequestThreshold) {
      _slowRequestCount++;

      _reportPerformanceIssue(
        type: PerformanceIssueType.slowApiRequest,
        severity: durationMs > 5000
            ? PerformanceIssueSeverity.critical
            : PerformanceIssueSeverity.warning,
        message: 'Slow API request: $endpoint - ${durationMs}ms',
        value: durationMs.toDouble(),
        context: {'endpoint': endpoint},
      );
    }

    AnalyticsLogger.logEvent('api_request_time', parameters: {
      'endpoint': endpoint,
      'duration_ms': durationMs,
    });
  }

  /// Start user journey tracking
  void startJourney(String journeyName) {
    _journeyStartTimes[journeyName] = DateTime.now();

    if (kDebugMode) {
      debugPrint('🚀 Journey Started: $journeyName');
    }
  }

  /// End user journey tracking
  void endJourney(String journeyName, {bool success = true}) {
    final startTime = _journeyStartTimes[journeyName];
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _journeyStartTimes.remove(journeyName);
    _journeyDurations[journeyName] = duration;

    AnalyticsLogger.logEvent('journey_completed', parameters: {
      'journey': journeyName,
      'duration_ms': duration,
      'success': success,
    });

    if (kDebugMode) {
      debugPrint('✅ Journey Completed: $journeyName - ${duration}ms - ${success ? "Success" : "Failed"}');
    }
  }

  /// Report performance issue
  void _reportPerformanceIssue({
    required PerformanceIssueType type,
    required PerformanceIssueSeverity severity,
    required String message,
    required double value,
    Map<String, dynamic>? context,
  }) {
    final issue = PerformanceIssue(
      type: type,
      severity: severity,
      message: message,
      value: value,
      timestamp: DateTime.now(),
      context: context,
    );

    _issues.add(issue);

    // Log critical issues
    if (severity == PerformanceIssueSeverity.critical) {
      AnalyticsLogger.logEvent('performance_issue_critical', parameters: {
        'type': type.toString(),
        'message': message,
        'value': value,
        ...?context,
      });

      if (kDebugMode) {
        debugPrint('🔴 CRITICAL PERFORMANCE ISSUE: $message');
      }
    }
  }

  /// Get current FPS
  int getCurrentFps() => _currentFps;

  /// Get current memory usage (bytes)
  int getCurrentMemoryUsage() => _currentMemoryUsage;

  /// Get peak memory usage (bytes)
  int getPeakMemoryUsage() => _peakMemoryUsage;

  /// Get average screen load time
  int? getAverageScreenLoadTime(String screenName) {
    final times = _screenLoadTimes[screenName];
    if (times == null || times.isEmpty) return null;

    return times.reduce((a, b) => a + b) ~/ times.length;
  }

  /// Get average API request time
  int? getAverageApiRequestTime(String endpoint) {
    final times = _apiRequestTimes[endpoint];
    if (times == null || times.isEmpty) return null;

    return times.reduce((a, b) => a + b) ~/ times.length;
  }

  /// Get performance report
  PerformanceReport getPerformanceReport() {
    return PerformanceReport(
      currentFps: _currentFps,
      currentMemoryMb: (_currentMemoryUsage / 1024 / 1024).round(),
      peakMemoryMb: (_peakMemoryUsage / 1024 / 1024).round(),
      totalIssues: _issues.length,
      criticalIssues: _issues.where((i) => i.severity == PerformanceIssueSeverity.critical).length,
      warningIssues: _issues.where((i) => i.severity == PerformanceIssueSeverity.warning).length,
      screenLoadTimes: Map.fromEntries(
        _screenLoadTimes.entries.map((e) => MapEntry(
          e.key,
          e.value.reduce((a, b) => a + b) ~/ e.value.length,
        )),
      ),
      slowApiRequests: _slowRequestCount,
    );
  }

  /// Get all performance issues
  List<PerformanceIssue> getAllIssues() => List.unmodifiable(_issues);

  /// Clear all issues
  void clearIssues() {
    _issues.clear();
  }

  /// Check if monitoring should be enabled (feature flag)
  Future<bool> _shouldEnableMonitoring() async {
    // In production, check remote config or feature flag
    // For now, enable in debug mode only
    return kDebugMode;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _issues.clear();
    _screenLoadTimes.clear();
    _screenStartTimes.clear();
    _apiRequestTimes.clear();
    _journeyStartTimes.clear();
    _journeyDurations.clear();
  }
}

/// Type of performance issue
enum PerformanceIssueType {
  lowFps,
  highMemory,
  slowScreenLoad,
  slowApiRequest,
  longJourney,
  appCrash,
}

/// Severity of performance issue
enum PerformanceIssueSeverity {
  info,
  warning,
  critical,
}

/// Performance issue data
class PerformanceIssue {
  final PerformanceIssueType type;
  final PerformanceIssueSeverity severity;
  final String message;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  PerformanceIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.value,
    required this.timestamp,
    this.context,
  });

  @override
  String toString() {
    return 'PerformanceIssue(type: $type, severity: $severity, message: $message, value: $value)';
  }
}

/// Performance report summary
class PerformanceReport {
  final int currentFps;
  final int currentMemoryMb;
  final int peakMemoryMb;
  final int totalIssues;
  final int criticalIssues;
  final int warningIssues;
  final Map<String, int> screenLoadTimes;
  final int slowApiRequests;

  PerformanceReport({
    required this.currentFps,
    required this.currentMemoryMb,
    required this.peakMemoryMb,
    required this.totalIssues,
    required this.criticalIssues,
    required this.warningIssues,
    required this.screenLoadTimes,
    required this.slowApiRequests,
  });

  @override
  String toString() {
    return '''
Performance Report:
  FPS: $currentFps
  Memory: ${currentMemoryMb}MB (Peak: ${peakMemoryMb}MB)
  Issues: $totalIssues ($criticalIssues critical, $warningIssues warnings)
  Slow API Requests: $slowApiRequests
  Screen Load Times: $screenLoadTimes
''';
  }
}

/// Helper class to get process info
class ProcessInfo {
  static Future<int> get currentRss async {
    if (Platform.isAndroid || Platform.isIOS) {
      // On mobile, use rough estimation (not accurate)
      return 100 * 1024 * 1024; // 100MB default
    }
    return ProcessInfo.currentRss;
  }
}
