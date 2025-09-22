import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised access to environment configuration.
///
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
        // ignore: avoid_print
        print('dotenv bootstrap skipped: $error');
      }
    }
  }

  static String _read(String key, {String? fallback}) {
    final fromDefine = const String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    final fromEnv = dotenv.env[key];
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

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
