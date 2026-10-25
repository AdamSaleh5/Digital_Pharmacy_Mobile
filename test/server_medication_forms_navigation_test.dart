import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/cache/memory_cache.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/core/widgets/golden_gradient_button.dart';
import 'package:digitalpharmacy/features/drugs/data/repository/medication_repository.dart';
import 'package:digitalpharmacy/features/drugs/widgets/dosage_forms_sheet.dart';
import 'package:digitalpharmacy/features/search/view/medication_selection_results_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MedicationWire implements HttpClientAdapter {
  _MedicationWire({this.medicationId = 982, this.failFirstForms = false});

  final int medicationId;
  final bool failFirstForms;
  final requests = <RequestOptions>[];
  Completer<ResponseBody>? heldForms;
  bool formsCancelled = false;
  int formsAttempts = 0;

  Map<String, Object?> _medication({
    required int id,
    String form = 'Original tablet',
    double price = 3.5,
  }) => {
    'id': id,
    'tradeName': 'Returned medication',
    'scientificName': 'Synthetic ingredient',
    'company': 'Synthetic company',
    'agent': 'Synthetic agent',
    'usage': '',
    'agentsPhoneNumber': '',
    'pharmaceuticalForm': form,
    'price': price,
  };

  ResponseBody _page(
    List<Map<String, Object?>> rows, {
    int page = 1,
    int pages = 1,
  }) => ResponseBody.fromString(
    jsonEncode({
      'status': 200,
      'data': {
        'data': rows,
        'meta': {
          'pageNumber': page,
          'totalPages': pages,
          'totalCount': pages,
          'hasPreviousPage': page > 1,
          'hasNextPage': page < pages,
        },
      },
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(request);
    if (request.path == '/api/GetMedicationDetails') {
      return _page([_medication(id: medicationId)]);
    }
    expect(request.path, '/api/GetPharmaceuticalForm');
    formsAttempts++;
    if (heldForms != null) {
      return Future.any([
        heldForms!.future,
        if (cancel != null)
          cancel.then<ResponseBody>((_) {
            formsCancelled = true;
            throw DioException(
              requestOptions: request,
              type: DioExceptionType.cancel,
            );
          }),
      ]);
    }
    if (failFirstForms && formsAttempts == 1) {
      return ResponseBody.fromString('synthetic unavailable', 503);
    }
    final page = request.queryParameters['PageNumber'] as int;
    return _page(
      [
        _medication(
          id: 1200 + page,
          form: page == 1 ? 'Returned capsule' : 'Returned solution',
          price: page == 1 ? 0 : 2.5,
        ),
      ],
      page: page,
      pages: 2,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final originalCountry = kAppCountry;
  final ads = AdsEntitlementController.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'selected_country_v1': 'palestine',
      'country_explicitly_selected_v1': true,
    });
    MemoryCache.instance.clear();
    ads.setFree();
    ads.setPrivacyPermission(false);
  });
  tearDown(() {
    MemoryCache.instance.clear();
    ads.setFree();
    ads.setPrivacyPermission(false);
    setAppCountry(originalCountry);
  });

  Future<AppProvider> openResults(
    WidgetTester tester,
    _MedicationWire wire,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = Dio(BaseOptions(baseUrl: 'https://catalog.invalid'))
      ..httpClientAdapter = wire;
    addTearDown(dio.close);
    final api = ApiService(client: ApiTransport(dio: dio));
    final app = AppProvider(
      medicationRepository: MedicationRepository(api: api),
    );
    await app.init();
    addTearDown(app.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MedicationSelectionResultsPage(
            id: 5177,
            title: 'Selected ingredient',
            searchType: MedicationSearchType.scientificName,
            api: api,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Returned medication'), findsOneWidget);
    await tester.tap(find.text('Returned medication'));
    await tester.pumpAndSettle();
    return app;
  }

  Future<void> openForms(WidgetTester tester) async {
    final button = find.byType(GoldenGradientButton);
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  testWidgets('primary returned-ID card opens all pharmaceutical form pages', (
    tester,
  ) async {
    final wire = _MedicationWire();
    final app = await openResults(tester, wire);
    // Existing favorite action still uses the returned medication identity.
    await tester.tap(find.byTooltip('Save medication'));
    await tester.pumpAndSettle();
    expect(app.isServerFavorite(982), isTrue);
    await openForms(tester);
    await tester.pumpAndSettle();
    expect(find.byType(DosageFormsSheet), findsOneWidget);
    expect(find.text('Returned capsule'), findsOneWidget);
    expect(find.text('Returned solution'), findsOneWidget);
    expect(find.text('0.00 (currency unspecified)'), findsOneWidget);
    expect(find.text('2.50 (currency unspecified)'), findsOneWidget);
    expect(wire.requests.first.queryParameters['id'], 5177);
    final forms = wire.requests.skip(1).toList();
    expect(forms, hasLength(2));
    for (var index = 0; index < forms.length; index++) {
      expect(forms[index].queryParameters, {
        'id': 982,
        'PageNumber': index + 1,
        'PageSize': 100,
      });
      expect(forms[index].headers['Authorization'], isNull);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'card without a positive returned medication ID has no forms action',
    (tester) async {
      final wire = _MedicationWire(medicationId: 0);
      await openResults(tester, wire);
      expect(find.byType(GoldenGradientButton), findsNothing);
      expect(wire.formsAttempts, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('repeated forms action opens one sheet and permits reopening', (
    tester,
  ) async {
    final wire = _MedicationWire();
    await openResults(tester, wire);
    final action = tester.widget<GoldenGradientButton>(
      find.byType(GoldenGradientButton),
    );
    // Invoke the real card callback twice before a frame can change the route.
    action.onPressed();
    action.onPressed();
    await tester.pumpAndSettle();
    expect(find.byType(DosageFormsSheet), findsOneWidget);
    expect(wire.formsAttempts, 2);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DosageFormsSheet), findsNothing);
    await openForms(tester);
    await tester.pumpAndSettle();
    expect(find.byType(DosageFormsSheet), findsOneWidget);
    expect(find.text('Returned capsule'), findsOneWidget);
    // The same repository caches the completed lookup across closing/reopening.
    expect(wire.formsAttempts, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'forms transport failure retries the same returned medication ID',
    (tester) async {
      final wire = _MedicationWire(failFirstForms: true);
      await openResults(tester, wire);
      await openForms(tester);
      await tester.pumpAndSettle();
      expect(find.text('An error occurred while loading data'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Returned capsule'), findsOneWidget);
      expect(find.text('Returned solution'), findsOneWidget);
      expect(wire.formsAttempts, 3);
      expect(
        wire.requests.skip(1).map((request) => request.queryParameters['id']),
        everyElement(982),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final changeCountry in [false, true]) {
    testWidgets(
      'pending forms are canceled on ${changeCountry ? 'country change' : 'Back'}',
      (tester) async {
        final wire = _MedicationWire()..heldForms = Completer<ResponseBody>();
        final app = await openResults(tester, wire);
        await openForms(tester);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(wire.formsAttempts, 1);
        if (changeCountry) {
          await app.setCountry(AppCountry.jordan);
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();
        expect(wire.formsCancelled, isTrue);
        expect(find.byType(DosageFormsSheet), findsNothing);
        expect(find.text('Returned capsule'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
