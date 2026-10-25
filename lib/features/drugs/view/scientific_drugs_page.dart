import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/utils/apple_review_mode.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/inline_native_ad_card.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../core/widgets/sticky_banner_ad.dart';
import '../../../data/models/drug.dart';
import '../../../providers/app_provider.dart';
import '../data/mappers/medication_mapper.dart';
import '../widgets/dosage_forms_sheet.dart';
import '../widgets/scientific_drug_card.dart';

class ScientificDrugsPage extends StatefulWidget {
  final String scientificName;
  const ScientificDrugsPage({super.key, required this.scientificName});

  @override
  State<ScientificDrugsPage> createState() => _ScientificDrugsPageState();
}

class _ScientificDrugsPageState extends State<ScientificDrugsPage> {
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
      _fetchDrugs();
    } else if (countryChanged || authChanged) {
      _refreshForDataScopeChange();
    }
  }

  void _refreshForDataScopeChange() {
    _cancelToken?.cancel();

    _fetchDrugs();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _fetchDrugs() async {
    _cancelToken?.cancel();
    final token = CancelToken();
    _cancelToken = token;
    setState(() {
      _loading = true;
      _error = null;
    });
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = context.read<AppProvider>().medicationRepo;
      final items = await repo.fetchMedicationsByName(
        query: widget.scientificName,
        searchType: MedicationSearchType.scientificName,
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
    Widget body;
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = _ErrorState(
        message: _error!,
        onRetry: _errorRetryable ? _fetchDrugs : null,
      );
    } else if (_drugs.isEmpty) {
      body = _EmptyState(message: scientificProductsEmpty(l10n));
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _scientificListItemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                scientificProductsCount(l10n, _drugs.length),
                style: theme.textTheme.bodyMedium,
              ),
            );
          }
          final contentIndex = index - 1;
          if (_isNativeAdSlot(contentIndex)) {
            return const InlineNativeAdCard();
          }
          final drug = _drugs[_drugIndexFor(contentIndex)];
          return ScientificDrugCard(
            drug: drug,
            onShowForms: () => _loadFormsAndShow(drug),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppHeader(
        title: scientificProductsTitle(l10n),
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

  int get _nativeAdsCount => _drugs.length ~/ _nativeAdInterval;

  int get _contentItemCount => _drugs.length + _nativeAdsCount;

  int get _scientificListItemCount => _contentItemCount + 1;

  bool _isNativeAdSlot(int index) =>
      index < _contentItemCount && (index + 1) % (_nativeAdInterval + 1) == 0;

  int _drugIndexFor(int index) {
    final adsBefore = (index + 1) ~/ (_nativeAdInterval + 1);
    return index - adsBefore;
  }
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
        borderRadius: BorderRadius.circular(22),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
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
