import 'package:digitalpharmacy/core/providers/locale_provider.dart';
import 'package:digitalpharmacy/features/home/view/home_page.dart';
import 'package:digitalpharmacy/features/shell/app_shell.dart';
import 'package:digitalpharmacy/main.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app opens country picker then its actual pharmacy home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    AdsEntitlementController.instance.setFree();
    final app = AppProvider();
    final locale = LocaleProvider();
    await app.init();
    await locale.init();
    addTearDown(app.dispose);
    addTearDown(locale.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppProvider>.value(value: app),
          ChangeNotifierProvider<LocaleProvider>.value(value: locale),
        ],
        child: const DigitalPharmacyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('الأردن'), findsWidgets);
    await tester.tap(find.text('الأردن').last);
    await tester.pumpAndSettle();
    expect(app.shouldAskForCountry, isFalse);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
