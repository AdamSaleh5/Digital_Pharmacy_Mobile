import 'package:digitalpharmacy/core/providers/locale_provider.dart';
import 'package:digitalpharmacy/features/favorites/view/favorites_page.dart';
import 'package:digitalpharmacy/features/shell/app_shell.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('short-screen drawer scrolls to the real favorites entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 420);
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
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider.value(value: locale),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'initial short-screen home');
    tester.state<ScaffoldState>(find.byType(Scaffold).first).openEndDrawer();
    await tester.pumpAndSettle();
    final favorite = find.text(AppLocalizationsEn().navFavorites);
    await tester.scrollUntilVisible(
      favorite,
      250,
      scrollable:
          find
              .descendant(
                of: find.byType(Drawer),
                matching: find.byType(Scrollable),
              )
              .first,
    );
    await tester.drag(
      find.descendant(of: find.byType(Drawer), matching: find.byType(ListView)),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(favorite);
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.text(AppLocalizationsEn().favoritesTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
