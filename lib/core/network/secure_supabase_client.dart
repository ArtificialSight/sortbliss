import 'package:dio/dio.dart';

import '../config/environment.dart';

class TokenExchangeException implements Exception {
  const TokenExchangeException(this.message);
  final String message;
  @override
  String toString() => 'TokenExchangeException: $message';
}

/// Proxy for interacting with Supabase Edge Functions that mint short-lived
/// service tokens for provider APIs (OpenAI, etc.).
class SecureSupabaseClient {
  SecureSupabaseClient({Dio? httpClient}) : _httpClient = httpClient ?? Dio();
  final Dio _httpClient;

  Future<String> fetchServiceToken({
    required String edgeFunction,
    required String sessionToken,
  }) async {
    if (sessionToken.isEmpty) {
      throw const TokenExchangeException('Missing Supabase session token.');
    }

    final baseUrl = Environment.supabaseFunctionsUrl;
    if (baseUrl.isEmpty) {
      throw const TokenExchangeException(
        'SUPABASE_FUNCTIONS_URL missing. Provide via --dart-define or .env.',
      );
    }

    final response = await _httpClient.post<Map<String, dynamic>>(
      '$baseUrl/functions/v1/$edgeFunction',
      options: Options(headers: {
        'Authorization': 'Bearer $sessionToken',
      }),
    );

    final data = response.data ?? const <String, dynamic>{};
    final token = data['token'] as String? ?? '';
    final expires = data['expiresIn'] as int?;
    if (token.isEmpty) {
      throw const TokenExchangeException('Edge function response missing token');
    }
    if (expires == null || expires <= 0) {
      throw const TokenExchangeException('Invalid expiresIn in edge response');
    }
    return token;
  }
}
