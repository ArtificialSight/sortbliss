import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortbliss/core/services/openai_service.dart';
import 'package:sortbliss/core/services/ai/ai_provider.dart';
import 'package:sortbliss/core/services/ai/ai_errors.dart';

class _MockSecureClient extends Fake {
  Future<String> fetchServiceToken({
    required String edgeFunction,
    required String sessionToken,
  }) async => 'ephemeral-token';
}

class _MockDio extends Fake implements Dio {
  _MockDio(this._handler);
  final Response<Map<String, dynamic>> Function(RequestOptions options) _handler;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    final resp = _handler(RequestOptions(path: path));
    return Response<T>(
      data: resp.data as T?,
      statusCode: resp.statusCode,
      requestOptions: resp.requestOptions,
    );
  }
}

void main() {
  group('OpenAiService', () {
    test('returns message content on success', () async {
      final dio = _MockDio((_) => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'choices': [
                {
                  'message': {'content': 'Hello'}
                }
              ]
            },
          ));
      final service = OpenAiService(
        http: dio as Dio,
        secureClient: _MockSecureClient() as dynamic,
      );
      final result = await service.createChatCompletion(
        messages: const [AIMessage(role: 'user', content: 'Hi')],
      );
      expect(result, 'Hello');
    });

    test('throws parsing error when no choices', () async {
      final dio = _MockDio((_) => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {},
          ));
      final service = OpenAiService(
        http: dio as Dio,
        secureClient: _MockSecureClient() as dynamic,
      );
      expect(
        () => service.createChatCompletion(
          messages: const [AIMessage(role: 'user', content: 'Hi')],
        ),
        throwsA(isA<AIError>()),
      );
    });
  });
}
