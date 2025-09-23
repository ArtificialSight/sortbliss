import 'package:dio/dio.dart';

import '../config/environment.dart';

class TokenExchangeException implements Exception {
  const TokenExchangeException(this.message);
  
  final String message;

  @override
  String toString() => 'TokenExchangeException: $message';
}

/// Provides a hardened proxy for interacting with Supabase Edge Functions that
/// mint short-lived service tokens.
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
        'SUPABASE_FUNCTIONS_URL is not configured. Provide it via --dart-define or .env.',
      );
    }

    final response = await _httpClient.post<Map<String, dynamic>>(
      '$baseUrl/functions/v1/$edgeFunction',
      options: Options(
        headers: {
          'Authorization': 'Bearer $sessionToken',
        },
      ),
    );

    final payload = response.data ?? const <String, dynamic>{};
    final token = payload['token'] as String? ?? '';
    final expiresIn = payload['expiresIn'] as int?;

    if (token.isEmpty) {
      throw const TokenExchangeException(
        'Edge function response did not include a token.',
      );
    }

    if (expiresIn == null || expiresIn <= 0) {
      throw const TokenExchangeException(
        'Edge function response must include a positive expiresIn value.',
      );
    }

    return token;
  }
}