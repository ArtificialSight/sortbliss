import 'ai_errors.dart';

/// A single message exchanged with an AI provider.
class AIMessage {
  const AIMessage({required this.role, required this.content});
  final String role; // e.g. system|user|assistant
  final String content;
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Contract for AI providers (OpenAI, Anthropic, etc.).
abstract class AIProvider {
  String get name;

  /// Creates a chat completion and returns the assistant reply text.
  Future<String> createChatCompletion({
    required List<AIMessage> messages,
    String? model,
    double? temperature,
  });
}

/// Manages multiple providers, enabling fallback or targeted execution.
class AIProviderRegistry {
  final Map<String, AIProvider> _providers = {};

  void register(AIProvider provider) => _providers[provider.name] = provider;

  AIProvider provider(String name) {
    final p = _providers[name];
    if (p == null) {
      throw AIError('Provider not registered: $name');
    }
    return p;
  }
}
