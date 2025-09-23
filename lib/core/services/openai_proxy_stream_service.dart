import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/environment.dart';
import 'ai/ai_errors.dart';
import 'ai/ai_provider.dart';
import 'ai/ai_debug.dart';

/// Provides streaming chat completion via the proxy by requesting a streaming
/// response from OpenAI and emitting incremental tokens. Requires the edge
/// function to support SSE pass-through (not yet implemented server-side).
class OpenAiProxyStreamService {
  OpenAiProxyStreamService({Dio? http, this.edgeFunction = 'openai-chat'})
      : _http = http ?? Dio();

  final Dio _http;
  final String edgeFunction;

  Stream<String> streamChatCompletion({
    required List<AIMessage> messages,
    String model = 'gpt-4o-mini',
    double temperature = 0.7,
  }) async* {
    final sessionToken = Environment.supabaseSessionToken;
    final functionsUrl = Environment.supabaseFunctionsUrl;

    if (sessionToken.isEmpty || functionsUrl.isEmpty) {
      throw AIUnauthorizedError('Missing session or functions URL');
    }

    aiDebug('[proxy-stream] start messages=${messages.length}');
    
    final response = await _http.post<String>(
      '$functionsUrl/functions/v1/$edgeFunction',
      data: jsonEncode({
        'messages': messages.map((m) => m.toJson()).toList(),
        'model': model,
        'temperature': temperature,
        'stream': true,
      }),
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    final stream = response.data;
    if (stream is! Stream<List<int>>) {
      throw AIResponseParsingError('Expected byte stream');
    }

    await for (final chunk in stream) {
      final text = utf8.decode(chunk);
      // Explicitly cast to List<String> to ensure non-null type
      final lines = LineSplitter().convert(text) as List<String>;
      
      for (final line in lines) {
        if (line.startsWith('data:')) {
          final payload = line.substring(5).trim();
          if (payload == '[DONE]') return;
          if (payload.isEmpty) continue;

          try {
            final jsonData = jsonDecode(payload) as Map<String, dynamic>;
            final choices = jsonData['choices'] as List<dynamic>?;
            if (choices == null || choices.isEmpty) continue;

            final delta = (choices.first as Map<String, dynamic>)['delta'] as Map<String, dynamic>?;
            final token = delta?['content'] as String?;
            if (token != null && token.isNotEmpty) {
              yield token;
            }
          } catch (_) {
            // Swallow malformed chunk
          }
        }
      }
    }
  }
}
