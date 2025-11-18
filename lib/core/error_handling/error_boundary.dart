import 'package:flutter/material.dart';
import 'dart:async';
import '../analytics/analytics_logger.dart';

/// Global error boundary widget that catches and handles Flutter framework errors
/// and provides fallback UI when critical errors occur.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    required this.child,
    this.fallbackBuilder,
    this.onError,
    super.key,
  });

  final Widget child;
  final Widget Function(FlutterErrorDetails details)? fallbackBuilder;
  final void Function(FlutterErrorDetails details)? onError;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log to analytics
      AnalyticsLogger.logEvent('app_error_boundary_triggered', parameters: {
        'error': details.exception.toString(),
        'stack_trace': details.stack.toString(),
        'library': details.library ?? 'unknown',
      });

      // Call custom error handler if provided
      widget.onError?.call(details);

      // Update UI to show error state
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      // Show custom fallback UI if provided
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(_errorDetails!);
      }

      // Default fallback UI
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We\'re sorry for the inconvenience. Please restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorDetails = null;
                      });
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Zone error handler for async errors not caught by Flutter's error handling
void runAppWithErrorHandling(Widget app) {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(app);
    },
    (error, stackTrace) {
      // Log async errors to analytics
      AnalyticsLogger.logEvent('app_async_error', parameters: {
        'error': error.toString(),
        'stack_trace': stackTrace.toString(),
      });

      // In production, you might want to send to crashlytics
      debugPrint('Async error caught: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}
