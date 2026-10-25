import 'package:digitalpharmacy/core/utils/price_presentation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/utils/apple_review_mode.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/network/auth_session.dart';
import '../../../data/models/drug.dart';

typedef FormsLoader = Future<List<DosageFormPrice>> Function(CancelToken token);

class DosageFormsSheet extends StatefulWidget {
  final String drugName;
  final FormsLoader loadForms;
  final AuthSession? session;

  const DosageFormsSheet({
    super.key,
    required this.drugName,
    required this.loadForms,
    this.session,
  });

  @override
  State<DosageFormsSheet> createState() => _DosageFormsSheetState();
}

class _DosageFormsSheetState extends State<DosageFormsSheet> {
  late final AuthSession? _session;
  CancelToken? _token;
  int _sessionRevision = 0;
  bool _loading = true;
  String? _error;
  bool _errorRetryable = true;
  List<DosageFormPrice> _forms = const [];

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _sessionRevision = (_session?.revision ?? 0);
    _session?.addListener(_onSessionChanged);
    _fetchForms();
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _token?.cancel();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted || _sessionRevision == (_session?.revision ?? 0)) return;
    _sessionRevision = (_session?.revision ?? 0);
    _token?.cancel();
    _fetchForms();
  }

  Future<void> _fetchForms() async {
    _token?.cancel();
    final token = CancelToken();
    _token = token;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final forms = await widget.loadForms(token);
      if (!mounted || token.isCancelled) return;
      setState(() {
        _forms = forms;
        _loading = false;
      });
    } on DioException catch (dioError) {
      if (!mounted || token.isCancelled || CancelToken.isCancel(dioError)) {
        return;
      }
      setState(() {
        final l10n = AppLocalizations.of(context)!;
        _error = apiFailureMessage(dioError, l10n);
        _errorRetryable = isApiFailureRetryable(dioError);
        _loading = false;
      });
    } catch (error) {
      if (!mounted || token.isCancelled) return;
      setState(() {
        final l10n = AppLocalizations.of(context)!;
        _error = apiFailureMessage(error, l10n);
        _errorRetryable = isApiFailureRetryable(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context)!;

    Widget content;
    if (_loading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_errorRetryable) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchForms,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.actionRetry),
              ),
            ],
          ],
        ),
      );
    } else if (_forms.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            l10n.noFormsAvailable,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    } else {
      content = Flexible(
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _forms.length,
          itemBuilder: (context, index) {
            final form = _forms[index];
            return Column(
              children: [
                if (index != 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          form.formName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          priceForDisplay(
                            formattedPrice: form.formattedPrice,
                            currencyKnown: form.priceCurrencyKnown,
                            l10n: l10n,
                          ),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    // change text direction to ltr

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(color: Colors.transparent),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        productFormsLabel(l10n),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.dosageFormsClose,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  widget.drugName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
