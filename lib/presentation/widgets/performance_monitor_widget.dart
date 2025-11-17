import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:developer' as developer;

/// Performance monitoring overlay for debugging
///
/// Shows real-time metrics:
/// - FPS (frames per second)
/// - Frame time (ms)
/// - Memory usage
/// - Jank detection
/// - Widget rebuild count
///
/// Usage:
/// ```dart
/// PerformanceMonitor(
///   enabled: kDebugMode, // Only in debug mode
///   child: MyApp(),
/// )
/// ```
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final bool showOverlay;

  const PerformanceMonitor({
    Key? key,
    required this.child,
    this.enabled = false,
    this.showOverlay = true,
  }) : super(key: key);

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();

  /// Get the performance monitor state to access metrics
  static _PerformanceMonitorState? of(BuildContext context) {
    return context.findAncestorStateOfType<_PerformanceMonitorState>();
  }
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with WidgetsBindingObserver {
  final List<double> _frameTimes = [];
  double _currentFps = 60.0;
  double _averageFrameTime = 0.0;
  int _jankCount = 0;
  int _totalFrames = 0;
  bool _overlayVisible = true;

  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();

    if (widget.enabled) {
      WidgetsBinding.instance.addObserver(this);
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    // Monitor frame rendering
    SchedulerBinding.instance.addTimingsCallback(_onFrameRendered);

    // Update metrics periodically
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateMetrics();
        });
      }
    });
  }

  void _onFrameRendered(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds / 1000.0; // ms
      _frameTimes.add(frameTime);
      _totalFrames++;

      // Detect jank (>16.67ms for 60fps)
      if (frameTime > 16.67) {
        _jankCount++;
      }

      // Keep only last 60 frames
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
    }
  }

  void _updateMetrics() {
    if (_frameTimes.isEmpty) return;

    // Calculate average frame time
    _averageFrameTime =
        _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;

    // Calculate FPS
    _currentFps = _averageFrameTime > 0 ? 1000 / _averageFrameTime : 60.0;
  }

  void toggleOverlay() {
    setState(() {
      _overlayVisible = !_overlayVisible;
    });
  }

  /// Get current metrics
  PerformanceMetrics getMetrics() {
    return PerformanceMetrics(
      fps: _currentFps,
      averageFrameTime: _averageFrameTime,
      jankCount: _jankCount,
      totalFrames: _totalFrames,
      jankPercentage: _totalFrames > 0 ? (_jankCount / _totalFrames) * 100 : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled && widget.showOverlay && _overlayVisible)
          _buildOverlay(),
      ],
    );
  }

  Widget _buildOverlay() {
    final metrics = getMetrics();
    final fpsColor = _getFpsColor(metrics.fps);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 8,
      child: GestureDetector(
        onTap: toggleOverlay,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: fpsColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMetricRow('FPS', metrics.fps.toStringAsFixed(1), fpsColor),
              const SizedBox(height: 4),
              _buildMetricRow(
                'Frame',
                '${metrics.averageFrameTime.toStringAsFixed(2)}ms',
                _getFrameTimeColor(metrics.averageFrameTime),
              ),
              const SizedBox(height: 4),
              _buildMetricRow(
                'Jank',
                '${metrics.jankPercentage.toStringAsFixed(1)}%',
                _getJankColor(metrics.jankPercentage),
              ),
              const SizedBox(height: 4),
              _buildMetricRow(
                'Frames',
                metrics.totalFrames.toString(),
                Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Color _getFpsColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.yellow;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getFrameTimeColor(double frameTime) {
    if (frameTime <= 16.67) return Colors.green; // 60 FPS
    if (frameTime <= 33.33) return Colors.yellow; // 30 FPS
    return Colors.red;
  }

  Color _getJankColor(double jankPercentage) {
    if (jankPercentage <= 1) return Colors.green;
    if (jankPercentage <= 5) return Colors.yellow;
    return Colors.red;
  }
}

/// Performance metrics data class
class PerformanceMetrics {
  final double fps;
  final double averageFrameTime;
  final int jankCount;
  final int totalFrames;
  final double jankPercentage;

  PerformanceMetrics({
    required this.fps,
    required this.averageFrameTime,
    required this.jankCount,
    required this.totalFrames,
    required this.jankPercentage,
  });

  bool get isGood => fps >= 55 && jankPercentage <= 1;
  bool get isAcceptable => fps >= 30 && jankPercentage <= 5;
  bool get isPoor => !isAcceptable;

  @override
  String toString() {
    return 'PerformanceMetrics('
        'fps: ${fps.toStringAsFixed(1)}, '
        'frameTime: ${averageFrameTime.toStringAsFixed(2)}ms, '
        'jank: ${jankPercentage.toStringAsFixed(1)}%'
        ')';
  }
}

/// Widget rebuild counter for debugging
class RebuildCounter extends StatefulWidget {
  final Widget child;
  final String? label;

  const RebuildCounter({
    Key? key,
    required this.child,
    this.label,
  }) : super(key: key);

  @override
  State<RebuildCounter> createState() => _RebuildCounterState();
}

class _RebuildCounterState extends State<RebuildCounter> {
  int _rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;

    developer.log(
      'Rebuild #$_rebuildCount${widget.label != null ? ' [${widget.label}]' : ''}',
      name: 'RebuildCounter',
    );

    return widget.child;
  }
}

/// Performance benchmark helper
class PerformanceBenchmark {
  final String name;
  final Stopwatch _stopwatch = Stopwatch();

  PerformanceBenchmark(this.name);

  /// Start timing
  void start() {
    _stopwatch.start();
  }

  /// Stop timing and log result
  void stop() {
    _stopwatch.stop();
    final duration = _stopwatch.elapsedMicroseconds / 1000.0; // ms

    developer.log(
      '$name took ${duration.toStringAsFixed(2)}ms',
      name: 'Performance',
    );

    _stopwatch.reset();
  }

  /// Time a synchronous operation
  static T time<T>(String name, T Function() operation) {
    final benchmark = PerformanceBenchmark(name);
    benchmark.start();
    final result = operation();
    benchmark.stop();
    return result;
  }

  /// Time an asynchronous operation
  static Future<T> timeAsync<T>(
      String name, Future<T> Function() operation) async {
    final benchmark = PerformanceBenchmark(name);
    benchmark.start();
    final result = await operation();
    benchmark.stop();
    return result;
  }
}

/// Memory profiler
class MemoryProfiler {
  static void logMemoryUsage() {
    // Note: Actual memory profiling requires platform channels or additional packages
    // This is a placeholder for the API

    developer.log(
      'Memory profiling requires additional platform implementation',
      name: 'MemoryProfiler',
    );
  }
}
