import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/features/activation/view/activation_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/services/ads/activation_coordinator.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ObservedResponseAdapter implements HttpClientAdapter {
  _ObservedResponseAdapter(this.response);
  final Map<String, dynamic> response;
  int requests = 0;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(response['body']),
      response['statusCode'] as int,
      headers: {
        Headers.contentTypeHeader: [response['contentType'] as String],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ads = AdsEntitlementController.instance;
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/activation/observed-unsupported-media-20261015.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final response = fixture['response'] as Map<String, dynamic>;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ads.setFree();
    ads.setPrivacyPermission(true);
  });
  tearDown(() {
    ads.setFree();
    ads.setPrivacyPermission(false);
  });

  Future<ActivationEntitlementRestorer> prepare(
    AdsEntitlementState state,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final restorer = ActivationEntitlementRestorer(
      preferences: preferences,
      ads: ads,
    );
    if (state != AdsEntitlementState.free) {
      await preferences.setString(
        ActivationEntitlementRestorer.historyKey,
        'synthetic-existing-binding',
      );
      restorer.bootstrap();
      if (state == AdsEntitlementState.confirmedAdFree) {
        ads.setConfirmedAdFree();
      } else {
        ads.beginRestoration();
      }
    }
    addTearDown(restorer.dispose);
    return restorer;
  }

  void expectPreserved(AdsEntitlementState state) {
    expect(ads.state, state);
    expect(ads.canRequestAds, state == AdsEntitlementState.free);
  }

  for (final state in AdsEntitlementState.values) {
    test(
      'OBSERVED415 fixture replay decodes problem+json and preserves $state',
      () async {
        final origin = Uri.parse('https://api.example.test');
        final session =
            AuthSession()..start(
              accessToken: 'synthetic-not-transmitted',
              apiOrigin: origin,
            );
        final dio = Dio();
        final adapter = _ObservedResponseAdapter(response);
        dio.httpClientAdapter = adapter;
        addTearDown(dio.close);
        final restorer = await prepare(state);
        final flow = ActivationCoordinator(
          verifier: ActivationService(
            dio: dio,
            session: session,
            apiOrigin: origin,
          ),
          session: session,
          restorer: restorer,
        );
        try {
          // Fixture replay only. The fake adapter has no network implementation;
          // this synthetic code/session is never sent to the live backend.
          await flow.submit('synthetic-not-transmitted');
          fail(
            '415 must remain a request failure, not an activation decision.',
          );
        } on DioException catch (error) {
          expect(error.type, DioExceptionType.badResponse);
          expect(error.response!.statusCode, 415);
          expect(error.response!.data, isA<Map>());
          expect(error.response!.data['title'], 'Unsupported Media Type');
          expect(error.response!.data['status'], 415);
        }
        expect(adapter.requests, 1);
        expect(adapter.lastRequest!.contentType, Headers.jsonContentType);
        expect(adapter.lastRequest!.data, {
          'activationCode': 'synthetic-not-transmitted',
        });
        expect(session.isSignedIn, isTrue);
        expectPreserved(state);
        expect(
          (await SharedPreferences.getInstance()).getString(
            ActivationEntitlementRestorer.historyKey,
          ),
          state == AdsEntitlementState.free
              ? isNull
              : 'synthetic-existing-binding',
        );
      },
    );
  }

  for (final language in ['en', 'ar']) {
    for (final state in AdsEntitlementState.values) {
      testWidgets(
        'OBSERVED415 fixture replay shows $language retry UI preserving $state',
        (tester) async {
          final origin = Uri.parse('https://api.example.test');
          final session =
              AuthSession()..start(
                accessToken: 'synthetic-not-transmitted',
                apiOrigin: origin,
              );
          final dio = Dio();
          final adapter = _ObservedResponseAdapter(response);
          dio.httpClientAdapter = adapter;
          addTearDown(dio.close);
          final restorer = await prepare(state);
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ActivationPage(
                deviceId: 'synthetic-fcm-test-token',
                session: session,
                apiOrigin: origin,
                restorer: restorer,
                verifier: ActivationService(
                  dio: dio,
                  session: session,
                  apiOrigin: origin,
                ),
              ),
            ),
          );
          if (state == AdsEntitlementState.confirmedAdFree) {
            expect(adapter.requests, 0);
            expect(
              tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
              isNull,
            );
            expectPreserved(state);
            return;
          }
          await tester.enterText(
            find.byType(TextField),
            'synthetic-not-transmitted',
          );
          await tester.tap(
            find.text(language == 'en' ? 'Verify code' : 'تحقق من الكود'),
          );
          await tester.pumpAndSettle();
          final l10n =
              AppLocalizations.of(tester.element(find.byType(ActivationPage)))!;
          expect(find.text(l10n.activationVerificationFailed), findsOneWidget);
          expect(find.text(l10n.activationConfirmed), findsNothing);
          expect(find.text(l10n.activationUnconfirmed), findsNothing);
          expect(find.textContaining('Unsupported Media Type'), findsNothing);
          expect(find.textContaining('traceId'), findsNothing);
          expect(find.textContaining('[redacted]'), findsNothing);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            isEmpty,
          );
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNotNull,
          );
          await tester.pump(const Duration(seconds: 5));
          expect(adapter.requests, 1);
          expect(session.isSignedIn, isTrue);
          expectPreserved(state);
          expect(
            restorer.preferences.getString(
              ActivationEntitlementRestorer.historyKey,
            ),
            state == AdsEntitlementState.free
                ? isNull
                : 'synthetic-existing-binding',
          );
        },
      );
    }
  }
}
