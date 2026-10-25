import 'dart:async';

import 'package:digitalpharmacy/core/widgets/ad_banner_placement.dart';
import 'package:digitalpharmacy/core/widgets/inline_native_ad_card.dart';
import 'package:digitalpharmacy/services/ads/ad_size_settings.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Real Dart SDK/listener paths; platform channels are mocked, with no ad traffic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final ads = AdsEntitlementController.instance;
  late List<MethodCall> calls;
  String? failMethod;
  WidgetTester? activeTester;

  List<int> ids(String method) =>
      calls
          .where((c) => c.method == method)
          .map((c) => (c.arguments as Map)['adId'] as int)
          .toList();
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

  Future<void> pump(
    WidgetTester tester,
    Widget slot, {
    Size size = const Size(390, 844),
    TextDirection direction = TextDirection.ltr,
    double keyboard = 0,
  }) async {
    activeTester = tester;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(bottom: 24),
            viewPadding: const EdgeInsets.only(bottom: 24),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(
              bottomNavigationBar:
                  slot is AdBannerPlacement
                      ? SizedBox(key: const Key('slot'), child: slot)
                      : null,
              body:
                  slot is AdBannerPlacement
                      ? const Text('Real content')
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(key: const Key('slot'), child: slot),
                          const Text('Real content'),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  void slotTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    failMethod = null;
    ads.setFree();
    ads.setPrivacyPermission(true);
    await AdSizeSettings.instance.setPreference(AdSizePreference.compact);
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      calls.add(call);
      if (call.method == 'AdSize#getAnchoredAdaptiveBannerAdSize') return 50;
      if (call.method == failMethod) {
        throw PlatformException(code: 'synthetic-channel-failure');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') return 0;
      if (call.method == 'resize') return {'width': 320.0, 'height': 120.0};
      return null;
    });
  });
  tearDown(() async {
    ads.setPrivacyPermission(false);
    ads.setFree();
    activeTester?.view.resetPhysicalSize();
    activeTester?.view.resetDevicePixelRatio();
    activeTester = null;
    messenger.setMockMethodCallHandler(instanceManager.channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
  });

  slotTest(
    'native failure falls back to a loaded banner and activation removes both formats',
    (tester) async {
      await pump(tester, const InlineNativeAdCard.forTesting());
      final native =
          instanceManager.adFor(ids('loadNativeAd').single)! as NativeAd;
      native.listener.onAdFailedToLoad!(
        native,
        LoadAdError(0, 'synthetic', 'Incorrect native ad response', null),
      );
      await tester.pump();
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      final bannerId = ids('loadBannerAd').single;
      final banner = instanceManager.adFor(bannerId)! as BannerAd;
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
      await loaded(bannerId);
      await tester.pump();
      expect(find.byType(AdWidget), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('slot'))).height,
        greaterThan(0),
      );
      expect(
        tester.getRect(find.text('Real content')).top,
        greaterThanOrEqualTo(
          tester.getRect(find.byKey(const Key('slot'))).bottom,
        ),
      );
      ads.setConfirmedAdFree();
      await tester.pump();
      banner.listener.onAdLoaded!(banner);
      await tester.pump();
      expect(find.byType(AdWidget), findsNothing);
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
      expect(tester.takeException(), isNull);
    },
  );

  slotTest(
    'native waiting/failure leaves zero height, no spinner or automatic retry',
    (tester) async {
      await pump(tester, const InlineNativeAdCard.forTesting());
      final id = ids('loadNativeAd').single;
      final ad = instanceManager.adFor(id)! as NativeAd;
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      ad.listener.onAdFailedToLoad!(
        ad,
        LoadAdError(0, 'synthetic', 'Internal error', null),
      );
      await tester.pump();
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
      expect(find.text('Real content'), findsOneWidget);
      await tester.pump(const Duration(seconds: 31));
      expect(ids('loadNativeAd'), [id]);
      expect(tester.takeException(), isNull);
    },
  );

  slotTest('native channel rejection is contained and disposes the request', (
    tester,
  ) async {
    failMethod = 'loadNativeAd';
    await pump(tester, const InlineNativeAdCard.forTesting());
    expect(ids('loadNativeAd'), hasLength(1));
    expect(calls.any((c) => c.method == 'disposeAd'), isTrue);
    expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
    expect(tester.takeException(), isNull);
  });

  slotTest(
    'native deadline disposes missing callback and rejects late success',
    (tester) async {
      await pump(tester, const InlineNativeAdCard.forTesting());
      final id = ids('loadNativeAd').single;
      final ad = instanceManager.adFor(id)! as NativeAd;
      await tester.pump(const Duration(seconds: 31));
      ad.listener.onAdLoaded!(ad);
      await tester.pump();
      expect(instanceManager.adFor(id), isNull);
      expect(find.byType(AdWidget), findsNothing);
      expect(ids('loadNativeAd'), [id]);
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
    },
  );

  slotTest(
    'confirmation removes a loaded native including its spacing and late callback',
    (tester) async {
      await pump(tester, const InlineNativeAdCard.forTesting());
      final id = ids('loadNativeAd').single;
      final ad = instanceManager.adFor(id)! as NativeAd;
      await loaded(id);
      await tester.pump();
      expect(find.byType(AdWidget), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 128);
      ads.setConfirmedAdFree();
      await tester.pump();
      ad.listener.onAdLoaded!(ad);
      await tester.pump();
      expect(find.byType(AdWidget), findsNothing);
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
    },
  );

  slotTest('narrow native never requests a clipped creative', (tester) async {
    await pump(
      tester,
      const InlineNativeAdCard.forTesting(),
      size: const Size(280, 640),
    );
    expect(ids('loadNativeAd'), isEmpty);
    expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
  });

  for (final direction in TextDirection.values) {
    for (final size in [
      const Size(360, 640),
      const Size(760, 360),
      const Size(1024, 1366),
    ]) {
      slotTest('native bounded and nonoverlapping $size $direction', (
        tester,
      ) async {
        await pump(
          tester,
          const InlineNativeAdCard.forTesting(),
          size: size,
          direction: direction,
        );
        await loaded(ids('loadNativeAd').single);
        await tester.pump();
        final rect = tester.getRect(find.byType(AdWidget));
        expect(rect.width, inInclusiveRange(320, 400));
        expect(rect.height, 120);
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(
          rect.bottom,
          lessThanOrEqualTo(tester.getRect(find.text('Real content')).top),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final direction in TextDirection.values) {
    for (final size in [
      const Size(360, 640),
      const Size(760, 360),
      const Size(1024, 1366),
    ]) {
      slotTest('responsive banner safe/nonoverlapping $size $direction', (
        tester,
      ) async {
        await tester.runAsync(
          () => AdSizeSettings.instance.setPreference(
            AdSizePreference.responsive,
          ),
        );
        await pump(
          tester,
          const AdBannerPlacement.forTesting(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          ),
          size: size,
          direction: direction,
        );
        await loaded(ids('loadBannerAd').single);
        await tester.pump();
        final rect = tester.getRect(find.byType(AdWidget));
        expect(rect.width, size.width - 32);
        expect(rect.height, 50);
        expect(rect.left, greaterThanOrEqualTo(16));
        expect(rect.right, lessThanOrEqualTo(size.width - 16));
        expect(rect.bottom, lessThanOrEqualTo(size.height - 36));
        expect(
          tester.getRect(find.text('Real content')).bottom,
          lessThanOrEqualTo(rect.top),
        );
        final requested =
            calls
                    .lastWhere(
                      (c) =>
                          c.method == 'AdSize#getAnchoredAdaptiveBannerAdSize',
                    )
                    .arguments
                as Map;
        expect(
          requested['orientation'],
          size.width > size.height ? 'landscape' : 'portrait',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  slotTest(
    'banner failure/suppression collapses its SafeArea and retry spacing',
    (tester) async {
      await pump(
        tester,
        const AdBannerPlacement.forTesting(
          padding: EdgeInsets.only(bottom: 12),
        ),
      );
      final id = ids('loadBannerAd').single;
      final ad = instanceManager.adFor(id)! as BannerAd;
      await loaded(id);
      await tester.pump();
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 86);
      ad.listener.onAdFailedToLoad!(
        ad,
        LoadAdError(0, 'synthetic', 'failure', null),
      );
      await tester.pump();
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
      ads.setConfirmedAdFree();
      await tester.pump(const Duration(seconds: 31));
      expect(ids('loadBannerAd'), [id]);
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
    },
  );

  slotTest('old banner load callback cannot mark a later retry loaded', (
    tester,
  ) async {
    await pump(tester, const AdBannerPlacement.forTesting());
    final oldId = ids('loadBannerAd').single;
    final oldAd = instanceManager.adFor(oldId)! as BannerAd;
    oldAd.listener.onAdFailedToLoad!(
      oldAd,
      LoadAdError(0, 'synthetic', 'failure', null),
    );
    await tester.pump(const Duration(seconds: 31));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(ids('loadBannerAd'), hasLength(2));
    oldAd.listener.onAdLoaded!(oldAd);
    await tester.pump();
    expect(find.byType(AdWidget), findsNothing);
  });

  slotTest('banner channel rejection is contained', (tester) async {
    failMethod = 'loadBannerAd';
    await pump(tester, const AdBannerPlacement.forTesting());
    expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
    expect(tester.takeException(), isNull);
  });

  slotTest(
    'keyboard hides loaded banner without reserving space or re-requesting',
    (tester) async {
      await pump(tester, const AdBannerPlacement.forTesting());
      await loaded(ids('loadBannerAd').single);
      await tester.pump();
      expect(find.byType(AdWidget), findsOneWidget);
      await pump(tester, const AdBannerPlacement.forTesting(), keyboard: 300);
      expect(find.byType(AdWidget), findsNothing);
      expect(tester.getSize(find.byKey(const Key('slot'))).height, 0);
      await pump(tester, const AdBannerPlacement.forTesting());
      expect(find.byType(AdWidget), findsOneWidget);
      expect(ids('loadBannerAd'), hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
