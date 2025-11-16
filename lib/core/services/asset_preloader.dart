import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../analytics/analytics_logger.dart';
import '../telemetry/telemetry_manager.dart';

/// Service for preloading assets to improve perceived performance
/// Caches images, fonts, and other assets for instant access
class AssetPreloader {
  AssetPreloader._();
  static final AssetPreloader instance = AssetPreloader._();

  final Set<String> _preloadedImages = {};
  bool _initialized = false;

  /// Initialize and preload critical assets
  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;
    _initialized = true;

    final trace = TelemetryManager.instance.startTrace('asset_preload');

    try {
      await Future.wait([
        _preloadCriticalImages(context),
        _preloadFonts(),
      ]);

      trace.setMetric('images_preloaded', _preloadedImages.length);
      trace.stop();

      AnalyticsLogger.logEvent('assets_preloaded', parameters: {
        'image_count': _preloadedImages.length,
      });
    } catch (e) {
      AnalyticsLogger.logEvent('asset_preload_failed', parameters: {
        'error': e.toString(),
      });
      trace.stop();
    }
  }

  /// Preload critical images (app logo, common UI elements)
  Future<void> _preloadCriticalImages(BuildContext context) async {
    final imagesToPreload = [
      'assets/img_app_logo.svg',
      // Add more critical images here
    ];

    for (final imagePath in imagesToPreload) {
      try {
        if (imagePath.endsWith('.svg')) {
          // SVG files don't need precaching (they're loaded on demand)
          continue;
        }

        await precacheImage(AssetImage(imagePath), context);
        _preloadedImages.add(imagePath);
      } catch (e) {
        // Image might not exist, continue silently
        continue;
      }
    }
  }

  /// Preload custom fonts
  Future<void> _preloadFonts() async {
    // Google Fonts are automatically cached, but we can ensure they're loaded
    // by triggering a paint with the font
    // This is handled automatically by the google_fonts package
  }

  /// Preload images for the next level (call during level complete screen)
  Future<void> preloadNextLevelAssets(
    BuildContext context, {
    required int nextLevelNumber,
  }) async {
    final trace = TelemetryManager.instance.startTrace('next_level_preload');

    try {
      // Preload any level-specific assets
      // This is a placeholder - implement based on your level structure
      final levelAssets = _getLevelAssets(nextLevelNumber);

      for (final asset in levelAssets) {
        if (!_preloadedImages.contains(asset)) {
          try {
            await precacheImage(AssetImage(asset), context);
            _preloadedImages.add(asset);
          } catch (e) {
            // Asset might not exist
            continue;
          }
        }
      }

      trace.setMetric('level', nextLevelNumber);
      trace.setMetric('assets_loaded', levelAssets.length);
      trace.stop();

      AnalyticsLogger.logEvent('next_level_assets_preloaded', parameters: {
        'level': nextLevelNumber,
        'asset_count': levelAssets.length,
      });
    } catch (e) {
      trace.stop();
    }
  }

  List<String> _getLevelAssets(int levelNumber) {
    // Return list of assets needed for the level
    // This is a placeholder - customize based on your game's needs
    return [];
  }

  /// Preload audio assets (load into memory for instant playback)
  Future<void> preloadAudio(List<String> audioFiles) async {
    for (final audioFile in audioFiles) {
      try {
        // Load audio file into memory
        await rootBundle.load('assets/audio/$audioFile');

        AnalyticsLogger.logEvent('audio_preloaded', parameters: {
          'file': audioFile,
        });
      } catch (e) {
        // Audio file might not exist
        continue;
      }
    }
  }

  /// Clear preloaded assets to free memory (call on app pause)
  void clearCache() {
    _preloadedImages.clear();
    imageCache.clear();
    imageCache.clearLiveImages();

    AnalyticsLogger.logEvent('asset_cache_cleared');
  }

  /// Get memory usage of image cache
  int getCacheSize() {
    return imageCache.currentSize;
  }

  /// Get max cache size
  int getMaxCacheSize() {
    return imageCache.maximumSize;
  }
}
