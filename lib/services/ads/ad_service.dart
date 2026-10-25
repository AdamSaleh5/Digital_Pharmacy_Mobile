import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/utils/app_constants.dart';
import 'ads_entitlement_controller.dart';

class AdService {
  factory AdService() => instance;
  AdService._() : this._withPlatformCheck(null);
  AdService._withPlatformCheck(this._platformCheck) {
    _interstitialLoadGate = AdLoadGate(AdsEntitlementController.instance);
    _appOpenLoadGate = AdLoadGate(AdsEntitlementController.instance);
    AdsEntitlementController.instance.addListener(_onEntitlementChanged);
  }
  static final AdService instance = AdService._();
  @visibleForTesting
  factory AdService.forTesting({required bool Function() isSupported}) =>
      AdService._withPlatformCheck(isSupported);
  final bool Function()? _platformCheck;
  bool get _supported => _platformCheck?.call() ?? isSupportedPlatform;

  static bool get isSupportedPlatform => Platform.isAndroid || Platform.isIOS;
  bool get adsAllowed => AdsEntitlementController.instance.canRequestAds;

  // Debug/profile use Google demo units. Release uses this project's publisher
  // units, recovered from the repository's original AdMob configuration.
  static String get bannerId {
    if (kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3456400512213896/1767331324'
          : 'ca-app-pub-3456400512213896/2425952666';
    }
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    return 'ca-app-pub-3940256099942544/2934735716';
  }

  static String get interstitialId {
    if (kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3456400512213896/2070583650'
          : 'ca-app-pub-3456400512213896/8085327663';
    }
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    return 'ca-app-pub-3940256099942544/4411468910';
  }

  static String get nativeId {
    if (kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3456400512213896/3056362265'
          : 'ca-app-pub-3456400512213896/4146082651';
    }
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/2247696110';
    return 'ca-app-pub-3940256099942544/3986624511';
  }

  static String get appOpenId {
    if (kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3456400512213896/4529226037'
          : 'ca-app-pub-3456400512213896/3930460234';
    }
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/9257395921';
    return 'ca-app-pub-3940256099942544/5575463023';
  }

  BannerAd createBannerAd({BannerAdListener? listener}) {
    return BannerAd(
      adUnitId: bannerId,
      request: const AdRequest(nonPersonalizedAds: true),
      size: AdSize.banner,
      listener: listener ?? const BannerAdListener(),
    );
  }

  NativeAd createNativeAd({
    NativeAdListener? listener,
    TemplateType templateType = TemplateType.small,
  }) {
    return NativeAd(
      adUnitId: nativeId,
      request: const AdRequest(nonPersonalizedAds: true),
      nativeTemplateStyle: NativeTemplateStyle(templateType: templateType),
      listener: listener ?? NativeAdListener(),
    );
  }

  InterstitialAd? _interstitial;
  InterstitialAd? _showingInterstitialAd;
  late final AdLoadGate _interstitialLoadGate;
  bool _loadingInterstitial = false;
  DateTime? _lastInterstitialShownAt;
  AppOpenAd? _appOpenAd;
  AppOpenAd? _showingAppOpenAd;
  late final AdLoadGate _appOpenLoadGate;
  final LaunchAdOpportunity _launchOpportunity = LaunchAdOpportunity();
  bool _loadingAppOpen = false;
  bool _showingAppOpen = false;

  void _disposeAd(Ad? ad) {
    if (ad != null) unawaited(ad.dispose().catchError((Object _) {}));
  }

  void _onEntitlementChanged() {
    if (adsAllowed) {
      loadInterstitial();
      return;
    }
    _loadingInterstitial = false;
    _loadingAppOpen = false;
    _launchOpportunity.cancel();
    _disposeAd(_interstitial);
    _interstitial = null;
    _disposeAd(_showingInterstitialAd);
    _showingInterstitialAd = null;
    _disposeAd(_appOpenAd);
    _appOpenAd = null;
    _disposeAd(_showingAppOpenAd);
    _showingAppOpenAd = null;
    _showingAppOpen = false;
  }

  void loadInterstitial() {
    if (!_supported || !adsAllowed) return;
    if (_loadingInterstitial ||
        _interstitial != null ||
        _showingInterstitialAd != null) {
      return;
    }
    _loadingInterstitial = true;
    final generation = _interstitialLoadGate.beginAttempt();

    unawaited(
      InterstitialAd.load(
        adUnitId: interstitialId,
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!_interstitialLoadGate.accepts(generation)) {
              _disposeAd(ad);
              return;
            }
            _interstitial = ad;
            _loadingInterstitial = false;
            if (kDebugMode) debugPrint('[Ads] interstitial.loaded');
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
              debugPrint('[Ads] interstitial.load.failed code=${error.code}');
            }
            if (!_interstitialLoadGate.accepts(generation)) return;
            _interstitial = null;
            _loadingInterstitial = false;
          },
        ),
      ).catchError((Object _) {
        if (!_interstitialLoadGate.accepts(generation)) return;
        _interstitialLoadGate.invalidate();
        _loadingInterstitial = false;
        if (kDebugMode) debugPrint('[Ads] interstitial.load.channel-failed');
      }),
    );
  }

  bool showInterstitialIfReady() {
    if (!_supported || !adsAllowed) return false;
    final ad = _interstitial;
    if (ad == null) return false;
    final lastShown = _lastInterstitialShownAt;
    if (lastShown != null) {
      final secondsSinceLast = DateTime.now().difference(lastShown).inSeconds;
      if (secondsSinceLast < AppConstants.interstitialMinIntervalSeconds) {
        return false;
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (shown) {
        if (identical(_showingInterstitialAd, shown)) {
          _lastInterstitialShownAt = DateTime.now();
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        if (!identical(_showingInterstitialAd, ad)) {
          _disposeAd(ad);
          return;
        }
        if (kDebugMode) debugPrint('[Ads] interstitial.dismissed');
        _disposeAd(ad);
        _showingInterstitialAd = null;
        _interstitial = null;
        if (adsAllowed) loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        if (!identical(_showingInterstitialAd, ad)) {
          _disposeAd(ad);
          return;
        }
        if (kDebugMode) {
          debugPrint('[Ads] interstitial.show.failed code=${err.code}');
        }
        _disposeAd(ad);
        _showingInterstitialAd = null;
        _interstitial = null;
        if (adsAllowed) loadInterstitial();
      },
    );

    _showingInterstitialAd = ad;
    _interstitial = null;
    unawaited(
      _dispatchInterstitialShow(ad, _interstitialLoadGate.beginAttempt()),
    );
    return true;
  }

  Future<void> _dispatchInterstitialShow(
    InterstitialAd ad,
    int generation,
  ) async {
    // Re-check after a client-queued show, before dispatching to the native SDK.
    // Already-dispatched native overlays cannot be forcibly closed by this API.
    await Future<void>.value();
    if (!_interstitialLoadGate.accepts(generation) ||
        !identical(_showingInterstitialAd, ad)) {
      _disposeAd(ad);
      return;
    }
    try {
      if (kDebugMode) debugPrint('[Ads] interstitial.show.requested');
      await ad.show();
    } catch (_) {
      if (!identical(_showingInterstitialAd, ad)) return;
      _showingInterstitialAd = null;
      _disposeAd(ad);
      if (kDebugMode) debugPrint('[Ads] interstitial.show.channel-failed');
    }
  }

  void disposeInterstitial() {
    _interstitialLoadGate.invalidate();
    _loadingInterstitial = false;
    _disposeAd(_interstitial);
    _interstitial = null;
  }

  void loadAppOpen() {
    // No dedicated loading screen exists; do not request/show this format.
    if (!AppConstants.appOpenAdsEnabled) return;
    if (!_supported || !adsAllowed) return;
    if (_loadingAppOpen || _appOpenAd != null) return;
    _loadingAppOpen = true;
    final generation = _appOpenLoadGate.beginAttempt();
    unawaited(
      AppOpenAd.load(
        adUnitId: appOpenId,
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            if (!_appOpenLoadGate.accepts(generation)) {
              _disposeAd(ad);
              return;
            }
            _appOpenAd = ad;
            _loadingAppOpen = false;
          },
          onAdFailedToLoad: (error) {
            if (!_appOpenLoadGate.accepts(generation)) return;
            _appOpenAd = null;
            _loadingAppOpen = false;
          },
        ),
      ).catchError((Object _) {
        if (!_appOpenLoadGate.accepts(generation)) return;
        _appOpenLoadGate.invalidate();
        _loadingAppOpen = false;
      }),
    );
  }

  void showLaunchAppOpenIfReady() {
    if (!AppConstants.appOpenAdsEnabled) return;
    if (!_supported || !adsAllowed) return;
    if (_launchOpportunity.take(
      adsAllowed: adsAllowed,
      adReady: _appOpenAd != null,
    )) {
      _showAppOpenIfReady();
    }
  }

  void _showAppOpenIfReady() {
    if (!_supported || !adsAllowed) return;
    if (_showingAppOpen) return;
    final ad = _appOpenAd;
    if (ad == null) return;
    _showingAppOpen = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        if (!identical(_showingAppOpenAd, ad)) {
          _disposeAd(ad);
          return;
        }
        _disposeAd(ad);
        _showingAppOpenAd = null;
        _appOpenAd = null;
        _showingAppOpen = false;
        if (adsAllowed) loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (!identical(_showingAppOpenAd, ad)) {
          _disposeAd(ad);
          return;
        }
        _disposeAd(ad);
        _showingAppOpenAd = null;
        _appOpenAd = null;
        _showingAppOpen = false;
        if (adsAllowed) loadAppOpen();
      },
    );
    _showingAppOpenAd = ad;
    _appOpenAd = null;
    unawaited(_dispatchAppOpenShow(ad, _appOpenLoadGate.beginAttempt()));
  }

  Future<void> _dispatchAppOpenShow(AppOpenAd ad, int generation) async {
    await Future<void>.value();
    if (!_appOpenLoadGate.accepts(generation) ||
        !identical(_showingAppOpenAd, ad)) {
      _disposeAd(ad);
      return;
    }
    try {
      await ad.show();
    } catch (_) {
      if (!identical(_showingAppOpenAd, ad)) return;
      _showingAppOpenAd = null;
      _showingAppOpen = false;
      _disposeAd(ad);
    }
  }

  void disposeAppOpen() {
    _appOpenLoadGate.invalidate();
    _loadingAppOpen = false;
    _disposeAd(_appOpenAd);
    _appOpenAd = null;
  }

  @visibleForTesting
  void disposeForTesting() {
    AdsEntitlementController.instance.removeListener(_onEntitlementChanged);
    _interstitialLoadGate.dispose();
    _appOpenLoadGate.dispose();
    disposeInterstitial();
    disposeAppOpen();
    _disposeAd(_showingInterstitialAd);
    _showingInterstitialAd = null;
    _disposeAd(_showingAppOpenAd);
    _showingAppOpenAd = null;
    _showingAppOpen = false;
  }
}
