import 'package:flutter/foundation.dart';

/// Lightweight analytics facade so monetization events can be audited,
/// instrumented, and swapped out for a production analytics SDK later on.
class AnalyticsLogger {
  AnalyticsLogger._();

  /// Logs the [eventName] and optional [parameters]. For now we rely on
  /// `debugPrint` so developers can verify instrumentation during testing.
  static void logEvent(String eventName,
      {Map<String, Object?> parameters = const {}}) {
    final buffer = StringBuffer('[analytics] $eventName');
    if (parameters.isNotEmpty) {
      buffer.write(' -> ');
      buffer.write(parameters);
    }
    debugPrint(buffer.toString());
  }
}
