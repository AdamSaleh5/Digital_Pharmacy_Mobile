import 'dart:async';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/features/drugs/data/models/medication_item.dart';
import 'package:digitalpharmacy/features/pharmacies/data/models/pharmacy_item.dart';
import 'package:digitalpharmacy/features/pharmacies/view/pharmacies_page.dart';
import 'package:digitalpharmacy/features/search/view/medication_selection_results_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ApiPageMetadata _metadata(int page) => ApiPageMetadata(
  pageNumber: page,
  totalPages: 2,
  totalCount: 2,
  hasPreviousPage: page > 1,
  hasNextPage: page == 1,
);

class _Api extends ApiService {
  final List<int> pharmacyPages = [];
  final List<AppCountry> pharmacyCountries = [];
  Completer<ApiPage<PharmacyItem>>? nextPageWait;
  final List<int> medicationPages = [];
  bool failNextPharmacyPage = false;
  @override
  Future<ApiPage<PharmacyItem>> fetchPharmacyPage({
    String? query,
    PharmacySearchType? searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    pharmacyPages.add(pageNumber);
    pharmacyCountries.add(kAppCountry);
    if (pageNumber == 2 && nextPageWait != null) return nextPageWait!.future;
    if (pageNumber == 2 && failNextPharmacyPage) {
      failNextPharmacyPage = false;
      throw DioException.connectionError(
        requestOptions: RequestOptions(path: '/api/GetPharmacies'),
        reason: 'synthetic offline',
      );
    }
    return ApiPage(
      items: [
        PharmacyItem.fromJson({
          'id': pageNumber,
          'name': 'Server pharmacy $pageNumber',
          'address': 'Synthetic address',
          'managerName': 'Synthetic manager',
          'phoneNumber': 'synthetic-phone',
        }),
      ],
      metadata: _metadata(pageNumber),
    );
  }

  @override
  Future<ApiPage<MedicationItem>> fetchMedicationDetailsPage({
    required int id,
    required MedicationSearchType searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    medicationPages.add(pageNumber);
    return ApiPage(
      items: [
        for (final row in pageNumber == 1 ? [17] : [17, 18])
          MedicationItem.fromJson({
            'id': row,
            'tradeName': 'Server product $row',
            'scientificName': 'Synthetic ingredient',
            'company': 'Synthetic company',
            'agent': 'Synthetic warehouse',
            'pharmaceuticalForm': 'tablet',
            'price': 2.5,
          }),
      ],
      metadata: _metadata(pageNumber),
    );
  }
}

Future<AppProvider> _pump(
  WidgetTester tester,
  Widget page, {
  AuthSession? session,
}) async {
  SharedPreferences.setMockInitialValues({});
  final app = AppProvider(authSession: session);
  await app.init();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: app,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return app;
}

void main() {
  testWidgets('country change resets the pharmacy page and query scope', (
    tester,
  ) async {
    final api = _Api();
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-session',
          apiOrigin: Uri.parse('https://api.example.test'),
        );
    final app = await _pump(tester, PharmaciesPage(api: api), session: session);
    addTearDown(app.dispose);
    await app.setCountry(AppCountry.palestine);
    await tester.pumpAndSettle();
    expect(api.pharmacyPages, [1, 1]);
    expect(api.pharmacyCountries, [AppCountry.jordan, AppCountry.palestine]);
  });

  testWidgets('public data scope reload rejects a late next-page result', (
    tester,
  ) async {
    final api = _Api()..nextPageWait = Completer<ApiPage<PharmacyItem>>();
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-session',
          apiOrigin: Uri.parse('https://api.example.test'),
        );
    final app = await _pump(tester, PharmaciesPage(api: api), session: session);
    addTearDown(app.dispose);
    await tester.ensureVisible(find.text('Load more results'));
    await tester.tap(find.text('Load more results'));
    await tester.pump();
    app.invalidatePublicDataScope();
    await tester.pumpAndSettle();
    api.nextPageWait!.complete(
      ApiPage(
        items: [
          PharmacyItem.fromJson({
            'id': 9,
            'name': 'Late private result',
            'address': 'Synthetic',
            'managerName': 'Synthetic',
            'phoneNumber': 'synthetic-phone',
          }),
        ],
        metadata: _metadata(2),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Late private result'), findsNothing);
    expect(find.text('Server pharmacy 1'), findsOneWidget);
    expect(find.textContaining('Sign in'), findsNothing);
    expect(api.pharmacyPages, [1, 2, 1]);
  });
  testWidgets(
    'pharmacy load-more keeps earlier rows and retries the same page',
    (tester) async {
      final api = _Api()..failNextPharmacyPage = true;
      final app = await _pump(tester, PharmaciesPage(api: api));
      addTearDown(app.dispose);
      await tester.ensureVisible(find.text('Load more results'));
      await tester.tap(find.text('Load more results'));
      await tester.pumpAndSettle();
      expect(find.text('Server pharmacy 1'), findsOneWidget);
      await tester.ensureVisible(find.text('Load more results'));
      await tester.tap(find.text('Load more results'));
      await tester.pumpAndSettle();
      expect(api.pharmacyPages, [1, 2, 2]);
      expect(find.text('Server pharmacy 2'), findsOneWidget);
      expect(find.text('Load more results'), findsNothing);
    },
  );

  testWidgets(
    'details deduplicate pages and saving never reloads the API scope',
    (tester) async {
      final api = _Api();
      final app = await _pump(
        tester,
        MedicationSelectionResultsPage(
          id: 17,
          title: 'Selection',
          searchType: MedicationSearchType.tradeName,
          api: api,
        ),
      );
      addTearDown(app.dispose);
      await tester.tap(find.byTooltip('Save medication'));
      await tester.pumpAndSettle();
      expect(app.serverFavorites.single.id, 17);
      expect(api.medicationPages, [1]);
      await tester.ensureVisible(find.text('Load more results'));
      await tester.tap(find.text('Load more results'));
      await tester.pumpAndSettle();
      expect(api.medicationPages, [1, 2]);
      expect(find.text('Server product 17'), findsOneWidget);
      expect(find.text('Server product 18'), findsOneWidget);
      expect(find.text('Load more results'), findsNothing);
    },
  );
}
