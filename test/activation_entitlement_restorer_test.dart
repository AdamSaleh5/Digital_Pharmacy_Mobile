import 'dart:async';

import 'package:digitalpharmacy/core/entitlements/ad_entitlement.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ads = AdsEntitlementController.instance;
  Future<ActivationEntitlementRestorer> create() async =>
      ActivationEntitlementRestorer(
        preferences: await SharedPreferences.getInstance(),
        ads: ads,
      );
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ads.setFree();
  });

  test(
    'saved confirmation restores active without a network request',
    () async {
      final first = await create();
      await first.resolve(
        'synthetic-account-device',
        (_) async => EntitlementStatus.active,
      );
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      ads.setFree();
      final restarted = (await create())..bootstrap();
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      expect(restarted.hasSavedActivation, isTrue);
      await restarted.resolve(
        'synthetic-account-device',
        (_) async => EntitlementStatus.unknown,
      );
      expect(ads.adsAllowed, isFalse);
      await restarted.resolve(
        'synthetic-account-device',
        (_) async => EntitlementStatus.inactive,
      );
      expect(ads.adsAllowed, isTrue);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          ActivationEntitlementRestorer.historyKey,
        ),
        isFalse,
      );
    },
  );

  test('offline restore stays pending without a false active state', () async {
    SharedPreferences.setMockInitialValues({
      ActivationEntitlementRestorer.historyKey: 'synthetic-scope',
    });
    final restorer = (await create())..bootstrap();
    await restorer.resolve(
      'synthetic-scope',
      (_) async => throw StateError('offline'),
    );
    expect(ads.state, AdsEntitlementState.restorationPending);
    expect(ads.adsAllowed, isFalse);
  });

  test(
    'logout rejects a late success and removes confirmation history',
    () async {
      final restorer = await create();
      final response = Completer<EntitlementStatus>();
      final lookup = restorer.resolve(
        'synthetic-first',
        (_) => response.future,
      );
      await restorer.clear();
      response.complete(EntitlementStatus.active);
      await lookup;
      expect(ads.adsAllowed, isTrue);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          ActivationEntitlementRestorer.historyKey,
        ),
        isFalse,
      );
    },
  );

  test('old account result cannot override a newer account lookup', () async {
    final restorer = await create();
    final oldResponse = Completer<EntitlementStatus>();
    final oldLookup = restorer.resolve(
      'synthetic-first',
      (_) => oldResponse.future,
    );
    await restorer.resolve(
      'synthetic-second',
      (_) async => EntitlementStatus.inactive,
    );
    oldResponse.complete(EntitlementStatus.active);
    await oldLookup;
    expect(ads.adsAllowed, isTrue);
  });
}
