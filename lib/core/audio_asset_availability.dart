import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AudioAssetAvailability {
  AudioAssetAvailability._internal();

  static final AudioAssetAvailability instance =
      AudioAssetAvailability._internal();

  final Map<String, bool> _assetCache = {};
  final Set<String> _manifestEntries = <String>{};
  bool _manifestLoaded = false;
  bool _manifestLoadFailed = false;
  bool _feedbackShown = false;
  final Set<String> _missingAssets = <String>{};
  void Function(String message)? _feedbackHandler;

  @visibleForTesting
  void registerFeedbackHandler(void Function(String message)? handler) {
    _feedbackHandler = handler;
  }

  @visibleForTesting
  void resetForTesting() {
    _assetCache.clear();
    _manifestEntries.clear();
    _manifestLoaded = false;
    _manifestLoadFailed = false;
    _feedbackShown = false;
    _missingAssets.clear();
    _feedbackHandler = null;
  }

  Future<bool> exists(String relativePath) async {
    final normalizedPath =
        relativePath.startsWith('assets/') ? relativePath : 'assets/$relativePath';

    if (_assetCache.containsKey(normalizedPath)) {
      return _assetCache[normalizedPath]!;
    }

    await _ensureManifestLoaded();

    final exists = _manifestEntries.contains(normalizedPath);
    _assetCache[normalizedPath] = exists;

    if (!exists) {
      _missingAssets.add(normalizedPath);
    }

    return exists;
  }

  bool get hasMissingAssets => _missingAssets.isNotEmpty;

  void notifyMissingAssets({bool isPremium = false}) {
    if (_feedbackShown) {
      return;
    }

    _feedbackShown = true;
    final message = isPremium
        ? 'Premium audio unavailable. Continuing without advanced sound.'
        : 'Audio assets unavailable. Sound has been disabled.';

    try {
      if (_feedbackHandler != null) {
        _feedbackHandler!(message);
      } else {
        Fluttertoast.showToast(msg: message);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Audio asset feedback error: $e');
      }
    }
  }

  Future<void> _ensureManifestLoaded() async {
    if (_manifestLoaded || _manifestLoadFailed) {
      return;
    }

    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestJson);
      _manifestEntries
        ..clear()
        ..addAll(manifestMap.keys);
      _manifestLoaded = true;
    } catch (e) {
      _manifestLoadFailed = true;
      if (kDebugMode) {
        debugPrint('Failed to load AssetManifest.json: $e');
      }
    }
  }
}
