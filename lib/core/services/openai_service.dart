import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/environment.dart';
import '../network/secure_supabase_client.dart';

/// Lightweight client that acquires a short-lived OpenAI session token from a
/// Supabase Edge Function, then executes a chat completion call.
class OpenAiService {
  OpenAiService({Dio? http, SecureSupabaseClient? secureClient})
      : _http = http ?? Dio(),
        _secureClient = secureClient ?? SecureSupabaseClient();

  final Dio _http;
  final SecureSupabaseClient _secureClient;

  /// Create a chat completion using an ephemeral token minted server-side.
  ///
  /// [edgeFunction] is the Supabase Edge Function name that returns
  /// `{ token: string, expiresIn: number }`.
  Future<String> createChatCompletion({
    required String edgeFunction,
    required List<OpenAiMessage> messages,
    String model = 'gpt-4o-mini',
    double temperature = 0.7,
  }) async {
    final sessionToken = Environment.supabaseSessionToken;
    final ephemeral = await _secureClient.fetchServiceToken(
      edgeFunction: edgeFunction,
      sessionToken: sessionToken,
    );

    final url = '${Environment.openAiBaseUrl}/chat/completions';

    final payload = {
      'model': model,
      'temperature': temperature,
      'messages': messages.map((m) => m.toJson()).toList(),
    };

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
      throw const OpenAiServiceException('Empty response body');
    }

    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const OpenAiServiceException('No choices in response');
    }

    final first = choices.first as Map<String, dynamic>?;
    final message = (first?['message'] as Map<String, dynamic>?)?['content'];
    if (message is! String || message.isEmpty) {
      throw const OpenAiServiceException('Missing message content');
    }
    return message;
  }
}

class OpenAiMessage {
  const OpenAiMessage({required this.role, required this.content});
  final String role;
  final String content;

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class OpenAiServiceException implements Exception {
  const OpenAiServiceException(this.message);
  final String message;
  @override
  String toString() => 'OpenAiServiceException: $message';
}
