import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/models/paginated_result.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/features/drugs/data/models/medication_item.dart';
import 'package:digitalpharmacy/features/drugs/data/repository/medication_repository.dart';
import 'package:digitalpharmacy/features/search/view/agent_drugs_page.dart';
import 'package:digitalpharmacy/features/search/view/company_drugs_page.dart';
import 'package:digitalpharmacy/features/search/view/medication_selection_results_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Repository/API doubles only: no sockets, ad requests or real credentials.
class _CatalogApi extends ApiService {
  _CatalogApi(this.failPage);
  final int failPage;
  final calls = <int>[];
  bool failed = false;
  CancelToken? failedToken;

  Future<ApiPage<MedicationItem>> page(int page, CancelToken? token) async {
    calls.add(page);
    if (page == failPage && !failed) {
      failed = true;
      failedToken = token;
      throw DioException(
        requestOptions: RequestOptions(path: '/synthetic'),
        type: DioExceptionType.cancel,
      );
    }
    return ApiPage(
      items: [
        for (final id in page == 1 ? List.generate(20, (i) => i + 1) : [21])
          MedicationItem.fromJson({
            'id': id,
            'tradeName': 'Synthetic product $id',
            'scientificName': 'Synthetic ingredient',
            'company': 'Synthetic company',
            'agent': 'Synthetic warehouse',
            'price': 2.5,
          }),
      ],
      metadata: ApiPageMetadata(
        pageNumber: page,
        totalPages: 2,
        totalCount: 21,
        hasPreviousPage: page > 1,
        hasNextPage: page == 1,
      ),
    );
  }

  @override
  Future<ApiPage<MedicationItem>> fetchMedicationDetailsPage({
    required int id,
    required MedicationSearchType searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) => page(pageNumber, cancelToken);
}

class _Repository extends MedicationRepository {
  _Repository(this.api);
  final _CatalogApi api;
  Future<PaginatedResult<MedicationItem>> page(
    int number,
    CancelToken? token,
  ) async {
    final result = await api.page(number, token);
    return PaginatedResult(
      page: number,
      hasMore: result.metadata.hasNextPage,
      items: result.items,
    );
  }

  @override
  Future<PaginatedResult<MedicationItem>> companyMedicationsPaged({
    required int companyId,
    required int page,
    int pageSize = 20,
    required AppCountry country,
    CancelToken? cancelToken,
  }) => this.page(page, cancelToken);

  @override
  Future<PaginatedResult<MedicationItem>> agentMedicationsPaged({
    required int agentId,
    required int page,
    int pageSize = 20,
    required AppCountry country,
    CancelToken? cancelToken,
  }) => this.page(page, cancelToken);
}

void main() {
  for (final screen in ['company', 'agent', 'selection']) {
    for (final failPage in [1, 2]) {
      testWidgets(
        '$screen current cancellation page$failPage ends loading and retries',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          AdsEntitlementController.instance.setFree();
          AdsEntitlementController.instance.setPrivacyPermission(false);
          final api = _CatalogApi(failPage);
          final app = AppProvider(medicationRepository: _Repository(api));
          addTearDown(app.dispose);
          await app.init();
          final Widget page = switch (screen) {
            'company' => const CompanyDrugsPage(
              companyId: 1,
              companyName: 'Catalogue',
              agentName: 'Warehouse',
            ),
            'agent' => const AgentDrugsPage(agentId: 1, agentName: 'Catalogue'),
            _ => MedicationSelectionResultsPage(
              id: 1,
              title: 'Selection',
              searchType: MedicationSearchType.tradeName,
              api: api,
            ),
          };
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
          if (failPage == 2) {
            if (screen == 'selection') {
              await tester.scrollUntilVisible(
                find.text('Load more results'),
                600,
              );
              await tester.tap(find.text('Load more results'));
            } else {
              await tester.drag(find.byType(ListView), const Offset(0, -6000));
            }
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 20));
          }
          expect(api.failedToken!.isCancelled, isFalse);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          if (failPage == 2) {
            if (screen == 'selection') {
              tester
                  .state<ScrollableState>(find.byType(Scrollable).first)
                  .position
                  .jumpTo(0);
              await tester.pump();
            }
            expect(find.text('Drugs: 20'), findsOneWidget);
          }
          if (screen == 'selection' && failPage == 2) {
            await tester.scrollUntilVisible(find.text('Retry'), 600);
          }
          await tester.ensureVisible(find.text('Retry'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Retry'));
          await tester.pumpAndSettle();
          expect(api.calls, failPage == 1 ? [1, 1] : [1, 2, 2]);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.text('Retry'), findsNothing);
          if (screen == 'selection') {
            tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position
                .jumpTo(0);
            await tester.pump();
          }
          expect(
            find.text('Drugs: ${failPage == 1 ? 20 : 21}'),
            findsOneWidget,
          );
        },
      );
    }
  }
}
