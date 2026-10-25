// Isolated debug entrypoint. Never used by lib/main.dart or a release build.
// NativeAd/NativeTemplateStyle lifecycle follows google_mobile_ads 5.3.1's
// bundled example/lib/native_template_example.dart. Retain the app's AdMob
// demo unit and non-personalized request to isolate Dart orchestration only.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:digitalpharmacy/services/ads/ad_load_diagnostics.dart';

void main() {
  if (!kDebugMode) throw StateError('Native control requires a debug build.');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: NativeControl()));
}

class NativeControl extends StatefulWidget {
  const NativeControl({super.key});

  @override
  State<NativeControl> createState() => _NativeControlState();
}

class _NativeControlState extends State<NativeControl> {
  static const _medium = bool.fromEnvironment('NATIVE_CONTROL_MEDIUM');
  NativeAd? _ad;
  bool _loaded = false;
  String _status = 'Waiting for real UMP permission';

  @override
  void initState() {
    super.initState();
    unawaited(_loadOnce());
  }

  Future<void> _loadOnce() async {
    try {
      final update = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => update.complete(),
        (_) => update.complete(),
      );
      await update.future;
      final form = Completer<void>();
      ConsentForm.loadAndShowConsentFormIfRequired((_) => form.complete());
      await form.future;
      final allowed = await ConsentInformation.instance.canRequestAds();
      debugPrint('[NativeControl] ump.canRequestAds=$allowed');
      if (!mounted || !allowed) {
        if (mounted) setState(() => _status = 'No SDK permission; no request');
        return;
      }
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating:
              const bool.fromEnvironment(
                    'NATIVE_CONTROL_MAX_G',
                    defaultValue: true,
                  )
                  ? MaxAdContentRating.g
                  : null,
        ),
      );
      await MobileAds.instance.initialize();
      if (!mounted) return;
      _ad = NativeAd(
        adUnitId:
            Platform.isAndroid
                ? 'ca-app-pub-3940256099942544/2247696110'
                : 'ca-app-pub-3940256099942544/3986624511',
        request: const AdRequest(nonPersonalizedAds: true),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: _medium ? TemplateType.medium : TemplateType.small,
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            debugPrint('[NativeControl] native.loaded');
            setState(() {
              _loaded = true;
              _status = 'Native loaded; SDK test creative below';
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              '[NativeControl] native.failed ${jsonEncode(adLoadFailureDiagnostics(error))}',
            );
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _ad = null;
              _status =
                  'Native failed; no automatic retry\n${jsonEncode(adLoadFailureDiagnostics(error))}';
            });
          },
        ),
      );
      debugPrint('[NativeControl] native.requested');
      setState(() => _status = 'One native request in progress');
      await _ad!.load();
    } catch (_) {
      debugPrint('[NativeControl] initialization.failed');
      if (mounted) setState(() => _status = 'Initialization failed; no retry');
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Native SDK control — debug only')),
    body: SafeArea(
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(_status)),
          if (_loaded && _ad != null)
            Center(
              child: SizedBox(
                width: 380,
                height: _medium ? 350 : 120,
                child: AdWidget(ad: _ad!),
              ),
            ),
        ],
      ),
    ),
  );
}
