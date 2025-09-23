import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortbliss/core/services/openai_proxy_service.dart';
import 'package:sortbliss/core/services/ai/ai_provider.dart';
import 'package:sortbliss/core/services/ai/ai_errors.dart';
import 'package:sortbliss/core/config/environment.dart';

class _FakeDio extends Fake implements Dio {
  _FakeDio(this._response);
  final Response<Map<String, dynamic>> _response;

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
    return Response<T>(
      data: _response.data as T?,
      statusCode: _response.statusCode,
      requestOptions: RequestOptions(path: path),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OpenAiProxyService', () {
    setUp(() async {
      // Simulate environment being loaded with required URLs & token.
      Environment.bootstrap();
    });

    test('parses successful response', () async {
      final dio = _FakeDio(Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {
          'data': {
            'choices': [
              {
                'message': {'content': 'Proxy Hello'}
              }
            ]
          }
        },
      ));

      final service = OpenAiProxyService(http: dio as Dio);
      final result = await service.createChatCompletion(
        messages: const [AIMessage(role: 'user', content: 'Hi')],
      );
      expect(result, 'Proxy Hello');
    });

    test('throws parsing error with empty choices', () async {
      final dio = _FakeDio(Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {
          'data': {
            'choices': []
          }
        },
      ));

      final service = OpenAiProxyService(http: dio as Dio);
      expect(
        () => service.createChatCompletion(
          messages: const [AIMessage(role: 'user', content: 'Hi')],
        ),
        throwsA(isA<AIError>()),
      );
    });
  });
}
