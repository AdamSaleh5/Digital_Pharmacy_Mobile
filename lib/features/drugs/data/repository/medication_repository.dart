import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/cache/memory_cache.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/drug_search_mode.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/api_service.dart';
import '../models/company_agent_item.dart';
import '../models/agent_catalog_item.dart';
import '../models/medication_item.dart';
import '../models/medication_suggestion.dart';

class MedicationRepository {
  MedicationRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;
  int _cacheRevision = 0;
  bool get hasResolvedCountryId => _api.hasResolvedCountryId;

  Future<T> _countryRequest<T>(Future<T> Function() operation) async {
    final countryRevision = appCountryRevision;
    final cacheRevision = _cacheRevision;
    final result = await operation();
    if (countryRevision != appCountryRevision ||
        cacheRevision != _cacheRevision) {
      throw DioException(
        requestOptions: RequestOptions(path: 'country-scoped-cache'),
        type: DioExceptionType.cancel,
        message: 'Obsolete country data discarded.',
      );
    }
    return result;
  }

  void _ensureCountry(AppCountry country) {
    if (country != kAppCountry) {
      throw ArgumentError(
        'Repository country must match the selected country.',
      );
    }
    _cache.ensureCountry(country);
  }

  final MemoryCache _cache = MemoryCache.instance;
  final Map<String, List<MedicationSuggestion>> _suggestionCache = {};
  final Map<String, List<MedicationItem>> _byNameCache = {};
  final Map<String, List<MedicationItem>> _alternativesCache = {};
  final Map<String, List<CompanyAgentItem>> _companyCache = {};
  final Map<String, List<MedicationItem>> _companyMedicationsCache = {};
  final Map<String, bool> _companyPageHasMore = {};
  final Map<String, List<AgentCatalogItem>> _agentCache = {};
  final Map<String, List<MedicationItem>> _agentMedicationsCache = {};
  final Map<String, bool> _agentPageHasMore = {};

  /// Invalidate country/data caches and prevent old in-flight work repopulating them.
  void clearSessionCaches() {
    _cacheRevision++;
    _suggestionCache.clear();
    _byNameCache.clear();
    _alternativesCache.clear();
    _companyCache.clear();
    _companyMedicationsCache.clear();
    _companyPageHasMore.clear();
    _agentCache.clear();
    _agentMedicationsCache.clear();
    _agentPageHasMore.clear();
    _cache.clear();
    _api.clearSessionCache();
  }

  Future<List<MedicationSuggestion>> fetchSuggestions({
    String? query,
    required MedicationSearchType searchType,
    CancelToken? cancelToken,
    bool fetchInitial = false,
  }) async {
    final trimmed = query?.trim() ?? '';
    final initialKey = '${apiCountryString()}|${searchType.name}|initial';
    if (!fetchInitial && trimmed.isEmpty) {
      return _suggestionCache[initialKey] ?? const [];
    }
    final key =
        fetchInitial
            ? initialKey
            : '${apiCountryString()}|${searchType.name}|${trimmed.toLowerCase()}';
    final cached = _suggestionCache[key];
    if (cached != null) return cached;

    final results = await _countryRequest(
      () => _api.fetchMedicationSuggestions(
        query: fetchInitial ? null : trimmed,
        searchType: searchType,
        cancelToken: cancelToken,
      ),
    );
    final unmodifiable = List<MedicationSuggestion>.unmodifiable(results);
    _suggestionCache[key] = unmodifiable;
    return unmodifiable;
  }

  Future<ApiPage<MedicationSuggestion>> fetchSuggestionsPage({
    String? query,
    required MedicationSearchType searchType,
    required int pageNumber,
    required int pageSize,
    CancelToken? cancelToken,
  }) {
    return _api.fetchMedicationSuggestionPage(
      query: query,
      searchType: searchType,
      pageNumber: pageNumber,
      pageSize: pageSize,
      cancelToken: cancelToken,
    );
  }

  Future<List<MedicationItem>> fetchMedicationsByName({
    required String query,
    required MedicationSearchType searchType,
    CancelToken? cancelToken,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final key =
        '${apiCountryString()}|ByName|${searchType.name}|${trimmed.toLowerCase()}';
    final cached = _byNameCache[key];
    if (cached != null) return cached;

    final results = await _countryRequest(
      () => _api.fetchMedicationsByName(
        query: trimmed,
        searchType: searchType,
        cancelToken: cancelToken,
      ),
    );
    final unmodifiable = List<MedicationItem>.unmodifiable(results);
    _byNameCache[key] = unmodifiable;
    return unmodifiable;
  }

  Future<List<MedicationItem>> fetchAlternatives(
    int id, {
    CancelToken? cancelToken,
  }) async {
    final key = '${apiCountryString()}|Alternatives|$id';
    if (kDebugMode) {
      debugPrint('[MedicationRepository] Alternatives cache key: $key');
    }
    final cached = _alternativesCache[key];
    if (cached != null) {
      final isEmpty = cached.isEmpty;
      if (kDebugMode) {
        debugPrint(
          '[MedicationRepository] cache hit (empty=$isEmpty) for $key',
        );
      }
      if (!isEmpty) {
        return cached;
      }
      if (kDebugMode) {
        debugPrint(
          '[MedicationRepository] cached list empty, forcing refetch for $key',
        );
      }
    }

    final results = await _countryRequest(
      () => _api.fetchAlternatives(id, cancelToken: cancelToken),
    );
    final unmodifiable = List<MedicationItem>.unmodifiable(results);
    _alternativesCache[key] = unmodifiable;
    if (kDebugMode) {
      debugPrint(
        '[MedicationRepository] fetched ${unmodifiable.length} items for $key',
      );
    }
    return unmodifiable;
  }

  Future<List<MedicationItem>> fetchPharmaceuticalForms({
    required int id,
    CancelToken? cancelToken,
  }) {
    return fetchFormsOnce(
      medId: id,
      country: kAppCountry,
      cancelToken: cancelToken,
    );
  }

  Future<List<CompanyAgentItem>> fetchCompanies({
    String? query,
    CancelToken? cancelToken,
    bool fetchInitial = false,
  }) async {
    final trimmed = query?.trim() ?? '';
    final catalogKey = 'Company|${kAppCountry.name}|catalog';
    var catalog = _companyCache[catalogKey];
    if (catalog == null) {
      catalog = List<CompanyAgentItem>.unmodifiable(
        await _countryRequest(
          () => _api.fetchCompanies(cancelToken: cancelToken),
        ),
      );
      _companyCache[catalogKey] = catalog;
    }
    if (fetchInitial || trimmed.isEmpty) return catalog;
    final normalized = trimmed.toLowerCase();
    return List<CompanyAgentItem>.unmodifiable(
      catalog.where(
        (item) =>
            item.company.toLowerCase().contains(normalized) ||
            item.agent.toLowerCase().contains(normalized),
      ),
    );
  }

  Future<List<MedicationItem>> fetchMedicationsByCompany({
    required String companyName,
    CancelToken? cancelToken,
  }) async {
    final trimmed = companyName.trim();
    if (trimmed.isEmpty) return const [];
    final key =
        '${appCountryStorageValue(kAppCountry)}|ByCompanyName|${trimmed.toLowerCase()}';
    final cached = _companyMedicationsCache[key];
    if (cached != null) return cached;

    final results = await _countryRequest(
      () => _api.fetchMedicationsByCompany(
        companyName: trimmed,
        cancelToken: cancelToken,
      ),
    );
    final unmodifiable = List<MedicationItem>.unmodifiable(results);
    _companyMedicationsCache[key] = unmodifiable;
    return unmodifiable;
  }

  Future<List<AgentCatalogItem>> fetchAgents({
    String? query,
    CancelToken? cancelToken,
    bool fetchInitial = false,
  }) async {
    final trimmed = query?.trim() ?? '';
    final catalogKey = 'Agent|${kAppCountry.name}|catalog';
    var catalog = _agentCache[catalogKey];
    if (catalog == null) {
      catalog = List<AgentCatalogItem>.unmodifiable(
        await _countryRequest(() => _api.fetchAgents(cancelToken: cancelToken)),
      );
      _agentCache[catalogKey] = catalog;
    }
    if (fetchInitial || trimmed.isEmpty) return catalog;
    final normalized = trimmed.toLowerCase();
    return List<AgentCatalogItem>.unmodifiable(
      catalog.where((item) => item.value.toLowerCase().contains(normalized)),
    );
  }

  Future<List<MedicationItem>> fetchMedicationsByAgent({
    required String agentName,
    CancelToken? cancelToken,
  }) async {
    final trimmed = agentName.trim();
    if (trimmed.isEmpty) {
      return <MedicationItem>[];
    }
    final key =
        '${appCountryStorageValue(kAppCountry)}|ByAgentName|${trimmed.toLowerCase()}';
    final cached = _agentMedicationsCache[key];
    if (cached != null) {
      return List<MedicationItem>.from(cached, growable: true);
    }

    final response = await _countryRequest(
      () => _api.fetchMedicationsByAgent(
        agentName: trimmed,
        cancelToken: cancelToken,
      ),
    );
    final growable = response.toList(growable: true);
    if (kDebugMode) {
      debugPrint(
        '[MedicationRepository] fetchMedicationsByAgent type=${growable.runtimeType} length=${growable.length}',
      );
    }
    _agentMedicationsCache[key] = growable;
    return List<MedicationItem>.from(growable, growable: true);
  }

  Future<PaginatedResult<MedicationItem>> searchPaged({
    required String query,
    required int page,
    int pageSize = 20,
    required DrugSearchMode mode,
    required AppCountry country,
    CancelToken? cancelToken,
  }) async {
    _ensureCountry(country);
    final normalized = query.trim().toLowerCase();
    final key = 'Search|${country.name}|${mode.name}|$normalized';
    var cached = _cache.get<List<MedicationItem>>(key);
    if (cached == null) {
      final results = await _countryRequest(
        () => _loadSearchResults(
          query: query,
          mode: mode,
          cancelToken: cancelToken,
        ),
      );
      cached = List<MedicationItem>.unmodifiable(results);
      _cache.set<List<MedicationItem>>(key, cached);
    }
    return _slicePage(items: cached, page: page, pageSize: pageSize);
  }

  Future<PaginatedResult<MedicationItem>> alternativesPaged({
    required int medId,
    required int page,
    int pageSize = 20,
    required AppCountry country,
    CancelToken? cancelToken,
  }) async {
    _ensureCountry(country);
    final key = 'Alternatives|${country.name}|$medId';
    var cached = _cache.get<List<MedicationItem>>(key);
    if (cached == null) {
      final results = await _countryRequest(
        () => _api.fetchAlternatives(medId, cancelToken: cancelToken),
      );
      cached = List<MedicationItem>.unmodifiable(results);
      _cache.set<List<MedicationItem>>(key, cached);
    }
    return _slicePage(items: cached, page: page, pageSize: pageSize);
  }

  Future<List<MedicationItem>> fetchFormsOnce({
    required int medId,
    required AppCountry country,
    CancelToken? cancelToken,
  }) async {
    _ensureCountry(country);
    final key = 'Forms|${country.name}|$medId';
    final cached = _cache.get<List<MedicationItem>>(key);
    if (cached != null) return cached;

    final results = await _countryRequest(
      () => _api.fetchPharmaceuticalForms(id: medId, cancelToken: cancelToken),
    );
    final unmodifiable = List<MedicationItem>.unmodifiable(results);
    _cache.set<List<MedicationItem>>(key, unmodifiable);
    return unmodifiable;
  }

  Future<List<MedicationItem>> _loadSearchResults({
    required String query,
    required DrugSearchMode mode,
    CancelToken? cancelToken,
  }) {
    final trimmed = query.trim();
    switch (mode) {
      case DrugSearchMode.trade:
        return _api.fetchMedicationsByName(
          query: trimmed,
          searchType: MedicationSearchType.tradeName,
          cancelToken: cancelToken,
        );
      case DrugSearchMode.scientific:
        return _api.fetchMedicationsByName(
          query: trimmed,
          searchType: MedicationSearchType.scientificName,
          cancelToken: cancelToken,
        );
      case DrugSearchMode.company:
        return _api.fetchMedicationsByCompany(
          companyName: trimmed,
          cancelToken: cancelToken,
        );
      case DrugSearchMode.agent:
        return _api.fetchMedicationsByAgent(
          agentName: trimmed,
          cancelToken: cancelToken,
        );
      case DrugSearchMode.all:
        return SynchronousFuture<List<MedicationItem>>(const []);
    }
  }

  PaginatedResult<T> _slicePage<T>({
    required List<T> items,
    required int page,
    required int pageSize,
  }) {
    final safePage = page <= 0 ? 1 : page;
    if (items.isEmpty) {
      return PaginatedResult<T>(items: <T>[], page: safePage, hasMore: false);
    }
    final start = (safePage - 1) * pageSize;
    if (start >= items.length) {
      return PaginatedResult<T>(items: <T>[], page: safePage, hasMore: false);
    }
    final end = (start + pageSize).clamp(0, items.length);
    final slice = items.sublist(start, end).toList(growable: true);
    final hasMore = end < items.length;
    return PaginatedResult<T>(items: slice, page: safePage, hasMore: hasMore);
  }

  Future<PaginatedResult<MedicationItem>> companyMedicationsPaged({
    required int companyId,
    required int page,
    int pageSize = 20,
    required AppCountry country,
    CancelToken? cancelToken,
  }) async {
    _ensureCountry(country);
    if (companyId <= 0) throw ArgumentError.value(companyId, 'companyId');
    final key = 'CompanyMeds|${country.name}|$companyId|$page|$pageSize';
    final cached = _companyMedicationsCache[key];
    if (cached != null) {
      return PaginatedResult(
        items: cached,
        page: page,
        hasMore: _companyPageHasMore[key] ?? false,
      );
    }
    final result = await _countryRequest(
      () => _api.fetchMedicationPageByCompany(
        companyId: companyId,
        pageNumber: page,
        pageSize: pageSize,
        cancelToken: cancelToken,
      ),
    );
    final items = List<MedicationItem>.unmodifiable(result.items);
    _companyMedicationsCache[key] = items;
    _companyPageHasMore[key] = result.metadata.hasNextPage;
    return PaginatedResult(
      items: items,
      page: result.metadata.pageNumber,
      hasMore: result.metadata.hasNextPage,
    );
  }

  Future<PaginatedResult<MedicationItem>> agentMedicationsPaged({
    required int agentId,
    required int page,
    int pageSize = 20,
    required AppCountry country,
    CancelToken? cancelToken,
  }) async {
    _ensureCountry(country);
    if (agentId <= 0) throw ArgumentError.value(agentId, 'agentId');
    final key = 'AgentMeds|${country.name}|$agentId|$page|$pageSize';
    final cached = _agentMedicationsCache[key];
    if (cached != null) {
      return PaginatedResult(
        items: cached,
        page: page,
        hasMore: _agentPageHasMore[key] ?? false,
      );
    }
    final result = await _countryRequest(
      () => _api.fetchMedicationPageByAgent(
        agentId: agentId,
        pageNumber: page,
        pageSize: pageSize,
        cancelToken: cancelToken,
      ),
    );
    final items = List<MedicationItem>.unmodifiable(result.items);
    _agentMedicationsCache[key] = items;
    _agentPageHasMore[key] = result.metadata.hasNextPage;
    return PaginatedResult(
      items: items,
      page: result.metadata.pageNumber,
      hasMore: result.metadata.hasNextPage,
    );
  }
}
