import 'dart:async';

import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/models/drug_search_mode.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/features/drugs/data/models/medication_suggestion.dart';
import 'package:digitalpharmacy/features/drugs/data/repository/medication_repository.dart';
import 'package:digitalpharmacy/features/search/view/search_results_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PendingSuggestionCall {
  _PendingSuggestionCall(this.query, this.cancelToken);

  final String? query;
  final CancelToken? cancelToken;
  final Completer<ApiPage<MedicationSuggestion>> completer = Completer();
}

class _DeferredMedicationRepository extends MedicationRepository {
  final List<_PendingSuggestionCall> calls = [];

  @override
  Future<ApiPage<MedicationSuggestion>> fetchSuggestionsPage({
    String? query,
    required MedicationSearchType searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) {
    final call = _PendingSuggestionCall(query, cancelToken);
    calls.add(call);
    return call.completer.future;
  }

  void complete(int index, String result) {
    calls[index].completer.complete(
      ApiPage(
        items: [
          MedicationSuggestion(tradeName: result, scientificName: result),
        ],
        metadata: ApiPageMetadata(
          pageNumber: 1,
          totalPages: 1,
          totalCount: 1,
          hasPreviousPage: false,
          hasNextPage: false,
        ),
      ),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setAppCountry(AppCountry.jordan);
  });

  Future<(AppProvider, AuthSession, _DeferredMedicationRepository)> mountSearch(
    WidgetTester tester,
  ) async {
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-session-token',
          apiOrigin: Uri.parse('https://api.example.test'),
        );
    final repository = _DeferredMedicationRepository();
    final app = AppProvider(
      medicationRepository: repository,
      authSession: session,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: app,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SearchResultsPage(
            initialQuery: 'older',
            searchMode: DrugSearchMode.trade,
          ),
        ),
      ),
    );
    await tester.pump();
    return (app, session, repository);
  }

  testWidgets(
    'new query cancels old request before debounce and ignores late data',
    (tester) async {
      final (app, _, repository) = await mountSearch(tester);
      expect(repository.calls, hasLength(1));
      final oldCall = repository.calls.single;

      await tester.enterText(find.byType(TextField), 'newer');
      expect(oldCall.cancelToken!.isCancelled, isTrue);
      oldCall.completer.complete(
        ApiPage(
          items: [
            MedicationSuggestion(
              tradeName: 'stale older result',
              scientificName: 'stale older result',
            ),
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
      await tester.pump();
      expect(find.text('stale older result'), findsNothing);

      await tester.pump(const Duration(milliseconds: 301));
      expect(repository.calls, hasLength(2));
      expect(repository.calls.last.query, 'newer');
      repository.complete(1, 'fresh newer result');
      await tester.pumpAndSettle();
      expect(find.text('fresh newer result'), findsOneWidget);
      expect(find.text('stale older result'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
    },
  );

  testWidgets('country change clears old results and fetches the new scope', (
    tester,
  ) async {
    final (app, _, repository) = await mountSearch(tester);
    repository.complete(0, 'Jordan result');
    await tester.pumpAndSettle();
    expect(find.text('Jordan result'), findsOneWidget);

    await app.setCountry(AppCountry.palestine);
    await tester.pump();
    expect(repository.calls, hasLength(2));
    expect(find.text('Jordan result'), findsNothing);
    repository.complete(1, 'Palestine result');
    await tester.pumpAndSettle();
    expect(find.text('Palestine result'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets(
    'public data scope change cancels stale results and starts anonymous reload',
    (tester) async {
      final (app, _, repository) = await mountSearch(tester);
      final pending = repository.calls.single;
      app.invalidatePublicDataScope();
      await tester.pump();
      expect(
        find.text(AppLocalizationsEn().apiAuthenticationRequired),
        findsNothing,
      );
      expect(repository.calls, hasLength(2));
      expect(pending.cancelToken!.isCancelled, isTrue);
      repository.complete(1, 'fresh public scope');

      pending.completer.complete(
        ApiPage(
          items: [
            MedicationSuggestion(
              tradeName: 'stale session result',
              scientificName: 'stale session result',
            ),
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
      await tester.pump();
      expect(find.text('stale session result'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
    },
  );
}
