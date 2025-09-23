import 'dart:developer' as dev;

/// Set at build time: --dart-define=AI_DEBUG=1 to enable verbose AI logs.
final bool aiDebugEnabled = const String.fromEnvironment('AI_DEBUG') == '1';

void aiDebug(String message) {
  if (aiDebugEnabled) {
    dev.log(message, name: 'AI');
  }
}
