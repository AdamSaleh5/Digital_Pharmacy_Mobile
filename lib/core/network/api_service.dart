import 'package:dio/dio.dart';

import '../../features/drugs/data/models/company_agent_item.dart';
import '../../features/drugs/data/models/agent_catalog_item.dart';
import '../../features/drugs/data/models/medication_item.dart';
import '../../features/drugs/data/models/medication_suggestion.dart';
import '../../features/pharmacies/data/models/pharmacy_item.dart';
import '../config/app_config.dart';
import '../config/api_country_bindings.dart';
import 'models/api_country.dart';
import 'api_transport.dart';

class ApiService {
  ApiService({
    ApiTransport? client,
    ApiCountryBindings? countryBindings,
    Duration countryLookupTimeout = const Duration(seconds: 30),
  }) : _client = client ?? ApiTransport(),
       _countryBindings =
           countryBindings ?? ApiCountryBindings.fromEnvironment(),
       _countryLookupTimeout = countryLookupTimeout {
    if (countryLookupTimeout <= Duration.zero) {
      throw ArgumentError.value(countryLookupTimeout, 'countryLookupTimeout');
    }
  }

  final ApiTransport _client;
  final ApiCountryBindings _countryBindings;

  int? _configuredCountryId(AppCountry country) =>
      _countryBindings.idFor(country, Uri.parse(_client.dio.options.baseUrl));

  bool get hasResolvedCountryId {
    try {
      return _knownCountryId != null;
    } catch (_) {
      return false;
    }
  }

  Future<Response<T>> _scopedGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final revision = appCountryRevision;
    final response = await _client.get<T>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
    if (revision != appCountryRevision) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.cancel,
        message: 'Country scope changed.',
      );
    }
    return response;
  }

  final Duration _countryLookupTimeout;
  Future<List<ApiCountry>>? _countriesFuture;
  List<ApiCountry> _resolvedCountries = const [];

  int? get _knownCountryId {
    final configured = _configuredCountryId(kAppCountry);
    if (configured != null) return configured;
    final wanted = apiCountryString().toLowerCase();
    for (final country in _resolvedCountries) {
      if (country.name.toLowerCase() == wanted) return country.id;
    }
    return null;
  }

  CancelToken? _countriesToken;

  /// Drop data cached under a previous in-memory authentication session.
  void clearSessionCache() {
    final token = _countriesToken;
    _countriesFuture = null;
    _resolvedCountries = const [];
    _countriesToken = null;
    token?.cancel('API data scope changed.');
  }

  Future<List<ApiCountry>> fetchCountries({CancelToken? cancelToken}) async {
    final response = await _client.get<dynamic>(
      '/api/GetCountries',
      cancelToken: cancelToken,
    );
    final countries =
        _parseObjects(
          response.data,
          '/api/GetCountries',
          requiredKeys: const ['id', 'name'],
        ).map(ApiCountry.fromJson).toList();
    if (cancelToken?.isCancelled != true) _resolvedCountries = countries;
    return countries;
  }

  Future<List<MedicationSuggestion>> fetchMedicationSuggestions({
    required MedicationSearchType searchType,
    String? query,
    CancelToken? cancelToken,
  }) async {
    final page = await fetchMedicationSuggestionPage(
      searchType: searchType,
      query: query,
      pageNumber: 1,
      pageSize: 100,
      cancelToken: cancelToken,
    );
    return page.items;
  }

  Future<ApiPage<MedicationSuggestion>> fetchMedicationSuggestionPage({
    required MedicationSearchType searchType,
    String? query,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    if (pageNumber < 1 || pageSize < 1) {
      throw ArgumentError('pageNumber and pageSize must be positive.');
    }
    final params = <String, dynamic>{
      'CountryId': await _countryId(cancelToken),
      'SearchType': int.parse(searchType.asNumber()),
      'PageNumber': pageNumber,
      'PageSize': pageSize,
    };
    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      params['StringSerch'] = trimmed;
    }
    final response = await _scopedGet<dynamic>(
      '/api/GetMedicationSelect',
      queryParameters: params,
      cancelToken: cancelToken,
    );
    final pageData = _unwrapPage(response.data, '/api/GetMedicationSelect');
    final items =
        _parseObjects(
          pageData['data'],
          '/api/GetMedicationSelect',
        ).map(MedicationSuggestion.fromJson).toList();
    return ApiPage(
      items: items,
      metadata: ApiPageMetadata.fromJson(
        pageData['meta'] as Map,
      ).validatedFor(requestedPage: pageNumber, itemCount: items.length),
    );
  }

  Future<List<MedicationItem>> fetchMedicationsByName({
    required String query,
    required MedicationSearchType searchType,
    CancelToken? cancelToken,
  }) async {
    if (query.trim().isEmpty) return const [];
    final suggestions = await fetchMedicationSuggestions(
      searchType: searchType,
      query: query,
      cancelToken: cancelToken,
    );
    // A name query can return several selections. The current UI lets the user
    // choose an actual returned ID and preserves its searchType for details.
    if (suggestions.isNotEmpty) {
      throw const ApiContractUnavailable(
        'Choose a returned medication selection before requesting details.',
      );
    }
    return const [];
  }

  Future<List<MedicationItem>> fetchAlternatives(
    int id, {
    CancelToken? cancelToken,
  }) async {
    throw const ApiContractUnavailable(
      'Medication alternatives are not exposed by the documented API contract.',
    );
  }

  Future<List<MedicationItem>> fetchPharmaceuticalForms({
    required int id,
    CancelToken? cancelToken,
  }) async {
    // Live 2026-10-17 check: a returned medication ID selects its other forms;
    // the response uses the same medication/pagination envelope as details.
    final revision = appCountryRevision;
    final items = <MedicationItem>[];
    var pageNumber = 1;
    for (var request = 0; request < 100; request++) {
      final page = await fetchPharmaceuticalFormPage(
        id: id,
        pageNumber: pageNumber,
        pageSize: 100,
        cancelToken: cancelToken,
      );
      if (revision != appCountryRevision) {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/GetPharmaceuticalForm'),
          type: DioExceptionType.cancel,
          message: 'Country scope changed.',
        );
      }
      items.addAll(page.items);
      if (!page.metadata.hasNextPage) return List.unmodifiable(items);
      pageNumber = page.metadata.pageNumber + 1;
    }
    throw const FormatException(
      'Pharmaceutical forms exceeded the page limit.',
    );
  }

  Future<ApiPage<MedicationItem>> fetchPharmaceuticalFormPage({
    required int id,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    if (id <= 0 || pageNumber < 1 || pageSize < 1) {
      throw ArgumentError('A positive medication ID and page are required.');
    }
    final response = await _scopedGet<dynamic>(
      '/api/GetPharmaceuticalForm',
      queryParameters: {
        'id': id,
        'PageNumber': pageNumber,
        'PageSize': pageSize,
      },
      cancelToken: cancelToken,
    );
    final data = _unwrapPage(response.data, '/api/GetPharmaceuticalForm');
    final items =
        _parseObjects(
          data['data'],
          '/api/GetPharmaceuticalForm',
          requiredKeys: const [
            'id',
            'tradeName',
            'scientificName',
            'pharmaceuticalForm',
          ],
        ).map(MedicationItem.fromJson).toList();
    return ApiPage(
      items: items,
      metadata: ApiPageMetadata.fromJson(
        data['meta'] as Map,
      ).validatedFor(requestedPage: pageNumber, itemCount: items.length),
    );
  }

  Future<List<CompanyAgentItem>> fetchCompanies({
    String? query,
    CancelToken? cancelToken,
  }) async {
    final all = <CompanyAgentItem>[];
    var pageNumber = 1;
    const pageSize = 3000;
    for (var request = 0; request < 100; request++) {
      final page = await fetchCompanyPage(
        pageNumber: pageNumber,
        pageSize: pageSize,
        cancelToken: cancelToken,
      );
      all.addAll(page.items.where((item) => item.isSelectable));
      if (!page.metadata.hasNextPage) {
        final normalizedQuery = query?.trim().toLowerCase() ?? '';
        if (normalizedQuery.isEmpty) return List.unmodifiable(all);
        return List.unmodifiable(
          all.where(
            (item) =>
                item.company.toLowerCase().contains(normalizedQuery) ||
                item.agent.toLowerCase().contains(normalizedQuery),
          ),
        );
      }
      pageNumber = page.metadata.pageNumber + 1;
    }
    throw const FormatException('Company selection exceeded the page limit.');
  }

  Future<ApiPage<CompanyAgentItem>> fetchCompanyPage({
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    if (pageNumber < 1 || pageSize < 1) {
      throw ArgumentError('pageNumber and pageSize must be positive.');
    }
    final response = await _scopedGet<dynamic>(
      '/api/GetCompanySeletc',
      queryParameters: {
        'PageNumber': pageNumber,
        'PageSize': pageSize,
        if (_knownCountryId != null) 'CountryId': _knownCountryId,
      },
      cancelToken: cancelToken,
    );
    final pageData = _unwrapPage(response.data, '/api/GetCompanySeletc');
    final items =
        _parseObjects(
          pageData['data'],
          '/api/GetCompanySeletc',
          requiredKeys: const ['id', 'company', 'agent'],
        ).map(CompanyAgentItem.fromJson).toList();
    return ApiPage(
      items: items,
      metadata: ApiPageMetadata.fromJson(
        pageData['meta'] as Map,
      ).validatedFor(requestedPage: pageNumber, itemCount: items.length),
    );
  }

  Future<List<MedicationItem>> fetchMedicationsByCompany({
    required String companyName,
    CancelToken? cancelToken,
  }) async {
    throw const ApiContractUnavailable(
      'Company detail lookup requires the backend company ID contract.',
    );
  }

  Future<ApiPage<MedicationItem>> fetchMedicationPageByCompany({
    required int companyId,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    if (companyId <= 0 || pageNumber < 1 || pageSize < 1) {
      throw ArgumentError(
        'companyId, pageNumber, and pageSize must be positive.',
      );
    }
    final response = await _scopedGet<dynamic>(
      '/api/GetMedicationDetailsByCompany',
      queryParameters: {
        'id': companyId,
        if (_knownCountryId != null) 'CountryId': _knownCountryId,
        'PageNumber': pageNumber,
        'PageSize': pageSize,
      },
      cancelToken: cancelToken,
    );
    final pageData = _unwrapPage(
      response.data,
      '/api/GetMedicationDetailsByCompany',
    );
    final items =
        _parseObjects(
          pageData['data'],
          '/api/GetMedicationDetailsByCompany',
          requiredKeys: const [
            'id',
            'tradeName',
            'scientificName',
            'company',
            'agent',
          ],
        ).map(MedicationItem.fromJson).toList();
    return ApiPage(
      items: items,
      metadata: ApiPageMetadata.fromJson(
        pageData['meta'] as Map,
      ).validatedFor(requestedPage: pageNumber, itemCount: items.length),
    );
  }

  Future<List<AgentCatalogItem>> fetchAgents({
    String? query,
    CancelToken? cancelToken,
  }) async {
    final all = <AgentCatalogItem>[];
    var pageNumber = 1;
    const pageSize = 1000;
    for (var request = 0; request < 100; request++) {
      final response = await _scopedGet<dynamic>(
        '/api/GetAgentSeletc',
        queryParameters: {
          'PageNumber': pageNumber,
          'PageSize': pageSize,
          if (_knownCountryId != null) 'CountryId': _knownCountryId,
        },
        cancelToken: cancelToken,
      );
      final pageData = _unwrapPage(response.data, '/api/GetAgentSeletc');
      final pageItems =
          _parseObjects(
            pageData['data'],
            '/api/GetAgentSeletc',
            requiredKeys: const ['id', 'value'],
          ).map(AgentCatalogItem.fromJson).toList();
      all.addAll(pageItems.where((item) => item.isSelectable));
      final metadata = ApiPageMetadata.fromJson(
        pageData['meta'] as Map,
      ).validatedFor(requestedPage: pageNumber, itemCount: pageItems.length);
      if (!metadata.hasNextPage) {
        final normalizedQuery = query?.trim().toLowerCase() ?? '';
        if (normalizedQuery.isEmpty) return List.unmodifiable(all);
        return List.unmodifiable(
          all.where(
            (item) => item.value.toLowerCase().contains(normalizedQuery),
          ),
        );
      }
      pageNumber = metadata.pageNumber + 1;
    }
    throw const FormatException('Agent selection exceeded the page limit.');
  }

  Future<List<MedicationItem>> fetchMedicationsByAgent({
    required String agentName,
    CancelToken? cancelToken,
  }) async {
    throw const ApiContractUnavailable(
      'Agent detail lookup requires the backend agent ID contract.',
    );
  }

  Future<ApiPage<MedicationItem>> fetchMedicationPageByAgent({
    required int agentId,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    if (agentId <= 0 || pageNumber < 1 || pageSize < 1) {
      throw ArgumentError(
        'agentId, pageNumber, and pageSize must be positive.',
      );
    }
    final response = await _scopedGet<dynamic>(
      '/api/GetMedicationDetailsByAgent',
      queryParameters: {
        'id': agentId,
        if (_knownCountryId != null) 'CountryId': _knownCountryId,
        'PageNumber': pageNumber,
        'PageSize': pageSize,
      },
      cancelToken: cancelToken,
    );
    final pageData = _unwrapPage(
      response.data,
      '/api/GetMedicationDetailsByAgent',
    );
    final items =
        _parseObjects(
          pageData['data'],
          '/api/GetMedicationDetailsByAgent',
          requiredKeys: const [
            'id',
            'tradeName',
            'scientificName',
            'company',
            'agent',
          ],
        ).map(MedicationItem.fromJson).toList();
    return ApiPage(
      items: items,
      metadata: ApiPageMetadata.fromJson(
        pageData['meta'] as Map,
      ).validatedFor(requestedPage: pageNumber, itemCount: items.length),
    );
  }

  Future<List<PharmacyItem>> fetchPharmacies({
    String? query,
    PharmacySearchType? searchType,
    CancelToken? cancelToken,
  }) async {
    return (await fetchPharmacyPage(
      query: query,
      searchType: searchType,
      pageNumber: 1,
      pageSize: 20,
      cancelToken: cancelToken,
    )).items;
  }

  Future<ApiPage<PharmacyItem>> fetchPharmacyPage({
    String? query,
    PharmacySearchType? searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    if (pageNumber < 1 || pageSize < 1) throw ArgumentError('Invalid page.');
    final params = <String, dynamic>{
      'CountryId': await _countryId(cancelToken),
      'SearchType': int.parse(
        (searchType ?? PharmacySearchType.name).asNumber(),
      ),
      'PageNumber': pageNumber,
      'PageSize': pageSize,
    };
    if (query?.trim().isNotEmpty == true) params['StringSerch'] = query!.trim();
    final response = await _scopedGet<dynamic>(
      '/api/GetPharmacies',
      queryParameters: params,
      cancelToken: cancelToken,
    );
    final pageData = _unwrapPage(response.data, '/api/GetPharmacies');
    final items =
        _parseObjects(
          pageData['data'],
          '/api/GetPharmacies',
          requiredKeys: const [
            'id',
            'name',
            'address',
            'managerName',
            'phoneNumber',
          ],
        ).map(PharmacyItem.fromJson).toList();
    return ApiPage(
      items: items,
      metadata: ApiPageMetadata.fromJson(
        pageData['meta'] as Map,
      ).validatedFor(requestedPage: pageNumber, itemCount: items.length),
    );
  }

  Future<ApiPage<MedicationItem>> fetchMedicationDetailsPage({
    required int id,
    required MedicationSearchType searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    if (id <= 0 || pageNumber < 1 || pageSize < 1) {
      throw ArgumentError('A positive backend ID and page are required.');
    }
    final response = await _scopedGet<dynamic>(
      '/api/GetMedicationDetails',
      queryParameters: {
        'id': id,
        'searchType': int.parse(searchType.asNumber()),
        'PageNumber': pageNumber,
        'PageSize': pageSize,
      },
      cancelToken: cancelToken,
    );
    final data = _unwrapPage(response.data, '/api/GetMedicationDetails');
    final items =
        _parseObjects(
          data['data'],
          '/api/GetMedicationDetails',
          requiredKeys: const [
            'id',
            'tradeName',
            'scientificName',
            'company',
            'agent',
          ],
        ).map(MedicationItem.fromJson).toList();
    return ApiPage(
      items: items,
      metadata: ApiPageMetadata.fromJson(
        data['meta'] as Map,
      ).validatedFor(requestedPage: pageNumber, itemCount: items.length),
    );
  }

  Future<int> _countryId(CancelToken? cancelToken) async {
    if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
    final country = kAppCountry;
    final revision = appCountryRevision;
    final configured = _configuredCountryId(country);
    if (configured != null) return configured;
    final lookup = _countriesFuture ??= _loadCountries();
    // A caller can stop waiting without aborting other queries' shared lookup.
    final countries =
        cancelToken == null
            ? await lookup
            : await Future.any<List<ApiCountry>>([
              lookup,
              cancelToken.whenCancel.then<List<ApiCountry>>(
                (error) => throw error,
              ),
            ]);
    if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
    if (revision != appCountryRevision) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/GetCountries'),
        type: DioExceptionType.cancel,
        message: 'Country scope changed during lookup.',
      );
    }
    final wantedName = apiCountryString(country).toLowerCase();
    for (final country in countries) {
      if (country.name.toLowerCase() == wantedName) return country.id;
    }
    throw StateError('The API country list does not contain "$wantedName".');
  }

  Future<List<ApiCountry>> _loadCountries() {
    final token = CancelToken();
    _countriesToken = token;
    late final Future<List<ApiCountry>> lookup;
    lookup = fetchCountries(cancelToken: token)
        .timeout(
          _countryLookupTimeout,
          onTimeout: () {
            token.cancel('Country lookup deadline reached.');
            throw DioException(
              requestOptions: RequestOptions(path: '/api/GetCountries'),
              type: DioExceptionType.receiveTimeout,
              message: 'Country lookup exceeded its deadline.',
            );
          },
        )
        .then(
          (countries) {
            if (identical(_countriesFuture, lookup)) _countriesToken = null;
            return countries;
          },
          onError: (Object error, StackTrace stack) {
            // An obsolete failure must not evict a newer scope's lookup.
            if (identical(_countriesFuture, lookup)) {
              _countriesFuture = null;
              _countriesToken = null;
            }
            Error.throwWithStackTrace(error, stack);
          },
        );
    return lookup;
  }

  dynamic _unwrapPage(dynamic response, String endpoint) {
    if (response is Map && response['status'] == 200) {
      final payload = response['data'];
      if (payload is Map && payload['data'] is List && payload['meta'] is Map) {
        return payload;
      }
    }
    throw FormatException(
      'Unexpected response from $endpoint; expected status/data/meta pagination envelope.',
    );
  }

  List<Map<String, dynamic>> _parseObjects(
    dynamic data,
    String endpoint, {
    List<String> requiredKeys = const [],
  }) {
    if (data is List && data.every((item) => item is Map)) {
      final objects =
          data
              .cast<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
      if (objects.every((item) => requiredKeys.every(item.containsKey))) {
        return objects;
      }
    }
    throw FormatException(
      'Unexpected item list from $endpoint; expected objects with $requiredKeys.',
    );
  }
}

class ApiPage<T> {
  const ApiPage({required this.items, required this.metadata});

  final List<T> items;
  final ApiPageMetadata metadata;
}

class ApiPageMetadata {
  const ApiPageMetadata({
    required this.pageNumber,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final int pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;

  ApiPageMetadata validatedFor({
    required int requestedPage,
    required int itemCount,
  }) {
    if (pageNumber != requestedPage ||
        pageNumber < 1 ||
        totalPages < 0 ||
        totalCount < 0 ||
        (hasNextPage && (pageNumber >= totalPages || itemCount == 0))) {
      throw const FormatException(
        'API pagination did not advance consistently.',
      );
    }
    return this;
  }

  factory ApiPageMetadata.fromJson(Map json) {
    int intField(String key) {
      final value = json[key];
      if (value is int) return value;
      throw FormatException('Pagination field "$key" must be an integer.');
    }

    bool boolField(String key) {
      final value = json[key];
      if (value is bool) return value;
      throw FormatException('Pagination field "$key" must be a boolean.');
    }

    return ApiPageMetadata(
      pageNumber: intField('pageNumber'),
      totalPages: intField('totalPages'),
      totalCount: intField('totalCount'),
      hasPreviousPage: boolField('hasPreviousPage'),
      hasNextPage: boolField('hasNextPage'),
    );
  }
}

class ApiContractUnavailable implements Exception {
  const ApiContractUnavailable(this.details);

  final String details;
}
