import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/config/api_country_bindings.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/features/drugs/data/mappers/medication_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

const _origin = 'http://144.91.111.63:5002';
// Deliberately synthetic numbers. Not a proposed deployment mapping.
const _bindings = ApiCountryBindings(
  jordanId: 73,
  palestineId: 89,
  evidence: 'synthetic unit-test country export',
);
Map<String, dynamic> _page(Object item) => {
  'status': 200,
  'data': {
    'data': [item],
    'meta': {
      'pageNumber': 1,
      'totalPages': 1,
      'totalCount': 1,
      'hasPreviousPage': false,
      'hasNextPage': false,
    },
  },
};

class _Wire implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  Completer<ResponseBody>? held;
  Map<String, dynamic> medication(int country) => {
    'id': 17,
    'tradeName': 'Synthetic $country',
    'scientificName': 'Synthetic',
    'company': 'Synthetic',
    'agent': 'Synthetic',
    'price': country == 73 ? 12.5 : 32.75,
  };
  ResponseBody result(RequestOptions request) {
    final country = request.queryParameters['CountryId'] as int? ?? 89;
    final item = switch (request.uri.path) {
      '/api/GetCountries' => null,
      '/api/GetCompanySeletc' => {
        'id': 17,
        'company': 'Synthetic company $country',
        'agent': 'Synthetic',
      },
      '/api/GetAgentSeletc' => {'id': 17, 'value': 'Synthetic agent $country'},
      '/api/GetPharmacies' => {
        'id': 17,
        'name': 'Synthetic pharmacy $country',
        'address': 'Synthetic',
        'managerName': 'Synthetic',
        'phoneNumber': 'synthetic',
      },
      _ => medication(country),
    };
    return ResponseBody.fromString(
      jsonEncode(
        item == null
            ? {
              'status': 401,
              'message': 'Synthetic public country lookup unavailable',
              'data': null,
            }
            : _page(item),
      ),
      item == null ? 401 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls.add(options);
    final wait = held;
    held = null;
    return wait == null ? result(options) : wait.future;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final original = kAppCountry;
  late _Wire wire;
  late Dio dio;
  ApiService api([ApiCountryBindings? binding = _bindings]) {
    final transport = ApiTransport(dio: dio);
    return ApiService(client: transport, countryBindings: binding);
  }

  setUp(() {
    setAppCountry(AppCountry.jordan);
    wire = _Wire();
    dio = Dio(BaseOptions(baseUrl: _origin))..httpClientAdapter = wire;
  });
  tearDown(() {
    dio.close();
    setAppCountry(original);
  });
  test('explicit empty adapter contains no numeric country IDs', () {
    const empty = ApiCountryBindings();
    for (final country in AppCountry.values) {
      expect(empty.idFor(country, Uri.parse(_origin)), isNull);
    }
  });
  test(
    'explicit evidence-bound two-country mapping routes all filterable app reads without country lookup or admin auth',
    () async {
      final service = api();
      for (final country in AppCountry.values) {
        setAppCountry(country);
        final expected = country == AppCountry.jordan ? 73 : 89;
        await service.fetchMedicationSuggestionPage(
          searchType: MedicationSearchType.tradeName,
          pageNumber: 1,
          pageSize: 20,
        );
        await service.fetchCompanyPage(pageNumber: 1, pageSize: 20);
        await service.fetchMedicationPageByCompany(
          companyId: 17,
          pageNumber: 1,
          pageSize: 20,
        );
        await service.fetchAgents();
        await service.fetchMedicationPageByAgent(
          agentId: 17,
          pageNumber: 1,
          pageSize: 20,
        );
        await service.fetchPharmacyPage(
          searchType: PharmacySearchType.name,
          pageNumber: 1,
          pageSize: 20,
        );
        for (final request in wire.calls.skip(wire.calls.length - 6)) {
          expect(request.queryParameters['CountryId'], expected);
          expect(request.queryParameters['CountryId'], isA<int>());
          expect(
            request.headers.keys.map((key) => key.toLowerCase()),
            isNot(contains('authorization')),
          );
        }
      }
      expect(wire.calls, hasLength(12));
      expect(
        wire.calls.where((request) => request.uri.path == '/api/GetCountries'),
        isEmpty,
      );
    },
  );
  test(
    'ordinary build preserves user-supplied zero/one country IDs on the wire',
    () async {
      final service = api(null);
      for (final country in AppCountry.values) {
        setAppCountry(country);
        final expected = country == AppCountry.jordan ? 0 : 1;
        await service.fetchMedicationSuggestionPage(
          searchType: MedicationSearchType.tradeName,
          pageNumber: 1,
          pageSize: 3,
        );
        await service.fetchCompanyPage(pageNumber: 1, pageSize: 3);
        await service.fetchMedicationPageByCompany(
          companyId: 17,
          pageNumber: 1,
          pageSize: 3,
        );
        await service.fetchAgents();
        await service.fetchMedicationPageByAgent(
          agentId: 17,
          pageNumber: 1,
          pageSize: 3,
        );
        await service.fetchPharmacyPage(pageNumber: 1, pageSize: 3);
        for (final request in wire.calls.skip(wire.calls.length - 6)) {
          expect(request.uri.queryParameters['CountryId'], '$expected');
          expect(request.queryParameters['CountryId'], expected);
          expect(
            request.headers.keys.map((k) => k.toLowerCase()),
            isNot(contains('authorization')),
          );
        }
      }
      expect(wire.calls, hasLength(12));
      final defaults = ApiCountryBindings.fromEnvironment();
      expect(defaults.evidence, contains('Human instruction'));
      expect(defaults.evidence, contains('not a server dictionary export'));
      expect(
        () => defaults.idFor(
          AppCountry.jordan,
          Uri.parse('http://other.example'),
        ),
        throwsStateError,
      );
    },
  );
  test('country zero does not weaken positive entity ID guards', () async {
    final service = api(null);
    await expectLater(
      service.fetchMedicationDetailsPage(
        id: 0,
        searchType: MedicationSearchType.tradeName,
        pageNumber: 1,
        pageSize: 3,
      ),
      throwsArgumentError,
    );
    expect(wire.calls, isEmpty);
  });
  test(
    'partial mapping never substitutes Jordan for an unmapped Palestine',
    () async {
      final service = api(
        const ApiCountryBindings(
          jordanId: 73,
          evidence: 'synthetic partial export',
        ),
      );
      setAppCountry(AppCountry.palestine);
      await expectLater(
        service.fetchPharmacyPage(pageNumber: 1, pageSize: 20),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'country access',
            401,
          ),
        ),
      );
      expect(wire.calls.map((request) => request.uri.path), [
        '/api/GetCountries',
      ]);
      expect(wire.calls.single.queryParameters, isEmpty);
    },
  );
  for (final invalid in [
    const ApiCountryBindings(
      jordanId: 73,
      palestineId: 73,
      evidence: 'synthetic duplicate',
    ),
    const ApiCountryBindings(jordanId: -1, evidence: 'synthetic negative'),
    const ApiCountryBindings(jordanId: 73),
    const ApiCountryBindings(
      jordanId: 2147483648,
      evidence: 'synthetic outside int32',
    ),
    const ApiCountryBindings(
      origin: 'http://other.example.test',
      jordanId: 73,
      evidence: 'synthetic wrong origin',
    ),
  ]) {
    test(
      'invalid/ambiguous country binding fails before any network request: ${invalid.evidence}',
      () async {
        await expectLater(
          api(invalid).fetchMedicationSuggestionPage(
            searchType: MedicationSearchType.tradeName,
            pageNumber: 1,
            pageSize: 20,
          ),
          throwsStateError,
        );
        expect(wire.calls, isEmpty);
      },
    );
  }
  test(
    'late country response is discarded even without caller cancellation and after Jordan→Palestine→Jordan',
    () async {
      final service = api();
      wire.held = Completer<ResponseBody>();
      final held = wire.held!;
      final response = service.fetchMedicationSuggestionPage(
        searchType: MedicationSearchType.tradeName,
        pageNumber: 1,
        pageSize: 20,
      );
      while (wire.calls.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      final check = expectLater(
        response,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'obsolete country',
            DioExceptionType.cancel,
          ),
        ),
      );
      setAppCountry(AppCountry.palestine);
      setAppCountry(AppCountry.jordan);
      held.complete(wire.result(wire.calls.first));
      await check;
    },
  );
  test(
    'late country dictionary cannot reinterpret an already-started query as the newly selected country',
    () async {
      final service = api(const ApiCountryBindings());
      wire.held = Completer<ResponseBody>();
      final held = wire.held!;
      final response = service.fetchMedicationSuggestionPage(
        searchType: MedicationSearchType.tradeName,
        pageNumber: 1,
        pageSize: 20,
      );
      while (wire.calls.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      final check = expectLater(
        response,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'obsolete lookup',
            DioExceptionType.cancel,
          ),
        ),
      );
      setAppCountry(AppCountry.palestine);
      held.complete(
        ResponseBody.fromString(
          jsonEncode([
            {'id': 73, 'name': 'Jordan'},
            {'id': 89, 'name': 'Palestine'},
          ]),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      await check;
      expect(wire.calls, hasLength(1));
    },
  );
  test(
    'server prices stay attached to their country-filtered response and never gain a currency from a later global selection',
    () async {
      final service = api();
      final jordan = await service.fetchMedicationPageByCompany(
        companyId: 17,
        pageNumber: 1,
        pageSize: 20,
      );
      final drug = MedicationMapper.toDrug(jordan.items.single);
      setAppCountry(AppCountry.palestine);
      final palestine = await service.fetchMedicationPageByCompany(
        companyId: 17,
        pageNumber: 1,
        pageSize: 20,
      );
      expect(jordan.items.single.price, 12.5);
      expect(palestine.items.single.price, 32.75);
      expect(drug.formattedPriceJod, '12.50');
      expect(
        MedicationMapper.toDrug(palestine.items.single).formattedPriceJod,
        '32.75',
      );
      expect(drug.priceCurrencyKnown, isFalse);
      expect(
        wire.calls.map((request) => request.queryParameters['CountryId']),
        [73, 89],
      );
    },
  );
}
