import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/models/drug_search_mode.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
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

ApiPageMetadata _metadata(int page, bool more) => ApiPageMetadata(
  pageNumber: page,
  totalPages: more ? 2 : page,
  totalCount: more ? 2 : 1,
  hasPreviousPage: page > 1,
  hasNextPage: more,
);

class _Repository extends MedicationRepository {
  _Repository(this.failure, {this.failPage = 1});
  final DioExceptionType failure;
  final int failPage;
  bool failed = false;
  CancelToken? failedToken;
  final calls = <String>[];

  @override
  Future<ApiPage<MedicationSuggestion>> fetchSuggestionsPage({
    String? query,
    required MedicationSearchType searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    calls.add('${query ?? ""}|$pageNumber');
    if (query == 'sentry' && pageNumber == failPage && !failed) {
      failed = true;
      failedToken = cancelToken;
      throw DioException(
        requestOptions: RequestOptions(path: '/synthetic'),
        type: failure,
      );
    }
    final label =
        query == null
            ? 'Initial result'
            : pageNumber == 1
            ? 'Fresh sentry'
            : 'Next sentry';
    return ApiPage(
      items: [
        MedicationSuggestion(
          id: 17 + pageNumber,
          tradeName: label,
          scientificName: label,
        ),
      ],
      metadata: _metadata(pageNumber, failPage == 2 && pageNumber == 1),
    );
  }
}

class _PharmacyApi extends ApiService {
  bool failed = false;
  CancelToken? failedToken;
  final calls = <String?>[];
  @override
  Future<ApiPage<PharmacyItem>> fetchPharmacyPage({
    String? query,
    PharmacySearchType? searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    calls.add(query);
    if (query == 'sentry' && !failed) {
      failed = true;
      failedToken = cancelToken;
      throw DioException(
        requestOptions: RequestOptions(path: '/synthetic'),
        type: DioExceptionType.cancel,
      );
    }
    return ApiPage(
      items: [
        PharmacyItem.fromJson({
          'id': 17,
          'name': query == null ? 'Initial pharmacy' : 'Fresh pharmacy',
        }),
      ],
      metadata: _metadata(1, false),
    );
  }
}

Future<void> _pump(
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  setUp(() {
    setAppCountry(AppCountry.jordan);
    AdsEntitlementController.instance.setFree();
    AdsEntitlementController.instance.setPrivacyPermission(false);
  });
  for (final mode in [
    DrugSearchMode.trade,
    DrugSearchMode.scientific,
    DrugSearchMode.all,
  ]) {
    for (final failure in [
      DioExceptionType.cancel,
      DioExceptionType.receiveTimeout,
    ]) {
      testWidgets(
        '${mode.name} current ${failure.name} ends loading and keeps retry query',
        (tester) async {
          final repo = _Repository(failure);
          await _pump(
            tester,
            SearchResultsPage(initialQuery: '', searchMode: mode),
            repository: repo,
          );
          await tester.enterText(find.byType(TextField), 'sentry');
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 20));
          expect(repo.failedToken!.isCancelled, isFalse);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(
            find.text(AppLocalizationsEn().errorLoadingData),
            findsOneWidget,
          );
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'sentry',
          );
          await tester.tap(find.text(AppLocalizationsEn().actionRetry));
          await tester.pumpAndSettle();
          expect(repo.calls.where((call) => call == 'sentry|1'), hasLength(2));
          expect(find.text('Fresh sentry'), findsOneWidget);
        },
      );
    }
  }

  testWidgets(
    'current page cancellation retains earlier rows and retries page2',
    (tester) async {
      final repo = _Repository(DioExceptionType.cancel, failPage: 2);
      await _pump(
        tester,
        const SearchResultsPage(
          initialQuery: 'sentry',
          searchMode: DrugSearchMode.trade,
        ),
        repository: repo,
      );
      await tester.tap(find.text('Load more results'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(repo.failedToken!.isCancelled, isFalse);
      expect(find.text('Fresh sentry'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text(AppLocalizationsEn().actionRetry));
      await tester.pumpAndSettle();
      expect(repo.calls, ['sentry|1', 'sentry|2', 'sentry|2']);
      expect(find.text('Fresh sentry'), findsOneWidget);
      expect(find.text('Next sentry'), findsOneWidget);
    },
  );

  testWidgets(
    'pharmacy upstream cancellation is recoverable with retained query',
    (tester) async {
      final api = _PharmacyApi();
      await _pump(tester, PharmaciesPage(api: api));
      await tester.enterText(find.byType(TextField), 'sentry');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(api.failedToken!.isCancelled, isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'sentry',
      );
      await tester.tap(find.text(AppLocalizationsEn().actionRetry));
      await tester.pumpAndSettle();
      expect(api.calls, [null, 'sentry', 'sentry']);
      expect(find.text('Fresh pharmacy'), findsOneWidget);
    },
  );
}
