import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ads/ad_service.dart';
import '../../services/ads/ad_size_settings.dart';
import '../../services/ads/ads_entitlement_controller.dart';

/// Responsive, entitlement-aware banner slot shared by all app placements.
class AdBannerPlacement extends StatefulWidget {
  const AdBannerPlacement({super.key, this.padding = EdgeInsets.zero})
    : _supportedOverride = null;

  @visibleForTesting
  const AdBannerPlacement.forTesting({
    super.key,
    this.padding = EdgeInsets.zero,
  }) : _supportedOverride = true;

  final EdgeInsetsGeometry padding;
  final bool? _supportedOverride;

  @override
  State<AdBannerPlacement> createState() => _AdBannerPlacementState();
}

class _AdBannerPlacementState extends State<AdBannerPlacement> {
  BannerAd? _banner;
  AdSize? _size;
  bool _loaded = false;
  bool _resolvingSize = false;
  Timer? _retryTimer;
  int? _layoutWidth;
  Orientation? _layoutOrientation;
  late final AdLoadGate _loadGate;

  bool get _supported =>
      widget._supportedOverride ?? AdService.isSupportedPlatform;

  @override
  void initState() {
    super.initState();
    _loadGate = AdLoadGate(AdsEntitlementController.instance);
    AdsEntitlementController.instance.addListener(_onStateChanged);
    AdSizeSettings.instance.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant AdBannerPlacement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.padding != widget.padding) _reload();
  }

  void _onStateChanged() {
    if (!mounted) return;
    if (!AdsEntitlementController.instance.canRequestAds) {
      _clear();
      setState(() {});
    } else {
      _reload();
    }
  }

  void _clear() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _loadGate.invalidate();
    _banner?.dispose();
    _banner = null;
    _size = null;
    _loaded = false;
    _resolvingSize = false;
  }

  void _reload() {
    _clear();
    if (mounted) setState(() {});
  }

  Future<void> _ensureLoaded(double width) async {
    final orientation = MediaQuery.orientationOf(context);
    final requestedWidth = width.floor();
    if (_layoutWidth != requestedWidth || _layoutOrientation != orientation) {
      _clear();
      _layoutWidth = requestedWidth;
      _layoutOrientation = orientation;
    }
    if (_banner != null ||
        !AdsEntitlementController.instance.canRequestAds ||
        !_supported ||
        _retryTimer != null ||
        _resolvingSize) {
      return;
    }
    _resolvingSize = true;
    final generation = _loadGate.beginAttempt();
    AdSize size;
    try {
      size = await AdSizeSettings.instance.resolveSize(
        requestedWidth,
        orientation: orientation,
      );
    } catch (_) {
      if (!mounted || !_loadGate.accepts(generation)) return;
      size = AdSize.banner;
    }
    if (!mounted || !_loadGate.accepts(generation)) return;
    _resolvingSize = false;
    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: AdService.bannerId,
      request: const AdRequest(nonPersonalizedAds: true),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted ||
              !_loadGate.accepts(generation) ||
              !identical(_banner, ad)) {
            ad.dispose();
            return;
          }
          if (kDebugMode) {
            debugPrint(
              '[Ads] banner.loaded width=${size.width} height=${size.height} '
              'orientation=${orientation.name}',
            );
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failedAd, error) {
          if (kDebugMode) {
            debugPrint('[Ads] banner.load.failed code=${error.code}');
          }
          _handleLoadFailure(ad, generation);
        },
      ),
    );
    _banner = ad;
    _size = size;
    if (kDebugMode) {
      debugPrint(
        '[Ads] banner.load.requested width=${size.width} height=${size.height} '
        'orientation=${orientation.name}',
      );
    }
    unawaited(_loadBanner(ad, generation));
  }

  void _handleLoadFailure(BannerAd ad, int generation) {
    unawaited(ad.dispose().catchError((Object _) {}));
    if (!mounted || !_loadGate.accepts(generation) || !identical(_banner, ad))
      return;
    // A channel error and an SDK callback must not create two retry timers.
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      _retryTimer = null;
      if (mounted && _loadGate.accepts(generation)) setState(() {});
    });
    setState(() {
      _banner = null;
      _size = null;
      _loaded = false;
    });
  }

  Future<void> _loadBanner(BannerAd ad, int generation) async {
    try {
      await ad.load();
    } catch (_) {
      _handleLoadFailure(ad, generation);
    }
  }

  @override
  void dispose() {
    AdsEntitlementController.instance.removeListener(_onStateChanged);
    AdSizeSettings.instance.removeListener(_onStateChanged);
    _loadGate.dispose();
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdsEntitlementController.instance.canRequestAds ||
        !_supported ||
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
        final horizontalInsets =
            widget.padding.resolve(Directionality.of(context)).horizontal;
        final safeInsets = MediaQuery.paddingOf(context);
        final contentWidth = width - horizontalInsets - safeInsets.horizontal;
        if (contentWidth < 320) return const SizedBox.shrink();
        _ensureLoaded(contentWidth);
        final banner = _banner;
        final size = _size;
        if (!_loaded || banner == null || size == null) {
          return const SizedBox.shrink();
        }
        final actualHeight = size.height.toDouble();
        return SafeArea(
          top: false,
          child: Padding(
            padding: widget.padding,
            child: Center(
              heightFactor: 1,
              child: SizedBox(
                width: size.width.toDouble(),
                height: actualHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AdWidget(ad: banner),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
