import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/apple_review_notice_card.dart';
import '../../../core/widgets/inline_native_ad_card.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../core/widgets/sticky_banner_ad.dart';
import '../../../data/models/drug.dart';
import '../../../providers/app_provider.dart';
import '../../drugs/data/mappers/medication_mapper.dart';
import '../../drugs/view/medication_alternatives_page.dart';
import '../widgets/drug_info_card.dart';
import '../../drugs/widgets/dosage_forms_sheet.dart';

class TradeDetailsPage extends StatefulWidget {
  final String tradeName;
  const TradeDetailsPage({super.key, required this.tradeName});

  @override
  State<TradeDetailsPage> createState() => _TradeDetailsPageState();
}

class _TradeDetailsPageState extends State<TradeDetailsPage> {
  static const int _nativeAdInterval = 10;
  CancelToken? _cancelToken;
  bool _loading = true;
  String? _error;
  bool _errorRetryable = true;
  List<Drug> _drugs = const [];

  bool _didRequestData = false;
  AppCountry? _observedCountry;
  int? _observedAuthRevision;

  @override
  void initState() {
    super.initState();
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
    if (!_didRequestData) {
      _didRequestData = true;
      _fetchTradeDrugs();
    } else if (countryChanged || authChanged) {
      _refreshForDataScopeChange();
    }
  }

  void _refreshForDataScopeChange() {
    _cancelToken?.cancel();

    _fetchTradeDrugs();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _fetchTradeDrugs() async {
    _cancelToken?.cancel();
    final token = CancelToken();
    _cancelToken = token;
    setState(() {
      _loading = true;
      _error = null;
      _errorRetryable = true;
    });
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = context.read<AppProvider>().medicationRepo;
      final items = await repo.fetchMedicationsByName(
        query: widget.tradeName,
        searchType: MedicationSearchType.tradeName,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      setState(() {
        _drugs = items.map(MedicationMapper.toDrug).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted ||
          token.isCancelled ||
          (error is DioException && CancelToken.isCancel(error))) {
        return;
      }
      setState(() {
        _error = apiFailureMessage(error, l10n);
        _errorRetryable = isApiFailureRetryable(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>().authSessionRevision;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = _TradeError(
        message: _error!,
        onRetry: _errorRetryable ? _fetchTradeDrugs : null,
      );
    } else if (_drugs.isEmpty) {
      content = _EmptyState(message: l10n.tradeDetailsEmpty);
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _tradeListItemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppleReviewNoticeCard(
                  margin: EdgeInsets.only(bottom: 12),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.tradeDetailsCount(_drugs.length),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            );
          }
          final contentIndex = index - 1;
          if (_isNativeAdSlot(contentIndex)) {
            return const InlineNativeAdCard();
          }
          final drug = _drugs[_drugIndexFor(contentIndex)];
          return DrugInfoCard(
            drug: drug,
            hideFormAndPrice: true,
            showFormsButton: true,
            onShowForms: () => _loadFormsAndShow(drug),
            onShowAlternatives: () => _openAlternativesPage(context, drug),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppHeader(
        title: widget.tradeName,
        subtitle: l10n.tradeDetailsSubtitle,
      ),
      bottomNavigationBar: const StickyBannerAd(),
      body: SoftBackground(child: SafeArea(child: content)),
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

  int get _nativeAdsCount => _drugs.length ~/ _nativeAdInterval;

  int get _contentItemCount => _drugs.length + _nativeAdsCount;

  int get _tradeListItemCount => _contentItemCount + 1;

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

class _TradeError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _TradeError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
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
