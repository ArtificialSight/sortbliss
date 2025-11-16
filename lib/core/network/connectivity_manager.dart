import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../analytics/analytics_logger.dart';

/// Manages network connectivity state and provides automatic retry logic
/// for network-dependent operations.
class ConnectivityManager extends ChangeNotifier {
  ConnectivityManager._();
  static final ConnectivityManager instance = ConnectivityManager._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _initialized = false;

  bool get isOnline => _isOnline;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Check initial connectivity
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (e) {
      AnalyticsLogger.logEvent('connectivity_check_failed', parameters: {
        'error': e.toString(),
      });
      _isOnline = false;
    }

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivityStatus,
      onError: (error) {
        AnalyticsLogger.logEvent('connectivity_stream_error', parameters: {
          'error': error.toString(),
        });
      },
    );
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Consider online if any connection type is available (except none)
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      AnalyticsLogger.logEvent(
        _isOnline ? 'connectivity_restored' : 'connectivity_lost',
        parameters: {
          'connection_types': results.map((r) => r.toString()).toList(),
        },
      );
      notifyListeners();
    }
  }

  /// Executes an async operation with automatic retry on network failure
  ///
  /// [operation] - The async function to execute
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [retryDelay] - Base delay between retries in seconds (default: 2)
  /// [exponentialBackoff] - Use exponential backoff for retries (default: true)
  ///
  /// Returns the result of the operation or throws the last error
  Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    int retryDelay = 2,
    bool exponentialBackoff = true,
  }) async {
    int attempts = 0;
    dynamic lastError;

    while (attempts <= maxRetries) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        attempts++;

        if (attempts > maxRetries) {
          AnalyticsLogger.logEvent('network_retry_exhausted', parameters: {
            'attempts': attempts,
            'error': e.toString(),
          });
          rethrow;
        }

        // Calculate delay with optional exponential backoff
        final delay = exponentialBackoff
            ? retryDelay * (1 << (attempts - 1)) // 2^(attempts-1)
            : retryDelay;

        AnalyticsLogger.logEvent('network_retry_attempt', parameters: {
          'attempt': attempts,
          'max_retries': maxRetries,
          'delay_seconds': delay,
        });

        await Future.delayed(Duration(seconds: delay));
      }
    }

    throw lastError;
  }

  /// Waits for online connectivity with timeout
  ///
  /// Returns true if connectivity is restored within timeout, false otherwise
  Future<bool> waitForConnectivity({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isOnline) return true;

    final completer = Completer<bool>();
    Timer? timeoutTimer;
    StreamSubscription<List<ConnectivityResult>>? tempSubscription;

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
        tempSubscription?.cancel();
      }
    });

    tempSubscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((result) => result != ConnectivityResult.none);
      if (online && !completer.isCompleted) {
        completer.complete(true);
        timeoutTimer?.cancel();
        tempSubscription?.cancel();
      }
    });

    return completer.future;
  }

  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
