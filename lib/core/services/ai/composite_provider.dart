import 'ai_provider.dart';
import 'ai_errors.dart';
import 'ai_debug.dart';

/// Attempts providers in order until one succeeds. Collects errors and throws
/// the last error if all fail.
class CompositeAIProvider implements AIProvider {
  CompositeAIProvider(this.providers, {this.name = 'composite'});
  @override
  final String name;
  final List<AIProvider> providers;

  @override
  Future<String> createChatCompletion({
    required List<AIMessage> messages,
    String? model,
    double? temperature,
  }) async {
    AIError? lastError;
    for (final p in providers) {
      try {
        aiDebug('[composite] trying provider=${p.name}');
        final result = await p.createChatCompletion(
          messages: messages,
          model: model,
          temperature: temperature,
        );
        return result;
      } on AIError catch (e) {
        lastError = e;
        aiDebug('[composite] provider=${p.name} failed: ${e.message}');
      }
    }
    throw lastError ?? AIError('All providers failed');
  }
}
