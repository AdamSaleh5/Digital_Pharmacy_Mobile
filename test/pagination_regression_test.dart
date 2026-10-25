import 'dart:async';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/models/drug_search_mode.dart';
import 'package:digitalpharmacy/core/models/paginated_result.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/features/drugs/data/models/medication_item.dart';
import 'package:digitalpharmacy/features/drugs/data/models/medication_suggestion.dart';
import 'package:digitalpharmacy/features/drugs/data/repository/medication_repository.dart';
import 'package:digitalpharmacy/features/search/view/agent_drugs_page.dart';
import 'package:digitalpharmacy/features/search/view/company_drugs_page.dart';
import 'package:digitalpharmacy/features/search/view/search_results_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository extends MedicationRepository {
  final pages = <int>[];
  final suggestionCalls = <String>[];
  bool failNext = true;
  final oldQuery = Completer<ApiPage<MedicationSuggestion>>();

  Future<PaginatedResult<MedicationItem>> _fetch(int page) async {
    pages.add(page);
    if (page == 2 && failNext) {
      failNext = false;
      throw DioException.connectionError(
        requestOptions: RequestOptions(path: '/synthetic'),
        reason: 'synthetic offline',
      );
    }
    return PaginatedResult(
      page: page,
      hasMore: page == 1,
      items: [
        for (final id
            in page == 1 ? List.generate(20, (i) => i + 1) : [20, 21, 22, 23])
          MedicationItem.fromJson({
            'id': id,
            'tradeName': 'Server product $id',
            'scientificName': 'Synthetic ingredient',
            'company': 'Synthetic company',
            'agent': 'Synthetic warehouse',
            'pharmaceuticalForm': 'tablet',
            'price': 2.5,
          }),
      ],
    );
  }

  @override
  Future<PaginatedResult<MedicationItem>> companyMedicationsPaged({
    required int companyId,
    required int page,
    int pageSize = 20,
    required AppCountry country,
    CancelToken? cancelToken,
  }) => _fetch(page);
  @override
  Future<PaginatedResult<MedicationItem>> agentMedicationsPaged({
    required int agentId,
    required int page,
    int pageSize = 20,
    required AppCountry country,
    CancelToken? cancelToken,
  }) => _fetch(page);
  @override
  Future<ApiPage<MedicationSuggestion>> fetchSuggestionsPage({
    String? query,
    required MedicationSearchType searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    suggestionCalls.add('${query ?? ""}|$pageNumber');
    if (query == 'old') return oldQuery.future;
    final filtered = query?.isNotEmpty == true;
    return ApiPage(
      items: [
        for (final id
            in filtered
                ? [3]
                : pageNumber == 1
                ? [1]
                : [1, 2])
          MedicationSuggestion(
            id: id,
            tradeName: filtered ? 'New query' : 'Same name',
            scientificName: 'Synthetic ingredient',
          ),
      ],
      metadata: ApiPageMetadata(
        pageNumber: pageNumber,
        totalPages: filtered ? 1 : 2,
        totalCount: filtered ? 1 : 2,
        hasPreviousPage: pageNumber > 1,
        hasNextPage: !filtered && pageNumber == 1,
      ),
    );
  }
}

class _FailingSuggestionRepository extends MedicationRepository {
  _FailingSuggestionRepository(this.failure);

  final Object failure;
  final calls = <String>[];
  final retryResponse = Completer<ApiPage<MedicationSuggestion>>();
  bool _failed = false;

  ApiPage<MedicationSuggestion> page(int number) => ApiPage(
    items: [
      for (final id in number == 1 ? List.generate(20, (i) => i + 1) : [20, 21])
        MedicationSuggestion(
          id: id,
          tradeName: 'Synthetic suggestion $id',
          scientificName: 'Synthetic ingredient',
        ),
    ],
    metadata: ApiPageMetadata(
      pageNumber: number,
      totalPages: 2,
      totalCount: 21,
      hasPreviousPage: number > 1,
      hasNextPage: number == 1,
    ),
  );

  @override
  Future<ApiPage<MedicationSuggestion>> fetchSuggestionsPage({
    String? query,
    required MedicationSearchType searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    calls.add('${query ?? ""}|$pageNumber');
    if (pageNumber == 2) {
      if (!_failed) {
        _failed = true;
        throw failure;
      }
      return retryResponse.future;
    }
    return page(pageNumber);
  }
}

Future<AppProvider> _pump(
  WidgetTester tester,
  MedicationRepository repo,
  Widget page, {
  bool settle = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final app = AppProvider(medicationRepository: repo);
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return app;
}

void _scrollSuggestionsToEnd(WidgetTester tester) {
  final controller = tester.widget<ListView>(find.byType(ListView)).controller!;
  controller.jumpTo(controller.position.maxScrollExtent);
}

void _scrollSuggestionsToStart(WidgetTester tester) {
  final controller = tester.widget<ListView>(find.byType(ListView)).controller!;
  controller.jumpTo(0);
}

void main() {
  for (final isCompany in [true, false]) {
    testWidgets(
      '${isCompany ? "company" : "agent"} retains earlier page on error and deduplicates retry',
      (tester) async {
        final repo = _Repository();
        final app = await _pump(
          tester,
          repo,
          isCompany
              ? const CompanyDrugsPage(
                companyId: 1,
                companyName: 'Catalogue',
                agentName: 'Warehouse',
              )
              : const AgentDrugsPage(agentId: 1, agentName: 'Catalogue'),
        );
        addTearDown(app.dispose);
        await tester.drag(find.byType(ListView), const Offset(0, -6000));
        await tester.pumpAndSettle();
        expect(
          find.text(AppLocalizationsEn().scientificDrugsCount(20)),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text(AppLocalizationsEn().actionRetry));
        await tester.tap(find.text(AppLocalizationsEn().actionRetry));
        await tester.pumpAndSettle();
        expect(repo.pages, [1, 2, 2]);
        expect(
          find.text(AppLocalizationsEn().scientificDrugsCount(23)),
          findsOneWidget,
        );
        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(repo.pages.length, 3);
      },
    );
  }

  for (final mode in [
    DrugSearchMode.trade,
    DrugSearchMode.scientific,
    DrugSearchMode.all,
  ]) {
    for (final retryable in [true, false]) {
      testWidgets(
        '${mode.name} failed suggestion page requires permitted manual retry=$retryable',
        (tester) async {
          final failure =
              retryable
                  ? DioException.connectionError(
                    requestOptions: RequestOptions(path: '/synthetic'),
                    reason: 'synthetic offline',
                  )
                  : const FormatException('Synthetic malformed page metadata');
          final repo = _FailingSuggestionRepository(failure);
          final app = await _pump(
            tester,
            repo,
            SearchResultsPage(initialQuery: '', searchMode: mode),
          );
          addTearDown(app.dispose);
          final l10n = AppLocalizationsEn();
          _scrollSuggestionsToEnd(tester);
          await tester.pumpAndSettle();
          expect(repo.calls, ['|1', '|2']);
          expect(find.text(l10n.searchResultsCount(20)), findsOneWidget);

          // Repeated genuine ScrollPosition notifications must not retry a
          // failed page, including errors classified as non-retryable.
          for (var i = 0; i < 3; i++) {
            _scrollSuggestionsToStart(tester);
            await tester.pumpAndSettle();
            _scrollSuggestionsToEnd(tester);
            await tester.pumpAndSettle();
          }
          expect(repo.calls, ['|1', '|2']);
          expect(find.text('Load more results'), findsNothing);
          if (retryable) {
            await tester.ensureVisible(find.text(l10n.actionRetry));
            // ensureVisible updates the scroll offset; layout must catch up
            // before hit-testing a retry below the taller scientific header.
            await tester.pumpAndSettle();
            await tester.tap(find.text(l10n.actionRetry).hitTestable());
            await tester.pump();
            expect(repo.calls, ['|1', '|2', '|2']);
            // The delayed retry also blocks scroll-triggered duplicate loads.
            _scrollSuggestionsToStart(tester);
            _scrollSuggestionsToEnd(tester);
            await tester.pump();
            expect(repo.calls, ['|1', '|2', '|2']);
            repo.retryResponse.complete(repo.page(2));
            await tester.pumpAndSettle();
            expect(find.text(l10n.searchResultsCount(21)), findsOneWidget);
            expect(find.text(l10n.actionRetry), findsNothing);
            _scrollSuggestionsToStart(tester);
            _scrollSuggestionsToEnd(tester);
            await tester.pumpAndSettle();
            expect(repo.calls, ['|1', '|2', '|2']);
          } else {
            expect(find.text(l10n.actionRetry), findsNothing);
            // A new filter is a new first-page request, not an implicit retry.
            await tester.enterText(find.byType(TextField), 'new');
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pumpAndSettle();
            expect(repo.calls, ['|1', '|2', 'new|1']);
            expect(find.text(l10n.apiContractUnavailable), findsNothing);
            expect(find.text(l10n.searchResultsCount(20)), findsOneWidget);
          }
        },
      );
    }

    testWidgets(
      '${mode.name} suggestions page by ID and restore the unfiltered page cache',
      (tester) async {
        final repo = _Repository();
        final app = await _pump(
          tester,
          repo,
          SearchResultsPage(initialQuery: '', searchMode: mode),
        );
        addTearDown(app.dispose);
        await tester.tap(find.text('Load more results'));
        await tester.pumpAndSettle();
        expect(repo.suggestionCalls, ['|1', '|2']);
        // Distinct positive IDs with identical labels must remain distinct.
        await tester.enterText(find.byType(TextField), 'new');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();
        expect(repo.suggestionCalls, ['|1', '|2', 'new|1']);
        expect(find.text('Load more results'), findsNothing);
        expect(
          find.text(AppLocalizationsEn().searchResultsCount(2)),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('late initial query cannot overwrite the newer filter', (
    tester,
  ) async {
    final repo = _Repository();
    final app = await _pump(
      tester,
      repo,
      const SearchResultsPage(
        initialQuery: 'old',
        searchMode: DrugSearchMode.trade,
      ),
      settle: false,
    );
    addTearDown(app.dispose);
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    repo.oldQuery.complete(
      ApiPage(
        items: [
          MedicationSuggestion(tradeName: 'Old query', scientificName: 'Old'),
        ],
        metadata: const ApiPageMetadata(
          pageNumber: 1,
          totalPages: 1,
          totalCount: 1,
          hasPreviousPage: false,
          hasNextPage: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New query'), findsOneWidget);
    expect(find.text('Old query'), findsNothing);
  });
}
