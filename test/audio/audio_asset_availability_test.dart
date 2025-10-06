import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sortbliss/core/audio_asset_availability.dart';

ByteData _byteDataFromString(String value) {
  final bytes = utf8.encode(value);
  return Uint8List.fromList(bytes).buffer.asByteData();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const manifest = '{"assets/audio/present.mp3": []}';

  setUp(() {
    AudioAssetAvailability.instance.resetForTesting();
    ServicesBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'AssetManifest.json') {
        return _byteDataFromString(manifest);
      }
      return null;
    });
  });

  tearDown(() {
    ServicesBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test('returns true when asset exists in manifest', () async {
    final exists = await AudioAssetAvailability.instance.exists('audio/present.mp3');
    expect(exists, isTrue);
    expect(AudioAssetAvailability.instance.hasMissingAssets, isFalse);
  });

  test('records missing asset and triggers feedback handler once', () async {
    String? capturedMessage;
    AudioAssetAvailability.instance
        .registerFeedbackHandler((message) => capturedMessage = message);

    final exists = await AudioAssetAvailability.instance.exists('audio/missing.mp3');
    expect(exists, isFalse);
    expect(AudioAssetAvailability.instance.hasMissingAssets, isTrue);

    AudioAssetAvailability.instance.notifyMissingAssets();
    expect(capturedMessage, isNotNull);

    capturedMessage = null;
    AudioAssetAvailability.instance.notifyMissingAssets();
    expect(capturedMessage, isNull);
  });
}
