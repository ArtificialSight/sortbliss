import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortbliss/core/config/environment.dart';
import 'package:sortbliss/core/services/ai/ai_provider.dart';
import 'package:sortbliss/core/services/openai_proxy_stream_service.dart';

class _FakeStreamDio extends Fake implements Dio {
  _FakeStreamDio(this._response);

  final Response<ResponseBody> _response;

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

  group('OpenAiProxyStreamService', () {
    setUp(() async {
      await dotenv.testLoad(
        fileInput:
            'SUPABASE_SESSION_TOKEN=dummy\nSUPABASE_FUNCTIONS_URL=https://example.test',
      );
      Environment.bootstrap();
    });

    tearDown(() {
      dotenv.reset();
    });

    test('emits tokens from SSE data events', () async {
      final responseBody = ResponseBody(
        Stream<List<int>>.fromIterable([
          utf8.encode(
              'data: {"choices":[{"delta":{"content":"Hel"}}]}\n\n'),
          utf8.encode(
              'data: {"choices":[{"delta":{"content":"lo"}}]}\n\n'),
          utf8.encode('data: [DONE]\n\n'),
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: ['text/event-stream'],
        },
      );

      final dio = _FakeStreamDio(
        Response<ResponseBody>(
          data: responseBody,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final service = OpenAiProxyStreamService(http: dio);

      final tokens = await service.streamChatCompletion(
        messages: const [AIMessage(role: 'user', content: 'Hello')],
      ).toList();

      expect(tokens, ['Hel', 'lo']);
    });
  });
}
