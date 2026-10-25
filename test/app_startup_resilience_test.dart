import 'dart:async';
import 'dart:convert';

import 'package:digitalpharmacy/core/utils/app_constants.dart';
import 'package:digitalpharmacy/features/shell/app_shell.dart';
import 'package:digitalpharmacy/main.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ads = AdsEntitlementController.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppConstants.countryKey: 'jordan',
      AppConstants.countryExplicitlySelectedKey: true,
      ActivationEntitlementRestorer.historyKey: 'verify-device-installation-v1',
    });
    ads.setFree();
    ads.setPrivacyPermission(false);
  });
  tearDown(() {
    ads.setFree();
    ads.setPrivacyPermission(false);
  });

  testWidgets('first frame and saved entitlement do not wait for push setup', (
    tester,
  ) async {
    final push = Completer<void>();
    await runDigitalPharmacy(initializePush: () => push.future);
    await tester.pump();
    expect(find.byType(AppShell), findsOneWidget);
    expect(ads.state, AdsEntitlementState.confirmedAdFree);
    expect(ads.canRequestAds, isFalse);
    expect(tester.takeException(), isNull);
    push.complete();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('unavailable native push leaves a usable app and saved state', (
    tester,
  ) async {
    await runDigitalPharmacy(
      initializePush: () async => throw StateError('synthetic native failure'),
    );
    await tester.pump();
    expect(find.byType(AppShell), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(ads.state, AdsEntitlementState.confirmedAdFree);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(ActivationEntitlementRestorer.historyKey),
      'verify-device-installation-v1',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'malformed optional saved collections do not erase data or block init',
    () async {
      final rawFavorites = '{unreadable legacy collection';
      final rawRecent = jsonEncode(['retained query', 42, null]);
      final rawNames = '{unreadable names';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.favKey, rawFavorites);
      await prefs.setString(AppConstants.recentKey, rawRecent);
      await prefs.setString('server_favorite_names_v1', rawNames);
      final app = AppProvider();
      addTearDown(app.dispose);
      await app.init();
      expect(app.favoriteIds, isEmpty);
      expect(app.recentSearches, ['retained query']);
      expect(ads.state, AdsEntitlementState.confirmedAdFree);
      expect(prefs.getString(AppConstants.favKey), rawFavorites);
      expect(prefs.getString(AppConstants.recentKey), rawRecent);
      expect(prefs.getString('server_favorite_names_v1'), rawNames);
    },
  );

  test(
    'mixed legacy favorites keep valid entries without rewriting storage',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(['legacy-favorite', 17, null]);
      await prefs.setString(AppConstants.favKey, raw);
      final app = AppProvider();
      addTearDown(app.dispose);
      await app.init();
      expect(app.favoriteIds, {'legacy-favorite'});
      expect(prefs.getString(AppConstants.favKey), raw);
    },
  );
}
