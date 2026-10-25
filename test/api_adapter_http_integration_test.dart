import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:digitalpharmacy/core/config/api_country_bindings.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/api_errors.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

// These fixtures cross a real local HTTP socket and Dio's JSON decoder. They
// never contact the deployed API or submit activation/account data.
void main() {
  late HttpServer server;
  late Dio dio;
  late ApiService api;
  late List<_ObservedGet> requests;
  late Future<void> Function(HttpRequest) respond;

  setUp(() async {
    setAppCountry(AppCountry.jordan);
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = 'http://127.0.0.1:${server.port}';
    respond = (request) => _jsonReply(request, _page([]));
    server.listen((request) async {
      requests.add(
        _ObservedGet(
          request.method,
          request.uri.path,
          Map<String, String>.from(request.uri.queryParameters),
          request.headers.value(HttpHeaders.authorizationHeader),
          request.headers.value(HttpHeaders.cookieHeader),
        ),
      );
      await respond(request);
    });
    dio = Dio(
      BaseOptions(
        baseUrl: origin,
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
        followRedirects: false,
        headers: const {
          'Accept': 'application/json',
          'Authorization': 'fixture-stale-authorization',
        },
      ),
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()..findProxy = (_) => 'DIRECT',
    );
    api = ApiService(
      client: ApiTransport(dio: dio, baseUrl: origin),
      countryBindings: ApiCountryBindings(
        origin: origin,
        jordanId: 0,
        palestineId: 1,
        evidence: 'Synthetic loopback fixture; preserves owner country IDs.',
      ),
    );
  });

  tearDown(() async {
    dio.close(force: true);
    await server.close(force: true);
    setAppCountry(AppCountry.jordan);
  });

  test(
    'real HTTP pages preserve exact query names and anonymous headers',
    () async {
      respond = (request) {
        final page = int.parse(request.uri.queryParameters['PageNumber']!);
        return _jsonReply(
          request,
          _page(
            [
              {'id': 100 + page, 'value': 'Synthetic selection $page'},
            ],
            pageNumber: page,
            totalPages: 2,
            totalCount: 2,
          ),
        );
      };

      final first = await api.fetchMedicationSuggestionPage(
        searchType: MedicationSearchType.scientificName,
        query: '  Synthetic ingredient  ',
        pageNumber: 1,
        pageSize: 1,
      );
      final second = await api.fetchMedicationSuggestionPage(
        searchType: MedicationSearchType.scientificName,
        query: 'Synthetic ingredient',
        pageNumber: 2,
        pageSize: 1,
      );

      expect(first.items.single.id, 101);
      expect(first.metadata.hasNextPage, isTrue);
      expect(second.items.single.id, 102);
      expect(second.metadata.pageNumber, 2);
      expect(second.metadata.hasNextPage, isFalse);
      expect(requests, hasLength(2));
      for (var index = 0; index < requests.length; index++) {
        final request = requests[index];
        expect(request.method, 'GET');
        expect(request.path, '/api/GetMedicationSelect');
        expect(request.query, {
          'CountryId': '0',
          'SearchType': '2',
          'StringSerch': 'Synthetic ingredient',
          'PageNumber': '${index + 1}',
          'PageSize': '1',
        });
        expect(request.authorization, isNull);
        expect(request.cookie, isNull);
      }
    },
  );

  test(
    'all public catalog adapters decode observed wire shapes over HTTP',
    () async {
      setAppCountry(AppCountry.palestine);
      respond = (request) {
        final items = switch (request.uri.path) {
          '/api/GetCompanySeletc' => <Map<String, Object?>>[
            {
              'id': 201,
              'company': 'Synthetic company',
              'agent': 'Synthetic agent',
              'agentsPhoneNumber': 'fixture-phone',
            },
          ],
          '/api/GetAgentSeletc' => <Map<String, Object?>>[
            {'id': 301, 'value': 'Synthetic agent'},
          ],
          '/api/GetPharmacies' => <Map<String, Object?>>[
            {
              'id': 401,
              'name': 'Synthetic pharmacy',
              'address': 'Synthetic address',
              'managerName': 'Synthetic manager',
              'phoneNumber': 'fixture-phone',
            },
          ],
          _ => <Map<String, Object?>>[_medication],
        };
        return _jsonReply(request, _page(items));
      };

      final companies = await api.fetchCompanyPage(pageNumber: 1, pageSize: 2);
      final agents = await api.fetchAgents();
      final pharmacies = await api.fetchPharmacyPage(
        searchType: PharmacySearchType.address,
        query: '  Synthetic address  ',
        pageNumber: 1,
        pageSize: 2,
      );
      final details = await api.fetchMedicationDetailsPage(
        id: 101,
        searchType: MedicationSearchType.tradeName,
        pageNumber: 1,
        pageSize: 2,
      );
      final byCompany = await api.fetchMedicationPageByCompany(
        companyId: 201,
        pageNumber: 1,
        pageSize: 2,
      );
      final byAgent = await api.fetchMedicationPageByAgent(
        agentId: 301,
        pageNumber: 1,
        pageSize: 2,
      );
      final forms = await api.fetchPharmaceuticalFormPage(
        id: 101,
        pageNumber: 1,
        pageSize: 2,
      );

      expect(companies.items.single.company, 'Synthetic company');
      expect(agents.single.id, 301);
      expect(pharmacies.items.single.address, 'Synthetic address');
      for (final page in [details, byCompany, byAgent, forms]) {
        expect(page.items.single.id, 101);
        expect(page.items.single.price, 4.5);
        expect(page.items.single.pharmaceuticalForm, 'Synthetic form');
      }
      expect(requests.map((request) => request.path), [
        '/api/GetCompanySeletc',
        '/api/GetAgentSeletc',
        '/api/GetPharmacies',
        '/api/GetMedicationDetails',
        '/api/GetMedicationDetailsByCompany',
        '/api/GetMedicationDetailsByAgent',
        '/api/GetPharmaceuticalForm',
      ]);
      final pharmacy = requests[2];
      expect(pharmacy.query, {
        'CountryId': '1',
        'SearchType': '2',
        'StringSerch': 'Synthetic address',
        'PageNumber': '1',
        'PageSize': '2',
      });
      expect(requests[3].query, {
        'id': '101',
        'searchType': '1',
        'PageNumber': '1',
        'PageSize': '2',
      });
      expect(requests[4].query['id'], '201');
      expect(requests[4].query['CountryId'], '1');
      expect(requests[5].query['id'], '301');
      expect(requests[5].query['CountryId'], '1');
      expect(requests[6].query, {
        'id': '101',
        'PageNumber': '1',
        'PageSize': '2',
      });
      for (final request in requests) {
        expect(request.method, 'GET');
        expect(request.authorization, isNull);
        expect(request.cookie, isNull);
      }
    },
  );

  for (final status in [401, 403, 404, 422, 429, 500]) {
    test(
      'HTTP $status retains status for application error handling',
      () async {
        respond =
            (request) => _jsonReply(request, {
              'status': status,
              'message': 'Synthetic failure',
              'data': null,
            }, statusCode: status);
        DioException? failure;
        try {
          await api.fetchMedicationSuggestionPage(
            searchType: MedicationSearchType.tradeName,
            pageNumber: 1,
            pageSize: 2,
          );
        } on DioException catch (error) {
          failure = error;
        }
        expect(failure, isNotNull);
        expect(failure!.response?.statusCode, status);
        expect(failure.type, DioExceptionType.badResponse);
        final l10n = AppLocalizationsEn();
        expect(
          apiFailureMessage(failure, l10n),
          status == 401 || status == 403
              ? l10n.apiAuthenticationRequired
              : l10n.errorLoadingData,
        );
        expect(requests.single.path, '/api/GetMedicationSelect');
        expect(requests.single.authorization, isNull);
      },
    );
  }

  test(
    'malformed 200 envelopes fail as contract errors instead of empty data',
    () async {
      final malformedBodies = <Object>[
        {'status': 200, 'data': <Object>[]},
        _page([
          {'unexpected': 'Synthetic field'},
        ]),
        {
          'status': 200,
          'data': {
            'data': <Object>[],
            'meta': {
              'pageNumber': 1,
              'totalPages': 2,
              'totalCount': 1,
              'hasPreviousPage': false,
              'hasNextPage': true,
            },
          },
        },
      ];
      for (final body in malformedBodies) {
        respond = (request) => _jsonReply(request, body);
        await expectLater(
          api.fetchMedicationSuggestionPage(
            searchType: MedicationSearchType.tradeName,
            pageNumber: 1,
            pageSize: 2,
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => apiFailureMessage(error, AppLocalizationsEn()),
              'localized contract error',
              AppLocalizationsEn().apiContractUnavailable,
            ),
          ),
        );
      }
    },
  );

  test(
    'invalid JSON received over HTTP does not become a successful page',
    () async {
      respond = (request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"status":200,"data":');
        await request.response.close();
      };
      await expectLater(
        api.fetchMedicationSuggestionPage(
          searchType: MedicationSearchType.tradeName,
          pageNumber: 1,
          pageSize: 2,
        ),
        throwsA(isA<DioException>()),
      );
    },
  );

  test(
    'dropped connection surfaces a transport failure with no HTTP status',
    () async {
      respond = (request) async {
        final socket = await request.response.detachSocket(writeHeaders: false);
        socket.destroy();
      };
      await expectLater(
        api.fetchMedicationSuggestionPage(
          searchType: MedicationSearchType.tradeName,
          pageNumber: 1,
          pageSize: 2,
        ),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'HTTP response absent',
            isNull,
          ),
        ),
      );
    },
  );

  test(
    'a stalled HTTP response reaches the configured receive timeout',
    () async {
      dio.options.receiveTimeout = const Duration(milliseconds: 50);
      respond = (_) async {};
      await expectLater(
        api.fetchMedicationSuggestionPage(
          searchType: MedicationSearchType.tradeName,
          pageNumber: 1,
          pageSize: 2,
        ),
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'bounded receive failure',
            DioExceptionType.receiveTimeout,
          ),
        ),
      );
      expect(requests, hasLength(1));
    },
  );

  test('redirects are not followed by the actual HTTP adapter', () async {
    respond = (request) async {
      request.response.statusCode = HttpStatus.found;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        '/must-not-load',
      );
      await request.response.close();
    };
    await expectLater(
      api.fetchMedicationSuggestionPage(
        searchType: MedicationSearchType.tradeName,
        pageNumber: 1,
        pageSize: 2,
      ),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'redirect status',
          HttpStatus.found,
        ),
      ),
    );
    expect(requests, hasLength(1));
    expect(requests.single.path, '/api/GetMedicationSelect');
  });
}

Future<void> _jsonReply(
  HttpRequest request,
  Object body, {
  int statusCode = HttpStatus.ok,
}) async {
  request.response.statusCode = statusCode;
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(body));
  await request.response.close();
}

Map<String, Object> _page(
  List<Map<String, Object?>> items, {
  int pageNumber = 1,
  int totalPages = 1,
  int? totalCount,
}) => {
  'status': 200,
  'message': 'Synthetic fixture',
  'data': {
    'data': items,
    'meta': {
      'pageNumber': pageNumber,
      'totalPages': totalPages,
      'totalCount': totalCount ?? items.length,
      'hasPreviousPage': pageNumber > 1,
      'hasNextPage': pageNumber < totalPages,
    },
  },
};

const _medication = <String, Object?>{
  'id': 101,
  'tradeName': 'Synthetic product',
  'scientificName': 'Synthetic ingredient',
  'usage': 'Synthetic fixture usage',
  'company': 'Synthetic company',
  'agent': 'Synthetic agent',
  'agentsPhoneNumber': 'fixture-phone',
  'pharmaceuticalForm': 'Synthetic form',
  'price': 4.5,
};

class _ObservedGet {
  const _ObservedGet(
    this.method,
    this.path,
    this.query,
    this.authorization,
    this.cookie,
  );

  final String method;
  final String path;
  final Map<String, String> query;
  final String? authorization;
  final String? cookie;
}
