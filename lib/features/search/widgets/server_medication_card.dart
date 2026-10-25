import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/drug.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_provider.dart';
import '../../drugs/data/mappers/medication_mapper.dart';
import '../../drugs/data/models/medication_item.dart';
import '../../drugs/widgets/dosage_forms_sheet.dart';
import 'drug_info_card.dart';

class ServerMedicationCard extends StatefulWidget {
  const ServerMedicationCard({super.key, required this.item});
  final MedicationItem item;

  @override
  State<ServerMedicationCard> createState() => _ServerMedicationCardState();
}

class _ServerMedicationCardState extends State<ServerMedicationCard> {
  bool _formsOpen = false;

  Future<void> _showForms(
    AppProvider app,
    AppCountry country,
    int revision,
  ) async {
    if (!mounted ||
        _formsOpen ||
        widget.item.id <= 0 ||
        country != app.selectedCountry ||
        revision != app.dataScopeRevision) {
      return;
    }
    final item = widget.item;
    _formsOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => _ServerMedicationFormsSheet(
              item: item,
              app: app,
              country: country,
              revision: revision,
            ),
      );
    } finally {
      _formsOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final country = app.selectedCountry;
    final revision = app.dataScopeRevision;
    return DrugInfoCard(
      drug: MedicationMapper.toDrug(widget.item),
      compact: true,
      showActionButton: false,
      showFormsButton: widget.item.id > 0,
      onShowForms:
          widget.item.id > 0 ? () => _showForms(app, country, revision) : null,
      trailing: ServerFavoriteButton(
        id: widget.item.id,
        name: widget.item.tradeName,
      ),
    );
  }
}

class _ServerMedicationFormsSheet extends StatefulWidget {
  const _ServerMedicationFormsSheet({
    required this.item,
    required this.app,
    required this.country,
    required this.revision,
  });

  final MedicationItem item;
  final AppProvider app;
  final AppCountry country;
  final int revision;

  @override
  State<_ServerMedicationFormsSheet> createState() =>
      _ServerMedicationFormsSheetState();
}

class _ServerMedicationFormsSheetState
    extends State<_ServerMedicationFormsSheet> {
  CancelToken? _token;
  bool _closing = false;

  bool get _currentScope =>
      widget.country == widget.app.selectedCountry &&
      widget.revision == widget.app.dataScopeRevision;

  @override
  void initState() {
    super.initState();
    widget.app.addListener(_onScopeChanged);
    if (!_currentScope) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScopeChanged());
    }
  }

  void _onScopeChanged() {
    if (!mounted || _closing || _currentScope) return;
    _closing = true;
    _token?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    widget.app.removeListener(_onScopeChanged);
    _token?.cancel();
    super.dispose();
  }

  Future<List<DosageFormPrice>> _loadForms(CancelToken token) async {
    _token = token;
    if (!_currentScope) {
      token.cancel();
      throw token.cancelError!;
    }
    final items = await widget.app.medicationRepo.fetchFormsOnce(
      medId: widget.item.id,
      country: widget.country,
      cancelToken: token,
    );
    return items
        .where((item) => item.pharmaceuticalForm.trim().isNotEmpty)
        .map(
          (item) => DosageFormPrice(
            formName: item.pharmaceuticalForm,
            priceJod: item.price,
            priceCurrencyKnown: false,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) =>
      DosageFormsSheet(drugName: widget.item.tradeName, loadForms: _loadForms);
}

class ServerFavoriteButton extends StatelessWidget {
  const ServerFavoriteButton({super.key, required this.id, required this.name});
  final int? id;
  final String name;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final selected = id != null && app.isServerFavorite(id!);
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: selected ? l10n.removeFavorite : l10n.addFavorite,
      icon: Icon(selected ? Icons.favorite : Icons.favorite_border),
      onPressed:
          id != null && id! > 0 && name.trim().isNotEmpty
              ? () => app.toggleServerFavorite(id: id!, name: name)
              : null,
    );
  }
}
