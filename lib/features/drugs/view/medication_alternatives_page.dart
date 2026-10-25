import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/utils/apple_review_mode.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/error_state_card.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../core/widgets/sticky_banner_ad.dart';
import '../../../core/widgets/inline_native_ad_card.dart';
import '../../../data/models/drug.dart';
import '../../../providers/app_provider.dart';
import '../data/mappers/medication_mapper.dart';
import '../../search/widgets/drug_info_card.dart';
import '../widgets/dosage_forms_sheet.dart';

class MedicationAlternativesPage extends StatefulWidget {
  final int medicationId;
  final String drugName;
  final String scientificName;
  const MedicationAlternativesPage({
    super.key,
    required this.medicationId,
    required this.drugName,
    required this.scientificName,
  });

  @override
  State<MedicationAlternativesPage> createState() =>
      _MedicationAlternativesPageState();
}

class _MedicationAlternativesPageState
    extends State<MedicationAlternativesPage> {
  static const int _pageSize = 20;
  static const int _nativeAdInterval = 10;
  int get _nativeAdCount =>
      _alternatives.isEmpty
          ? 0
          : (_alternatives.length - 1) ~/ _nativeAdInterval;
  int get _contentItemCount => _alternatives.length + _nativeAdCount;
  late final ScrollController _scrollController;
  CancelToken? _pageToken;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _nextPage = 1;
  String? _error;
  bool _errorRetryable = true;
  List<Drug> _alternatives = const [];
  bool _didRequestFirstPage = false;
  AppCountry? _observedCountry;
  int? _observedAuthRevision;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
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
      _alternatives = const [];
      _error = null;
      _nextPage = 1;
    });
    _fetchPage(1);
  }

  void _onScroll() {
    if (!_hasMore || _isInitialLoading || _isLoadingMore) return;
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
    });
    _fetchPage(_nextPage);
  }

  Future<void> _fetchPage(int page) async {
    final repo = context.read<AppProvider>().medicationRepo;
    _pageToken?.cancel();
    final token = CancelToken();
    _pageToken = token;
    try {
      final result = await repo.alternativesPaged(
        medId: widget.medicationId,
        page: page,
        pageSize: _pageSize,
        country: kAppCountry,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      final mapped = List<Drug>.unmodifiable(
        result.items.map(MedicationMapper.toDrug),
      );
      final combined =
          page == 1
              ? mapped
              : List<Drug>.unmodifiable(<Drug>[..._alternatives, ...mapped]);
      if (!mounted) return;
      setState(() {
        _alternatives = combined;
        _isInitialLoading = false;
        _isLoadingMore = false;
        _hasMore = result.hasMore;
        _error = null;
        _nextPage = page + 1;
      });
    } on DioException catch (dioError) {
      if (!mounted || token.isCancelled || CancelToken.isCancel(dioError)) {
        return;
      }
      _handleError(dioError);
    } catch (error) {
      if (!mounted || token.isCancelled) return;
      _handleError(error);
    }
  }

  void _handleError(Object error) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error =
          l10n == null ? 'Error loading data' : apiFailureMessage(error, l10n);
      _errorRetryable = isApiFailureRetryable(error);
      _isInitialLoading = false;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>().authSessionRevision;
    final l10n = AppLocalizations.of(context)!;
    debugPrint(
      '[MedicationAlternativesPage] build -> alternatives length ${_alternatives.length}',
    );
    Widget body;
    if (_isInitialLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ErrorStateCard(
        message: _error!,
        actionLabel: l10n.actionRetry,
        onRetry: _errorRetryable ? _fetchFirstPage : null,
      );
    } else if (_alternatives.isEmpty) {
      body = _AlternativesEmpty(message: noRelatedProductsFoundLabel(l10n));
    } else {
      body = ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _contentItemCount + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _contentItemCount) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (index % (_nativeAdInterval + 1) == _nativeAdInterval) {
            return const InlineNativeAdCard();
          }
          final drug = _alternatives[index - index ~/ (_nativeAdInterval + 1)];
          return RepaintBoundary(
            child: DrugInfoCard(
              drug: drug,
              hideFormAndPrice: true,
              showFormsButton: true,
              onShowForms: () => _loadFormsAndShow(drug),
              showActionButton: false,
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppHeader(
        title: relatedProductsPageTitle(l10n, widget.drugName),
        subtitle: widget.scientificName,
      ),
      bottomNavigationBar: const StickyBannerAd(),
      body: SoftBackground(child: SafeArea(child: body)),
    );
  }

  Future<void> _loadFormsAndShow(Drug drug) async {
    final id = int.tryParse(drug.id);
    if (id == null || !mounted) return;
    final repo = context.read<AppProvider>().medicationRepo;
    await showModalBottomSheet(
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
}

class _AlternativesEmpty extends StatelessWidget {
  final String message;
  const _AlternativesEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
