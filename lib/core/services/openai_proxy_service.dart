import 'package:dio/dio.dart';
import '../config/environment.dart';
import 'ai/ai_errors.dart';
import 'ai/ai_provider.dart';
import 'ai/retry_policy.dart';
import 'ai/ai_debug.dart';

/// Uses the Supabase Edge Function `openai-chat` to proxy requests. The
/// edge function holds the real OpenAI API key, keeping it off-device.
class OpenAiProxyService implements AIProvider {
  OpenAiProxyService({
    Dio? http,
    RetryPolicy? retryPolicy,
    this.edgeFunction = 'openai-chat',
    this.defaultModel = 'gpt-4o-mini',
  })  : _http = http ?? Dio(),
        _retryPolicy = retryPolicy ?? RetryPolicy();

  final Dio _http;
  final RetryPolicy _retryPolicy;
  final String edgeFunction;
  final String defaultModel;

  @override
  String get name => 'openai-proxy';

  @override
  Future<String> createChatCompletion({
    required List<AIMessage> messages,
    String? model,
    double? temperature,
  }) async {
    final sessionToken = Environment.supabaseSessionToken;
    if (sessionToken.isEmpty) {
      throw AIUnauthorizedError('Missing Supabase session token');
    }

    final functionsUrl = Environment.supabaseFunctionsUrl;
    if (functionsUrl.isEmpty) {
      throw AIError('Missing SUPABASE_FUNCTIONS_URL');
    }

    return _retryPolicy.execute(() async {
      try {
        aiDebug('[proxy] POST edgeFunction=$edgeFunction model=${model ?? defaultModel} messages=${messages.length}');
        
        final resp = await _http.post<Map<String, dynamic>>(
          '$functionsUrl/functions/v1/$edgeFunction',
          data: {
            'messages': messages.map((m) => m.toJson()).toList(),
            'model': model ?? defaultModel,
            if (temperature != null) 'temperature': temperature,
          },
          options: Options(headers: {
            'Authorization': 'Bearer $sessionToken',
          }),
        );

        aiDebug('[proxy] status=${resp.statusCode} keys=${resp.data?.keys.toList()}');
        
        final data = resp.data?['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw AIResponseParsingError('Missing data envelope');
        }

        final choices = data['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          throw AIResponseParsingError('No choices array');
        }

        final first = choices.first as Map<String, dynamic>?;
        final content = (first?['message'] as Map<String, dynamic>?)?['content'];
        if (content is! String || content.isEmpty) {
          throw AIResponseParsingError('Empty content');
        }

        return content;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          throw AIUnauthorizedError('Unauthorized', cause: e);
        } else if (status == 429) {
          throw AIRateLimitError('Rate limited', cause: e);
        } else if (status != null && status >= 500) {
          throw AIServerError('Server error ($status)', statusCode: status, cause: e);
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw AINetworkError('Timeout', cause: e);
        }
        throw AINetworkError('Network error: ${e.message}', cause: e);
      }
    });
  }
}
