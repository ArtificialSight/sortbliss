import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/environment.dart';
import '../network/secure_supabase_client.dart';
import 'ai/ai_errors.dart';
import 'ai/ai_provider.dart';
import 'ai/retry_policy.dart';

/// OpenAI provider implementing the generic [AIProvider] contract with
/// retry + structured error mapping and ephemeral token flow.
class OpenAiService implements AIProvider {
  OpenAiService({
    Dio? http,
    SecureSupabaseClient? secureClient,
    RetryPolicy? retryPolicy,
    this.edgeFunction = 'issue-openai-token',
    this.defaultModel = 'gpt-4o-mini',
  })  : _http = http ?? Dio(),
        _secureClient = secureClient ?? SecureSupabaseClient(),
        _retryPolicy = retryPolicy ?? RetryPolicy();

  final Dio _http;
  final SecureSupabaseClient _secureClient;
  final RetryPolicy _retryPolicy;
  final String edgeFunction;
  final String defaultModel;

  @override
  String get name => 'openai';

  @override
  Future<String> createChatCompletion({
    required List<AIMessage> messages,
    String? model,
    double? temperature,
  }) async {
    return _retryPolicy.execute(() async {
      final ephemeral = await _secureClient.fetchServiceToken(
        edgeFunction: edgeFunction,
        sessionToken: Environment.supabaseSessionToken,
      );

      final url = '${Environment.openAiBaseUrl}/chat/completions';
      final payload = <String, dynamic>{
        'model': model ?? defaultModel,
        if (temperature != null) 'temperature': temperature,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

      try {
        final response = await _http.post<Map<String, dynamic>>(
          url,
          data: jsonEncode(payload),
          options: Options(headers: {
            'Authorization': 'Bearer $ephemeral',
            'Content-Type': 'application/json',
          }),
        );

        final data = response.data;
        if (data == null) {
          throw AIResponseParsingError('Empty response body');
        }

        final choices = data['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          throw AIResponseParsingError('No choices in response');
        }

        final first = choices.first as Map<String, dynamic>?;
        final message = (first?['message'] as Map<String, dynamic>?)?['content'];
        if (message is! String || message.isEmpty) {
          throw AIResponseParsingError('Missing message content');
        }

        return message;
      } on DioException catch (e) {
        _mapAndThrow(e);
      }
      throw AIServerError('Unreachable state');
    });
  }

  Never _mapAndThrow(DioException e) {
    final status = e.response?.statusCode;
    switch (status) {
      case 401:
      case 403:
        throw AIUnauthorizedError('Unauthorized (${status ?? 'no status'})',
            cause: e);
      case 429:
        Duration? retryAfter;
        final header = e.response?.headers.value('retry-after');
        if (header != null) {
          final secs = int.tryParse(header);
          if (secs != null) retryAfter = Duration(seconds: secs);
        }
        throw AIRateLimitError('Rate limited', cause: e, retryAfter: retryAfter);
      default:
        if (status != null && status >= 500) {
          throw AIServerError('Server error ($status)', cause: e, statusCode: status);
        }
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw AINetworkError('Network timeout', cause: e);
        }
        throw AINetworkError('Network error: ${e.message}', cause: e);
    }
  }
}
