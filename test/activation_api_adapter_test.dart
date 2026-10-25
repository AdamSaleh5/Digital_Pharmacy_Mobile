import 'dart:async';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/entitlements/ad_entitlement.dart';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/features/activation/view/activation_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/activation_coordinator.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This adapter is ONLY a typed synthetic fixture, never a proposed wire schema.
class _FixtureAdapter extends ActivationApiAdapter {
  _FixtureAdapter(
    this.result, {
    this.path = '/api/users/verify-device',
    this.lookup,
  });
  final ActivationVerification result;
  final String path;
  final ActivationStatusLookup? lookup;
  int decoded = 0;
  int? status;
  @override
  String get verificationPath => path;
  @override
  Set<int> get handledStatusCodes => const {200, 422};
  @override
  ActivationStatusLookup? get statusLookup => lookup;
  @override
  ActivationVerification decodeVerification(ActivationApiReply reply) {
    decoded++;
    status = reply.statusCode;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ads = AdsEntitlementController.instance;
  final origin = Uri.parse('https://api.example.test');
  late AuthSession session;
  late List<RequestOptions> requests;
  final transports = <Dio>[];
  Completer<void>? requestSeen;
  ActivationService service(
    ActivationApiAdapter adapter, {
    int status = 200,
    Future<void>? wait,
    bool networkFailure = false,
  }) {
    final dio = Dio();
    transports.add(dio);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) async {
          requests.add(request);
          if (requestSeen != null && !requestSeen!.isCompleted)
            requestSeen!.complete();
          if (wait != null) await wait;
          if (networkFailure) {
            handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.receiveTimeout,
              ),
            );
          } else {
            handler.resolve(
              Response<dynamic>(
                requestOptions: request,
                statusCode: status,
                data: const {'syntheticFixtureOnly': true},
                headers: Headers.fromMap({
                  'content-type': ['application/json'],
                }),
              ),
            );
          }
        },
      ),
    );
    return ActivationService(
      dio: dio,
      session: session,
      apiOrigin: origin,
      adapter: adapter,
    );
  }

  Future<ActivationEntitlementRestorer> store() async =>
      ActivationEntitlementRestorer(
        preferences: await SharedPreferences.getInstance(),
        ads: ads,
      );
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ads.setFree();
    ads.setPrivacyPermission(false);
    requests = [];
    requestSeen = null;
    session =
        AuthSession()
          ..start(accessToken: 'synthetic-auth-only', apiOrigin: origin);
  });
  tearDown(() {
    for (final dio in transports) {
      dio.close();
    }
    transports.clear();
    session.dispose();
    ads.setFree();
    ads.setPrivacyPermission(false);
  });

  test(
    'default published adapter remains unconfirmed for an opaque 200',
    () async {
      final result = await service(
        const SwaggerActivationApiAdapter(),
      ).verifyDevice(activationCode: 'synthetic-code');
      expect(result, ActivationVerification.unconfirmed);
      expect(
        requests.single.uri.toString(),
        'https://api.example.test/api/users/verify-device',
      );
      expect(requests.single.data, {'activationCode': 'synthetic-code'});
      expect(requests.single.followRedirects, isFalse);
    },
  );

  test(
    'explicit fixture adapter confirms, persists scope, restores and revokes through existing hook',
    () async {
      var state = EntitlementStatus.unknown;
      final adapter = _FixtureAdapter(
        ActivationVerification.active(confirmedScope: 'synthetic-stable-scope'),
        lookup: (_) async => state,
      );
      final restorer = await store();
      final coordinator = ActivationCoordinator(
        verifier: service(adapter),
        session: session,
        restorer: restorer,
      );
      expect(
        await coordinator.submit('synthetic-code'),
        ActivationSubmission.confirmed,
      );
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      expect(adapter.decoded, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {ActivationEntitlementRestorer.historyKey});
      expect(
        prefs.getString(ActivationEntitlementRestorer.historyKey),
        'synthetic-stable-scope',
      );
      ads.setFree();
      final app = AppProvider(authSession: session, activationAdapter: adapter);
      await app.init();
      expect(ads.state, AdsEntitlementState.restorationPending);
      state = EntitlementStatus.active;
      await app.restoreActivation();
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      state = EntitlementStatus.inactive;
      await app.restoreActivation();
      expect(ads.state, AdsEntitlementState.free);
      expect(
        prefs.containsKey(ActivationEntitlementRestorer.historyKey),
        isFalse,
      );
      app.dispose();
    },
  );

  for (final prior in AdsEntitlementState.values) {
    for (final outcome in ['rejected', 'unknown', 'network']) {
      test(
        '$outcome preserves prior entitlement $prior and its history',
        () async {
          final prefs = await SharedPreferences.getInstance();
          if (prior != AdsEntitlementState.free)
            await prefs.setString(
              ActivationEntitlementRestorer.historyKey,
              'synthetic-existing-scope',
            );
          switch (prior) {
            case AdsEntitlementState.free:
              ads.setFree();
            case AdsEntitlementState.confirmedAdFree:
              ads.setConfirmedAdFree();
            case AdsEntitlementState.restorationPending:
              ads.beginRestoration();
          }
          final adapter = _FixtureAdapter(
            outcome == 'rejected'
                ? ActivationVerification.rejected
                : ActivationVerification.unconfirmed,
          );
          final coordinator = ActivationCoordinator(
            verifier: service(
              adapter,
              status: outcome == 'rejected' ? 422 : 200,
              networkFailure: outcome == 'network',
            ),
            session: session,
            restorer: await store(),
          );
          if (outcome == 'network') {
            await expectLater(
              coordinator.submit('synthetic-code'),
              throwsA(isA<DioException>()),
            );
          } else {
            expect(
              await coordinator.submit('synthetic-code'),
              outcome == 'rejected'
                  ? ActivationSubmission.rejected
                  : ActivationSubmission.unconfirmed,
            );
          }
          expect(ads.state, prior);
          expect(
            prefs.containsKey(ActivationEntitlementRestorer.historyKey),
            prior != AdsEntitlementState.free,
          );
        },
      );
    }
  }

  test(
    'duplicate normalized submission shares one pending verification and persistence',
    () async {
      final reply = Completer<void>();
      final adapter = _FixtureAdapter(
        ActivationVerification.active(confirmedScope: 'synthetic-scope'),
      );
      final coordinator = ActivationCoordinator(
        verifier: service(adapter, wait: reply.future),
        session: session,
        restorer: await store(),
      );
      requestSeen = Completer<void>();
      final first = coordinator.submit(' synthetic-code ');
      final second = coordinator.submit('synthetic-code');
      expect(identical(first, second), isTrue);
      await requestSeen!.future;
      expect(requests, hasLength(1));
      reply.complete();
      expect(await first, ActivationSubmission.confirmed);
      expect(await second, ActivationSubmission.confirmed);
      expect(adapter.decoded, 1);
    },
  );

  test(
    'admin session replacement does not invalidate installation verification',
    () async {
      final reply = Completer<void>();
      final adapter = _FixtureAdapter(
        ActivationVerification.active(confirmedScope: 'synthetic-old-scope'),
      );
      final api = service(adapter, wait: reply.future);
      requestSeen = Completer<void>();
      final pending = api.verifyDevice(activationCode: 'synthetic-code');
      await requestSeen!.future;
      session.start(accessToken: 'synthetic-new-account', apiOrigin: origin);
      reply.complete();
      expect((await pending).isConfirmedActive, isTrue);
      expect(adapter.decoded, 1);
    },
  );

  test(
    'replacement adapter cannot redirect the credential-bearing operation off origin',
    () async {
      final adapter = _FixtureAdapter(
        ActivationVerification.unconfirmed,
        path: 'http://other.example.test/synthetic',
      );
      await expectLater(
        service(adapter).verifyDevice(activationCode: 'synthetic-code'),
        throwsStateError,
      );
      expect(requests, isEmpty);
    },
  );

  for (final locale in ['en', 'ar']) {
    testWidgets(
      'explicit adapter rejection has localized $locale feedback and clears code',
      (tester) async {
        final adapter = _FixtureAdapter(ActivationVerification.rejected);
        final api = service(adapter, status: 422);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ActivationPage(
              apiOrigin: Uri.parse('https://api.example.test'),
              deviceId: 'synthetic-fcm-test-token',
              session: session,
              verifier: api,
              restorer: await store(),
            ),
          ),
        );
        await tester.enterText(find.byType(TextField), 'synthetic-code');
        await tester.tap(
          find.text(locale == 'en' ? 'Verify code' : 'تحقق من الكود'),
        );
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
        expect(
          find.text(
            locale == 'en'
                ? 'The activation code was not accepted.'
                : 'لم يُقبل كود التفعيل.',
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        expect(ads.state, AdsEntitlementState.free);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
