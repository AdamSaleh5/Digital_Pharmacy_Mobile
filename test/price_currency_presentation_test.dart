import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/data/models/drug.dart';
import 'package:digitalpharmacy/features/drugs/data/mappers/medication_mapper.dart';
import 'package:digitalpharmacy/features/drugs/data/models/medication_item.dart';
import 'package:digitalpharmacy/features/drugs/view/medication_alternatives_page.dart';
import 'package:digitalpharmacy/features/drugs/widgets/dosage_forms_sheet.dart';
import 'package:digitalpharmacy/features/search/widgets/drug_info_card.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(String language, Widget child) => MaterialApp(
  key: UniqueKey(),
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  final original = kAppCountry;
  tearDown(() => setAppCountry(original));
  for (final language in ['en', 'ar']) {
    final suffix =
        language == 'en' ? 'currency unspecified' : 'العملة غير محددة';
    testWidgets(
      'server price explicitly lacks currency in $language after country switch',
      (tester) async {
        Widget cards() => SingleChildScrollView(
          child: Column(
            children: [
              for (final price in [12.5, 0, null])
                DrugInfoCard(
                  drug: MedicationMapper.toDrug(
                    MedicationItem.fromJson({
                      'id': 17,
                      'tradeName': 'Synthetic product',
                      'scientificName': 'Synthetic',
                      'company': 'Synthetic',
                      'agent': 'Synthetic',
                      'pharmaceuticalForm': 'tablet',
                      'price': price,
                    }),
                  ),
                  showActionButton: false,
                ),
            ],
          ),
        );
        for (final country in AppCountry.values) {
          setAppCountry(country);
          await tester.pumpWidget(host(language, cards()));
          await tester.pumpAndSettle();
          for (final number in ['12.50', '0.00', '—']) {
            expect(find.text('$number ($suffix)'), findsOneWidget);
          }
          expect(find.textContaining('₪'), findsNothing);
          expect(find.textContaining('د.أ'), findsNothing);
          expect(tester.takeException(), isNull);
        }
      },
    );
    testWidgets(
      'narrow forms sheet shows unknown currency without overflow in $language',
      (tester) async {
        await tester.pumpWidget(
          host(
            language,
            Center(
              child: SizedBox(
                width: 260,
                child: DosageFormsSheet(
                  drugName: 'Synthetic product',
                  loadForms:
                      (_) async => const [
                        DosageFormPrice(
                          formName:
                              'Long synthetic pharmaceutical form 5000 units / 0.2 ml - ten ampoules',
                          priceJod: 37.53,
                          priceCurrencyKnown: false,
                        ),
                      ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('37.53 ($suffix)'), findsOneWidget);
        expect(find.textContaining('₪'), findsNothing);
        expect(find.textContaining('د.أ'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'unavailable alternatives settle as a contract error without invented empty results or retry',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'selected_country_v1': 'jordan',
        'country_explicitly_selected_v1': true,
      });
      final app = AppProvider();
      await app.init();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: host(
            'en',
            const MedicationAlternativesPage(
              medicationId: 17,
              drugName: 'Synthetic product',
              scientificName: 'Synthetic',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizationsEn().apiContractUnavailable),
        findsOneWidget,
      );
      expect(find.text(AppLocalizationsEn().actionRetry), findsNothing);
      expect(find.text(AppLocalizationsEn().noAlternativesFound), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    },
  );
}
