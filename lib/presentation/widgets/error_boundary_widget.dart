import 'package:flutter/material.dart';
import '../../core/utils/analytics_logger.dart';

/// Error boundary widget that catches and displays errors gracefully
///
/// Usage: Wrap your app or specific widgets with ErrorBoundary
///
/// ```dart
/// ErrorBoundary(
///   child: MyApp(),
/// )
/// ```
///
/// Features:
/// - Catches all errors in widget tree
/// - Logs errors to analytics
/// - Shows user-friendly error UI
/// - Provides retry functionality
/// - Different UI for development vs production
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final Function(Object error, StackTrace? stackTrace)? onError;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
    this.onError,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();

    // Set up error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
    };
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });

    // Log to analytics
    AnalyticsLogger.logEvent('error_boundary_caught', parameters: {
      'error': error.toString(),
      'stack_trace': stackTrace.toString(),
    });

    // Call custom error handler
    widget.onError?.call(error, stackTrace);

    // Print to console
    debugPrint('❌ Error Boundary caught error: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Use custom error builder if provided
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }

      // Default error UI
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red.shade50,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We\'re sorry for the inconvenience. Please try again.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),

                    // Show error details in development mode
                    if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                      const SizedBox(height: 48),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Error Details (Development Only):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _error.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      if (_stackTrace != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _stackTrace.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Smaller error boundary for specific features
class FeatureErrorBoundary extends StatefulWidget {
  final Widget child;
  final String featureName;
  final Widget? fallback;

  const FeatureErrorBoundary({
    Key? key,
    required this.child,
    required this.featureName,
    this.fallback,
  }) : super(key: key);

  @override
  State<FeatureErrorBoundary> createState() => _FeatureErrorBoundaryState();
}

class _FeatureErrorBoundaryState extends State<FeatureErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      if (widget.fallback != null) {
        return widget.fallback!;
      }

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 32,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.featureName} unavailable',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This feature encountered an error',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ErrorBoundary(
      onError: (error, stackTrace) {
        AnalyticsLogger.logEvent('feature_error', parameters: {
          'feature': widget.featureName,
          'error': error.toString(),
        });

        setState(() {
          _hasError = true;
        });
      },
      child: widget.child,
    );
  }
}

/// Async error handler for Future operations
class AsyncErrorHandler {
  /// Handle async operation with error catching
  static Future<T?> handle<T>({
    required Future<T> Function() operation,
    required String operationName,
    T? fallbackValue,
    Function(Object error)? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      AnalyticsLogger.logEvent('async_error', parameters: {
        'operation': operationName,
        'error': e.toString(),
      });

      debugPrint('❌ Async error in $operationName: $e');
      debugPrint(stackTrace.toString());

      onError?.call(e);

      return fallbackValue;
    }
  }

  /// Handle async operation with retry logic
  static Future<T?> handleWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    T? fallbackValue,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        attempts++;

        if (attempts >= maxRetries) {
          AnalyticsLogger.logEvent('async_error_max_retries', parameters: {
            'operation': operationName,
            'attempts': attempts,
            'error': e.toString(),
          });

          debugPrint('❌ Async error after $attempts attempts: $e');
          debugPrint(stackTrace.toString());

          return fallbackValue;
        }

        // Wait before retrying
        await Future.delayed(retryDelay * attempts);

        AnalyticsLogger.logEvent('async_retry', parameters: {
          'operation': operationName,
          'attempt': attempts,
        });
      }
    }

    return fallbackValue;
  }
}
