import 'dart:async';
import 'package:digitalpharmacy/services/ads/ad_service.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ads = AdsEntitlementController.instance;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late AdService service;
  Future<void> event(int id, String event) async {
    final done = Completer<void>();
    messenger.handlePlatformMessage(
      instanceManager.channel.name,
      instanceManager.channel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {'adId': id, 'eventName': event}),
      ),
      (_) => done.complete(),
    );
    await done.future;
    await Future<void>.delayed(Duration.zero);
  }

  int loadedId() =>
      (calls.lastWhere((c) => c.method == 'loadInterstitialAd').arguments
              as Map)['adId']
          as int;
  setUp(() {
    ads.setFree();
    ads.setPrivacyPermission(true);
    calls = [];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      calls.add(call);
      return null;
    });
    service = AdService.forTesting(isSupported: () => true);
  });
  tearDown(() async {
    service.disposeForTesting();
    await Future<void>.delayed(Duration.zero);
    ads.setFree();
    ads.setPrivacyPermission(false);
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(instanceManager.channel, null);
  });
  test(
    'actual SDK late interstitial load after disposal is discarded',
    () async {
      service.loadInterstitial();
      await Future<void>.delayed(Duration.zero);
      final id = loadedId();
      service.disposeInterstitial();
      await event(id, 'onAdLoaded');
      expect(service.showInterstitialIfReady(), isFalse);
      expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
      expect(
        calls.any(
          (c) => c.method == 'disposeAd' && (c.arguments as Map)['adId'] == id,
        ),
        isTrue,
      );
    },
  );
  test(
    'actual SDK late loaded ad after server confirmation cannot show',
    () async {
      service.loadInterstitial();
      await Future<void>.delayed(Duration.zero);
      final id = loadedId();
      ads.setConfirmedAdFree();
      await event(id, 'onAdLoaded');
      expect(service.showInterstitialIfReady(), isFalse);
      expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
    },
  );
  test('obsolete fullscreen dismissal cannot discard a newer ready ad', () async {
    service.loadInterstitial();
    await Future<void>.delayed(Duration.zero);
    final old = loadedId();
    await event(old, 'onAdLoaded');
    final oldAd = instanceManager.adFor(old)!;
    expect(service.showInterstitialIfReady(), isTrue);
    await Future<void>.delayed(Duration.zero);
    ads.setConfirmedAdFree();
    ads.setFree();
    await Future<void>.delayed(Duration.zero);
    final next = loadedId();
    await event(next, 'onAdLoaded');
    // SDK may deliver a callback retained by a native full-screen overlay after
    // dispose. Invoke its actual Dart listener even though its ID was removed.
    (oldAd as dynamic).fullScreenContentCallback.onAdDismissedFullScreenContent(
      oldAd,
    );
    await Future<void>.delayed(Duration.zero);
    expect(instanceManager.adFor(next), isNotNull);
    expect(calls.where((c) => c.method == 'loadInterstitialAd').length, 2);
    service.loadAppOpen();
    service.showLaunchAppOpenIfReady();
    expect(calls.where((c) => c.method == 'loadAppOpenAd'), isEmpty);
  });
}
