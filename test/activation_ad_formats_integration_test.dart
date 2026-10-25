import 'dart:async';
import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/entitlements/ad_entitlement.dart';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/core/widgets/ad_banner_placement.dart';
import 'package:digitalpharmacy/core/widgets/inline_native_ad_card.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/activation_coordinator.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/ads/ad_service.dart';
import 'package:digitalpharmacy/services/ads/ad_size_settings.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:digitalpharmacy/services/notifications/push_token_lifecycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ExplicitFixtureAdapter extends ActivationApiAdapter {
  const _ExplicitFixtureAdapter();
  @override
  String get verificationPath => '/api/users/verify-device';
  @override
  ActivationVerification decodeVerification(ActivationApiReply reply) =>
      ActivationVerification.active(confirmedScope: 'synthetic-stable-binding');
}

// End-to-end CLIENT evidence only. Both API and SDK channels are mocked.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final ads = AdsEntitlementController.instance;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AdSizeSettings.instance.setPreference(AdSizePreference.compact);
  });
  for (final initiallyLoaded in [false, true]) {
    testWidgets(
      'SIMULATED adapter confirmation suppresses all SDK paths, loaded=$initiallyLoaded, navigation/restart/token/revocation',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        ads.setFree();
        ads.setPrivacyPermission(true);
        final calls = <MethodCall>[];
        messenger.setMockMethodCallHandler(instanceManager.channel, (
          call,
        ) async {
          calls.add(call);
          return null;
        });
        messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
          call,
        ) async {
          if (call.method == 'create') return 0;
          if (call.method == 'resize') return {'width': 320.0, 'height': 120.0};
          return null;
        });
        final origin = Uri.parse('https://api.example.test');
        final session =
            AuthSession()
              ..start(accessToken: 'synthetic-session', apiOrigin: origin);
        final freshSession = AuthSession();
        final prefs = await SharedPreferences.getInstance();
        final restorer = ActivationEntitlementRestorer(
          preferences: prefs,
          ads: ads,
        );
        var syntheticRequests = 0;
        final dio =
            Dio()
              ..interceptors.add(
                InterceptorsWrapper(
                  onRequest: (request, handler) {
                    syntheticRequests++;
                    handler.resolve(
                      Response<dynamic>(
                        requestOptions: request,
                        statusCode: 200,
                        data: const {'syntheticFixtureOnly': true},
                      ),
                    );
                  },
                ),
              );
        final verifier = ActivationService(
          dio: dio,
          session: session,
          apiOrigin: origin,
          adapter: const _ExplicitFixtureAdapter(),
        );
        final flow = ActivationCoordinator(
          verifier: verifier,
          session: session,
          restorer: restorer,
        );
        final services = <AdService>[];
        final refreshes = StreamController<String>.broadcast();
        PushTokenLifecycle? tokens;
        AppProvider? restarted;
        void Function()? observer;
        List<int> ids(String method) =>
            calls
                .where((c) => c.method == method)
                .map((c) => (c.arguments as Map)['adId'] as int)
                .toList();
        Widget screen() => const MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [InlineNativeAdCard.forTesting(), Text('Main content')],
            ),
            bottomNavigationBar: AdBannerPlacement.forTesting(),
          ),
        );
        Future<void> settle() async {
          await tester.pump(const Duration(milliseconds: 20));
          await tester.pump();
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await tester.pump();
        }

        try {
          final service = AdService.forTesting(isSupported: () => true);
          services.add(service);
          service.loadInterstitial();
          await tester.pumpWidget(screen());
          await settle();
          debugPrint("fixture phase: slots initialized");
          final nativeId = ids('loadNativeAd').single;
          final bannerId = ids('loadBannerAd').single;
          final interstitialId = ids('loadInterstitialAd').single;
          final native = instanceManager.adFor(nativeId)! as NativeAd;
          final banner = instanceManager.adFor(bannerId)! as BannerAd;
          final interstitial =
              instanceManager.adFor(interstitialId)! as InterstitialAd;
          if (initiallyLoaded) {
            native.listener.onAdLoaded!(native);
            banner.listener.onAdLoaded!(banner);
            interstitial.adLoadCallback.onAdLoaded(interstitial);
            await tester.pump();
            expect(find.byType(AdWidget), findsNWidgets(2));
          }
          var pendingObserved = false;
          var pendingSlotsDisposed = false;
          var pendingShowBlocked = false;
          observer = () {
            if (ads.state == AdsEntitlementState.restorationPending) {
              pendingObserved = true;
              pendingSlotsDisposed =
                  instanceManager.adFor(nativeId) == null &&
                  instanceManager.adFor(bannerId) == null;
              pendingShowBlocked = !service.showInterstitialIfReady();
            }
          };
          ads.addListener(observer);
          ActivationSubmission? result;
          Object? submissionError;
          final submitting = flow
              .submit('synthetic-code')
              .then<void>(
                (value) => result = value,
                onError: (Object error) => submissionError = error,
              );
          for (
            var i = 0;
            i < 10 && result == null && submissionError == null;
            i++
          ) {
            await settle();
          }
          debugPrint(
            "fixture phase: confirmation result=$result, error=$submissionError, requests=$syntheticRequests",
          );
          expect(submissionError, isNull);
          expect(result, ActivationSubmission.confirmed);
          await submitting;
          expect(pendingObserved, isTrue);
          expect(pendingSlotsDisposed, isTrue);
          expect(pendingShowBlocked, isTrue);
          ads.removeListener(observer);
          observer = null;
          await tester.pump();
          expect(find.byType(AdWidget), findsNothing);
          expect(
            prefs.getString(ActivationEntitlementRestorer.historyKey),
            'synthetic-stable-binding',
          );
          final beforeRequests =
              calls.where((c) => c.method.startsWith('load')).length;
          native.listener.onAdLoaded!(native);
          banner.listener.onAdLoaded!(banner);
          interstitial.adLoadCallback.onAdLoaded(interstitial);
          await settle();
          expect(find.byType(AdWidget), findsNothing);
          expect(service.showInterstitialIfReady(), isFalse);
          service.loadAppOpen();
          service.showLaunchAppOpenIfReady();
          expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
          expect(calls.where((c) => c.method == 'loadAppOpenAd'), isEmpty);
          expect(
            calls.where((c) => c.method.startsWith('load')).length,
            beforeRequests,
          );

          final pending = PendingPushTokenRegistration();
          tokens = PushTokenLifecycle(
            fetchCurrentToken: () async => 'synthetic-old-fcm',
            tokenRefreshes: refreshes.stream,
            onTokenChanged: pending.markPending,
          );
          debugPrint("fixture phase: token rotation");
          await tokens.start();
          refreshes.add('synthetic-new-fcm');
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          final registered = await pending.retry(
            (_) async => throw StateError('synthetic reassociation offline'),
          );
          expect(registered, isFalse);
          expect(pending.hasPendingRegistration, isTrue);
          expect(ads.state, AdsEntitlementState.confirmedAdFree);
          expect(
            prefs.getString(ActivationEntitlementRestorer.historyKey),
            'synthetic-stable-binding',
          );

          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          await tester.pumpWidget(screen());
          await settle();
          expect(find.byType(AdWidget), findsNothing);
          expect(
            calls.where((c) => c.method.startsWith('load')).length,
            beforeRequests,
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          service.disposeForTesting();
          services.remove(service);
          ads.setFree(); // Simulated process: no UI/SDK may mount before bootstrap.
          restarted = AppProvider(
            authSession: freshSession,
            activationAdapter: const _ExplicitFixtureAdapter(),
          );
          debugPrint("fixture phase: simulated restart");
          await restarted.init();
          expect(ads.state, AdsEntitlementState.confirmedAdFree);
          final nextService = AdService.forTesting(isSupported: () => true);
          services.add(nextService);
          nextService.loadInterstitial();
          nextService.loadAppOpen();
          await tester.pumpWidget(screen());
          await settle();
          expect(find.byType(AdWidget), findsNothing);
          expect(
            calls.where((c) => c.method.startsWith('load')).length,
            beforeRequests,
          );
          await restarted.activationRestorer!.restore(
            (_) async => EntitlementStatus.unknown,
          );
          expect(ads.canRequestAds, isFalse);
          await restarted.activationRestorer!.restore(
            (_) async => EntitlementStatus.active,
          );
          expect(ads.state, AdsEntitlementState.confirmedAdFree);
          await restarted.activationRestorer!.restore(
            (_) async => EntitlementStatus.inactive,
          );
          await settle();
          expect(ads.state, AdsEntitlementState.free);
          expect(
            prefs.containsKey(ActivationEntitlementRestorer.historyKey),
            isFalse,
          );
          expect(ids('loadNativeAd'), hasLength(2));
          expect(ids('loadBannerAd'), hasLength(2));
          expect(ids('loadInterstitialAd'), hasLength(2));
          expect(tester.takeException(), isNull);
        } finally {
          debugPrint("fixture phase: bounded cleanup");
          if (observer != null) ads.removeListener(observer);
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          for (final service in services) {
            service.disposeForTesting();
          }
          for (final call in List<MethodCall>.from(calls).where(
            (c) => [
              'loadNativeAd',
              'loadBannerAd',
              'loadInterstitialAd',
            ].contains(c.method),
          )) {
            final ad = instanceManager.adFor(
              (call.arguments as Map)['adId'] as int,
            );
            if (ad != null) await tester.runAsync(() => ad.dispose());
          }
          await tester.runAsync(() async {
            await tokens?.dispose();
          });
          await tester.runAsync(() => refreshes.close());
          restarted?.dispose();
          restorer.dispose();
          dio.close();
          session.dispose();
          freshSession.dispose();
          ads.setPrivacyPermission(false);
          ads.setFree();
          messenger.setMockMethodCallHandler(instanceManager.channel, null);
          messenger.setMockMethodCallHandler(
            SystemChannels.platform_views,
            null,
          );
        }
      },
    );
  }
}
