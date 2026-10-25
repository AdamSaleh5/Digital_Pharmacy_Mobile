import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/error_state_card.dart';
import '../../../core/widgets/inline_native_ad_card.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../core/widgets/sticky_banner_ad.dart';
import '../../../data/models/drug.dart';
import '../../../providers/app_provider.dart';
import '../../drugs/data/mappers/medication_mapper.dart';
import '../../drugs/view/medication_alternatives_page.dart';
import '../widgets/drug_info_card.dart';
import '../widgets/server_medication_card.dart';

class AgentDrugsPage extends StatefulWidget {
  final int agentId;
  final String agentName;
  const AgentDrugsPage({
    super.key,
    required this.agentId,
    required this.agentName,
  });

  @override
  State<AgentDrugsPage> createState() => _AgentDrugsPageState();
}

class _AgentDrugsPageState extends State<AgentDrugsPage> {
  static const int _pageSize = 20;
  static const int _nativeAdInterval = 10;
  late final ScrollController _scrollController;
  CancelToken? _pageToken;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _nextPage = 1;
  String? _error;
  String? _moreError;
  bool _errorRetryable = true;
  List<Drug> _drugs = const [];
  bool _didRequestFirstPage = false;
  AppCountry? _observedCountry;
  int? _observedAuthRevision;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _setError(Object error) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      final message =
          l10n == null ? 'Error loading data' : apiFailureMessage(error, l10n);
      if (_drugs.isEmpty) {
        _error = message;
      } else {
        _moreError = message;
        if (!isApiFailureRetryable(error)) _hasMore = false;
      }
      _errorRetryable = isApiFailureRetryable(error);
      _isInitialLoading = false;
      _isLoadingMore = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppProvider>();
    final countryChanged =
        _observedCountry != null && _observedCountry != app.selectedCountry;
    final authChanged =
        _observedAuthRevision != null &&
        _observedAuthRevision != app.dataScopeRevision;
    _observedCountry = app.selectedCountry;
    _observedAuthRevision = app.dataScopeRevision;
    if (!_didRequestFirstPage) {
      _didRequestFirstPage = true;
      _fetchFirstPage();
    } else if (countryChanged || authChanged) {
      _refreshForDataScopeChange();
    }
  }

  void _refreshForDataScopeChange() {
    _pageToken?.cancel();

    _fetchFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pageToken?.cancel();
    super.dispose();
  }

  void _fetchFirstPage() {
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _drugs = const [];
      _error = null;
      _moreError = null;
      _nextPage = 1;
    });
    _fetchPage(1);
  }

  void _onScroll() {
    if (!_hasMore || _isInitialLoading || _isLoadingMore || _moreError != null)
      return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasPixels || position.maxScrollExtent == 0) return;
    final threshold = position.maxScrollExtent * 0.8;
    if (position.pixels >= threshold) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _moreError = null;
    });
    _fetchPage(_nextPage);
  }

  Future<void> _fetchPage(int page) async {
    final repo = context.read<AppProvider>().medicationRepo;
    _pageToken?.cancel();
    final token = CancelToken();
    _pageToken = token;
    try {
      final result = await repo.agentMedicationsPaged(
        agentId: widget.agentId,
        page: page,
        pageSize: _pageSize,
        country: kAppCountry,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      final mapped = result.items
          .map(MedicationMapper.toDrug)
          .toList(growable: true);
      setState(() {
        final seen =
            page == 1 ? <String>{} : _drugs.map((drug) => drug.id).toSet();
        final combined = <Drug>[
          if (page != 1) ..._drugs,
          ...mapped.where((drug) => seen.add(drug.id)),
        ];
        _drugs = combined;
        _isInitialLoading = false;
        _isLoadingMore = false;
        _hasMore = result.hasMore;
        _error = null;
        _moreError = null;
        _nextPage = page + 1;
      });
    } catch (error) {
      if (!mounted || token.isCancelled) {
        return;
      }
      if (kDebugMode) {
        debugPrint(
          '[AgentDrugsPage] fetch error for agent id ${widget.agentId}: $error',
        );
      }
      if (!mounted) return;
      _setError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>().authSessionRevision;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    Widget body;
    if (_isInitialLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ErrorStateCard(
        message: _error!,
        actionLabel: l10n.actionRetry,
        onRetry: _errorRetryable ? _fetchFirstPage : null,
      );
    } else if (_drugs.isEmpty) {
      body = _EmptyState(message: l10n.agentDrugsEmpty);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!context.read<AppProvider>().medicationRepo.hasResolvedCountryId)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(l10n.catalogCountryUnverified),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              l10n.scientificDrugsCount(_drugs.length),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _displayItemCount,
              itemBuilder: (context, index) {
                if (_isLoadingRow(index)) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (index == _contentItemCount && _moreError != null) {
                  return ErrorStateCard(
                    message: _moreError!,
                    actionLabel: l10n.actionRetry,
                    onRetry: _errorRetryable ? _loadMore : null,
                  );
                }
                if (_isNativeAdSlot(index)) {
                  return const InlineNativeAdCard();
                }
                final drug = _drugs[_drugIndexFor(index)];
                return RepaintBoundary(
                  child: DrugInfoCard(
                    drug: drug,
                    hideFormAndPrice: false,
                    onShowAlternatives:
                        () => _openAlternativesPage(context, drug),
                    compact: true,
                    trailing: ServerFavoriteButton(
                      id: int.tryParse(drug.id),
                      name: drug.brandName,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppHeader(
        title: widget.agentName,
        subtitle: l10n.agentDrugsSubtitle,
      ),
      bottomNavigationBar: const StickyBannerAd(),
      body: SoftBackground(child: SafeArea(child: body)),
    );
  }

  int get _nativeAdsCount => _drugs.length ~/ _nativeAdInterval;

  int get _contentItemCount => _drugs.length + _nativeAdsCount;

  int get _displayItemCount =>
      _contentItemCount + ((_isLoadingMore || _moreError != null) ? 1 : 0);

  bool _isLoadingRow(int index) => _isLoadingMore && index == _contentItemCount;

  bool _isNativeAdSlot(int index) =>
      index < _contentItemCount && (index + 1) % (_nativeAdInterval + 1) == 0;

  int _drugIndexFor(int index) {
    final adsBefore = (index + 1) ~/ (_nativeAdInterval + 1);
    return index - adsBefore;
  }
}

void _openAlternativesPage(BuildContext context, Drug drug) {
  final id = int.tryParse(drug.id);
  if (id == null) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (_) => MedicationAlternativesPage(
            medicationId: id,
            drugName: drug.brandName,
            scientificName: drug.scientificName,
          ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
