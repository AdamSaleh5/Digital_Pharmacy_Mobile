import 'package:digitalpharmacy/core/widgets/ad_banner_placement.dart';
import 'package:digitalpharmacy/core/widgets/inline_native_ad_card.dart';
import 'package:digitalpharmacy/core/entitlements/ad_entitlement.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/services/ads/ad_size_settings.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AdsEntitlementController.instance.setFree();
    AdsEntitlementController.instance.setPrivacyPermission(true);
  });

  test(
    'a user with no activation history starts with ordinary ads enabled',
    () {
      final entitlement = AdsEntitlementController.instance;
      entitlement.setFree();
      expect(entitlement.state, AdsEntitlementState.free);
      expect(entitlement.adsAllowed, isTrue);
      expect(
        entitlement.adEntitlement.value.status,
        EntitlementStatus.inactive,
      );
    },
  );

  test('pending restoration suppresses ads until a server result resolves', () {
    final entitlement = AdsEntitlementController.instance;
    entitlement.beginRestoration();
    expect(entitlement.state, AdsEntitlementState.restorationPending);
    expect(entitlement.adsAllowed, isFalse);
    expect(entitlement.adEntitlement.value.status, EntitlementStatus.unknown);

    entitlement.setFree();
    expect(entitlement.adsAllowed, isTrue);
    expect(entitlement.adEntitlement.value.status, EntitlementStatus.inactive);

    entitlement.setConfirmedAdFree();
    expect(entitlement.adsAllowed, isFalse);
    expect(entitlement.adEntitlement.value.status, EntitlementStatus.active);

    entitlement.beginRestoration();
    expect(entitlement.adsAllowed, isFalse);
  });

  test('a queued load result is rejected after entitlement changes', () {
    final entitlement = AdsEntitlementController.instance;
    final gate = AdLoadGate(entitlement);
    addTearDown(gate.dispose);

    entitlement.setFree();
    final pendingFreeAdRequest = gate.beginAttempt();
    expect(gate.accepts(pendingFreeAdRequest), isTrue);

    entitlement.setConfirmedAdFree();
    expect(gate.accepts(pendingFreeAdRequest), isFalse);
    entitlement.setFree();
    expect(gate.accepts(pendingFreeAdRequest), isFalse);
  });

  for (final format in const ['banner', 'native', 'interstitial', 'app-open']) {
    test(
      '$format cannot render or show an already-loaded ad after activation',
      () {
        final entitlement = AdsEntitlementController.instance;
        entitlement.setFree();
        final gate = AdLoadGate(entitlement);
        addTearDown(gate.dispose);
        final loadRevision = gate.beginAttempt();
        var loaded = gate.accepts(loadRevision);
        expect(loaded, isTrue);

        entitlement.setConfirmedAdFree();

        // Widgets and full-screen show methods both check these same state and
        // revision gates after their ad has loaded.
        if (!gate.accepts(loadRevision) || !entitlement.adsAllowed) {
          loaded = false;
        }
        expect(gate.accepts(loadRevision), isFalse);
        expect(loaded, isFalse);
        expect(entitlement.adsAllowed, isFalse);
      },
    );
  }

  test('launch ads never appear late or survive restoration', () {
    final opportunity = LaunchAdOpportunity();
    expect(opportunity.take(adsAllowed: true, adReady: false), isFalse);
    expect(opportunity.take(adsAllowed: true, adReady: true), isFalse);

    final cancelled = LaunchAdOpportunity()..cancel();
    expect(cancelled.take(adsAllowed: true, adReady: true), isFalse);

    final ready = LaunchAdOpportunity();
    expect(ready.take(adsAllowed: true, adReady: true), isTrue);
    expect(ready.take(adsAllowed: true, adReady: true), isFalse);
  });

  test(
    'compact preference persists and resolves to the supported banner size',
    () async {
      final settings = AdSizeSettings.instance;
      await settings.setPreference(AdSizePreference.compact);

      expect(settings.preference, AdSizePreference.compact);
      expect(await settings.resolveSize(320), AdSize.banner);
      expect(
        (await SharedPreferences.getInstance()).getString(
          AdSizeSettings.preferenceKey,
        ),
        'compact',
      );
    },
  );

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'suppressed ad placements stay hidden on narrow ${locale.languageCode} layout',
      (tester) async {
        AdsEntitlementController.instance.beginRestoration();
        tester.view.physicalSize = const Size(280, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: Column(
                children: [AdBannerPlacement(), InlineNativeAdCard()],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(AdWidget), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
