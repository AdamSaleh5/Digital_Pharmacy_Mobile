import 'package:digitalpharmacy/core/config/api_country_bindings.dart';
import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/core/network/api_errors.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';

void main() {
  late Dio dio;
  late ApiService api;
  late List<RequestOptions> requests;

  Map<String, dynamic> countryResponse = {'id': 7, 'name': 'Jordan'};
  dynamic countriesResponse;

  setUp(() {
    setAppCountry(AppCountry.jordan);
    countryResponse = {'id': 7, 'name': 'Jordan'};
    countriesResponse = [countryResponse];
    requests = [];
    dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (options.path == '/api/GetCountries') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: countriesResponse,
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: _medicationPage(
                pageNumber: options.queryParameters['PageNumber'] as int,
                hasNextPage: true,
                data: const [
                  {
                    'id': 17,
                    'tradeName': 'Synthetic product',
                    'scientificName': 'Synthetic ingredient',
                  },
                ],
              ),
            ),
          );
        },
      ),
    );
    api = ApiService(
      countryBindings: const ApiCountryBindings(),
      client: ApiTransport(dio: dio),
    );
  });

  test(
    'medication GET parses the verified envelope and exact query names',
    () async {
      final result = await api.fetchMedicationSuggestionPage(
        searchType: MedicationSearchType.tradeName,
        query: '  aspirin  ',
        pageNumber: 2,
        pageSize: 5,
      );

      expect(result.items.single.id, 17);
      expect(result.metadata.pageNumber, 2);
      expect(result.metadata.hasNextPage, isTrue);
      expect(requests.first.path, '/api/GetCountries');
      final search = requests.last;
      expect(search.path, '/api/GetMedicationSelect');
      expect(search.queryParameters, {
        'CountryId': 7,
        'SearchType': 1,
        'StringSerch': 'aspirin',
        'PageNumber': 2,
        'PageSize': 5,
      });
    },
  );

  test('search type enums stay within Swagger numeric values', () {
    expect(MedicationSearchType.tradeName.asNumber(), '1');
    expect(MedicationSearchType.scientificName.asNumber(), '2');
    expect(PharmacySearchType.name.asNumber(), '1');
    expect(PharmacySearchType.address.asNumber(), '2');
    expect(PharmacySearchType.managerName.asNumber(), '3');
    expect(PharmacySearchType.phoneNumber.asNumber(), '4');
  });

  test('page bounds are validated before making a request', () async {
    await expectLater(
      api.fetchMedicationSuggestionPage(
        searchType: MedicationSearchType.tradeName,
        pageNumber: 0,
        pageSize: 5,
      ),
      throwsArgumentError,
    );
    expect(requests, isEmpty);
  });

  test(
    'CountryId is resolved by exact country name; no ID is guessed',
    () async {
      countryResponse = {'id': 7, 'name': 'Hashemite Kingdom'};
      countriesResponse = [countryResponse];
      await expectLater(
        api.fetchMedicationSuggestionPage(
          searchType: MedicationSearchType.tradeName,
          pageNumber: 1,
          pageSize: 5,
        ),
        throwsStateError,
      );
      expect(requests.map((request) => request.path), ['/api/GetCountries']);
    },
  );

  test('empty country list fails closed without a numeric fallback', () async {
    countriesResponse = <dynamic>[];
    await expectLater(
      api.fetchMedicationSuggestions(
        searchType: MedicationSearchType.tradeName,
      ),
      throwsStateError,
    );
    expect(requests.map((request) => request.path), ['/api/GetCountries']);
  });

  test('malformed country item fails before the medication request', () async {
    countriesResponse = [
      <String, dynamic>{'name': 'Jordan'},
    ];
    await expectLater(
      api.fetchMedicationSuggestions(
        searchType: MedicationSearchType.tradeName,
      ),
      throwsFormatException,
    );
    expect(requests.map((request) => request.path), ['/api/GetCountries']);
  });

  test(
    '401 remains an authorization error and is not converted to empty data',
    () async {
      dio.interceptors.clear();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 401,
                  data: {
                    'status': 401,
                    'message': 'A valid access token is required.',
                  },
                ),
              ),
            );
          },
        ),
      );
      await expectLater(
        api.fetchMedicationSuggestions(
          searchType: MedicationSearchType.tradeName,
        ),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
    },
  );

  test('401 maps to service-access failure with manual retry', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/api/GetCountries'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/GetCountries'),
        statusCode: 401,
      ),
    );
    final l10n = AppLocalizationsEn();
    expect(apiFailureMessage(error, l10n), l10n.apiAuthenticationRequired);
    expect(isApiFailureRetryable(error), isTrue);
  });

  test('offline errors keep a retryable localized error state', () async {
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException.connectionError(
              requestOptions: options,
              reason: 'offline in test',
            ),
          );
        },
      ),
    );
    final l10n = AppLocalizationsEn();
    try {
      await api.fetchMedicationSuggestions(
        searchType: MedicationSearchType.tradeName,
      );
      fail('Expected an offline error.');
    } on DioException catch (error) {
      expect(apiFailureMessage(error, l10n), l10n.errorLoadingData);
      expect(isApiFailureRetryable(error), isTrue);
    }
  });

  test('cancellation is propagated and does not issue a request', () async {
    final token = CancelToken()..cancel('test cancellation');
    await expectLater(
      api.fetchMedicationSuggestions(
        searchType: MedicationSearchType.tradeName,
        cancelToken: token,
      ),
      throwsA(
        isA<DioException>().having(CancelToken.isCancel, 'is cancel', isTrue),
      ),
    );
    expect(requests, isEmpty);
  });

  test(
    'pharmacy parser rejects a response missing pharmacy DTO fields',
    () async {
      await expectLater(
        api.fetchPharmacies(searchType: PharmacySearchType.address),
        throwsFormatException,
      );
      expect(requests.map((request) => request.path), [
        '/api/GetCountries',
        '/api/GetPharmacies',
      ]);
    },
  );

  test(
    'unknown medication envelope and unverified item shape fail explicitly',
    () async {
      dio.interceptors.clear();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data:
                    options.path == '/api/GetCountries'
                        ? [countryResponse]
                        : {'items': []},
              ),
            );
          },
        ),
      );
      await expectLater(
        api.fetchMedicationSuggestions(
          searchType: MedicationSearchType.tradeName,
        ),
        throwsA(isA<FormatException>()),
      );

      dio.interceptors.clear();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: _medicationPage(
                  pageNumber: 1,
                  data: [
                    {'unknown': 'unvalidated medication shape'},
                  ],
                ),
              ),
            );
          },
        ),
      );
      await expectLater(
        api.fetchMedicationSuggestions(
          searchType: MedicationSearchType.tradeName,
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'malformed pagination metadata fails instead of inventing defaults',
    () async {
      dio.interceptors.clear();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data:
                    options.path == '/api/GetCountries'
                        ? countriesResponse
                        : _medicationPage(
                          pageNumber: 1,
                          metadata: {'pageNumber': 1},
                        ),
              ),
            );
          },
        ),
      );
      await expectLater(
        api.fetchMedicationSuggestionPage(
          searchType: MedicationSearchType.tradeName,
          pageNumber: 1,
          pageSize: 5,
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );
}

Map<String, dynamic> _medicationPage({
  required int pageNumber,
  bool hasNextPage = false,
  List<dynamic> data = const [],
  Map<String, dynamic>? metadata,
}) => {
  'status': 200,
  'message': 'The process was completed successfully.',
  'data': {
    'data': data,
    'meta':
        metadata ??
        {
          'pageNumber': pageNumber,
          'totalPages': hasNextPage ? pageNumber + 1 : pageNumber,
          'totalCount': data.length,
          'hasPreviousPage': pageNumber > 1,
          'hasNextPage': hasNextPage,
        },
  },
};
