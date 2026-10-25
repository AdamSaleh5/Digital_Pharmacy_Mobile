import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ads/ad_service.dart';
import '../../services/ads/ad_load_diagnostics.dart';
import '../../services/ads/ads_entitlement_controller.dart';
import 'ad_banner_placement.dart';

/// Only real content rows count toward the interval; spacing belongs to the ad
/// so a hidden/failed placement leaves neither a placeholder nor an empty gap.
List<Widget> interleaveNativeAds(Iterable<Widget> rows) {
  final result = <Widget>[];
  var index = 0;
  for (final row in rows) {
    if (index > 0 && index % 10 == 0) {
      result.add(const InlineNativeAdCard());
    }
    result.add(row);
    index++;
  }
  return result;
}

class InlineNativeAdCard extends StatefulWidget {
  const InlineNativeAdCard({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 8),
  }) : _supportedOverride = null,
       _loadTimeout = const Duration(seconds: 30);

  @visibleForTesting
  const InlineNativeAdCard.forTesting({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 8),
    Duration loadTimeout = const Duration(seconds: 30),
  }) : _supportedOverride = true,
       _loadTimeout = loadTimeout;

  final EdgeInsetsGeometry padding;
  final bool? _supportedOverride;
  final Duration _loadTimeout;

  @override
  State<InlineNativeAdCard> createState() => _InlineNativeAdCardState();
}

class _InlineNativeAdCardState extends State<InlineNativeAdCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _failed = false;
  bool _hasSpace = false;
  bool _loadScheduled = false;
  Timer? _loadDeadline;
  late final AdLoadGate _loadGate;

  bool get _supported =>
      widget._supportedOverride ?? AdService.isSupportedPlatform;

  @override
  void initState() {
    super.initState();
    _loadGate = AdLoadGate(AdsEntitlementController.instance);
    AdsEntitlementController.instance.addListener(_onEntitlementChanged);
  }

  void _disposeAd(Ad ad) {
    unawaited(ad.dispose().catchError((Object _) {}));
  }

  void _clear() {
    _loadGate.invalidate();
    _loadDeadline?.cancel();
    _loadDeadline = null;
    final ad = _nativeAd;
    _nativeAd = null;
    _isLoaded = false;
    if (ad != null) _disposeAd(ad);
  }

  void _onEntitlementChanged() {
    if (!mounted) return;
    _clear();
    setState(() {
      _failed = !AdsEntitlementController.instance.canRequestAds;
    });
  }

  bool _current(Ad ad, int generation) =>
      mounted && identical(_nativeAd, ad) && _loadGate.accepts(generation);

  void _fail(Ad ad, int generation) {
    if (!_current(ad, generation)) {
      _disposeAd(ad);
      return;
    }
    _clear();
    setState(() => _failed = true);
  }

  Future<void> _startLoad(NativeAd ad, int generation) async {
    try {
      await ad.load();
    } catch (_) {
      // A rejected method-channel Future need not emit the SDK failure callback.
      // Keep this slot hidden and contain the error instead of blocking content.
      _fail(ad, generation);
    }
  }

  void _loadIfAllowed() {
    if (!mounted ||
        !_supported ||
        !_hasSpace ||
        _failed ||
        _nativeAd != null ||
        !AdsEntitlementController.instance.canRequestAds) {
      return;
    }
    final generation = _loadGate.beginAttempt();
    final ad = AdService().createNativeAd(
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!_current(ad, generation)) {
            _disposeAd(ad);
            return;
          }
          _loadDeadline?.cancel();
          _loadDeadline = null;
          if (kDebugMode) debugPrint('[Ads] native.loaded');
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint(
              '[Ads] native.load.failed ${jsonEncode(adLoadFailureDiagnostics(error))}',
            );
          }
          _fail(ad, generation);
        },
      ),
    );
    _nativeAd = ad;
    _loadDeadline = Timer(widget._loadTimeout, () {
      if (kDebugMode) debugPrint('[Ads] native.load.deadline');
      _fail(ad, generation);
    });
    if (kDebugMode) debugPrint('[Ads] native.load.requested');
    unawaited(_startLoad(ad, generation));
  }

  @override
  void dispose() {
    AdsEntitlementController.instance.removeListener(_onEntitlementChanged);
    _clear();
    _loadGate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdsEntitlementController.instance.canRequestAds || !_supported) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth -
            widget.padding.resolve(Directionality.of(context)).horizontal;
        if (!width.isFinite || width < 320) {
          if (_hasSpace) _clear();
          _hasSpace = false;
          return const SizedBox.shrink();
        }
        if (!_hasSpace) {
          _hasSpace = true;
          _failed = false;
        }
        if (!_failed && _nativeAd == null && !_loadScheduled) {
          _loadScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadScheduled = false;
            _loadIfAllowed();
          });
        }
        final ad = _nativeAd;
        if (_failed) {
          // Native inventory can fail independently of banner inventory. Use
          // the existing gated banner slot; it occupies space only when loaded.
          return widget._supportedOverride == true
              // Forward the explicit test platform override to the child slot.
              // ignore: invalid_use_of_visible_for_testing_member
              ? AdBannerPlacement.forTesting(padding: widget.padding)
              : AdBannerPlacement(padding: widget.padding);
        }
        if (!_isLoaded || ad == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: widget.padding,
          child: Center(
            heightFactor: 1,
            child: SizedBox(
              width: math.min(width, 400),
              height: 120,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: AdWidget(ad: ad),
              ),
            ),
          ),
        );
      },
    );
  }
}
