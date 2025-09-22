import 'package:dio/dio.dart';

import '../config/environment.dart';
import 'secure_supabase_client.dart';

/// Wraps [Dio] to enforce that outbound API calls include a short-lived token
/// acquired from the secure Supabase Edge Function exchange.
class AuthenticatedHttpClient {
  AuthenticatedHttpClient({
    Dio? httpClient,
    SecureSupabaseClient? supabaseClient,
  })  : _httpClient = httpClient ?? Dio(),
        _supabaseClient =
            supabaseClient ?? SecureSupabaseClient(httpClient: Dio());

  final Dio _httpClient;
  final SecureSupabaseClient _supabaseClient;

  /// Executes a POST request to an external provider using a token minted by a
  /// Supabase Edge Function. The caller supplies the [edgeFunction] responsible
  /// for issuing the provider token.
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
      options: Options(
        headers: {
          'Authorization': 'Bearer $providerToken',
        },
      ),
    );
  }
}
