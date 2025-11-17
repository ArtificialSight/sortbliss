import 'package:flutter/foundation.dart';
// TODO: Uncomment after Firebase setup (P0.5)
// import 'package:firebase_analytics/firebase_analytics.dart';

/// Lightweight analytics facade so monetization events can be audited,
/// instrumented, and swapped out for a production analytics SDK later on.
///
/// After Firebase setup, events are sent to both debug console and Firebase Analytics.
class AnalyticsLogger {
  AnalyticsLogger._();

  // TODO: Uncomment after Firebase setup (P0.5)
  // static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Logs the [eventName] and optional [parameters].
  ///
  /// In debug mode: Prints to console for verification
  /// In production: Sends to Firebase Analytics for tracking
  static void logEvent(String eventName,
      {Map<String, Object?> parameters = const {}}) {
    // Always log to console in debug mode for developer verification
    if (kDebugMode) {
      final buffer = StringBuffer('[analytics] $eventName');
      if (parameters.isNotEmpty) {
        buffer.write(' -> ');
        buffer.write(parameters);
      }
      debugPrint(buffer.toString());
    }

    // TODO: Uncomment after Firebase setup (P0.5)
    // Send to Firebase Analytics in production
    // try {
    //   // Firebase Analytics has a 40 character limit on event names
    //   final sanitizedEventName = eventName.length > 40
    //       ? eventName.substring(0, 40)
    //       : eventName;
    //
    //   // Firebase Analytics has strict parameter value type requirements
    //   final sanitizedParameters = <String, Object>{};
    //   parameters.forEach((key, value) {
    //     if (value != null) {
    //       // Firebase only accepts String, int, double, bool
    //       if (value is String || value is int || value is double || value is bool) {
    //         sanitizedParameters[key] = value;
    //       } else {
    //         // Convert other types to string
    //         sanitizedParameters[key] = value.toString();
    //       }
    //     }
    //   });
    //
    //   _analytics.logEvent(
    //     name: sanitizedEventName,
    //     parameters: sanitizedParameters,
    //   );
    // } catch (e) {
    //   debugPrint('[analytics] Failed to log event to Firebase: $e');
    // }
  }

  /// Log screen view for navigation tracking
  ///
  /// Automatically tracks screen transitions in Firebase Analytics
  static void logScreenView({
    required String screenName,
    String? screenClass,
  }) {
    logEvent('screen_view', parameters: {
      'screen_name': screenName,
      if (screenClass != null) 'screen_class': screenClass,
    });

    // TODO: Uncomment after Firebase setup (P0.5)
    // try {
    //   _analytics.logScreenView(
    //     screenName: screenName,
    //     screenClass: screenClass ?? screenName,
    //   );
    // } catch (e) {
    //   debugPrint('[analytics] Failed to log screen view to Firebase: $e');
    // }
  }

  /// Set user ID for analytics attribution
  ///
  /// **IMPORTANT:** Only use anonymized/hashed user IDs, never actual user data
  static void setUserId(String? userId) {
    if (kDebugMode) {
      debugPrint('[analytics] User ID set: ${userId ?? "null"}');
    }

    // TODO: Uncomment after Firebase setup (P0.5)
    // try {
    //   _analytics.setUserId(id: userId);
    // } catch (e) {
    //   debugPrint('[analytics] Failed to set user ID in Firebase: $e');
    // }
  }

  /// Set user property for segmentation
  ///
  /// Examples: premium_user=true, install_source=organic, country=US
  static void setUserProperty({
    required String name,
    required String? value,
  }) {
    if (kDebugMode) {
      debugPrint('[analytics] User property set: $name = ${value ?? "null"}');
    }

    // TODO: Uncomment after Firebase setup (P0.5)
    // try {
    //   _analytics.setUserProperty(name: name, value: value);
    // } catch (e) {
    //   debugPrint('[analytics] Failed to set user property in Firebase: $e');
    // }
  }

  /// Reset analytics data (e.g., on user logout)
  static void resetAnalyticsData() {
    if (kDebugMode) {
      debugPrint('[analytics] Analytics data reset');
    }

    // TODO: Uncomment after Firebase setup (P0.5)
    // try {
    //   _analytics.resetAnalyticsData();
    // } catch (e) {
    //   debugPrint('[analytics] Failed to reset analytics data in Firebase: $e');
    // }
  }
}
