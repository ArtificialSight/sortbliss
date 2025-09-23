import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised access to environment configuration.
///
/// Resolution order:
/// 1. `--dart-define` build time variables.
/// 2. `.env` file values via `flutter_dotenv` for local dev.
/// 3. Provided fallback (defaults to empty string).
class Environment {
  Environment._();

  static Future<void> bootstrap() async {
    if (dotenv.isInitialized) return;
    try {
      await dotenv.load(fileName: '.env');
    } catch (error) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('dotenv bootstrap skipped: $error');
      }
    }
  }

  static String _read(String key, {String? fallback}) {
    final fromDefine = const String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromEnv = dotenv.env[key];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return fallback ?? '';
  }

  static String get supabaseUrl => _read('SUPABASE_URL');
  static String get supabaseFunctionsUrl =>
      _read('SUPABASE_FUNCTIONS_URL', fallback: supabaseUrl);
  static String get supabaseSessionToken => _read('SUPABASE_SESSION_TOKEN');

  static String get openAiSessionToken => _read('OPENAI_SESSION_TOKEN');
  static String get geminiSessionToken => _read('GEMINI_SESSION_TOKEN');
  static String get anthropicSessionToken => _read('ANTHROPIC_SESSION_TOKEN');
  static String get perplexitySessionToken => _read('PERPLEXITY_SESSION_TOKEN');
}
