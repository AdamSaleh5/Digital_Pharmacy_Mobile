import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/models/drug_search_mode.dart';
import 'package:digitalpharmacy/features/drugs/data/models/company_agent_item.dart';
import 'package:digitalpharmacy/features/drugs/data/repository/medication_repository.dart';
import 'package:digitalpharmacy/features/search/view/search_results_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository extends MedicationRepository {
  int requests = 0;
  @override
  Future<List<CompanyAgentItem>> fetchCompanies({
    String? query,
    CancelToken? cancelToken,
    bool fetchInitial = false,
  }) async {
    requests++;
    return List.generate(
      55,
      (i) => CompanyAgentItem(
        id: i + 1,
        company: 'Company${(i + 1).toString().padLeft(3, '0')}',
        agent: 'Synthetic warehouse',
      ),
    );
  }
}

void main() {
  testWidgets('company browsing continues past the old 50-row cap', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _Repository();
    final app = AppProvider(medicationRepository: repo);
    addTearDown(app.dispose);
    await app.init();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SearchResultsPage(
            initialQuery: '',
            searchMode: DrugSearchMode.company,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Company055'), findsOneWidget);
    expect(repo.requests, 1);
    expect(tester.takeException(), isNull);
  });
}
