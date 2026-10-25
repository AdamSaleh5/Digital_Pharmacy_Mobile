import 'dart:async';
import 'package:digitalpharmacy/services/ads/ad_service.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final ads = AdsEntitlementController.instance;
  late AdService service;
  late List<MethodCall> calls;
  String? rejectedMethod;
  Future<void> loaded(int id) async {
    final done = Completer<void>();
    messenger.handlePlatformMessage(
      instanceManager.channel.name,
      instanceManager.channel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {'adId': id, 'eventName': 'onAdLoaded'}),
      ),
      (_) => done.complete(),
    );
    await done.future;
  }

  int id() =>
      (calls.lastWhere((c) => c.method == 'loadInterstitialAd').arguments
              as Map)['adId']
          as int;
  setUp(() {
    ads.setFree();
    ads.setPrivacyPermission(true);
    calls = [];
    rejectedMethod = null;
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      calls.add(call);
      if (call.method == rejectedMethod)
        throw PlatformException(code: 'synthetic-platform-failure');
      return null;
    });
    service = AdService.forTesting(isSupported: () => true);
  });
  tearDown(() async {
    service.disposeForTesting();
    for (final c in List<MethodCall>.from(
      calls,
    ).where((c) => c.method == 'loadInterstitialAd')) {
      await instanceManager
          .adFor((c.arguments as Map)['adId'] as int)
          ?.dispose();
    }
    ads.setPrivacyPermission(false);
    ads.setFree();
    messenger.setMockMethodCallHandler(instanceManager.channel, null);
  });
  test(
    'confirmation cancels a client-queued fullscreen show before native dispatch',
    () async {
      service.loadInterstitial();
      await Future<void>.delayed(Duration.zero);
      await loaded(id());
      expect(service.showInterstitialIfReady(), isTrue);
      ads.setConfirmedAdFree();
      await Future<void>.delayed(Duration.zero);
      expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
    },
  );
  test(
    'channel load rejection releases loading state for the next deliberate attempt',
    () async {
      rejectedMethod = 'loadInterstitialAd';
      service.loadInterstitial();
      await Future<void>.delayed(Duration.zero);
      service.loadInterstitial();
      await Future<void>.delayed(Duration.zero);
      expect(
        calls.where((c) => c.method == 'loadInterstitialAd'),
        hasLength(2),
      );
    },
  );
  test(
    'channel show rejection does not consume actual-display cooldown or block reloading',
    () async {
      service.loadInterstitial();
      await Future<void>.delayed(Duration.zero);
      await loaded(id());
      rejectedMethod = 'showAdWithoutView';
      expect(service.showInterstitialIfReady(), isTrue);
      await Future<void>.delayed(Duration.zero);
      rejectedMethod = null;
      service.loadInterstitial();
      await Future<void>.delayed(Duration.zero);
      expect(
        calls.where((c) => c.method == 'loadInterstitialAd'),
        hasLength(2),
      );
      await loaded(id());
      expect(service.showInterstitialIfReady(), isTrue);
      await Future<void>.delayed(Duration.zero);
    },
  );
  test(
    'successful display still enforces cooldown before a later ready ad',
    () async {
      service.loadInterstitial();
      await Future<void>.delayed(Duration.zero);
      await loaded(id());
      final ad = instanceManager.adFor(id())! as InterstitialAd;
      expect(service.showInterstitialIfReady(), isTrue);
      await Future<void>.delayed(Duration.zero);
      ad.fullScreenContentCallback!.onAdShowedFullScreenContent!(ad);
      ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
      await Future<void>.delayed(Duration.zero);
      await loaded(id());
      expect(service.showInterstitialIfReady(), isFalse);
      expect(calls.where((c) => c.method == 'showAdWithoutView'), hasLength(1));
    },
  );
}
