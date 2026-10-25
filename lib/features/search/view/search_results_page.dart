import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/drug_search_mode.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/inline_native_ad_card.dart';
import '../../../core/widgets/ad_banner_placement.dart';
import '../../../core/widgets/search_page_layout.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../data/models/drug.dart';
import '../../../providers/app_provider.dart';
import '../../drug_details/drug_details_page.dart';
import '../../drugs/data/mappers/medication_mapper.dart';
import '../../drugs/data/models/company_agent_item.dart';
import '../../drugs/data/models/agent_catalog_item.dart';
import '../../drugs/data/models/medication_suggestion.dart';
import '../../drugs/view/scientific_drugs_page.dart';
import '../../drugs/widgets/dosage_forms_sheet.dart';
import '../../drugs/widgets/scientific_name_tile.dart';
import 'agent_drugs_page.dart';
import 'company_drugs_page.dart';
import 'medication_selection_results_page.dart';
import 'trade_details_page.dart';
import '../widgets/drug_result_card.dart';

class SearchResultsPage extends StatefulWidget {
  final String initialQuery;
  final DrugSearchMode searchMode;
  const SearchResultsPage({
    super.key,
    required this.initialQuery,
    required this.searchMode,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  static const int _nativeAdInterval = 10;
  static const int _suggestionsPageSize = 20;
  int _catalogVisibleCount = 50;
  late TextEditingController controller;
  late final ScrollController _resultsScrollController;
  late final ScrollController _suggestionsScrollController;
  static const int _pageSize = 20;
  Timer? _suggestionsDebounce;
  CancelToken? _suggestionsToken;
  bool _isSuggestionsLoading = false;
  String? _suggestionsError;
  bool _suggestionsErrorRetryable = true;
  List<MedicationSuggestion> _medicationSuggestions = const [];
  List<_CompanySuggestion> _companySuggestions = const [];
  List<AgentCatalogItem> _agentSuggestions = const [];
  List<MedicationSuggestion> _initialMedicationSuggestions = const [];
  bool _didLoadInitialMedicationSuggestions = false;
  bool _initialSuggestionsHasMore = false;
  int _initialNextSuggestionsPage = 2;
  bool _suggestionsHasMore = false;
  int _nextSuggestionsPage = 2;
  bool _isLoadingMoreSuggestions = false;
  String? _suggestionsMoreError;
  bool _suggestionsMoreErrorRetryable = true;
  List<_CompanySuggestion> _initialCompanySuggestions = const [];
  List<AgentCatalogItem> _initialAgentSuggestions = const [];
  Timer? _resultsDebounce;
  CancelToken? _resultsToken;
  bool _isInitialResultsLoading = false;
  bool _isLoadingMoreResults = false;
  bool _resultsHasMore = true;
  int _nextResultsPage = 1;
  String? _resultsError;
  bool _resultsErrorRetryable = true;
  List<Drug> _paginatedResults = const [];

  bool get _usesMedicationApi =>
      widget.searchMode == DrugSearchMode.trade ||
      widget.searchMode == DrugSearchMode.scientific ||
      widget.searchMode == DrugSearchMode.all;

  bool get _usesCompanyApi => widget.searchMode == DrugSearchMode.company;

  bool get _usesAgentApi => widget.searchMode == DrugSearchMode.agent;

  MedicationSearchType get _medicationSearchType =>
      widget.searchMode == DrugSearchMode.scientific
          ? MedicationSearchType.scientificName
          : MedicationSearchType.tradeName;

  bool get _isPaginatedMode =>
      !(_usesMedicationApi || _usesCompanyApi || _usesAgentApi);

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialQuery);
    _resultsScrollController =
        ScrollController()..addListener(_onResultsScroll);
    _suggestionsScrollController =
        ScrollController()..addListener(_onSuggestionsScroll);
  }

  bool _didLoadInitialData = false;
  AppCountry? _observedCountry;
  int? _observedAuthSessionRevision;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppProvider>();
    final currentCountry = app.selectedCountry;
    final currentAuthRevision = app.dataScopeRevision;
    final countryChanged =
        _observedCountry != null && _observedCountry != currentCountry;
    final authChanged =
        _observedAuthSessionRevision != null &&
        _observedAuthSessionRevision != currentAuthRevision;
    _observedCountry = currentCountry;
    _observedAuthSessionRevision = currentAuthRevision;

    if (!_didLoadInitialData) {
      _didLoadInitialData = true;
      _loadInitialData();
    } else if (countryChanged || authChanged) {
      _refreshForDataScopeChange();
    }
  }

  void _refreshForDataScopeChange() {
    _suggestionsDebounce?.cancel();
    _suggestionsToken?.cancel();
    _resultsDebounce?.cancel();
    _resultsToken?.cancel();
    setState(() {
      _medicationSuggestions = const [];
      _companySuggestions = const [];
      _agentSuggestions = const [];
      _initialMedicationSuggestions = const [];
      _initialCompanySuggestions = const [];
      _initialAgentSuggestions = const [];
      _didLoadInitialMedicationSuggestions = false;
      _initialSuggestionsHasMore = false;
      _initialNextSuggestionsPage = 2;
      _suggestionsHasMore = false;
      _nextSuggestionsPage = 2;
      _isLoadingMoreSuggestions = false;
      _suggestionsMoreError = null;
      _paginatedResults = const [];
      _resultsHasMore = false;
      _nextResultsPage = 1;
      _isLoadingMoreResults = false;
      _isInitialResultsLoading = false;
      _suggestionsErrorRetryable = false;
      _resultsErrorRetryable = false;
      _suggestionsError = null;
      _resultsError = null;
      _isSuggestionsLoading = true;
    });
    if (_usesMedicationApi || _usesCompanyApi || _usesAgentApi) {
      _loadInitialData();
    } else {
      _startInitialResultsSearch();
    }
  }

  Widget _buildSuggestionTile(MedicationSuggestion suggestion) {
    final label = _suggestionLabel(suggestion);
    final onTap =
        suggestion.id == null
            ? null
            : () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) => MedicationSelectionResultsPage(
                        id: suggestion.id!,
                        title: label,
                        searchType: _medicationSearchType,
                      ),
                ),
              );
              if (mounted) context.read<AppProvider>().onCompletedDrugDetails();
            };
    if (widget.searchMode == DrugSearchMode.scientific) {
      return ScientificNameTile(name: label, onTap: onTap);
    }
    return _EntityCard(
      label: label,
      icon:
          widget.searchMode == DrugSearchMode.trade
              ? Icons.medical_services_outlined
              : Icons.biotech_outlined,
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _suggestionsScrollController
      ..removeListener(_onSuggestionsScroll)
      ..dispose();
    _resultsScrollController.removeListener(_onResultsScroll);
    _resultsScrollController.dispose();
    _suggestionsDebounce?.cancel();
    _suggestionsToken?.cancel();
    _resultsDebounce?.cancel();
    _resultsToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final title = widget.searchMode.title(l10n);
    final subtitle = widget.searchMode.subtitle(l10n);
    final hintText = widget.searchMode.hintText(l10n);
    final isHierarchical =
        widget.searchMode == DrugSearchMode.trade ||
        widget.searchMode == DrugSearchMode.scientific ||
        widget.searchMode == DrugSearchMode.company ||
        widget.searchMode == DrugSearchMode.agent;
    if (_usesMedicationApi) {
      return _buildMedicationSuggestionsView(
        app,
        theme,
        l10n,
        title,
        subtitle,
        hintText,
      );
    }

    if (_usesCompanyApi) {
      return _buildCompanySuggestionsView(
        app,
        theme,
        l10n,
        title,
        subtitle,
        hintText,
      );
    }

    if (_usesAgentApi) {
      return _buildAgentSuggestionsView(
        app,
        theme,
        l10n,
        title,
        subtitle,
        hintText,
      );
    }

    if (!isHierarchical) {
      return _buildPaginatedResultsView(
        app: app,
        theme: theme,
        l10n: l10n,
        title: title,
        subtitle: subtitle,
        hintText: hintText,
      );
    }

    final entries = _entityResults(app);
    final icon = _modeIcon(widget.searchMode);
    final header = <Widget>[
      Text(
        l10n.searchResultsCount(entries.length),
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 12),
    ];
    final listChildren =
        entries.isEmpty
            ? [
              _EmptyState(
                message: widget.searchMode.emptyStateDescription(l10n),
              ),
            ]
            : entries
                .asMap()
                .entries
                .map(
                  (entry) => _animatedResult(
                    order: entry.key,
                    child: _EntityCard(
                      label: entry.value,
                      icon: icon,
                      onTap: () => _openSecondLevel(context, entry.value),
                    ),
                  ),
                )
                .toList();

    return SearchPageLayout(
      title: title,
      subtitle: subtitle,
      controller: controller,
      hintText: hintText,
      onChanged: (_) => setState(() {}),
      onSubmitted: app.addRecent,
      bottomNavigationBar: _buildBannerBar(),
      headerChildren: header,
      listChildren: listChildren,
    );
  }

  void _showDosageFormsSheet(BuildContext context, Drug drug) {
    final id = int.tryParse(drug.id);
    if (id == null) return;
    final repo = context.read<AppProvider>().medicationRepo;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DosageFormsSheet(
            drugName: drug.brandName,
            loadForms: (token) async {
              final items = await repo.fetchFormsOnce(
                medId: id,
                country: kAppCountry,
                cancelToken: token,
              );
              return items
                  .map(
                    (item) => DosageFormPrice(
                      formName: item.pharmaceuticalForm,
                      priceJod: item.price,
                      priceCurrencyKnown: false,
                    ),
                  )
                  .where((form) => form.formName.trim().isNotEmpty)
                  .toList();
            },
          ),
    );
  }

  Future<void> _navigateToDrugDetails(
    AppProvider app,
    BuildContext context,
    Drug drug,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DrugDetailsPage(drugId: drug.id)),
    );
    if (context.mounted) app.onCompletedDrugDetails();
  }

  List<String> _entityResults(AppProvider app) {
    final query = controller.text;
    switch (widget.searchMode) {
      case DrugSearchMode.agent:
        return app.drugRepo.getUniqueAgents(query: query);
      case DrugSearchMode.company:
        return app.drugRepo.getUniqueCompanies(query: query);
      case DrugSearchMode.trade:
        return app.drugRepo.getUniqueTradeNames(query: query);
      case DrugSearchMode.scientific:
        return app.drugRepo.getUniqueScientificNames(query: query);
      case DrugSearchMode.all:
        return const [];
    }
  }

  void _openSecondLevel(BuildContext context, String value) {
    final widgetBuilder = () {
      switch (widget.searchMode) {
        case DrugSearchMode.agent:
          return null;
        case DrugSearchMode.company:
          return null;
        case DrugSearchMode.trade:
          return TradeDetailsPage(tradeName: value);
        case DrugSearchMode.scientific:
          return ScientificDrugsPage(scientificName: value);
        case DrugSearchMode.all:
          return null;
      }
    }();

    if (widgetBuilder == null) return;

    Navigator.push(context, MaterialPageRoute(builder: (_) => widgetBuilder));
  }

  void _openCompanyDetails(BuildContext context, _CompanySuggestion value) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CompanyDrugsPage(
              companyId: value.id,
              companyName: value.company,
              agentName: value.agent,
            ),
      ),
    );
  }

  void _openAgentDetails(BuildContext context, AgentCatalogItem value) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AgentDrugsPage(agentId: value.id, agentName: value.value),
      ),
    );
  }

  Future<void> _loadInitialData() async {
    if (!(_usesMedicationApi || _usesCompanyApi || _usesAgentApi)) {
      _startInitialResultsSearch();
      return;
    }
    _catalogVisibleCount = 50;
    _suggestionsToken?.cancel();
    final token = CancelToken();
    _suggestionsToken = token;
    setState(() {
      _isSuggestionsLoading = true;
      _suggestionsError = null;
      _suggestionsErrorRetryable = true;
    });
    final repo = context.read<AppProvider>().medicationRepo;
    final l10n = AppLocalizations.of(context)!;

    try {
      if (_usesMedicationApi) {
        final initialQuery = controller.text.trim();
        final page = await repo.fetchSuggestionsPage(
          searchType: _medicationSearchType,
          query: initialQuery.isEmpty ? null : initialQuery,
          pageNumber: 1,
          pageSize: _suggestionsPageSize,
          cancelToken: token,
        );
        if (!mounted || token.isCancelled) return;
        setState(() {
          _medicationSuggestions = page.items;
          _initialMedicationSuggestions =
              initialQuery.isEmpty ? page.items : const [];
          _didLoadInitialMedicationSuggestions = initialQuery.isEmpty;
          _initialSuggestionsHasMore =
              initialQuery.isEmpty && page.metadata.hasNextPage;
          _initialNextSuggestionsPage = page.metadata.pageNumber + 1;
          _suggestionsHasMore = page.metadata.hasNextPage;
          _nextSuggestionsPage = page.metadata.pageNumber + 1;
          _isLoadingMoreSuggestions = false;
          _suggestionsMoreError = null;
          _isSuggestionsLoading = false;
        });
      } else if (_usesCompanyApi) {
        final companies = await repo.fetchCompanies(
          query: controller.text,
          fetchInitial: controller.text.trim().isEmpty,
          cancelToken: token,
        );
        if (!mounted || token.isCancelled) return;
        final deduped = _dedupeCompanies(companies);
        setState(() {
          _initialCompanySuggestions = deduped;
          _companySuggestions = deduped;
          _isSuggestionsLoading = false;
        });
      } else if (_usesAgentApi) {
        final agents = await repo.fetchAgents(
          query: controller.text,
          fetchInitial: controller.text.trim().isEmpty,
          cancelToken: token,
        );
        if (!mounted || token.isCancelled) return;
        final deduped = _dedupeAgents(agents);
        setState(() {
          _initialAgentSuggestions = deduped;
          _agentSuggestions = deduped;
          _isSuggestionsLoading = false;
        });
      }
    } catch (error) {
      if (!mounted || token.isCancelled) {
        return;
      }
      setState(() {
        _suggestionsError = apiFailureMessage(error, l10n);
        _suggestionsErrorRetryable = isApiFailureRetryable(error);
        _isSuggestionsLoading = false;
      });
    }
  }

  IconData _modeIcon(DrugSearchMode mode) {
    switch (mode) {
      case DrugSearchMode.agent:
        return Icons.handshake_outlined;
      case DrugSearchMode.company:
        return Icons.factory_outlined;
      case DrugSearchMode.trade:
        return Icons.medical_services_outlined;
      case DrugSearchMode.scientific:
        return Icons.biotech_outlined;
      case DrugSearchMode.all:
        return Icons.search;
    }
  }

  Widget _buildPaginatedResultsView({
    required AppProvider app,
    required ThemeData theme,
    required AppLocalizations l10n,
    required String title,
    required String subtitle,
    required String hintText,
  }) {
    final banner = _buildBannerBar();
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = 24.0 + mediaQuery.viewPadding.bottom;
    Widget listContent;
    if (_isInitialResultsLoading) {
      listContent = const Center(child: CircularProgressIndicator());
    } else if (_resultsError != null) {
      listContent = _ErrorNotice(
        message: _resultsError!,
        onRetry: _resultsErrorRetryable ? _startInitialResultsSearch : null,
      );
    } else if (_paginatedResults.isEmpty) {
      listContent = _EmptyState(
        message: widget.searchMode.emptyStateDescription(l10n),
      );
    } else {
      listContent = ListView.builder(
        controller: _resultsScrollController,
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
        itemCount: _paginatedDisplayItemCount,
        itemBuilder: (context, index) {
          if (_isPaginatedLoadingRow(index)) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_isPaginatedNativeAdSlot(index)) {
            return const InlineNativeAdCard();
          }
          final drug = _paginatedResults[_paginatedDrugIndexFor(index)];
          return RepaintBoundary(
            child: _animatedResult(
              order: index,
              child: DrugResultCard(
                drug: drug,
                onTap: () => _navigateToDrugDetails(app, context, drug),
                onShowDosageForms: () => _showDosageFormsSheet(context, drug),
              ),
            ),
          );
        },
      );
    }

    final header = [
      Text(
        l10n.matchingResultsCount(_paginatedResults.length),
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 12),
    ];

    final content = SoftBackground(
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onChanged: _handlePaginatedQueryChanged,
                onSubmitted: (value) {
                  app.addRecent(value);
                  _startInitialResultsSearch();
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: hintText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: header,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: listContent),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppHeader(title: title, subtitle: subtitle),
      bottomNavigationBar: banner,
      body: content,
    );
  }

  Widget _buildMedicationSuggestionsView(
    AppProvider app,
    ThemeData theme,
    AppLocalizations l10n,
    String title,
    String subtitle,
    String hintText,
  ) {
    List<Widget> header = const [];
    late final List<Widget> listChildren;
    if (_isSuggestionsLoading) {
      listChildren = const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (_suggestionsError != null) {
      listChildren = [
        _ErrorNotice(
          message: _suggestionsError!,
          onRetry:
              _suggestionsErrorRetryable
                  ? () => _fetchSuggestions(controller.text)
                  : null,
        ),
      ];
    } else if (_medicationSuggestions.isEmpty) {
      listChildren = [
        _EmptyState(message: widget.searchMode.emptyStateDescription(l10n)),
      ];
    } else {
      header = [
        if (_medicationSuggestions.every((item) => item.id == null)) ...[
          _ApiInfoNotice(message: l10n.apiDetailsUnavailable),
          const SizedBox(height: 8),
        ],
        Text(
          l10n.searchResultsCount(_medicationSuggestions.length),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
      ];
      listChildren = interleaveNativeAds(
        _medicationSuggestions
            .asMap()
            .entries
            .map(
              (entry) => _animatedResult(
                order: entry.key,
                child: _buildSuggestionTile(entry.value),
              ),
            )
            .toList(),
      );
      if (_isLoadingMoreSuggestions) {
        listChildren.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      } else if (_suggestionsMoreError != null) {
        listChildren.add(
          _ErrorNotice(
            message: _suggestionsMoreError!,
            onRetry:
                _suggestionsMoreErrorRetryable
                    ? () => _loadMoreMedicationSuggestions(retry: true)
                    : null,
          ),
        );
      } else if (_suggestionsHasMore) {
        listChildren.add(
          OutlinedButton(
            onPressed: _loadMoreMedicationSuggestions,
            child: Text(l10n.loadMoreResults),
          ),
        );
      }
    }

    return SearchPageLayout(
      title: title,
      subtitle: subtitle,
      controller: controller,
      hintText: hintText,
      onChanged: _handleMedicationQueryChanged,
      onSubmitted: (value) {
        app.addRecent(value);
        _fetchSuggestions(value);
      },
      bottomNavigationBar: _buildBannerBar(),
      headerChildren: header,
      listChildren: listChildren,
      scrollController: _suggestionsScrollController,
    );
  }

  Widget _buildCompanySuggestionsView(
    AppProvider app,
    ThemeData theme,
    AppLocalizations l10n,
    String title,
    String subtitle,
    String hintText,
  ) {
    List<Widget> header = const [];
    late final List<Widget> listChildren;
    if (_isSuggestionsLoading) {
      listChildren = const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (_suggestionsError != null) {
      listChildren = [
        _ErrorNotice(
          message: _suggestionsError!,
          onRetry:
              _suggestionsErrorRetryable
                  ? () => _fetchCompanySuggestions(controller.text)
                  : null,
        ),
      ];
    } else if (_companySuggestions.isEmpty) {
      listChildren = [
        _EmptyState(message: widget.searchMode.emptyStateDescription(l10n)),
      ];
    } else {
      header = [
        Text(
          l10n.searchResultsCount(_companySuggestions.length),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
      ];
      listChildren = interleaveNativeAds(
        _companySuggestions
            .take(_catalogVisibleCount)
            .toList()
            .asMap()
            .entries
            .map((entry) {
              final suggestion = entry.value;
              final agentLine =
                  suggestion.agent.isEmpty
                      ? null
                      : '${l10n.labelAgentName}: ${suggestion.agent}';
              return _animatedResult(
                order: entry.key,
                child: _EntityCard(
                  label: suggestion.company,
                  icon: Icons.factory_outlined,
                  secondaryText: agentLine,
                  onTap: () => _openCompanyDetails(context, suggestion),
                ),
              );
            })
            .toList(),
      );
    }

    if (!context.read<AppProvider>().medicationRepo.hasResolvedCountryId)
      header = [
        Text(
          l10n.catalogCountryUnverified,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        ...header,
      ];
    return SearchPageLayout(
      title: title,
      subtitle: subtitle,
      controller: controller,
      hintText: hintText,
      onChanged: _handleCompanyQueryChanged,
      scrollController: _suggestionsScrollController,
      onSubmitted: (value) {
        app.addRecent(value);
        _fetchCompanySuggestions(value);
      },
      bottomNavigationBar: _buildBannerBar(),
      headerChildren: header,
      listChildren: listChildren,
    );
  }

  Widget _buildAgentSuggestionsView(
    AppProvider app,
    ThemeData theme,
    AppLocalizations l10n,
    String title,
    String subtitle,
    String hintText,
  ) {
    List<Widget> header = const [];
    late final List<Widget> listChildren;
    if (_isSuggestionsLoading) {
      listChildren = const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (_suggestionsError != null) {
      listChildren = [
        _ErrorNotice(
          message: _suggestionsError!,
          onRetry:
              _suggestionsErrorRetryable
                  ? () => _fetchAgentSuggestions(controller.text)
                  : null,
        ),
      ];
    } else if (_agentSuggestions.isEmpty) {
      listChildren = [
        _EmptyState(message: widget.searchMode.emptyStateDescription(l10n)),
      ];
    } else {
      header = [
        Text(
          l10n.searchResultsCount(_agentSuggestions.length),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
      ];
      listChildren = interleaveNativeAds(
        _agentSuggestions
            .take(_catalogVisibleCount)
            .toList()
            .asMap()
            .entries
            .map(
              (entry) => _animatedResult(
                order: entry.key,
                child: _EntityCard(
                  label: entry.value.value,
                  icon: Icons.handshake_outlined,
                  onTap: () => _openAgentDetails(context, entry.value),
                ),
              ),
            )
            .toList(),
      );
    }

    if (!context.read<AppProvider>().medicationRepo.hasResolvedCountryId)
      header = [
        Text(
          l10n.catalogCountryUnverified,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        ...header,
      ];
    return SearchPageLayout(
      title: title,
      subtitle: subtitle,
      controller: controller,
      hintText: hintText,
      onChanged: _handleAgentQueryChanged,
      scrollController: _suggestionsScrollController,
      onSubmitted: (value) {
        app.addRecent(value);
        _fetchAgentSuggestions(value);
      },
      bottomNavigationBar: _buildBannerBar(),
      headerChildren: header,
      listChildren: listChildren,
    );
  }

  void _handleMedicationQueryChanged(String value) {
    _suggestionsDebounce?.cancel();
    _suggestionsToken?.cancel();
    final query = value.trim();
    if (query.isEmpty && _didLoadInitialMedicationSuggestions) {
      setState(() {
        _medicationSuggestions = _initialMedicationSuggestions;
        _isSuggestionsLoading = false;
        _suggestionsError = null;
        _suggestionsHasMore = _initialSuggestionsHasMore;
        _nextSuggestionsPage = _initialNextSuggestionsPage;
        _isLoadingMoreSuggestions = false;
        _suggestionsMoreError = null;
      });
      return;
    }
    setState(() {
      _medicationSuggestions = const [];
      _isSuggestionsLoading = true;
      _suggestionsError = null;
      _suggestionsHasMore = false;
      _isLoadingMoreSuggestions = false;
      _suggestionsMoreError = null;
      _nextSuggestionsPage = 2;
    });
    if (query.isEmpty) {
      _fetchSuggestions('');
      return;
    }
    _suggestionsDebounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(value);
    });
  }

  Future<void> _fetchSuggestions(String value) async {
    // A keyboard submit consumes the pending edit debounce, too.
    _suggestionsDebounce?.cancel();
    final query = value.trim();
    _suggestionsToken?.cancel();
    if (query.isEmpty && _didLoadInitialMedicationSuggestions) {
      setState(() {
        _medicationSuggestions = _initialMedicationSuggestions;
        _isSuggestionsLoading = false;
        _suggestionsError = null;
        _suggestionsHasMore = _initialSuggestionsHasMore;
        _nextSuggestionsPage = _initialNextSuggestionsPage;
        _isLoadingMoreSuggestions = false;
        _suggestionsMoreError = null;
      });
      return;
    }

    final token = CancelToken();
    _suggestionsToken = token;
    setState(() {
      _isSuggestionsLoading = true;
      _suggestionsError = null;
      _suggestionsErrorRetryable = true;
      _isLoadingMoreSuggestions = false;
      _suggestionsMoreError = null;
    });
    final l10n = AppLocalizations.of(context)!;

    try {
      final repo = context.read<AppProvider>().medicationRepo;
      final page = await repo.fetchSuggestionsPage(
        query: query.isEmpty ? null : query,
        searchType: _medicationSearchType,
        pageNumber: 1,
        pageSize: _suggestionsPageSize,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      setState(() {
        _medicationSuggestions = page.items;
        if (query.isEmpty) {
          _initialMedicationSuggestions = page.items;
          _didLoadInitialMedicationSuggestions = true;
          _initialSuggestionsHasMore = page.metadata.hasNextPage;
          _initialNextSuggestionsPage = page.metadata.pageNumber + 1;
        }
        _suggestionsHasMore = page.metadata.hasNextPage;
        _nextSuggestionsPage = page.metadata.pageNumber + 1;
        _isSuggestionsLoading = false;
      });
    } catch (error) {
      if (!mounted || token.isCancelled) {
        return;
      }
      setState(() {
        _suggestionsError = apiFailureMessage(error, l10n);
        _suggestionsErrorRetryable = isApiFailureRetryable(error);
        _isSuggestionsLoading = false;
      });
    }
  }

  void _onSuggestionsScroll() {
    if ((_usesCompanyApi || _usesAgentApi) &&
        !_isSuggestionsLoading &&
        _suggestionsScrollController.hasClients) {
      final count =
          _usesCompanyApi
              ? _companySuggestions.length
              : _agentSuggestions.length;
      final position = _suggestionsScrollController.position;
      if (_catalogVisibleCount < count &&
          position.pixels >= position.maxScrollExtent * .8) {
        setState(() => _catalogVisibleCount += 50);
      }
      return;
    }
    if (!_usesMedicationApi ||
        !_suggestionsHasMore ||
        _suggestionsMoreError != null ||
        _isSuggestionsLoading ||
        _isLoadingMoreSuggestions ||
        !_suggestionsScrollController.hasClients) {
      return;
    }
    final position = _suggestionsScrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      _loadMoreMedicationSuggestions();
    }
  }

  Future<void> _loadMoreMedicationSuggestions({bool retry = false}) async {
    if (!_suggestionsHasMore ||
        _isSuggestionsLoading ||
        _isLoadingMoreSuggestions ||
        (_suggestionsMoreError != null &&
            (!retry || !_suggestionsMoreErrorRetryable))) {
      return;
    }
    _suggestionsToken?.cancel();
    final token = CancelToken();
    _suggestionsToken = token;
    final query = controller.text.trim();
    setState(() {
      _isLoadingMoreSuggestions = true;
      _suggestionsMoreError = null;
      _suggestionsMoreErrorRetryable = true;
    });
    final l10n = AppLocalizations.of(context)!;

    try {
      final page = await context
          .read<AppProvider>()
          .medicationRepo
          .fetchSuggestionsPage(
            query: query.isEmpty ? null : query,
            searchType: _medicationSearchType,
            pageNumber: _nextSuggestionsPage,
            pageSize: _suggestionsPageSize,
            cancelToken: token,
          );
      if (!mounted || token.isCancelled) return;
      setState(() {
        final seen = _medicationSuggestions.map(_suggestionKey).toSet();
        final appended = page.items.where(
          (item) => seen.add(_suggestionKey(item)),
        );
        _medicationSuggestions = List.unmodifiable([
          ..._medicationSuggestions,
          ...appended,
        ]);
        _suggestionsHasMore = page.metadata.hasNextPage;
        _nextSuggestionsPage = page.metadata.pageNumber + 1;
        _isLoadingMoreSuggestions = false;
        if (query.isEmpty) {
          _initialMedicationSuggestions = _medicationSuggestions;
          _initialSuggestionsHasMore = _suggestionsHasMore;
          _initialNextSuggestionsPage = _nextSuggestionsPage;
        }
      });
    } catch (error) {
      if (!mounted || token.isCancelled) return;
      setState(() {
        _suggestionsMoreError = apiFailureMessage(error, l10n);
        _suggestionsMoreErrorRetryable = isApiFailureRetryable(error);
        _isLoadingMoreSuggestions = false;
      });
    }
  }

  void _handleCompanyQueryChanged(String value) {
    _suggestionsDebounce?.cancel();
    _suggestionsToken?.cancel();
    _resetCompanyAgentQuery(value, isCompany: true);
    if (value.trim().isEmpty) {
      _loadInitialData();
      return;
    }
    _suggestionsDebounce = Timer(const Duration(milliseconds: 300), () {
      _fetchCompanySuggestions(value);
    });
  }

  void _resetCompanyAgentQuery(String value, {required bool isCompany}) {
    final query = value.trim();
    setState(() {
      _catalogVisibleCount = 50;
      if (isCompany) {
        _companySuggestions =
            query.isEmpty ? _initialCompanySuggestions : const [];
      } else {
        _agentSuggestions = query.isEmpty ? _initialAgentSuggestions : const [];
      }
      _isSuggestionsLoading = query.isNotEmpty;
      _suggestionsError = null;
    });
  }

  Future<void> _fetchCompanySuggestions(String value) async {
    _suggestionsDebounce?.cancel();
    final query = value.trim();
    _suggestionsToken?.cancel();
    if (query.isEmpty) {
      setState(() {
        _companySuggestions = _initialCompanySuggestions;
        _isSuggestionsLoading = false;
        _suggestionsError = null;
      });
      return;
    }

    final token = CancelToken();
    _suggestionsToken = token;
    setState(() {
      _isSuggestionsLoading = true;
      _suggestionsError = null;
      _suggestionsErrorRetryable = true;
    });
    final l10n = AppLocalizations.of(context)!;

    try {
      final repo = context.read<AppProvider>().medicationRepo;
      final results = await repo.fetchCompanies(
        query: query,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      final deduped = _dedupeCompanies(results);
      setState(() {
        _companySuggestions = deduped;
        _isSuggestionsLoading = false;
      });
    } catch (error) {
      if (!mounted || token.isCancelled) {
        return;
      }
      setState(() {
        _suggestionsError = apiFailureMessage(error, l10n);
        _suggestionsErrorRetryable = isApiFailureRetryable(error);
        _isSuggestionsLoading = false;
      });
    }
  }

  void _handleAgentQueryChanged(String value) {
    _suggestionsDebounce?.cancel();
    _suggestionsToken?.cancel();
    _resetCompanyAgentQuery(value, isCompany: false);
    if (value.trim().isEmpty) {
      _loadInitialData();
      return;
    }
    _suggestionsDebounce = Timer(const Duration(milliseconds: 300), () {
      _fetchAgentSuggestions(value);
    });
  }

  void _handlePaginatedQueryChanged(String value) {
    if (!_isPaginatedMode) return;
    _resultsDebounce?.cancel();
    _resultsToken?.cancel();
    final query = value.trim();
    setState(() {
      _paginatedResults = const [];
      _resultsHasMore = false;
      _nextResultsPage = 1;
      _isLoadingMoreResults = false;
      _resultsError = null;
      _isInitialResultsLoading = query.isNotEmpty;
    });
    if (query.isEmpty) return;
    _resultsDebounce = Timer(const Duration(milliseconds: 400), () {
      _startInitialResultsSearch();
    });
  }

  void _startInitialResultsSearch() {
    if (!_isPaginatedMode) return;
    _resultsToken?.cancel();
    final query = controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _paginatedResults = const [];
        _resultsHasMore = false;
        _isInitialResultsLoading = false;
        _resultsError = null;
      });
      return;
    }
    setState(() {
      _paginatedResults = const [];
      _resultsHasMore = true;
      _isInitialResultsLoading = true;
      _isLoadingMoreResults = false;
      _resultsError = null;
      _nextResultsPage = 1;
    });
    _fetchResultsPage(page: 1);
  }

  void _loadMoreResults() {
    if (_isLoadingMoreResults || !_resultsHasMore || _isInitialResultsLoading) {
      return;
    }
    setState(() {
      _isLoadingMoreResults = true;
    });
    _fetchResultsPage(page: _nextResultsPage);
  }

  void _onResultsScroll() {
    if (!_isPaginatedMode || !_resultsHasMore) return;
    if (!_resultsScrollController.hasClients) return;
    final position = _resultsScrollController.position;
    if (!position.hasPixels || position.maxScrollExtent == 0) return;
    final threshold = position.maxScrollExtent * 0.8;
    if (position.pixels >= threshold) {
      _loadMoreResults();
    }
  }

  Future<void> _fetchResultsPage({required int page}) async {
    final repo = context.read<AppProvider>().medicationRepo;
    final cancelToken = CancelToken();
    _resultsToken = cancelToken;
    try {
      final result = await repo.searchPaged(
        query: controller.text.trim(),
        page: page,
        pageSize: _pageSize,
        mode: widget.searchMode,
        country: kAppCountry,
        cancelToken: cancelToken,
      );
      if (!mounted || cancelToken.isCancelled) return;
      final mapped = result.items.map(MedicationMapper.toDrug).toList();
      setState(() {
        final combined =
            page == 1 ? mapped : List<Drug>.from(_paginatedResults)
              ..addAll(mapped);
        _paginatedResults = List<Drug>.unmodifiable(combined);
        _isInitialResultsLoading = false;
        _isLoadingMoreResults = false;
        _resultsHasMore = result.hasMore;
        _resultsError = null;
        _nextResultsPage = page + 1;
      });
    } catch (error) {
      if (!mounted || cancelToken.isCancelled) {
        return;
      }
      setState(() {
        final l10n = AppLocalizations.of(context)!;
        _resultsError = apiFailureMessage(error, l10n);
        _resultsErrorRetryable = isApiFailureRetryable(error);
        _isInitialResultsLoading = false;
        _isLoadingMoreResults = false;
      });
    }
  }

  Future<void> _fetchAgentSuggestions(String value) async {
    _suggestionsDebounce?.cancel();
    final query = value.trim();
    _suggestionsToken?.cancel();
    if (query.isEmpty) {
      setState(() {
        _agentSuggestions = _initialAgentSuggestions;
        _isSuggestionsLoading = false;
        _suggestionsError = null;
      });
      return;
    }

    final token = CancelToken();
    _suggestionsToken = token;
    setState(() {
      _isSuggestionsLoading = true;
      _suggestionsError = null;
      _suggestionsErrorRetryable = true;
    });
    final l10n = AppLocalizations.of(context)!;

    try {
      final repo = context.read<AppProvider>().medicationRepo;
      final results = await repo.fetchAgents(query: query, cancelToken: token);
      if (!mounted || token.isCancelled) return;
      setState(() {
        _agentSuggestions = _dedupeAgents(results);
        _isSuggestionsLoading = false;
      });
    } catch (error) {
      if (!mounted || token.isCancelled) {
        return;
      }
      setState(() {
        _suggestionsError = apiFailureMessage(error, l10n);
        _suggestionsErrorRetryable = isApiFailureRetryable(error);
        _isSuggestionsLoading = false;
      });
    }
  }

  String _suggestionLabel(MedicationSuggestion suggestion) {
    return suggestion.label(
      scientific: widget.searchMode == DrugSearchMode.scientific,
    );
  }

  String _suggestionKey(MedicationSuggestion item) =>
      item.id != null
          ? 'id:${item.id}'
          : 'name:${item.value.toLowerCase()}|${item.tradeName.toLowerCase()}|${item.scientificName.toLowerCase()}';

  List<AgentCatalogItem> _dedupeAgents(Iterable<AgentCatalogItem> values) {
    final seen = <int>{};
    final items = <AgentCatalogItem>[];
    for (final item in values) {
      if (item.isSelectable && seen.add(item.id)) items.add(item);
    }
    return items;
  }

  List<_CompanySuggestion> _dedupeCompanies(Iterable<CompanyAgentItem> items) {
    final map = <int, _CompanySuggestion>{};
    for (final item in items) {
      final company = item.company.trim();
      if (!item.isSelectable) continue;
      map.putIfAbsent(
        item.id,
        () => _CompanySuggestion(
          id: item.id,
          company: company,
          agent: item.agent.trim(),
        ),
      );
    }
    return map.values.toList();
  }

  int get _paginatedNativeAdsCount =>
      _paginatedResults.length ~/ _nativeAdInterval;

  int get _paginatedContentCount =>
      _paginatedResults.length + _paginatedNativeAdsCount;

  int get _paginatedDisplayItemCount =>
      _paginatedContentCount + (_isLoadingMoreResults ? 1 : 0);

  bool _isPaginatedLoadingRow(int index) =>
      _isLoadingMoreResults && index == _paginatedContentCount;

  bool _isPaginatedNativeAdSlot(int index) =>
      index < _paginatedContentCount &&
      (index + 1) % (_nativeAdInterval + 1) == 0;

  int _paginatedDrugIndexFor(int index) {
    final adsBefore = (index + 1) ~/ (_nativeAdInterval + 1);
    return index - adsBefore;
  }

  Widget _buildBannerBar() {
    return const AdBannerPlacement(padding: EdgeInsets.fromLTRB(16, 0, 16, 12));
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.errorContainer,
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: .2),
        ),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.actionRetry),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApiInfoNotice extends StatelessWidget {
  const _ApiInfoNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.start,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

Widget _animatedResult({required int order, required Widget child}) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 300 + order * 70),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: child,
        ),
      );
    },
  );
}

class _EntityCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final String? secondaryText;

  const _EntityCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF1B2343) : Colors.white;
    final border = isDark ? const Color(0xFF2D3755) : const Color(0xFFE6E9F8);
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final arrowIcon =
        isRtl ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios;
    final card = Card(
      color: background,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: .12,
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (secondaryText != null) ...[
                      const SizedBox(height: 4),
                      Text(secondaryText!, style: subtitleStyle),
                    ],
                  ],
                ),
              ),
              if (onTap != null) Icon(arrowIcon, size: 14),
            ],
          ),
        ),
      ),
    ).applyBorder(border);

    return Padding(padding: const EdgeInsets.only(bottom: 8), child: card);
  }
}

extension on Card {
  Widget applyBorder(Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: this,
    );
  }
}

class _CompanySuggestion {
  final int id;
  final String company;
  final String agent;

  const _CompanySuggestion({
    required this.id,
    required this.company,
    required this.agent,
  });
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sentiment_dissatisfied_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
