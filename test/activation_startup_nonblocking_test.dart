import 'dart:async';

import 'package:digitalpharmacy/core/entitlements/ad_entitlement.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('slow entitlement lookup cannot block provider/app startup', () async {
    SharedPreferences.setMockInitialValues({
      ActivationEntitlementRestorer.historyKey: 'synthetic-known-binding',
    });
    final ads = AdsEntitlementController.instance;
    ads.setFree();
    ads.setPrivacyPermission(false);
    final reply = Completer<EntitlementStatus>();
    final session = AuthSession();
    final app = AppProvider(
      authSession: session,
      entitlementLookup: (_) => reply.future,
    );
    var complete = false;
    final initialized = app.init().then((_) => complete = true);
    addTearDown(() async {
      if (!reply.isCompleted) reply.complete(EntitlementStatus.unknown);
      await initialized;
      app.dispose();
      session.dispose();
      ads.setFree();
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(ads.state, AdsEntitlementState.restorationPending);
    expect(ads.canRequestAds, isFalse);
    expect(
      complete,
      isTrue,
      reason: 'main awaits app.init before its first frame',
    );
  });
}
