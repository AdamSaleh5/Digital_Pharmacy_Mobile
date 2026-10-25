import 'dart:async';

import 'package:digitalpharmacy/services/ads/ad_consent_service.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class _Gateway implements AdConsentGateway {
  bool allowed = false;
  bool requiredOptions = false;
  bool failUpdate = false;
  int updates = 0;
  Completer<void>? updateWait;
  Completer<void>? optionsWait;

  @override
  Future<void> requestUpdate() async {
    updates++;
    if (updateWait != null) await updateWait!.future;
    if (failUpdate) throw StateError('synthetic update failure');
  }

  @override
  Future<void> showRequiredForm() async {}
  @override
  Future<void> showPrivacyOptions() async {
    if (optionsWait != null) await optionsWait!.future;
  }

  @override
  Future<bool> canRequestAds() async => allowed;
  @override
  Future<bool> privacyOptionsRequired() async => requiredOptions;
}

void main() {
  test('release consent ignores all SDK debug geography settings', () {
    final parameters = umpRequestParameters(
      debugBuild: false,
      forceEea: true,
      testDeviceId: 'not-a-real-identifier',
    );
    expect(parameters.consentDebugSettings, isNull);
  });

  test(
    'EEA SDK testing requires explicit debug flag and a test identifier',
    () {
      expect(
        umpRequestParameters(
          debugBuild: true,
          forceEea: false,
          testDeviceId: '',
        ).consentDebugSettings,
        isNull,
      );
      expect(
        () => umpRequestParameters(
          debugBuild: true,
          forceEea: true,
          testDeviceId: '',
        ),
        throwsArgumentError,
      );
      const syntheticId = '00000000000000000000000000000001';
      final settings =
          umpRequestParameters(
            debugBuild: true,
            forceEea: true,
            testDeviceId: syntheticId,
          ).consentDebugSettings!;
      expect(settings.debugGeography, DebugGeography.debugGeographyEea);
      expect(settings.testIdentifiers, [syntheticId]);
    },
  );

  final ads = AdsEntitlementController.instance;
  setUp(() {
    ads.setFree();
    ads.setPrivacyPermission(false);
  });
  tearDown(() {
    ads.setFree();
    ads.setPrivacyPermission(false);
  });

  test(
    'restored pending skips SDK work and confirmed inactive starts consent once',
    () async {
      ads.beginRestoration();
      final gateway = _Gateway()..allowed = true;
      var initialized = 0;
      final service = AdConsentService(
        gateway: gateway,
        isSupported: () => true,
        autoStartOnFree: true,
        initializeAds: () async {
          initialized++;
        },
      );
      addTearDown(service.dispose);
      await service.gatherConsent();
      expect(gateway.updates, 0);
      expect(initialized, 0);
      ads.setFree();
      await service.gatherConsent();
      expect(gateway.updates, 1);
      expect(initialized, 1);
      expect(ads.canRequestAds, isTrue);
    },
  );

  test(
    'late UMP completion cannot initialize ads after active confirmation',
    () async {
      final gateway =
          _Gateway()
            ..allowed = true
            ..updateWait = Completer<void>();
      var initialized = 0;
      final service = AdConsentService(
        gateway: gateway,
        isSupported: () => true,
        initializeAds: () async {
          initialized++;
        },
      );
      addTearDown(service.dispose);
      final gathering = service.gatherConsent();
      ads.setConfirmedAdFree();
      gateway.updateWait!.complete();
      await gathering;
      expect(initialized, 0);
      expect(ads.canRequestAds, isFalse);
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
    },
  );

  test('free entitlement does not permit SDK requests before consent', () {
    expect(ads.adsAllowed, isTrue);
    expect(ads.canRequestAds, isFalse);
    final gate = AdLoadGate(ads);
    addTearDown(gate.dispose);
    expect(gate.accepts(gate.beginAttempt()), isFalse);
  });

  test('denied/unknown SDK consent never initializes advertising', () async {
    var initializations = 0;
    final service = AdConsentService(
      gateway: _Gateway(),
      isSupported: () => true,
      initializeAds: () async => initializations++,
    );
    addTearDown(service.dispose);
    await service.gatherConsent();
    expect(initializations, 0);
    expect(ads.canRequestAds, isFalse);
  });

  test(
    'concurrent consent collection is one request and waits for SDK init',
    () async {
      final gateway =
          _Gateway()
            ..allowed = true
            ..updateWait = Completer<void>();
      final initWait = Completer<void>();
      var initializations = 0;
      final service = AdConsentService(
        gateway: gateway,
        isSupported: () => true,
        initializeAds: () async {
          initializations++;
          await initWait.future;
        },
      );
      addTearDown(service.dispose);
      final first = service.gatherConsent();
      final second = service.gatherConsent();
      expect(gateway.updates, 1);
      expect(ads.canRequestAds, isFalse);
      gateway.updateWait!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(initializations, 1);
      expect(ads.canRequestAds, isFalse);
      initWait.complete();
      await Future.wait([first, second]);
      expect(ads.canRequestAds, isTrue);
      await service.gatherConsent();
      expect(gateway.updates, 2);
      expect(initializations, 1);
    },
  );

  test(
    'SDK permission cannot override active or pending entitlement',
    () async {
      final service = AdConsentService(
        gateway: _Gateway()..allowed = true,
        isSupported: () => true,
        initializeAds: () async {},
      );
      addTearDown(service.dispose);
      ads.setConfirmedAdFree();
      await service.gatherConsent();
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      expect(ads.canRequestAds, isFalse);
      ads.beginRestoration();
      await service.gatherConsent();
      expect(ads.canRequestAds, isFalse);
    },
  );

  test(
    'privacy options invalidate in-flight ads and honor revoked consent',
    () async {
      final gateway =
          _Gateway()
            ..allowed = true
            ..requiredOptions = true;
      final service = AdConsentService(
        gateway: gateway,
        isSupported: () => true,
        initializeAds: () async {},
      );
      addTearDown(service.dispose);
      await service.gatherConsent();
      final gate = AdLoadGate(ads);
      addTearDown(gate.dispose);
      final revision = gate.beginAttempt();
      gateway.optionsWait = Completer<void>();
      final showing = service.showPrivacyOptions();
      expect(service.showingPrivacyOptions, isTrue);
      expect(gate.accepts(revision), isFalse);
      gateway.allowed = false;
      gateway.optionsWait!.complete();
      await showing;
      expect(ads.canRequestAds, isFalse);
      expect(service.showingPrivacyOptions, isFalse);
    },
  );

  test(
    'offline update trusts only UMP permission, never a local preference',
    () async {
      final gateway =
          _Gateway()
            ..failUpdate = true
            ..allowed = true;
      final service = AdConsentService(
        gateway: gateway,
        isSupported: () => true,
        initializeAds: () async {},
      );
      addTearDown(service.dispose);
      await service.gatherConsent();
      expect(ads.canRequestAds, isTrue);
      gateway.allowed = false;
      await service.gatherConsent();
      expect(ads.canRequestAds, isFalse);
    },
  );
  test(
    'stale SDK initialization cannot reopen the ad gate while privacy options are showing',
    () async {
      final gateway =
          _Gateway()
            ..allowed = true
            ..requiredOptions = true
            ..optionsWait = Completer<void>();
      final initStarted = Completer<void>();
      final initWait = Completer<void>();
      final service = AdConsentService(
        gateway: gateway,
        isSupported: () => true,
        initializeAds: () async {
          initStarted.complete();
          await initWait.future;
        },
      );
      addTearDown(service.dispose);
      final gathering = service.gatherConsent();
      await initStarted.future;
      final options = service.showPrivacyOptions();
      expect(service.showingPrivacyOptions, isTrue);
      initWait.complete();
      await gathering;
      try {
        expect(
          ads.canRequestAds,
          isFalse,
          reason:
              'The old consent flow must not load ads over the current privacy form',
        );
      } finally {
        gateway.allowed = false;
        gateway.optionsWait!.complete();
        await options;
      }
      expect(ads.canRequestAds, isFalse);
    },
  );
  test(
    'revoked privacy choice wins even when the old initialization completes after the form closes',
    () async {
      final gateway =
          _Gateway()
            ..allowed = true
            ..requiredOptions = true
            ..optionsWait = Completer<void>();
      final started = Completer<void>();
      final init = Completer<void>();
      final service = AdConsentService(
        gateway: gateway,
        isSupported: () => true,
        initializeAds: () async {
          started.complete();
          await init.future;
        },
      );
      addTearDown(service.dispose);
      final gathering = service.gatherConsent();
      await started.future;
      final options = service.showPrivacyOptions();
      gateway.allowed = false;
      gateway.optionsWait!.complete();
      await options;
      expect(ads.canRequestAds, isFalse);
      init.complete();
      await gathering;
      expect(ads.canRequestAds, isFalse);
    },
  );
  test(
    'latest allowed privacy choice shares one pending SDK initialization',
    () async {
      final gateway =
          _Gateway()
            ..allowed = true
            ..requiredOptions = true
            ..optionsWait = Completer<void>();
      final started = Completer<void>();
      final init = Completer<void>();
      var calls = 0;
      final service = AdConsentService(
        gateway: gateway,
        isSupported: () => true,
        initializeAds: () async {
          calls++;
          if (!started.isCompleted) started.complete();
          await init.future;
        },
      );
      addTearDown(service.dispose);
      final gathering = service.gatherConsent();
      await started.future;
      final options = service.showPrivacyOptions();
      gateway.optionsWait!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(ads.canRequestAds, isFalse);
      expect(calls, 1);
      init.complete();
      await Future.wait([gathering, options]);
      expect(calls, 1);
      expect(ads.canRequestAds, isTrue);
    },
  );
}
