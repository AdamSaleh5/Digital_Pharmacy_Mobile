import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/error_state_card.dart';
import '../../../core/widgets/inline_native_ad_card.dart';
import '../../../core/widgets/sticky_banner_ad.dart';
import '../../../features/drugs/data/models/medication_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_provider.dart';
import '../widgets/server_medication_card.dart';

/// Only accepts an actual positive selection ID returned by the server.
class MedicationSelectionResultsPage extends StatefulWidget {
  const MedicationSelectionResultsPage({
    super.key,
    required this.id,
    required this.title,
    required this.searchType,
    this.api,
  });

  final int id;
  final String title;
  final MedicationSearchType searchType;
  final ApiService? api;

  @override
  State<MedicationSelectionResultsPage> createState() =>
      _MedicationSelectionResultsPageState();
}

class _MedicationSelectionResultsPageState
    extends State<MedicationSelectionResultsPage> {
  late final ApiService _api = widget.api ?? ApiService();
  CancelToken? _token;
  List<MedicationItem> _items = const [];
  int _nextPage = 1;
  bool _hasMore = false;
  bool _loading = false;
  String? _error;
  bool _retryable = true;
  int? _authRevision;
  AppCountry? _country;
  AppCountry? _selectionCountry;
  bool _selectionInvalidated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppProvider>();
    _selectionCountry ??= app.selectedCountry;
    if (_selectionInvalidated || _selectionCountry != app.selectedCountry) {
      _selectionInvalidated = true;
      _token?.cancel('Selection belongs to the previous country.');
      _items = const [];
      _nextPage = 1;
      _hasMore = false;
      _loading = false;
      _retryable = false;
      _error = AppLocalizations.of(context)!.selectionCountryChanged;
      return;
    }

    if (_authRevision != app.dataScopeRevision ||
        _country != app.selectedCountry) {
      _authRevision = app.dataScopeRevision;
      _country = app.selectedCountry;
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _token?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading && !reset) return;
    _token?.cancel();
    final token = CancelToken();
    _token = token;
    final page = reset ? 1 : _nextPage;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items = const [];
        _hasMore = false;
        _nextPage = 1;
      }
    });
    try {
      final result = await _api.fetchMedicationDetailsPage(
        id: widget.id,
        searchType: widget.searchType,
        pageNumber: page,
        pageSize: 20,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      setState(() {
        final seen = _items.map((item) => item.id).toSet();
        _items = List.unmodifiable([
          ..._items,
          ...result.items.where((item) => seen.add(item.id)),
        ]);
        _nextPage = result.metadata.pageNumber + 1;
        _hasMore = result.metadata.hasNextPage;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || token.isCancelled) return;
      setState(() {
        _error = apiFailureMessage(error, AppLocalizations.of(context)!);
        _retryable = isApiFailureRetryable(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppHeader(title: widget.title),
      bottomNavigationBar: const StickyBannerAd(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.catalogCountryUnverified),
          const SizedBox(height: 12),
          Text(l10n.scientificDrugsCount(_items.length)),
          const SizedBox(height: 12),
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0 && i % 10 == 0) const InlineNativeAdCard(),
            ServerMedicationCard(item: _items[i]),
          ],
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            ErrorStateCard(
              message: _error!,
              actionLabel: l10n.actionRetry,
              onRetry: _retryable ? () => _load(reset: _items.isEmpty) : null,
            ),
          if (!_loading && _error == null && _items.isEmpty)
            Text(l10n.companyDrugsEmpty),
          if (!_loading && _error == null && _hasMore)
            OutlinedButton(onPressed: _load, child: Text(l10n.loadMoreResults)),
        ],
      ),
    );
  }
}
