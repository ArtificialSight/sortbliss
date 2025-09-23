import 'package:dio/dio.dart';

import '../config/environment.dart';
import 'secure_supabase_client.dart';

/// Enforces outbound calls include short-lived provider token fetched via a
/// Supabase Edge Function guarded by a valid session token.
class AuthenticatedHttpClient {
  AuthenticatedHttpClient({
    Dio? httpClient,
    SecureSupabaseClient? supabaseClient,
  })  : _httpClient = httpClient ?? Dio(),
        _supabaseClient = supabaseClient ?? SecureSupabaseClient();

  final Dio _httpClient;
  final SecureSupabaseClient _supabaseClient;

  Future<Response<T>> postWithEdgeToken<T>(
    String url, {
    required String edgeFunction,
    Map<String, dynamic>? body,
  }) async {
    final sessionToken = Environment.supabaseSessionToken;
    final providerToken = await _supabaseClient.fetchServiceToken(
      edgeFunction: edgeFunction,
      sessionToken: sessionToken,
    );

    return _httpClient.post<T>(
      url,
      data: body,
      options: Options(headers: {
        'Authorization': 'Bearer $providerToken',
      }),
    );
  }
}
