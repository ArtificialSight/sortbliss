import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../analytics/analytics_logger.dart';
import 'monetization_manager.dart';

/// Handles loading and displaying Google Mobile Ads placements used within the
/// game. This wrapper ensures ad requests respect the ad-free entitlement and
/// surface analytics for every monetization touchpoint.
class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _initialised = false;
  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;
  bool _listenerAttached = false;

  // Test ad unit IDs (these are safe to use in any app)
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  Future<void> initialize() async {
    if (_initialised) return;
    await MobileAds.instance.initialize();
    _initialised = true;
    await _loadRewardedAd();
    await _loadInterstitialAd();
    
    if (!_listenerAttached) {
      _listenerAttached = true;
      MonetizationManager.instance.addListener(_handleMonetizationChanged);
    }
  }

  void _handleMonetizationChanged() {
    if (MonetizationManager.instance.isAdFree) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _interstitialAd?.dispose();
      _interstitialAd = null;
    } else {
      _loadRewardedAd();
      _loadInterstitialAd();
    }
  }

  Future<void> _loadRewardedAd() async {
    if (_loadingRewarded || MonetizationManager.instance.isAdFree) return;
    
    _loadingRewarded = true;
    await RewardedAd.load(
      adUnitId: _testRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loadingRewarded = false;
          AnalyticsLogger.logEvent('rewarded_loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _loadingRewarded = false;
          AnalyticsLogger.logEvent('rewarded_failed_to_load',
              parameters: {'code': error.code, 'message': error.message});
        },
      ),
    );
  }

  Future<void> _loadInterstitialAd() async {
    if (_loadingInterstitial || MonetizationManager.instance.isAdFree) return;
    
    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: _testInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _loadingInterstitial = false;
          AnalyticsLogger.logEvent('interstitial_loaded');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _loadingInterstitial = false;
          AnalyticsLogger.logEvent('interstitial_failed_to_load',
              parameters: {'code': error.code, 'message': error.message});
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdUnavailable,
    VoidCallback? onAdClosed,
  }) async {
    if (MonetizationManager.instance.isAdFree) {
      AnalyticsLogger.logEvent('rewarded_skipped_entitled');
      onAdUnavailable?.call();
      return;
    }

    if (_rewardedAd == null) {
      AnalyticsLogger.logEvent('rewarded_not_ready');
      await _loadRewardedAd();
      onAdUnavailable?.call();
      return;
    }

    AnalyticsLogger.logEvent('rewarded_show');
    final rewardedAd = _rewardedAd!;
    _rewardedAd = null;

    rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        AnalyticsLogger.logEvent('rewarded_impression');
      },
      onAdDismissedFullScreenContent: (_) {
        AnalyticsLogger.logEvent('rewarded_closed');
        rewardedAd.dispose();
        _loadRewardedAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        AnalyticsLogger.logEvent('rewarded_failed_to_show',
            parameters: {'message': error.message});
        rewardedAd.dispose();
        _loadRewardedAd();
        onAdClosed?.call();
      },
    );

    rewardedAd.show(onUserEarnedReward: (_, reward) {
      AnalyticsLogger.logEvent('rewarded_earned',
          parameters: {'amount': reward.amount, 'type': reward.type});
      onRewardEarned();
    });
  }

  Future<void> showInterstitialIfEligible() async {
    if (MonetizationManager.instance.isAdFree) {
      AnalyticsLogger.logEvent('interstitial_skipped_entitled');
      return;
    }

    final interstitial = _interstitialAd;
    if (interstitial == null) {
      AnalyticsLogger.logEvent('interstitial_not_ready');
      await _loadInterstitialAd();
      return;
    }

    AnalyticsLogger.logEvent('interstitial_show');
    _interstitialAd = null;

    final completer = Completer<void>();
    interstitial.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        AnalyticsLogger.logEvent('interstitial_impression');
      },
      onAdDismissedFullScreenContent: (_) {
        AnalyticsLogger.logEvent('interstitial_closed');
        interstitial.dispose();
        _loadInterstitialAd();
        completer.complete();
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        AnalyticsLogger.logEvent('interstitial_failed_to_show',
            parameters: {'message': error.message});
        interstitial.dispose();
        _loadInterstitialAd();
        completer.complete();
      },
    );

    interstitial.show();
    await completer.future;
  }
}
