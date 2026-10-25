import 'dart:async';

import 'package:digitalpharmacy/core/entitlements/ad_entitlement.dart';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/activation_coordinator.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _Verifier implements ActivationVerifier {
  _Verifier(this.reply);
  final Future<ActivationVerification> Function() reply;
  @override
  Future<ActivationVerification> verifyDevice({
    required String activationCode,
    bool? isNewUser,
    String? deviceId,
  }) => reply();
}

class _SlowStore extends InMemorySharedPreferencesStore {
  _SlowStore({Map<String, Object> initialValues = const {}})
    : super.withData(initialValues);
  final started = Completer<void>();
  final release = Completer<bool>();
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (!started.isCompleted) {
      started.complete();
      if (!await release.future) return false;
    }
    return super.setValue(type, key, value);
  }
}

class _ThrowingStore extends InMemorySharedPreferencesStore {
  _ThrowingStore({Map<String, Object> initialValues = const {}})
    : super.withData(initialValues);
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      throw StateError('synthetic storage unavailable');
  @override
  Future<bool> remove(String key) async =>
      throw StateError('synthetic storage unavailable');
}

class _SlowRemovalStore extends InMemorySharedPreferencesStore {
  _SlowRemovalStore(String scope)
    : super.withData({
        'flutter.${ActivationEntitlementRestorer.historyKey}': scope,
      });
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<bool> remove(String key) async {
    if (!started.isCompleted) {
      started.complete();
      await release.future;
    }
    return super.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ads = AdsEntitlementController.instance;
  final origin = Uri.parse('https://api.example.test');
  late AuthSession session;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ads.setFree();
    ads.setPrivacyPermission(true);
    session =
        AuthSession()
          ..start(accessToken: 'synthetic-session', apiOrigin: origin);
  });
  tearDown(() {
    ads.setFree();
    ads.setPrivacyPermission(false);
  });

  test(
    'SIMULATED explicit acknowledgment suppresses all gates and persists only binding',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final restorer = ActivationEntitlementRestorer(
        preferences: prefs,
        ads: ads,
      );
      final gates = List.generate(4, (_) => AdLoadGate(ads));
      final generations = gates.map((g) => g.beginAttempt()).toList();
      final flow = ActivationCoordinator(
        verifier: _Verifier(
          () async => ActivationVerification.active(
            confirmedScope: 'synthetic-nonsecret-binding',
          ),
        ),
        session: session,
        restorer: restorer,
      );
      expect(
        await flow.submit('synthetic-code'),
        ActivationSubmission.confirmed,
      );
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      for (var i = 0; i < gates.length; i++) {
        expect(gates[i].accepts(generations[i]), isFalse);
        gates[i].dispose();
      }
      expect(prefs.getKeys(), {ActivationEntitlementRestorer.historyKey});
      expect(
        prefs.getString(ActivationEntitlementRestorer.historyKey),
        'synthetic-nonsecret-binding',
      );
      ads.setFree();
      final restarted = ActivationEntitlementRestorer(
        preferences: prefs,
        ads: ads,
      )..bootstrap();
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      await restarted.restore(
        (_) async => throw StateError('synthetic offline'),
      );
      expect(ads.canRequestAds, isFalse);
      await restarted.restore((_) async => EntitlementStatus.active);
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      await restarted.restore((_) async => EntitlementStatus.inactive);
      expect(ads.state, AdsEntitlementState.free);
      expect(
        prefs.containsKey(ActivationEntitlementRestorer.historyKey),
        isFalse,
      );
    },
  );

  test('unconfirmed response preserves existing confirmation', () async {
    ads.setConfirmedAdFree();
    final flow = ActivationCoordinator(
      verifier: _Verifier(() async => ActivationVerification.unconfirmed),
      session: session,
    );
    expect(
      await flow.submit('synthetic-code'),
      ActivationSubmission.unconfirmed,
    );
    expect(ads.state, AdsEntitlementState.confirmedAdFree);
  });

  test(
    'late server acknowledgment after installation reset cannot persist',
    () async {
      final app = AppProvider(authSession: session);
      await app.init();
      addTearDown(app.dispose);
      final reply = Completer<ActivationVerification>();
      final flow = ActivationCoordinator(
        verifier: _Verifier(() => reply.future),
        session: session,
        restorer: app.activationRestorer,
      );
      final pending = flow.submit('synthetic-code');
      await app.activationRestorer!.clear();
      reply.complete(
        ActivationVerification.active(confirmedScope: 'synthetic-old-binding'),
      );
      expect(await pending, ActivationSubmission.superseded);
      expect(ads.state, AdsEntitlementState.free);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          ActivationEntitlementRestorer.historyKey,
        ),
        isFalse,
      );
    },
  );

  test(
    'installation reset during disk write queues removal after obsolete write',
    () async {
      final disk = _SlowStore();
      SharedPreferencesStorePlatform.instance = disk;
      final app = AppProvider(authSession: session);
      await app.init();
      addTearDown(app.dispose);
      final flow = ActivationCoordinator(
        verifier: _Verifier(
          () async => ActivationVerification.active(
            confirmedScope: 'synthetic-obsolete-binding',
          ),
        ),
        session: session,
        restorer: app.activationRestorer,
      );
      final pending = flow.submit('synthetic-code');
      await disk.started.future;
      expect(ads.state, AdsEntitlementState.restorationPending);
      final reset = app.activationRestorer!.clear();
      disk.release.complete(true);
      expect(await pending, ActivationSubmission.superseded);
      await reset;
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(
        prefs.containsKey(ActivationEntitlementRestorer.historyKey),
        isFalse,
      );
      expect(ads.state, AdsEntitlementState.free);
    },
  );

  test(
    'failed persistence never grants active and keeps ads suppressed',
    () async {
      final disk = _SlowStore();
      SharedPreferencesStorePlatform.instance = disk;
      final restorer = ActivationEntitlementRestorer(
        preferences: await SharedPreferences.getInstance(),
        ads: ads,
      );
      final flow = ActivationCoordinator(
        verifier: _Verifier(
          () async => ActivationVerification.active(
            confirmedScope: 'synthetic-binding',
          ),
        ),
        session: session,
        restorer: restorer,
      );
      final pending = flow.submit('synthetic-code');
      await disk.started.future;
      disk.release.complete(false);
      expect(await pending, ActivationSubmission.notSaved);
      expect(ads.state, AdsEntitlementState.restorationPending);
      expect(ads.canRequestAds, isFalse);
    },
  );

  for (final throwsOnWrite in [false, true]) {
    for (final priorScope in <String?>[null, 'synthetic-prior-confirmation']) {
      test(
        'failed write repairs cached marker and preserves prior=$priorScope throws=$throwsOnWrite',
        () async {
          final initialValues = <String, Object>{
            if (priorScope != null)
              'flutter.${ActivationEntitlementRestorer.historyKey}': priorScope,
          };
          final slow = _SlowStore(initialValues: initialValues);
          if (!throwsOnWrite) slow.release.complete(false);
          SharedPreferencesStorePlatform.instance =
              throwsOnWrite
                  ? _ThrowingStore(initialValues: initialValues)
                  : slow;
          final prefs = await SharedPreferences.getInstance();
          final restorer = ActivationEntitlementRestorer(
            preferences: prefs,
            ads: ads,
          )..bootstrap();
          addTearDown(restorer.dispose);
          final flow = ActivationCoordinator(
            verifier: _Verifier(
              () async => ActivationVerification.active(
                confirmedScope: 'synthetic-unsaved-confirmation',
              ),
            ),
            restorer: restorer,
          );
          expect(
            await flow.submit('synthetic-code'),
            ActivationSubmission.notSaved,
          );
          // No reload: this catches SharedPreferences' speculative cache update.
          expect(
            prefs.getString(ActivationEntitlementRestorer.historyKey),
            priorScope,
          );
          ads.setFree();
          final rebuilt = ActivationEntitlementRestorer(
            preferences: prefs,
            ads: ads,
          )..bootstrap();
          addTearDown(rebuilt.dispose);
          expect(rebuilt.hasSavedActivation, priorScope != null);
          expect(
            ads.state,
            priorScope == null
                ? AdsEntitlementState.free
                : AdsEntitlementState.confirmedAdFree,
          );
          await prefs.reload();
          expect(
            prefs.getString(ActivationEntitlementRestorer.historyKey),
            priorScope,
          );
        },
      );
    }
  }

  for (final priorScope in <String?>[null, 'synthetic-prior-confirmation']) {
    for (final disposeDuringWrite in [false, true]) {
      test(
        'obsolete write repairs disk preserving prior=$priorScope disposed=$disposeDuringWrite',
        () async {
          final disk = _SlowStore(
            initialValues: {
              if (priorScope != null)
                'flutter.${ActivationEntitlementRestorer.historyKey}':
                    priorScope,
            },
          );
          SharedPreferencesStorePlatform.instance = disk;
          final prefs = await SharedPreferences.getInstance();
          final restorer = ActivationEntitlementRestorer(
            preferences: prefs,
            ads: ads,
          )..bootstrap();
          addTearDown(restorer.dispose);
          final old = ActivationCoordinator(
            verifier: _Verifier(
              () async => ActivationVerification.active(
                confirmedScope: 'synthetic-obsolete-confirmation',
              ),
            ),
            restorer: restorer,
          ).submit('synthetic-old-code');
          await disk.started.future;
          if (disposeDuringWrite) {
            restorer.dispose();
          } else {
            final newer = ActivationCoordinator(
              verifier: _Verifier(() async => ActivationVerification.rejected),
              restorer: restorer,
            );
            expect(
              await newer.submit('synthetic-new-code'),
              ActivationSubmission.rejected,
            );
          }
          disk.release.complete(true);
          expect(await old, ActivationSubmission.superseded);
          expect(
            prefs.getString(ActivationEntitlementRestorer.historyKey),
            priorScope,
          );
          // Reload reads the backing store, not the repaired Dart cache.
          await prefs.reload();
          expect(
            prefs.getString(ActivationEntitlementRestorer.historyKey),
            priorScope,
          );
          ads.setFree();
          final restarted = ActivationEntitlementRestorer(
            preferences: prefs,
            ads: ads,
          )..bootstrap();
          addTearDown(restarted.dispose);
          expect(restarted.hasSavedActivation, priorScope != null);
          expect(
            ads.state,
            priorScope == null
                ? AdsEntitlementState.free
                : AdsEntitlementState.confirmedAdFree,
          );
        },
      );
    }
  }

  test('obsolete removal cannot erase previously saved activation', () async {
    const priorScope = 'synthetic-prior-confirmation';
    final disk = _SlowRemovalStore(priorScope);
    SharedPreferencesStorePlatform.instance = disk;
    final prefs = await SharedPreferences.getInstance();
    final restorer = ActivationEntitlementRestorer(preferences: prefs, ads: ads)
      ..bootstrap();
    addTearDown(restorer.dispose);
    final obsolete = restorer.resolve(
      priorScope,
      (_) async => EntitlementStatus.inactive,
    );
    await disk.started.future;
    restorer.beginVerification();
    disk.release.complete();
    expect(await obsolete, isFalse);
    await prefs.reload();
    expect(
      prefs.getString(ActivationEntitlementRestorer.historyKey),
      priorScope,
    );
    expect(restorer.hasSavedActivation, isTrue);
  });

  test('new successful write follows obsolete write repair', () async {
    final disk = _SlowStore();
    SharedPreferencesStorePlatform.instance = disk;
    final prefs = await SharedPreferences.getInstance();
    final restorer = ActivationEntitlementRestorer(preferences: prefs, ads: ads)
      ..bootstrap();
    addTearDown(restorer.dispose);
    ActivationCoordinator flow(String scope) => ActivationCoordinator(
      verifier: _Verifier(
        () async => ActivationVerification.active(confirmedScope: scope),
      ),
      restorer: restorer,
    );
    final old = flow(
      'synthetic-obsolete-confirmation',
    ).submit('synthetic-old-code');
    await disk.started.future;
    final current = flow(
      'synthetic-current-confirmation',
    ).submit('synthetic-current-code');
    disk.release.complete(true);
    expect(await old, ActivationSubmission.superseded);
    expect(await current, ActivationSubmission.confirmed);
    await prefs.reload();
    expect(
      prefs.getString(ActivationEntitlementRestorer.historyKey),
      'synthetic-current-confirmation',
    );
    expect(ads.state, AdsEntitlementState.confirmedAdFree);
  });

  test(
    'provider invokes explicit status adapter on startup and foreground retry',
    () async {
      SharedPreferences.setMockInitialValues({
        ActivationEntitlementRestorer.historyKey: 'synthetic-binding',
      });
      var calls = 0;
      final app = AppProvider(
        authSession: session,
        entitlementLookup: (_) async {
          calls++;
          return calls == 1
              ? EntitlementStatus.unknown
              : EntitlementStatus.active;
        },
      );
      addTearDown(app.dispose);
      await app.init();
      expect(ads.state, AdsEntitlementState.restorationPending);
      await app.restoreActivation();
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      expect(calls, 2);
    },
  );

  test(
    'storage exceptions pause ads without crashing restore or logout',
    () async {
      SharedPreferencesStorePlatform.instance = _ThrowingStore();
      final restorer = ActivationEntitlementRestorer(
        preferences: await SharedPreferences.getInstance(),
        ads: ads,
      );
      expect(
        await restorer.resolve(
          'synthetic-binding',
          (_) async => EntitlementStatus.active,
        ),
        isFalse,
      );
      expect(ads.state, AdsEntitlementState.restorationPending);
      await restorer.clear();
      expect(ads.state, AdsEntitlementState.free);
    },
  );

  test('disposed provider rejects a late restoration response', () async {
    SharedPreferences.setMockInitialValues({
      ActivationEntitlementRestorer.historyKey: 'synthetic-binding',
    });
    final reply = Completer<EntitlementStatus>();
    final entered = Completer<void>();
    final app = AppProvider(
      authSession: session,
      entitlementLookup: (_) {
        entered.complete();
        return reply.future;
      },
    );
    final init = app.init();
    await entered.future;
    app.dispose();
    reply.complete(EntitlementStatus.active);
    await init;
    expect(ads.state, AdsEntitlementState.restorationPending);
  });

  test(
    'explicit acknowledgment pauses ads even when persistence is unavailable',
    () async {
      final flow = ActivationCoordinator(
        verifier: _Verifier(
          () async => ActivationVerification.active(
            confirmedScope: 'synthetic-binding',
          ),
        ),
        session: session,
      );
      expect(
        await flow.submit('synthetic-code'),
        ActivationSubmission.notSaved,
      );
      expect(ads.state, AdsEntitlementState.restorationPending);
    },
  );

  test(
    'disposed provider rejects an acknowledgment arriving before storage starts',
    () async {
      final app = AppProvider(authSession: session);
      await app.init();
      final reply = Completer<ActivationVerification>();
      final flow = ActivationCoordinator(
        verifier: _Verifier(() => reply.future),
        session: session,
        restorer: app.activationRestorer,
      );
      final pending = flow.submit('synthetic-code');
      app.dispose();
      reply.complete(
        ActivationVerification.active(
          confirmedScope: 'synthetic-obsolete-binding',
        ),
      );
      expect(await pending, ActivationSubmission.superseded);
      expect(ads.state, AdsEntitlementState.free);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          ActivationEntitlementRestorer.historyKey,
        ),
        isFalse,
      );
    },
  );
  test(
    'new page verification supersedes an older installation reply',
    () async {
      final restorer = ActivationEntitlementRestorer(
        preferences: await SharedPreferences.getInstance(),
        ads: ads,
      );
      final oldReply = Completer<ActivationVerification>();
      final first = ActivationCoordinator(
        verifier: _Verifier(() => oldReply.future),
        restorer: restorer,
      );
      final second = ActivationCoordinator(
        verifier: _Verifier(
          () async => ActivationVerification.active(
            confirmedScope: 'synthetic-new-installation-binding',
          ),
        ),
        restorer: restorer,
      );
      final stale = first.submit('synthetic-old');
      expect(
        await second.submit('synthetic-new'),
        ActivationSubmission.confirmed,
      );
      oldReply.complete(
        ActivationVerification.active(
          confirmedScope: 'synthetic-obsolete-binding',
        ),
      );
      expect(await stale, ActivationSubmission.superseded);
      expect(restorer.confirmationScope, 'synthetic-new-installation-binding');
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
    },
  );

  test(
    'explicit installation reset prevents duplicate coalescing with obsolete pending verification',
    () async {
      final restorer = ActivationEntitlementRestorer(
        preferences: await SharedPreferences.getInstance(),
        ads: ads,
      );
      final replies = [
        Completer<ActivationVerification>(),
        Completer<ActivationVerification>(),
      ];
      var requests = 0;
      final flow = ActivationCoordinator(
        verifier: _Verifier(() => replies[requests++].future),
        restorer: restorer,
      );
      final stale = flow.submit('synthetic-code');
      await restorer.clear();
      final current = flow.submit('synthetic-code');
      expect(identical(stale, current), isFalse);
      expect(requests, 2);
      replies[1].complete(
        ActivationVerification.active(
          confirmedScope: 'synthetic-current-binding',
        ),
      );
      expect(await current, ActivationSubmission.confirmed);
      replies[0].complete(
        ActivationVerification.active(
          confirmedScope: 'synthetic-stale-binding',
        ),
      );
      expect(await stale, ActivationSubmission.superseded);
      expect(restorer.confirmationScope, 'synthetic-current-binding');
    },
  );
}
