import 'package:flutter_test/flutter_test.dart';

import 'package:sortbliss/core/services/ai/ai_provider.dart';
import 'package:sortbliss/core/services/ai/composite_provider.dart';
import 'package:sortbliss/core/services/ai/ai_errors.dart';

class _FailingProvider implements AIProvider {
  _FailingProvider(this.name);
  @override
  final String name;
  @override
  Future<String> createChatCompletion({
    required List<AIMessage> messages,
    String? model,
    double? temperature,
  }) async {
    throw AIUnauthorizedError('fail');
  }
}

class _SuccessProvider implements AIProvider {
  @override
  String get name => 'success';
  @override
  Future<String> createChatCompletion({
    required List<AIMessage> messages,
    String? model,
    double? temperature,
  }) async => 'OK';
}

void main() {
  test('composite falls through to success provider', () async {
    final composite = CompositeAIProvider([
      _FailingProvider('p1'),
      _FailingProvider('p2'),
      _SuccessProvider(),
    ]);
    final result = await composite.createChatCompletion(
      messages: const [AIMessage(role: 'user', content: 'hi')],
    );
    expect(result, 'OK');
  });
}
