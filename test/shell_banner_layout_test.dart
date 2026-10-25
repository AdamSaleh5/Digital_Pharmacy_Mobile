import 'package:digitalpharmacy/core/providers/locale_provider.dart';
import 'package:digitalpharmacy/features/home/view/home_page.dart';
import 'package:digitalpharmacy/features/shell/app_shell.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('home content stays above the banner at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final app = AppProvider();
      final locale = LocaleProvider();
      await app.init();
      await locale.init();
      addTearDown(app.dispose);
      addTearDown(locale.dispose);
      const bannerKey = ValueKey('test-bottom-banner');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: app),
            ChangeNotifierProvider.value(value: locale),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppShell(
              bannerOverride: SizedBox(key: bannerKey, height: 80),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final home = tester.getRect(find.byType(HomePage));
      final banner = tester.getRect(find.byKey(bannerKey));
      expect(
        home.bottom,
        lessThanOrEqualTo(banner.top),
        reason: 'Home scroll viewport must not lie under the clickable ad',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
