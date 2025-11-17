import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/analytics_logger.dart';

/// Network connectivity monitoring service
///
/// Monitors internet connectivity and notifies listeners of changes.
/// Useful for:
/// - Showing offline indicators
/// - Queuing operations when offline
/// - Syncing data when online
///
/// Usage:
/// ```dart
/// await NetworkMonitorService.instance.initialize();
///
/// // Listen to changes
/// NetworkMonitorService.instance.addListener(() {
///   print('Online: ${NetworkMonitorService.instance.isOnline}');
/// });
///
/// // Check status
/// if (NetworkMonitorService.instance.isOnline) {
///   // Do online operation
/// }
/// ```
///
/// TODO: Integrate with connectivity_plus package for real monitoring
/// Currently uses mock implementation
class NetworkMonitorService extends ChangeNotifier {
  static final NetworkMonitorService instance = NetworkMonitorService._();
  NetworkMonitorService._();

  bool _initialized = false;
  bool _isOnline = true;
  DateTime? _lastOnlineTime;
  DateTime? _lastOfflineTime;
  Timer? _checkTimer;

  // Getters
  bool get initialized => _initialized;
  bool get isOnline => _isOnline;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  DateTime? get lastOfflineTime => _lastOfflineTime;

  /// Initialize network monitoring
  Future<void> initialize() async {
    if (_initialized) return;

    // TODO: Use connectivity_plus package
    // ```dart
    // _connectivity = Connectivity();
    // _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    // final initialStatus = await _connectivity.checkConnectivity();
    // _updateConnectionStatus(initialStatus);
    // ```

    // Mock: Assume online
    _isOnline = true;
    _lastOnlineTime = DateTime.now();

    // Start periodic check (mock)
    _startPeriodicCheck();

    _initialized = true;

    debugPrint('✅ Network Monitor initialized (online: $_isOnline)');
  }

  /// Start periodic connectivity check
  void _startPeriodicCheck() {
    _checkTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  /// Check connectivity (mock implementation)
  Future<void> _checkConnectivity() async {
    // TODO: Replace with real connectivity check
    // For now, always return online

    // In real implementation:
    // try {
    //   final result = await InternetAddress.lookup('google.com');
    //   _updateStatus(result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    // } catch (_) {
    //   _updateStatus(false);
    // }
  }

  /// Update online status
  void _updateStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;

      if (isOnline) {
        _lastOnlineTime = DateTime.now();
        _onConnectionRestored();
      } else {
        _lastOfflineTime = DateTime.now();
        _onConnectionLost();
      }

      notifyListeners();
    }
  }

  /// Handle connection restored
  void _onConnectionRestored() {
    debugPrint('📡 Connection restored');

    AnalyticsLogger.logEvent(
      'network_online',
      parameters: {
        'offline_duration': _lastOfflineTime != null
            ? DateTime.now().difference(_lastOfflineTime!).inSeconds
            : 0,
      },
    );

    // Trigger any pending operations
    // TODO: Notify offline analytics queue to flush
  }

  /// Handle connection lost
  void _onConnectionLost() {
    debugPrint('📡 Connection lost');

    AnalyticsLogger.logEvent('network_offline');

    // TODO: Queue any pending operations
  }

  /// Manually set online status (for testing)
  void setOnlineStatus(bool isOnline) {
    _updateStatus(isOnline);
  }

  /// Get connection statistics
  NetworkStatistics getStatistics() {
    final totalTime = _lastOnlineTime != null
        ? DateTime.now().difference(_lastOnlineTime!).inSeconds
        : 0;

    final offlineTime = _lastOfflineTime != null && !_isOnline
        ? DateTime.now().difference(_lastOfflineTime!).inSeconds
        : 0;

    return NetworkStatistics(
      isOnline: _isOnline,
      lastOnlineTime: _lastOnlineTime,
      lastOfflineTime: _lastOfflineTime,
      totalOnlineTime: totalTime,
      currentOfflineTime: offlineTime,
    );
  }

  /// Dispose
  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}

/// Network statistics
class NetworkStatistics {
  final bool isOnline;
  final DateTime? lastOnlineTime;
  final DateTime? lastOfflineTime;
  final int totalOnlineTime; // seconds
  final int currentOfflineTime; // seconds

  NetworkStatistics({
    required this.isOnline,
    this.lastOnlineTime,
    this.lastOfflineTime,
    required this.totalOnlineTime,
    required this.currentOfflineTime,
  });

  @override
  String toString() {
    return 'NetworkStatistics(\n'
        '  online: $isOnline,\n'
        '  lastOnline: $lastOnlineTime,\n'
        '  lastOffline: $lastOfflineTime,\n'
        '  totalOnlineTime: ${totalOnlineTime}s,\n'
        '  currentOfflineTime: ${currentOfflineTime}s\n'
        ')';
  }
}
