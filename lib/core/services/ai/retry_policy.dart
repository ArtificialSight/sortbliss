import 'dart:async';
import 'dart:math';

typedef RetryShouldRetry = bool Function(Object error, int attempt);

class RetryPolicy {
  RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 300),
    this.maxDelay = const Duration(seconds: 3),
    this.jitter = true,
    RetryShouldRetry? shouldRetry,
  }) : _shouldRetry = shouldRetry ?? _defaultShouldRetry;

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final bool jitter;
  final RetryShouldRetry _shouldRetry;

  static bool _defaultShouldRetry(Object error, int attempt) => true;

  Future<T> execute<T>(Future<T> Function() action) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        if (attempt == maxAttempts || !_shouldRetry(e, attempt)) {
          rethrow;
        }
        final delay = _computeDelay(attempt);
        await Future.delayed(delay);
      }
    }
    throw lastError!; // unreachable
  }

  Duration _computeDelay(int attempt) {
    final exp = baseDelay * pow(2, attempt - 1).toInt();
    var delay = exp > maxDelay ? maxDelay : exp;
    if (jitter) {
      final rand = Random();
      final jitterMs = rand.nextInt(delay.inMilliseconds ~/ 2 + 1);
      delay = Duration(milliseconds: delay.inMilliseconds - jitterMs);
    }
    return delay;
  }
}
