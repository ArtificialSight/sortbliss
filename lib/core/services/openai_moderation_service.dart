import 'package:dio/dio.dart';

import '../config/environment.dart';
import 'ai/ai_errors.dart';
import 'ai/ai_debug.dart';

/// Calls OpenAI moderation through the existing proxy edge function by
/// optionally adding a dedicated moderation function later. Currently this
/// can be pointed at a future `openai-moderation` function; for now we expect
/// the chat edge to have already executed moderation when enabled.
class OpenAiModerationService {
  OpenAiModerationService({Dio? http, this.edgeFunction = 'openai-chat'})
      : _http = http ?? Dio();

  final Dio _http;
  final String edgeFunction;

  Future<bool> isFlagged(String text) async {
    final sessionToken = Environment.supabaseSessionToken;
    final functionsUrl = Environment.supabaseFunctionsUrl;
    if (sessionToken.isEmpty || functionsUrl.isEmpty) {
      throw AIUnauthorizedError('Missing session or functions URL');
    }
    aiDebug('[moderation] check length=${text.length}');
    // This is a placeholder: since moderation currently runs server-side in
    // the chat function, we simulate a local heuristic.
    final lowered = text.toLowerCase();
    const banned = ['forbidden_example_token'];
    return banned.any(lowered.contains);
  }
}
