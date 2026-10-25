import 'package:digitalpharmacy/core/config/api_country_bindings.dart';
import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/features/drugs/data/models/agent_catalog_item.dart';
import 'package:digitalpharmacy/features/drugs/data/mappers/medication_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

const _origin = 'http://144.91.111.63:5002';

Map<String, dynamic> _page(
  List<Map<String, dynamic>> items, {
  required int page,
  required int totalPages,
}) => {
  'status': 200,
  'message': 'synthetic',
  'data': {
    'data': items,
    'meta': {
      'pageNumber': page,
      'totalPages': totalPages,
      'totalCount': items.length,
      'hasPreviousPage': page > 1,
      'hasNextPage': page < totalPages,
    },
  },
};

void main() {
  test(
    'company catalog maps stable IDs and labels but drops phone fields',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: _origin));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            final page = options.queryParameters['PageNumber'] as int;
            final response =
                page == 1
                    ? _page(
                      [
                        {
                          'id': 71,
                          'company': 'Acme Pharma',
                          'agent': 'North Warehouse',
                          'agentsPhoneNumber': 'synthetic-business-number',
                        },
                        {'id': 72, 'company': '0', 'agent': 'Unknown'},
                      ],
                      page: 1,
                      totalPages: 2,
                    )
                    : _page(
                      [
                        {
                          'id': 73,
                          'company': 'Other Pharma',
                          'agent': 'South Warehouse',
                          'agentsPhoneNumber': 'synthetic-business-number',
                        },
                      ],
                      page: 2,
                      totalPages: 2,
                    );
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: response,
              ),
            );
          },
        ),
      );
      final service = ApiService(
        countryBindings: const ApiCountryBindings(),
        client: ApiTransport(dio: dio, baseUrl: _origin),
      );

      final matches = await service.fetchCompanies(query: 'acme');

      expect(matches, hasLength(1));
      expect(matches.single.id, 71);
      expect(matches.single.company, 'Acme Pharma');
      expect(matches.single.agent, 'North Warehouse');
      expect(matches.single.isSelectable, isTrue);
      expect(requests, hasLength(2));
      expect(
        requests.every(
          (request) => request.uri.path == '/api/GetCompanySeletc',
        ),
        isTrue,
      );
      expect(requests.first.queryParameters, {
        'PageNumber': 1,
        'PageSize': 3000,
      });
      expect(
        requests.every(
          (request) => !request.queryParameters.containsKey('CountryId'),
        ),
        isTrue,
      );
    },
  );

  test('company ID drives the documented paged medication lookup', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: _origin));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: _page(
                [
                  {
                    'id': 901,
                    'tradeName': 'Sample tab',
                    'scientificName': 'Sample ingredient',
                    'company': 'Acme Pharma',
                    'agent': 'North Warehouse',
                    'usage': 'synthetic use',
                    'pharmaceuticalForm': 'tablet',
                    'price': 1.25,
                  },
                ],
                page: 1,
                totalPages: 3,
              ),
            ),
          );
        },
      ),
    );
    final service = ApiService(
      countryBindings: const ApiCountryBindings(),
      client: ApiTransport(dio: dio, baseUrl: _origin),
    );

    final result = await service.fetchMedicationPageByCompany(
      companyId: 71,
      pageNumber: 1,
      pageSize: 20,
    );

    expect(requests.single.uri.path, '/api/GetMedicationDetailsByCompany');
    expect(requests.single.queryParameters, {
      'id': 71,
      'PageNumber': 1,
      'PageSize': 20,
    });
    expect(result.items.single.id, 901);
    expect(result.items.single.company, 'Acme Pharma');
    expect(result.items.single.country, isNull);
    expect(MedicationMapper.toDrug(result.items.single).country, isEmpty);
    expect(result.metadata.hasNextPage, isTrue);
  });

  test('agent selection ID drives the documented ByAgent lookup', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: _origin));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (options.uri.path == '/api/GetAgentSeletc') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: _page(
                  [
                    {'id': 5493, 'value': 'Qualified Warehouse'},
                  ],
                  page: 1,
                  totalPages: 1,
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: _page(
                [
                  {
                    'id': 5493,
                    'tradeName': 'Bodykei',
                    'scientificName': 'Advanced Formula',
                    'company': 'Bodykei',
                    'agent': 'Qualified Warehouse',
                  },
                ],
                page: 1,
                totalPages: 1,
              ),
            ),
          );
        },
      ),
    );
    final service = ApiService(
      countryBindings: const ApiCountryBindings(),
      client: ApiTransport(dio: dio, baseUrl: _origin),
    );

    final agents = await service.fetchAgents(query: 'qualified');
    final page = await service.fetchMedicationPageByAgent(
      agentId: agents.single.id,
      pageNumber: 1,
      pageSize: 20,
    );

    expect(agents.single, isA<AgentCatalogItem>());
    expect(agents.single.value, 'Qualified Warehouse');
    expect(requests.first.uri.path, '/api/GetAgentSeletc');
    expect(requests.last.uri.path, '/api/GetMedicationDetailsByAgent');
    expect(requests.last.queryParameters, {
      'id': 5493,
      'PageNumber': 1,
      'PageSize': 20,
    });
    expect(
      requests.every(
        (request) => !request.queryParameters.containsKey('CountryId'),
      ),
      isTrue,
    );
    expect(page.items.single.tradeName, 'Bodykei');
  });
}
