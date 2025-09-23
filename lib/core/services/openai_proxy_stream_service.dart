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

    // NOTE: This is a placeholder design. The current edge function returns
    // non-streamed JSON. To enable real streaming, update edge function to
    // set `stream: true` in OpenAI request and forward Server-Sent Events.
    final resp = await _http.post<Map<String, dynamic>>(
      '$functionsUrl/functions/v1/$edgeFunction',
      data: {
        'messages': messages.map((m) => m.toJson()).toList(),
        'model': model,
        'temperature': temperature,
        // 'stream': true, // to be handled server side
      },
      options: Options(headers: {
        'Authorization': 'Bearer $sessionToken',
      }),
    );

    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw AIResponseParsingError('Missing data envelope');
    }
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw AIResponseParsingError('No choices');
    }
    final content =
        (choices.first['message'] as Map<String, dynamic>)['content'] as String?;
    if (content == null) {
      throw AIResponseParsingError('Missing content');
    }
    // For now emit the full content once.
    yield content;
  }
}
