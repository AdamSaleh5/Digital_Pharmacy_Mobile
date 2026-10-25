import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/models/drug_search_mode.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/features/drugs/data/repository/medication_repository.dart';
import 'package:digitalpharmacy/features/search/view/search_results_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Observed public GetMedicationSelect field shape, not a claimed Swagger schema.
class _ObservedWire implements HttpClientAdapter {
  _ObservedWire({this.id = 8665});
  final int id;
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls.add(request);
    expect(request.uri.path, '/api/GetMedicationSelect');
    final empty = request.queryParameters['CountryId'] == 0;
    return ResponseBody.fromString(
      jsonEncode({
        'status': 200,
        'data': {
          'data':
              empty
                  ? []
                  : [
                    {'id': id, 'value': 'Dalteparin'},
                  ],
          'meta': {
            'pageNumber': 1,
            'totalPages': empty ? 0 : 1,
            'totalCount': empty ? 0 : 1,
            'hasPreviousPage': false,
            'hasNextPage': false,
          },
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final original = kAppCountry;
  tearDown(() => setAppCountry(original));
  test(
    'observed id/value selection preserves label and identity and accepts empty country zero',
    () async {
      final wire = _ObservedWire();
      final dio = Dio(BaseOptions(baseUrl: 'http://144.91.111.63:5002'))
        ..httpClientAdapter = wire;
      addTearDown(dio.close);
      final api = ApiService(client: ApiTransport(dio: dio));
      setAppCountry(AppCountry.palestine);
      final page = await api.fetchMedicationSuggestionPage(
        searchType: MedicationSearchType.scientificName,
        pageNumber: 1,
        pageSize: 3,
      );
      final item = page.items.single;
      expect(item.id, 8665);
      expect(item.label(scientific: true), 'Dalteparin');
      expect(item.tradeName, isEmpty);
      expect(item.scientificName, isEmpty);
      expect(wire.calls.single.uri.queryParameters['SearchType'], '2');
      setAppCountry(AppCountry.jordan);
      final empty = await api.fetchMedicationSuggestionPage(
        searchType: MedicationSearchType.tradeName,
        pageNumber: 1,
        pageSize: 3,
      );
      expect(empty.items, isEmpty);
      expect(empty.metadata.totalPages, 0);
      expect(wire.calls.last.uri.queryParameters['CountryId'], '0');
      expect(wire.calls, hasLength(2));
    },
  );
  for (final (mode, id) in [
    (DrugSearchMode.trade, 8665),
    (DrugSearchMode.scientific, 8665),
    (DrugSearchMode.trade, 0),
  ]) {
    testWidgets(
      'actual selection DTO label and missing-ID notice for ${mode.name}/$id',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'selected_country_v1': 'palestine',
          'country_explicitly_selected_v1': true,
        });
        final wire = _ObservedWire(id: id);
        final dio = Dio(BaseOptions(baseUrl: 'http://144.91.111.63:5002'))
          ..httpClientAdapter = wire;
        final app = AppProvider(
          medicationRepository: MedicationRepository(
            api: ApiService(client: ApiTransport(dio: dio)),
          ),
        );
        await app.init();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: app,
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SearchResultsPage(initialQuery: '', searchMode: mode),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Dalteparin'), findsOneWidget);
        expect(
          find.text(
            'Details are unavailable until the API provides a medication ID.',
          ),
          id > 0 ? findsNothing : findsOneWidget,
        );
        expect(
          wire.calls.single.queryParameters['SearchType'],
          mode == DrugSearchMode.scientific ? 2 : 1,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        app.dispose();
        dio.close();
      },
    );
  }
}
