import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/features/activation/view/activation_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/services/ads/activation_coordinator.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// No socket or platform SDK is used: requests stop at the real Dio adapter edge.
class _Wire implements HttpClientAdapter {
  int status = 200;
  Object? body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Verifier implements ActivationVerifier {
  _Verifier({this.hold = false});
  final bool hold;
  final requests = <Map<String, Object>>[];
  final replies = <Completer<ActivationVerification>>[];

  @override
  Future<ActivationVerification> verifyDevice({
    required String activationCode,
    bool? isNewUser,
    String? deviceId,
  }) {
    requests.add({
      'activationCode': activationCode,
      if (isNewUser != null) 'isNewUser': isNewUser,
      if (deviceId != null) 'deviceId': deviceId,
    });
    if (!hold) return Future.value(ActivationVerification.unconfirmed);
    final reply = Completer<ActivationVerification>();
    replies.add(reply);
    return reply.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const origin = 'https://api.example.test';
  final ads = AdsEntitlementController.instance;
  final originalCountry = kAppCountry;
  setUp(() {
    ads.setFree();
    ads.setPrivacyPermission(false);
  });
  tearDown(() {
    ads.setFree();
    ads.setPrivacyPermission(false);
    AuthSession.shared.signOut();
    setAppCountry(originalCountry);
  });

  for (final newUser in [false, true]) {
    test(
      'confirmed ad-removal route forwards supplied three-field context: isNewUser=$newUser',
      () async {
        final wire = _Wire();
        final dio = Dio(BaseOptions(baseUrl: origin))..httpClientAdapter = wire;
        addTearDown(dio.close);
        AuthSession.shared.start(
          accessToken: 'synthetic-admin-not-for-application',
          apiOrigin: Uri.parse(origin),
        );
        final coordinator = ActivationCoordinator(
          verifier: ActivationService.configured(
            dio: dio,
            apiOrigin: Uri.parse(origin),
          ),
        );
        final result = await coordinator.submit(
          ' synthetic-code ',
          isNewUser: newUser,
          deviceId: 'synthetic-installation-A',
        );
        final request = wire.requests.single;
        expect(request.method, 'POST');
        expect(request.uri.toString(), '$origin/api/users/verify-device');
        expect(request.data, {
          'isNewUser': newUser,
          'activationCode': 'synthetic-code',
          'deviceId': 'synthetic-installation-A',
        });
        expect(request.contentType, Headers.jsonContentType);
        expect(request.followRedirects, isFalse);
        expect(request.queryParameters, isEmpty);
        expect(
          request.headers.keys.map((key) => key.toLowerCase()),
          isNot(contains('authorization')),
        );
        expect(
          request.headers.keys.map((key) => key.toLowerCase()),
          isNot(contains('cookie')),
        );
        expect(result, ActivationSubmission.unconfirmed);
        expect(AuthSession.shared.isSignedIn, isTrue);
        // Current saved Swagger has exactly these fields; no required-list entry
        // authorizes inventing new-user/device identity semantics.
        final spec =
            jsonDecode(
                  File(
                    'docs/integration-audit-20261014/public-contract-followup-20261015/swagger.json',
                  ).readAsStringSync(),
                )
                as Map;
        final schema =
            spec['components']['schemas']['VerifyDeviceRequest'] as Map;
        expect((schema['properties'] as Map).keys.toSet(), {
          'isNewUser',
          'activationCode',
          'deviceId',
        });
        expect(schema['additionalProperties'], isFalse);
        expect(schema['properties']['isNewUser']['type'], 'boolean');
        expect(schema['properties']['deviceId']['type'], 'string');
      },
    );
  }

  test(
    'absent context remains omitted rather than inventing a flag or identity for either country',
    () async {
      final wire = _Wire();
      final dio = Dio(BaseOptions(baseUrl: origin))..httpClientAdapter = wire;
      addTearDown(dio.close);
      final flow = ActivationCoordinator(
        verifier: ActivationService.configured(
          dio: dio,
          apiOrigin: Uri.parse(origin),
        ),
      );
      for (final country in AppCountry.values) {
        setAppCountry(country);
        await flow.submit('synthetic-code');
        expect(wire.requests.last.data, {'activationCode': 'synthetic-code'});
      }
      expect(wire.requests, hasLength(2));
    },
  );

  test(
    'only identical code and request context coalesce; changed identity or flag supersedes old work',
    () async {
      final verifier = _Verifier(hold: true);
      final flow = ActivationCoordinator(verifier: verifier);
      final first = flow.submit(
        'synthetic-code',
        isNewUser: false,
        deviceId: 'synthetic-A',
      );
      final duplicate = flow.submit(
        ' synthetic-code ',
        isNewUser: false,
        deviceId: 'synthetic-A',
      );
      expect(identical(first, duplicate), isTrue);
      final changedDevice = flow.submit(
        'synthetic-code',
        isNewUser: false,
        deviceId: 'synthetic-B',
      );
      final changedFlag = flow.submit(
        'synthetic-code',
        isNewUser: true,
        deviceId: 'synthetic-B',
      );
      expect(verifier.requests, hasLength(3));
      for (final reply in verifier.replies) {
        reply.complete(ActivationVerification.unconfirmed);
      }
      expect(await first, ActivationSubmission.superseded);
      expect(await changedDevice, ActivationSubmission.superseded);
      expect(await changedFlag, ActivationSubmission.unconfirmed);
    },
  );

  for (final state in AdsEntitlementState.values) {
    test(
      'opaque success with explicit request context preserves existing $state',
      () async {
        switch (state) {
          case AdsEntitlementState.free:
            ads.setFree();
          case AdsEntitlementState.restorationPending:
            ads.beginRestoration();
          case AdsEntitlementState.confirmedAdFree:
            ads.setConfirmedAdFree();
        }
        final wire =
            _Wire()
              ..body = {
                'status': 200,
                'active': true,
              }; // Deliberately uncontracted fixture.
        final dio = Dio(BaseOptions(baseUrl: origin))..httpClientAdapter = wire;
        addTearDown(dio.close);
        final result = await ActivationCoordinator(
          verifier: ActivationService.configured(
            dio: dio,
            apiOrigin: Uri.parse(origin),
          ),
        ).submit(
          'synthetic-code',
          isNewUser: false,
          deviceId: 'synthetic-installation',
        );
        expect(result, ActivationSubmission.unconfirmed);
        expect(ads.state, state);
      },
    );
  }

  // These statuses are synthetic failure-handling cases, not claimed published
  // invalid-code semantics: current Swagger documents only an opaque200.
  for (final status in [400, 401, 403, 422, 500]) {
    test(
      'undocumented mock HTTP$status remains a request error without activation or retry',
      () async {
        ads.setConfirmedAdFree();
        final wire =
            _Wire()
              ..status = status
              ..body = {'synthetic': 'unspecified failure'};
        final dio = Dio(BaseOptions(baseUrl: origin))..httpClientAdapter = wire;
        addTearDown(dio.close);
        await expectLater(
          ActivationCoordinator(
            verifier: ActivationService.configured(
              dio: dio,
              apiOrigin: Uri.parse(origin),
            ),
          ).submit(
            'synthetic-code',
            isNewUser: false,
            deviceId: 'synthetic-installation',
          ),
          throwsA(
            isA<DioException>().having(
              (error) => error.response?.statusCode,
              'status',
              status,
            ),
          ),
        );
        expect(wire.requests, hasLength(1));
        expect(ads.state, AdsEntitlementState.confirmedAdFree);
      },
    );
  }

  testWidgets(
    'activation page forwards explicit context and clears the submitted code',
    (tester) async {
      final verifier = _Verifier();
      ads.beginRestoration();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ActivationPage(
            apiOrigin: Uri.parse('https://api.example.test'),
            verifier: verifier,
            isNewUser: false,
            deviceId: 'synthetic-page-installation',
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), ' synthetic-page-code ');
      final button = find.widgetWithText(FilledButton, 'Verify code');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(verifier.requests.single, {
        'activationCode': 'synthetic-page-code',
        'isNewUser': false,
        'deviceId': 'synthetic-page-installation',
      });
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(ads.state, AdsEntitlementState.restorationPending);
      expect(find.textContaining('Sign in'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'invalidating changed request context rejects old success without resetting current entitlement',
    () async {
      ads.setConfirmedAdFree();
      final verifier = _Verifier(hold: true);
      final flow = ActivationCoordinator(verifier: verifier);
      final old = flow.submit(
        'synthetic-code',
        isNewUser: false,
        deviceId: 'synthetic-A',
      );
      flow.invalidatePendingSubmission();
      final current = flow.submit(
        'synthetic-code',
        isNewUser: false,
        deviceId: 'synthetic-A',
      );
      expect(verifier.requests, hasLength(2));
      verifier.replies[0].complete(
        ActivationVerification.active(
          confirmedScope: 'synthetic-obsolete-scope',
        ),
      );
      verifier.replies[1].complete(ActivationVerification.unconfirmed);
      expect(await old, ActivationSubmission.superseded);
      expect(await current, ActivationSubmission.unconfirmed);
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
    },
  );

  testWidgets(
    'page context replacement cannot apply success from the prior binding',
    (tester) async {
      final verifier = _Verifier(hold: true);
      Widget page(String device) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActivationPage(
          apiOrigin: Uri.parse('https://api.example.test'),
          key: const ValueKey('activation'),
          verifier: verifier,
          isNewUser: false,
          deviceId: device,
        ),
      );
      await tester.pumpWidget(page('synthetic-A'));
      await tester.enterText(find.byType(TextField), 'synthetic-code');
      final button = find.widgetWithText(FilledButton, 'Verify code');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      await tester.pumpWidget(page('synthetic-B'));
      verifier.replies.single.complete(
        ActivationVerification.active(confirmedScope: 'synthetic-old-binding'),
      );
      await tester.pumpAndSettle();
      expect(ads.state, AdsEntitlementState.free);
      expect(find.text('Activation confirmed. All ads are off.'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'changed explicit binding clears an unsubmitted code without a request',
    (tester) async {
      final verifier = _Verifier();
      Widget page(String device) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActivationPage(
          apiOrigin: Uri.parse('https://api.example.test'),
          key: const ValueKey('activation'),
          verifier: verifier,
          deviceId: device,
        ),
      );
      await tester.pumpWidget(page('synthetic-A'));
      await tester.enterText(find.byType(TextField), 'synthetic-unsubmitted');
      await tester.pumpWidget(page('synthetic-B'));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(verifier.requests, isEmpty);
      expect(ads.state, AdsEntitlementState.free);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'opaque response preserves saved confirmation history and stores no submitted request values',
    () async {
      SharedPreferences.setMockInitialValues({
        ActivationEntitlementRestorer.historyKey:
            'synthetic-existing-confirmation',
      });
      final prefs = await SharedPreferences.getInstance();
      final restorer = ActivationEntitlementRestorer(
        preferences: prefs,
        ads: ads,
      )..bootstrap();
      addTearDown(restorer.dispose);
      final wire = _Wire();
      final dio = Dio(BaseOptions(baseUrl: origin))..httpClientAdapter = wire;
      addTearDown(dio.close);
      await ActivationCoordinator(
        verifier: ActivationService.configured(
          dio: dio,
          apiOrigin: Uri.parse(origin),
        ),
        restorer: restorer,
      ).submit(
        'synthetic-new-code',
        isNewUser: false,
        deviceId: 'synthetic-new-device',
      );
      expect(prefs.getKeys(), {ActivationEntitlementRestorer.historyKey});
      expect(
        prefs.getString(ActivationEntitlementRestorer.historyKey),
        'synthetic-existing-confirmation',
      );
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
    },
  );
}
