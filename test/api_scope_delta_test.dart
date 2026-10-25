import 'package:digitalpharmacy/core/config/api_country_bindings.dart';
import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/features/drugs/data/mappers/medication_mapper.dart';
import 'package:digitalpharmacy/features/drugs/data/models/medication_item.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _page(
  List<Map<String, dynamic>> items,
  int page, {
  bool next = false,
}) => {
  'status': 200,
  'message': 'synthetic',
  'data': {
    'data': items,
    'meta': {
      'pageNumber': page,
      'totalPages': next ? page + 1 : page,
      'totalCount': items.length,
      'hasPreviousPage': page > 1,
      'hasNextPage': next,
    },
  },
};

ApiService _service(
  dynamic Function(RequestOptions) respond,
  List<RequestOptions> requests,
) {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        final data =
            options.path == '/api/GetCountries'
                ? [
                  {'id': 44, 'name': 'Jordan'},
                ]
                : respond(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: data,
          ),
        );
      },
    ),
  );
  return ApiService(
    countryBindings: const ApiCountryBindings(),
    client: ApiTransport(dio: dio, baseUrl: 'http://api.example.test'),
  );
}

void main() {
  setUp(() => setAppCountry(AppCountry.jordan));

  test(
    'usage is not strength and a currency is never inferred from app country',
    () {
      final item = MedicationItem.fromJson({
        'id': 17,
        'usage': 'Synthetic indication',
        'price': 2.5,
        'pharmaceuticalForm': 'tablet',
      });
      final drug = MedicationMapper.toDrug(item);
      expect(drug.usage, 'Synthetic indication');
      expect(drug.strength, isEmpty);
      expect(drug.formattedPriceJod, '2.50');
      expect(drug.dosageForms.single.formattedPrice, '2.50');
      setAppCountry(AppCountry.palestine);
      expect(drug.formattedPriceJod, '2.50');
    },
  );

  test(
    'missing or malformed prices stay unknown, while server zero is preserved',
    () {
      for (final input in [null, 'not-a-price', double.nan]) {
        final item = MedicationItem.fromJson({'id': 17, 'price': input});
        expect(item.price, isNull);
        expect(MedicationMapper.toDrug(item).formattedPriceJod, '—');
      }
      expect(MedicationItem.fromJson({'id': 17, 'price': 0}).price, 0);
    },
  );

  test(
    'anonymous catalog and company/agent reads use only a resolved country',
    () async {
      const origin = 'http://144.91.111.63:5002';
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: origin));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            final data =
                request.path == '/api/GetCountries'
                    ? [
                      {'id': 44, 'name': 'Jordan'},
                    ]
                    : _page([
                      request.path == '/api/GetCompanySeletc'
                          ? {
                            'id': 71,
                            'company': 'Synthetic company',
                            'agent': 'Synthetic warehouse',
                          }
                          : request.path == '/api/GetAgentSeletc'
                          ? {'id': 81, 'value': 'Synthetic warehouse'}
                          : {
                            'id': 17,
                            'tradeName': 'Synthetic product',
                            'scientificName': 'Synthetic ingredient',
                            'company': 'Synthetic company',
                            'agent': 'Synthetic warehouse',
                          },
                    ], 1);
            handler.resolve(
              Response<dynamic>(
                requestOptions: request,
                statusCode: 200,
                data: data,
              ),
            );
          },
        ),
      );
      final api = ApiService(
        countryBindings: const ApiCountryBindings(),
        client: ApiTransport(dio: dio, baseUrl: origin),
      );
      await api.fetchCountries();
      await api.fetchCompanyPage(pageNumber: 1, pageSize: 20);
      await api.fetchAgents();
      await api.fetchMedicationPageByCompany(
        companyId: 71,
        pageNumber: 1,
        pageSize: 20,
      );
      await api.fetchMedicationPageByAgent(
        agentId: 81,
        pageNumber: 1,
        pageSize: 20,
      );
      expect(requests.where((r) => r.path == '/api/GetCountries').length, 1);
      expect(
        requests
            .where((r) => r.path != '/api/GetCountries')
            .map((r) => r.queryParameters['CountryId']),
        [44, 44, 44, 44],
      );
    },
  );

  test(
    'pharmacy pages use verified country, filter enum and server metadata',
    () async {
      final requests = <RequestOptions>[];
      final api = _service(
        (r) => _page(
          [
            {
              'id': 90 + (r.queryParameters['PageNumber'] as int),
              'name': 'Synthetic Pharmacy',
              'address': 'Synthetic street',
              'managerName': 'Synthetic manager',
              'phoneNumber': 'synthetic-phone',
            },
          ],
          r.queryParameters['PageNumber'] as int,
          next: r.queryParameters['PageNumber'] == 1,
        ),
        requests,
      );
      final first = await api.fetchPharmacyPage(
        query: 'example',
        searchType: PharmacySearchType.phoneNumber,
        pageNumber: 1,
        pageSize: 20,
      );
      final last = await api.fetchPharmacyPage(
        query: 'example',
        searchType: PharmacySearchType.phoneNumber,
        pageNumber: 2,
        pageSize: 20,
      );
      expect(first.metadata.hasNextPage, isTrue);
      expect(last.metadata.hasNextPage, isFalse);
      expect(first.items.single.country, isNull);
      expect(requests.where((r) => r.path == '/api/GetCountries').length, 1);
      expect(requests.last.queryParameters, {
        'CountryId': 44,
        'SearchType': 4,
        'PageNumber': 2,
        'PageSize': 20,
        'StringSerch': 'example',
      });
    },
  );

  test(
    'selected medication details preserve actual ID and searchType',
    () async {
      final requests = <RequestOptions>[];
      final api = _service(
        (r) => _page([
          {
            'id': 17,
            'tradeName': 'Synthetic product',
            'scientificName': 'Synthetic ingredient',
            'company': 'Synthetic company',
            'agent': 'Synthetic warehouse',
            'pharmaceuticalForm': 'tablet',
            'price': 2.5,
          },
        ], 1),
        requests,
      );
      final page = await api.fetchMedicationDetailsPage(
        id: 17,
        searchType: MedicationSearchType.scientificName,
        pageNumber: 1,
        pageSize: 20,
      );
      expect(requests.single.path, '/api/GetMedicationDetails');
      expect(requests.single.queryParameters, {
        'id': 17,
        'searchType': 2,
        'PageNumber': 1,
        'PageSize': 20,
      });
      expect(page.items.single.id, 17);
      await expectLater(
        api.fetchMedicationDetailsPage(
          id: 0,
          searchType: MedicationSearchType.tradeName,
          pageNumber: 1,
          pageSize: 20,
        ),
        throwsArgumentError,
      );
      expect(requests.length, 1);
    },
  );

  test(
    'selection IDs are optional and invalid IDs cannot enable navigation',
    () async {
      final api = _service(
        (r) => _page([
          {'id': 17, 'tradeName': 'A', 'scientificName': 'B'},
          {'id': 0, 'tradeName': 'C', 'scientificName': 'D'},
          {'tradeName': 'E', 'scientificName': 'F'},
        ], 1),
        [],
      );
      final page = await api.fetchMedicationSuggestionPage(
        searchType: MedicationSearchType.tradeName,
        pageNumber: 1,
        pageSize: 20,
      );
      expect(page.items.map((i) => i.id), [17, null, null]);
    },
  );

  test(
    'repeated page metadata stops catalog traversal without 100 requests',
    () async {
      final requests = <RequestOptions>[];
      final api = _service(
        (r) => _page(
          [
            {
              'id': 81,
              'company': 'Synthetic company',
              'agent': 'Synthetic warehouse',
            },
          ],
          1,
          next: true,
        ),
        requests,
      );
      await expectLater(api.fetchCompanies(), throwsFormatException);
      expect(requests.length, 2);
    },
  );

  test('an empty next page and invalid counts are rejected', () {
    expect(
      () => ApiPageMetadata(
        pageNumber: 1,
        totalPages: 2,
        totalCount: 10,
        hasPreviousPage: false,
        hasNextPage: true,
      ).validatedFor(requestedPage: 1, itemCount: 0),
      throwsFormatException,
    );
  });
}
