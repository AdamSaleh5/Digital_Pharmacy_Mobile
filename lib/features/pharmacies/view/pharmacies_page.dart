import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../core/widgets/sticky_banner_ad.dart';
import '../../../core/widgets/inline_native_ad_card.dart';
import '../../../data/models/pharmacy.dart';
import '../../../data/repository/pharmacy_repository.dart';
import '../../../providers/app_provider.dart';
import '../../home/widgets/search_mode_chip.dart';
import '../data/models/pharmacy_item.dart';
import 'pharmacy_details_page.dart';

class PharmaciesPage extends StatefulWidget {
  final bool showStandaloneBanner;
  final ApiService? api;
  const PharmaciesPage({
    super.key,
    this.showStandaloneBanner = false,
    this.api,
  });

  @override
  State<PharmaciesPage> createState() => _PharmaciesPageState();
}

class _PharmaciesPageState extends State<PharmaciesPage> {
  late final TextEditingController controller;
  late final ApiService _api;
  Timer? _debounce;
  CancelToken? _cancelToken;
  bool _loading = false;
  String? _error;
  bool _errorRetryable = true;
  List<PharmacyItem> _results = const [];
  bool _hasMore = false;
  bool _loadingMore = false;
  int _nextPage = 1;
  String? _moreError;
  AppCountry? _observedCountry;
  int? _observedAuthRevision;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiService();
    controller = TextEditingController();
    controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPharmacies(initial: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    controller.dispose();
    super.dispose();
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
    if (countryChanged || authChanged) {
      _refreshForDataScopeChange();
    }
  }

  void _refreshForDataScopeChange() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    _api.clearSessionCache();
    _hasMore = false;
    _loadingMore = false;
    _moreError = null;

    _results = const [];
    _fetchPharmacies(initial: controller.text.trim().isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context)!;
    final List<PharmacyItem> results = _results;
    const bottomInset = 24.0;

    const modes = [
      _PharmacyModeOption(
        PharmacySearchMode.name,
        Icons.local_pharmacy_outlined,
      ),
      _PharmacyModeOption(PharmacySearchMode.address, Icons.place_outlined),
      _PharmacyModeOption(PharmacySearchMode.phone, Icons.phone_outlined),
      _PharmacyModeOption(PharmacySearchMode.manager, Icons.badge_outlined),
    ];

    return Scaffold(
      appBar: AppHeader(
        title: l10n.pharmaciesTitle,
        subtitle: l10n.homeActionPharmacyTitle,
      ),
      bottomNavigationBar:
          widget.showStandaloneBanner ? const StickyBannerAd() : null,
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
            children: [
              TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onChanged: (_) => _handleQueryChanged(),
                onSubmitted: (_) => _fetchPharmacies(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: app.pharmacySearchMode.hintText(l10n),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    modes
                        .map(
                          (item) => SearchModeChip(
                            selected: app.pharmacySearchMode == item.mode,
                            title: item.mode.label(l10n),
                            icon: item.icon,
                            onTap: () {
                              if (app.pharmacySearchMode == item.mode) return;
                              app.setPharmacySearchMode(item.mode);
                              _handleQueryChanged(force: true);
                            },
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pharmaciesSearchBy(app.pharmacySearchMode.label(l10n)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.pharmaciesMatches(results.length),
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorState(
                  message: _error!,
                  onRetry:
                      _errorRetryable
                          ? () => _fetchPharmacies(
                            initial: controller.text.trim().isEmpty,
                          )
                          : null,
                )
              else if (results.isEmpty)
                const _EmptyState()
              else
                ...interleaveNativeAds(
                  results.map(
                    (pharmacy) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          pharmacy.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDetails(pharmacy),
                      ),
                    ),
                  ),
                ),
              if (!_loading && (_hasMore || _moreError != null)) ...[
                if (_moreError != null) Text(_moreError!),
                OutlinedButton(
                  onPressed:
                      _loadingMore || !_hasMore
                          ? null
                          : () => _fetchPharmacies(loadMore: true),
                  child:
                      _loadingMore
                          ? const CircularProgressIndicator()
                          : Text(l10n.loadMoreResults),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleQueryChanged({bool force = false}) {
    _debounce?.cancel();
    _cancelToken?.cancel();
    setState(() {
      _results = const [];
      _loading = true;
      _error = null;
      _hasMore = false;
      _loadingMore = false;
      _moreError = null;
    });
    if (force || controller.text.trim().isEmpty) {
      _fetchPharmacies();
    } else {
      _debounce = Timer(const Duration(milliseconds: 300), _fetchPharmacies);
    }
  }

  Future<void> _fetchPharmacies({
    bool initial = false,
    bool loadMore = false,
  }) async {
    if (loadMore && (_loading || _loadingMore || !_hasMore)) return;
    // Submitting page1 must not leave a second scheduled search behind.
    if (!loadMore) _debounce?.cancel();
    _cancelToken?.cancel();
    final l10n = AppLocalizations.of(context)!;
    final query = controller.text.trim();
    final mode = context.read<AppProvider>().pharmacySearchMode;
    final page = loadMore ? _nextPage : 1;
    final token = CancelToken();
    _cancelToken = token;
    setState(() {
      _loading = !loadMore;
      _loadingMore = loadMore;
      if (!loadMore) {
        _results = const [];
        _hasMore = false;
        _nextPage = 1;
      }
      _error = null;
      _moreError = null;
    });
    try {
      final response = await _api.fetchPharmacyPage(
        query: query.isEmpty ? null : query,
        searchType: _mapModeToType(mode),
        pageNumber: page,
        pageSize: 20,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      setState(() {
        final seen =
            loadMore ? _results.map((item) => item.id).toSet() : <int>{};
        _results = List.unmodifiable([
          if (loadMore) ..._results,
          ...response.items.where((item) => seen.add(item.id)),
        ]);
        _hasMore = response.metadata.hasNextPage;
        _nextPage = response.metadata.pageNumber + 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || token.isCancelled) return;
      setState(() {
        if (loadMore) {
          _moreError = apiFailureMessage(error, l10n);
          if (!isApiFailureRetryable(error)) _hasMore = false;
        } else {
          _error = apiFailureMessage(error, l10n);
        }
        _errorRetryable = isApiFailureRetryable(error);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _openDetails(PharmacyItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PharmacyDetailsPage(
              pharmacy: Pharmacy(
                id: item.id.toString(),
                name: item.name,
                address: item.address,
                phone: item.phoneNumber,
                manager: item.managerName,
              ),
            ),
      ),
    );
  }

  PharmacySearchType _mapModeToType(PharmacySearchMode mode) {
    switch (mode) {
      case PharmacySearchMode.name:
        return PharmacySearchType.name;
      case PharmacySearchMode.address:
        return PharmacySearchType.address;
      case PharmacySearchMode.phone:
        return PharmacySearchType.phoneNumber;
      case PharmacySearchMode.manager:
        return PharmacySearchType.managerName;
    }
  }
}

class _PharmacyModeOption {
  final PharmacySearchMode mode;
  final IconData icon;
  const _PharmacyModeOption(this.mode, this.icon);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.apartment_outlined, size: 48, color: Colors.black45),
          const SizedBox(height: 12),
          Text(l10n.pharmaciesEmpty, textAlign: TextAlign.center),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(.2)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
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
