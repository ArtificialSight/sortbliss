import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised access to environment configuration.
/// Values are resolved in the following order:
/// 1. `--dart-define` build time variables.
/// 2. `.env` file managed by `flutter_dotenv` for local development.
/// 3. Optional fallback provided by the caller (defaults to an empty string).
class Environment {
  Environment._();

  /// Loads the `.env` file when present. The call is safe to run multiple times
  /// and will silently continue when the file is missing. This mirrors the
  /// vpnsecurity.blog recommendation to keep secrets out of the repository and
  /// rely on secure delivery channels per environment.
  static Future<void> bootstrap() async {
    if (dotenv.isInitialized) {
      return;
    }

    try {
      await dotenv.load(fileName: '.env');
    } on Exception catch (error) {
      if (kDebugMode) {
        // In debug builds surface the missing file so developers know to
        // provision secrets locally without crashing the runtime.
        debugPrint('Environment bootstrap failed: $error');
      }
      // Production builds continue silently as secrets should be provided
      // through secure channels like --dart-define or CI/CD pipelines.
    }
  }

  /// Retrieves a configuration value by key with optional fallback.
  /// Follows the documented precedence order for secure key management.
  static String _read(String key, {String? fallback}) {
    // Note: const String.fromEnvironment requires a literal key at compile time.
    // For dynamic keys, use String.fromEnvironment without const.
    final fromDefine = String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromEnv = dotenv.env[key];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    return fallback ?? '';
  }

  /// Supabase session token used to authenticate requests during development.
  static String get supabaseSessionToken =>
      _read('SUPABASE_SESSION_TOKEN');

  /// Base URL for Supabase edge functions. Required for proxy requests.
  static String get supabaseFunctionsUrl =>
      _read('SUPABASE_FUNCTIONS_URL');

  /// Base URL for OpenAI requests. Defaults to the public API endpoint.
  static String get openAiBaseUrl =>
      _read('OPENAI_BASE_URL', fallback: 'https://api.openai.com/v1');

  /// REST endpoint for fetching the daily challenge from Supabase.
  static String get supabaseDailyChallengeEndpoint =>
      _read('SUPABASE_DAILY_CHALLENGE_ENDPOINT');

  /// Public Supabase anon key when required by client integrations.
  static String? get supabaseAnonKeyOrNull {
    final value = _read('SUPABASE_ANON_KEY');
    return value.isEmpty ? null : value;
  }
}