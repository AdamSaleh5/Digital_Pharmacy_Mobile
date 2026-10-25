import 'dart:async';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/models/drug_search_mode.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/features/drugs/data/models/agent_catalog_item.dart';
import 'package:digitalpharmacy/features/drugs/data/models/company_agent_item.dart';
import 'package:digitalpharmacy/features/drugs/data/models/medication_suggestion.dart';
import 'package:digitalpharmacy/features/drugs/data/repository/medication_repository.dart';
import 'package:digitalpharmacy/features/pharmacies/data/models/pharmacy_item.dart';
import 'package:digitalpharmacy/features/pharmacies/view/pharmacies_page.dart';
import 'package:digitalpharmacy/features/search/view/search_results_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ApiPageMetadata _metadata(int page, {bool more = false}) => ApiPageMetadata(
  pageNumber: page,
  totalPages: more ? page + 1 : page,
  totalCount: more ? 2 : 1,
  hasPreviousPage: page > 1,
  hasNextPage: more,
);

class _Call {
  _Call(this.query, this.page, this.token, [this.filter]);
  final String? query;
  final int page;
  final CancelToken? token;
  final PharmacySearchType? filter;
}

class _SearchRepository extends MedicationRepository {
  bool holdQuery = false;
  final calls = <_Call>[];
  final queryReady = Completer<void>();
  final latePage = Completer<ApiPage<MedicationSuggestion>>();

  @override
  Future<ApiPage<MedicationSuggestion>> fetchSuggestionsPage({
    String? query,
    required MedicationSearchType searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    calls.add(_Call(query, pageNumber, cancelToken));
    if (pageNumber == 2) return latePage.future;
    if (query != null && holdQuery) await queryReady.future;
    return ApiPage(
      items: [
        MedicationSuggestion(
          id: query == null ? 1 : 3,
          tradeName: query == null ? 'Initial medication' : 'Fresh medication',
          scientificName:
              query == null ? 'Initial medication' : 'Fresh medication',
        ),
      ],
      metadata: _metadata(1, more: query == null),
    );
  }

  @override
  Future<List<CompanyAgentItem>> fetchCompanies({
    String? query,
    CancelToken? cancelToken,
    bool fetchInitial = false,
  }) async {
    calls.add(_Call(query, 1, cancelToken));
    if (query?.isNotEmpty == true && holdQuery) await queryReady.future;
    return [
      CompanyAgentItem(
        id: 71,
        company:
            query?.isNotEmpty == true ? 'Fresh company' : 'Initial company',
        agent: 'Synthetic warehouse',
      ),
    ];
  }

  @override
  Future<List<AgentCatalogItem>> fetchAgents({
    String? query,
    CancelToken? cancelToken,
    bool fetchInitial = false,
  }) async {
    calls.add(_Call(query, 1, cancelToken));
    if (query?.isNotEmpty == true && holdQuery) await queryReady.future;
    return [
      AgentCatalogItem(
        id: 81,
        value: query?.isNotEmpty == true ? 'Fresh agent' : 'Initial agent',
      ),
    ];
  }
}

class _PharmacyApi extends ApiService {
  bool holdQuery = false;
  final calls = <_Call>[];
  final queryReady = Completer<void>();
  final latePage = Completer<ApiPage<PharmacyItem>>();

  @override
  Future<ApiPage<PharmacyItem>> fetchPharmacyPage({
    String? query,
    PharmacySearchType? searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    calls.add(_Call(query, pageNumber, cancelToken, searchType));
    if (pageNumber == 2) return latePage.future;
    if (query != null && holdQuery) await queryReady.future;
    final initial = query == null && searchType == PharmacySearchType.name;
    return ApiPage(
      items: [
        PharmacyItem.fromJson({
          'id': initial ? 1 : 3,
          'name': initial ? 'Initial pharmacy' : 'Fresh pharmacy',
          'address': 'Synthetic address',
          'managerName': 'Synthetic manager',
          'phoneNumber': 'synthetic-phone',
        }),
      ],
      metadata: _metadata(1, more: initial),
    );
  }
}

Future<AppProvider> _pump(
  WidgetTester tester,
  Widget page, {
  MedicationRepository? repository,
}) async {
  SharedPreferences.setMockInitialValues({});
  final app = AppProvider(medicationRepository: repository);
  addTearDown(app.dispose);
  await app.init();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: app,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return app;
}

void main() {
  setUp(() {
    setAppCountry(AppCountry.jordan);
    AdsEntitlementController.instance.setFree();
    AdsEntitlementController.instance.setPrivacyPermission(false);
  });

  for (final mode in DrugSearchMode.values) {
    testWidgets('${mode.name} submit consumes pending debounce', (
      tester,
    ) async {
      final repository = _SearchRepository()..holdQuery = true;
      await _pump(
        tester,
        SearchResultsPage(initialQuery: '', searchMode: mode),
        repository: repository,
      );
      await tester.enterText(find.byType(TextField), 'fresh');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final submitted =
          repository.calls.where((call) => call.query == 'fresh').toList();
      final cancelled = submitted.first.token!.isCancelled;
      repository.queryReady.complete();
      await tester.pumpAndSettle();
      expect(submitted, hasLength(1));
      expect(cancelled, isFalse);
      expect(
        find.text(
          mode == DrugSearchMode.company
              ? 'Fresh company'
              : mode == DrugSearchMode.agent
              ? 'Fresh agent'
              : 'Fresh medication',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('pharmacy submit consumes pending debounce', (tester) async {
    final api = _PharmacyApi()..holdQuery = true;
    await _pump(tester, PharmaciesPage(api: api));
    await tester.enterText(find.byType(TextField), 'fresh');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final submitted = api.calls.where((call) => call.query == 'fresh').toList();
    final cancelled = submitted.first.token!.isCancelled;
    api.queryReady.complete();
    await tester.pumpAndSettle();
    expect(submitted, hasLength(1));
    expect(cancelled, isFalse);
    expect(find.text('Fresh pharmacy'), findsOneWidget);
  });

  for (final mode in [
    DrugSearchMode.trade,
    DrugSearchMode.scientific,
    DrugSearchMode.all,
  ]) {
    testWidgets(
      '${mode.name} new query rejects stale page and duplicate loads',
      (tester) async {
        final repository = _SearchRepository();
        await _pump(
          tester,
          SearchResultsPage(initialQuery: '', searchMode: mode),
          repository: repository,
        );
        await tester.tap(find.text('Load more results'));
        await tester.tap(find.text('Load more results'));
        await tester.pump();
        expect(repository.calls.where((call) => call.page == 2), hasLength(1));
        await tester.enterText(find.byType(TextField), 'fresh');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        repository.latePage.complete(
          ApiPage(
            items: [
              MedicationSuggestion(
                id: 2,
                tradeName: 'Late medication',
                scientificName: 'Late medication',
              ),
            ],
            metadata: _metadata(2),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Fresh medication'), findsOneWidget);
        expect(find.text('Initial medication'), findsNothing);
        expect(find.text('Late medication'), findsNothing);
        expect(find.text('Load more results'), findsNothing);
        expect(repository.calls.where((call) => call.page == 2), hasLength(1));
      },
    );
  }

  testWidgets('pharmacy filter rejects stale page and duplicate loads', (
    tester,
  ) async {
    final api = _PharmacyApi();
    await _pump(tester, PharmaciesPage(api: api));
    await tester.ensureVisible(find.text('Load more results'));
    await tester.tap(find.text('Load more results'));
    await tester.tap(find.text('Load more results'));
    await tester.pump();
    expect(api.calls.where((call) => call.page == 2), hasLength(1));
    await tester.ensureVisible(
      find.text(AppLocalizationsEn().pharmacyModeAddress),
    );
    await tester.tap(find.text(AppLocalizationsEn().pharmacyModeAddress));
    await tester.pumpAndSettle();
    api.latePage.complete(
      ApiPage(
        items: [
          PharmacyItem.fromJson({'id': 2, 'name': 'Late pharmacy'}),
        ],
        metadata: _metadata(2),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fresh pharmacy'), findsOneWidget);
    expect(find.text('Initial pharmacy'), findsNothing);
    expect(find.text('Late pharmacy'), findsNothing);
    expect(api.calls.where((call) => call.page == 2), hasLength(1));
    expect(api.calls.last.filter, PharmacySearchType.address);
    expect(api.calls.last.page, 1);
  });
}
