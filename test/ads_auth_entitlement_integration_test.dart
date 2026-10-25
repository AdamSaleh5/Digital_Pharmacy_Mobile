import 'dart:async';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:digitalpharmacy/core/entitlements/ad_entitlement.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/notifications/push_token_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const apiOrigin = 'https://api.example.test';
  final entitlement = AdsEntitlementController.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    entitlement.setFree();
  });

  test(
    'token rotation and reassociation failure preserve confirmed history and suppression',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final restorer = ActivationEntitlementRestorer(
        preferences: prefs,
        ads: entitlement,
      );
      await restorer.resolve(
        'synthetic-stable-binding',
        (_) async => EntitlementStatus.active,
      );
      final refreshes = StreamController<String>();
      final pending = PendingPushTokenRegistration();
      final lifecycle = PushTokenLifecycle(
        fetchCurrentToken: () async => 'synthetic-old-fcm',
        tokenRefreshes: refreshes.stream,
        onTokenChanged: pending.markPending,
      );
      await lifecycle.start();
      refreshes.add('synthetic-new-fcm');
      await Future<void>.delayed(Duration.zero);
      final attempts = <String>[];
      await pending.retry((token) async {
        attempts.add(token);
        throw StateError('synthetic offline');
      });
      expect(attempts, ['synthetic-new-fcm']);
      expect(pending.hasPendingRegistration, isTrue);
      expect(entitlement.canRequestAds, isFalse);
      expect(entitlement.state, AdsEntitlementState.confirmedAdFree);
      expect(
        prefs.getString(ActivationEntitlementRestorer.historyKey),
        'synthetic-stable-binding',
      );
      await lifecycle.dispose();
      await refreshes.close();
    },
  );

  test('admin session changes never revoke installation entitlement', () async {
    final session = AuthSession();
    final app = AppProvider(authSession: session);
    addTearDown(app.dispose);

    await app.init();
    expect(entitlement.state, AdsEntitlementState.free);
    expect(entitlement.adsAllowed, isTrue);

    session.start(
      accessToken: 'synthetic-user-token',
      apiOrigin: Uri.parse(apiOrigin),
    );
    expect(entitlement.state, AdsEntitlementState.free);
    expect(entitlement.adsAllowed, isTrue);

    entitlement.setConfirmedAdFree();
    session.signOut();
    expect(entitlement.state, AdsEntitlementState.confirmedAdFree);
    expect(entitlement.adsAllowed, isFalse);
    session.start(
      accessToken: 'synthetic-admin',
      apiOrigin: Uri.parse(apiOrigin),
    );
    expect(entitlement.state, AdsEntitlementState.confirmedAdFree);
  });

  test(
    'a code-less startup does not overwrite a restored server confirmation',
    () async {
      // Simulate an upstream bootstrap resolver restoring a prior server-confirmed
      // result before AppProvider initializes. Production never sets this from
      // local code or an undocumented verify-device response.
      entitlement.setConfirmedAdFree();
      final app = AppProvider(authSession: AuthSession());
      addTearDown(app.dispose);

      await app.init();

      expect(entitlement.state, AdsEntitlementState.confirmedAdFree);
      expect(entitlement.adsAllowed, isFalse);
    },
  );

  test(
    'pending restoration remains suppressed through provider startup and sign-in',
    () async {
      entitlement.beginRestoration();
      final session = AuthSession();
      final app = AppProvider(authSession: session);
      addTearDown(app.dispose);

      await app.init();
      expect(entitlement.state, AdsEntitlementState.restorationPending);
      expect(entitlement.adsAllowed, isFalse);

      session.start(
        accessToken: 'synthetic-restoring-user-token',
        apiOrigin: Uri.parse(apiOrigin),
      );
      expect(entitlement.state, AdsEntitlementState.restorationPending);
      expect(entitlement.adsAllowed, isFalse);

      session.signOut();
      expect(entitlement.state, AdsEntitlementState.restorationPending);
      expect(entitlement.adsAllowed, isFalse);
    },
  );

  test('unconfirmed activation payload cannot enable ad-free access', () async {
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-user-token',
          apiOrigin: Uri.parse(apiOrigin),
        );
    entitlement.setFree();
    final dio = Dio(BaseOptions(baseUrl: apiOrigin));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {'active': true, 'adFree': true},
            ),
          );
        },
      ),
    );
    final service = ActivationService(
      dio: dio,
      session: session,
      apiOrigin: Uri.parse(apiOrigin),
    );

    final result = await service.verifyDevice(
      activationCode: 'synthetic-activation-code',
    );

    expect(result, ActivationVerification.unconfirmed);
    expect(entitlement.state, AdsEntitlementState.free);
    expect(entitlement.adsAllowed, isTrue);
  });
}
