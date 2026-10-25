import 'dart:async';
import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/features/drugs/data/models/medication_item.dart';
import 'package:digitalpharmacy/features/search/view/medication_selection_results_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountryDetailApi extends ApiService {
  final calls = <(AppCountry, int)>[];
  final latePage = Completer<ApiPage<MedicationItem>>();
  ApiPage<MedicationItem> result(int page) => ApiPage(
    items: [
      MedicationItem.fromJson({
        'id': 17 + page,
        'tradeName': 'Jordan-only product $page',
        'scientificName': 'Synthetic',
        'company': 'Synthetic',
        'agent': 'Synthetic',
        'price': 12.5,
      }),
    ],
    metadata: ApiPageMetadata(
      pageNumber: page,
      totalPages: 2,
      totalCount: 2,
      hasPreviousPage: page > 1,
      hasNextPage: page == 1,
    ),
  );
  @override
  Future<ApiPage<MedicationItem>> fetchMedicationDetailsPage({
    required int id,
    required MedicationSearchType searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    calls.add((kAppCountry, pageNumber));
    if (pageNumber == 2) return latePage.future;
    return result(pageNumber);
  }
}

void main() {
  testWidgets(
    'country switch cannot reuse an old selection ID or show its late page/price',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'selected_country_v1': 'jordan',
        'country_explicitly_selected_v1': true,
      });
      final api = _CountryDetailApi();
      final app = AppProvider();
      await app.init();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MedicationSelectionResultsPage(
              id: 17,
              title: 'Selected in Jordan',
              searchType: MedicationSearchType.tradeName,
              api: api,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jordan-only product 1'), findsOneWidget);
      await tester.tap(find.text('Load more results'));
      await tester.pump();
      await app.setCountry(AppCountry.palestine);
      await tester.pump();
      expect(
        api.calls,
        [(AppCountry.jordan, 1), (AppCountry.jordan, 2)],
        reason:
            'GetMedicationDetails has no CountryId; a result ID must be reselected in the new country',
      );
      api.latePage.complete(api.result(2));
      await tester.pumpAndSettle();
      expect(find.textContaining('Jordan-only product'), findsNothing);
      expect(find.text('Load more results'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('choose a result'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    },
  );
}
