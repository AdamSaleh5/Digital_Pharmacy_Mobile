import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/features/activation/view/activation_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/ads/activation_coordinator.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Explicit synthetic success exercises client persistence, not backend semantics.
class _SyntheticConfirmedAdapter extends ActivationApiAdapter {
  const _SyntheticConfirmedAdapter();
  @override
  String get verificationPath => '/api/users/verify-device';
  @override
  ActivationVerification decodeVerification(ActivationApiReply reply) =>
      ActivationVerification.active(
        confirmedScope: 'synthetic-fixture-binding',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ads = AdsEntitlementController.instance;
  const adapter = SwaggerActivationApiAdapter();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ads.setFree();
    ads.setPrivacyPermission(false);
  });
  tearDown(() {
    ads.setFree();
    ads.setPrivacyPermission(false);
  });

  test('observed HTTP 200 / data:false rejects the code', () {
    final result = adapter.decodeVerification(
      const ActivationApiReply(
        statusCode: 200,
        body: {'status': 200, 'data': false},
      ),
    );
    expect(result.isRejected, isTrue);
    expect(result.isConfirmedActive, isFalse);
  });

  test('undocumented positive and ambiguous results never activate', () {
    expect(
      adapter
          .decodeVerification(
            const ActivationApiReply(
              statusCode: 200,
              body: {'status': 200, 'data': true},
            ),
          )
          .isConfirmedActive,
      isFalse,
    );
    for (final body in [
      null,
      true,
      {'status': 200, 'data': 'true'},
      {'status': 200, 'data': 1},
      {'status': 200, 'data': null},
      {'status': 400, 'data': true},
      {'data': true},
      {'success': true},
      {'status': 200, 'data': true, 'success': false},
      {'status': 200, 'data': true, 'error': 'synthetic conflicting result'},
      {'status': 200, 'data': true, 'expired': true},
      {'status': 200, 'data': true, 'message': <String, Object>{}},
    ]) {
      expect(
        adapter
            .decodeVerification(ActivationApiReply(statusCode: 200, body: body))
            .decision,
        ActivationDecision.unconfirmed,
      );
    }
  });

  for (final saved in [false, true]) {
    test('undocumented positive preserves saved entitlement=$saved', () async {
      if (saved)
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
      final dio =
          Dio()
            ..interceptors.add(
              InterceptorsWrapper(
                onRequest:
                    (request, handler) => handler.resolve(
                      Response<dynamic>(
                        requestOptions: request,
                        statusCode: 200,
                        data: {'status': 200, 'data': true},
                      ),
                    ),
              ),
            );
      addTearDown(dio.close);
      final flow = ActivationCoordinator(
        verifier: ActivationService.configured(
          dio: dio,
          apiOrigin: Uri.parse('https://api.example.test'),
        ),
        restorer: restorer,
      );
      expect(
        await flow.submit('synthetic-code'),
        ActivationSubmission.unconfirmed,
      );
      expect(
        prefs.getString(ActivationEntitlementRestorer.historyKey),
        saved ? 'synthetic-existing-confirmation' : null,
      );
      expect(
        ads.state,
        saved ? AdsEntitlementState.confirmedAdFree : AdsEntitlementState.free,
      );
    });
  }

  Widget page({
    required ActivationVerifier verifier,
    required ActivationEntitlementRestorer restorer,
    required Future<String?> Function() token,
  }) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ActivationPage(
      apiOrigin: Uri.parse('https://api.example.test'),
      verifier: verifier,
      restorer: restorer,
      deviceTokenProvider: token,
    ),
  );

  testWidgets('iOS exposes the same anonymous activation form', (tester) async {
    final app = AppProvider();
    await app.init();
    addTearDown(app.dispose);
    await tester.pumpWidget(
      page(
        verifier: ActivationService.configured(),
        restorer: app.activationRestorer!,
        token: () async => 'synthetic-ios-fcm-token',
      ),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Sign in'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets(
    'FCM request activates all gates, survives restart offline and skips reactivation',
    (tester) async {
      // Success is simulated: no valid production activation code was supplied.
      final requests = <RequestOptions>[];
      final dio =
          Dio()
            ..interceptors.add(
              InterceptorsWrapper(
                onRequest: (request, handler) {
                  requests.add(request);
                  handler.resolve(
                    Response(
                      requestOptions: request,
                      statusCode: 200,
                      data: {'status': 200, 'data': true},
                    ),
                  );
                },
              ),
            );
      addTearDown(dio.close);
      final verifier = ActivationService.configured(
        dio: dio,
        apiOrigin: Uri.parse('https://api.example.test'),
        adapter: const _SyntheticConfirmedAdapter(),
      );
      final app = AppProvider();
      await app.init();
      addTearDown(app.dispose);
      final gates = List.generate(4, (_) => AdLoadGate(ads));
      ads.setPrivacyPermission(true);
      final attempts = gates.map((gate) => gate.beginAttempt()).toList();
      await tester.pumpWidget(
        page(
          verifier: verifier,
          restorer: app.activationRestorer!,
          token: () async => 'synthetic-current-fcm-token',
        ),
      );
      await tester.enterText(find.byType(TextField), ' synthetic-code ');
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(requests.single.data, {
        'activationCode': 'synthetic-code',
        'isNewUser': true,
        'deviceId': 'synthetic-current-fcm-token',
      });
      expect(requests.single.headers['Authorization'], isNull);
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      for (var i = 0; i < gates.length; i++) {
        expect(gates[i].accepts(attempts[i]), isFalse);
        gates[i].dispose();
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {ActivationEntitlementRestorer.historyKey});
      expect(
        prefs.getString(ActivationEntitlementRestorer.historyKey),
        'synthetic-fixture-binding',
      );
      await tester.pumpWidget(const SizedBox());

      // A relaunch requires no messaging token and no activation status request.
      ads.setFree();
      final relaunched = AppProvider();
      await relaunched.init();
      addTearDown(relaunched.dispose);
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      await relaunched.restoreActivation();
      await tester.pumpWidget(
        page(
          verifier: verifier,
          restorer: relaunched.activationRestorer!,
          token: () => throw StateError('offline after token rotation'),
        ),
      );
      expect(
        find.text('Activation confirmed. All ads are off.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(requests, hasLength(1));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'missing FCM token sends nothing; retry uses the recovered token',
    (tester) async {
      final app = AppProvider();
      await app.init();
      addTearDown(app.dispose);
      final requests = <RequestOptions>[];
      final dio =
          Dio()
            ..interceptors.add(
              InterceptorsWrapper(
                onRequest: (request, handler) {
                  requests.add(request);
                  handler.resolve(
                    Response(
                      requestOptions: request,
                      statusCode: 200,
                      data: {'status': 200, 'data': false},
                    ),
                  );
                },
              ),
            );
      addTearDown(dio.close);
      String? token;
      await tester.pumpWidget(
        page(
          verifier: ActivationService.configured(
            dio: dio,
            apiOrigin: Uri.parse('https://api.example.test'),
          ),
          restorer: app.activationRestorer!,
          token: () async => token,
        ),
      );
      await tester.enterText(find.byType(TextField), 'synthetic-code');
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();
      expect(requests, isEmpty);
      expect(find.textContaining('device messaging token'), findsOneWidget);
      expect(ads.state, AdsEntitlementState.free);
      token = 'synthetic-recovered-fcm-token';
      await tester.enterText(find.byType(TextField), 'synthetic-code');
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();
      expect(requests.single.data['deviceId'], token);
      expect(requests.single.data['isNewUser'], isTrue);
      expect(
        find.text('The activation code was not accepted.'),
        findsOneWidget,
      );
      expect(app.activationRestorer!.hasSavedActivation, isFalse);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
      expect(ads.state, AdsEntitlementState.free);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
