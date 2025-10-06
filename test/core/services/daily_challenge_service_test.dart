import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortbliss/core/services/daily_challenge_service.dart';

void main() {
  group('DailyChallengeService', () {
    test('fetches challenge data from configured Supabase endpoint', () async {
      final resetAt =
          DateTime.now().toUtc().add(const Duration(hours: 2)).toIso8601String();
      final responsePayload = [
        {
          'id': 'challenge-123',
          'title': 'Test Challenge',
          'description': 'Complete the puzzle fast',
          'target_stars': 5,
          'current_stars': 2,
          'reset_at': resetAt,
          'rewards': [
            {
              'type': 'coins',
              'amount': 100,
              'is_exclusive': false,
            }
          ],
          'level_config': {
            'layout_id': 'layout-1',
            'difficulty': 3,
            'modifiers': ['double_points'],
            'metadata': <String, dynamic>{},
          },
          'rewards_claimed': false,
        }
      ];

      final adapter = _RecordingAdapter(
        responseBody: ResponseBody.fromString(
          jsonEncode(responsePayload),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      final dio = Dio()..httpClientAdapter = adapter;

      final service = DailyChallengeService(
        httpClient: dio,
        supabaseRestEndpoint:
            'https://example.supabase.co/rest/v1/daily_challenge',
        supabaseAnonKey: 'anon-key',
      );

      addTearDown(() async {
        await service.dispose();
      });

      final result = await service.loadDailyChallenge(forceRefresh: true);

      expect(adapter.lastRequest, isNotNull);
      expect(
        adapter.lastRequest!.uri.toString(),
        'https://example.supabase.co/rest/v1/daily_challenge',
      );
      expect(adapter.lastRequest!.headers['apikey'], 'anon-key');
      expect(result.id, 'challenge-123');
      expect(result.rewards, isNotEmpty);
    });
  });
}

class _RecordingAdapter extends HttpClientAdapter {
  _RecordingAdapter({required this.responseBody});

  final ResponseBody responseBody;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return responseBody;
  }
}
