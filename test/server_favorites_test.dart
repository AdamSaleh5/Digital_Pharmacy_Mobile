import 'dart:convert';

import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/features/favorites/view/favorites_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'favorite_ids_v1': jsonEncode(['d1']),
      'selected_country_v1': 'jordan',
      'country_explicitly_selected_v1': true,
    }),
  );

  test(
    'API favorites persist their ID/name/scope without deleting legacy data',
    () async {
      final app = AppProvider();
      addTearDown(app.dispose);
      await app.init();
      await app.toggleServerFavorite(id: 17, name: 'Synthetic server product');
      expect(app.favoriteIds, contains('d1'));
      final restored = AppProvider();
      addTearDown(restored.dispose);
      await restored.init();
      expect(restored.serverFavorites.single.id, 17);
      expect(restored.serverFavorites.single.name, 'Synthetic server product');
      expect(restored.legacyFavoriteCount, 1);
      await restored.setCountry(AppCountry.palestine);
      expect(restored.serverFavorites, isEmpty);
      expect(restored.favoriteIds.length, 2);
      await restored.setCountry(AppCountry.jordan);
      expect(restored.serverFavorites.single.id, 17);
      await restored.toggleServerFavorite(
        id: 17,
        name: 'Synthetic server product',
      );
      expect(restored.favoriteIds, ['d1']);
    },
  );

  testWidgets(
    'legacy favorites are retained without rendering mock medicine data',
    (tester) async {
      final app = AppProvider();
      addTearDown(app.dispose);
      await app.init();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const FavoritesPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('earlier saved items are retained'),
        findsOneWidget,
      );
      expect(find.text('بانادول أدفانس'), findsNothing);
      expect(app.favoriteIds, contains('d1'));
    },
  );
}
