/// Base class for AI related errors.
abstract class AIError implements Exception {
  AIError(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => '${runtimeType.toString()}: $message';
}

class AIUnauthorizedError extends AIError {
  AIUnauthorizedError(String message, {Object? cause})
      : super(message, cause: cause);
}

class AIRateLimitError extends AIError {
  AIRateLimitError(String message, {Object? cause, this.retryAfter})
      : super(message, cause: cause);
  final Duration? retryAfter;
}

class AIServerError extends AIError {
  AIServerError(String message, {Object? cause, this.statusCode})
      : super(message, cause: cause);
  final int? statusCode;
}

class AINetworkError extends AIError {
  AINetworkError(String message, {Object? cause}) : super(message, cause: cause);
}

class AIResponseParsingError extends AIError {
  AIResponseParsingError(String message, {Object? cause})
      : super(message, cause: cause);
}
