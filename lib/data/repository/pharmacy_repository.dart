import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../datasource/mock_pharmacies.dart';
import '../models/pharmacy.dart';

enum PharmacySearchMode {
  name,
  address,
  phone,
  manager,
}

extension PharmacySearchModeText on PharmacySearchMode {
  String label(AppLocalizations l10n) {
    switch (this) {
      case PharmacySearchMode.name:
        return l10n.pharmacyModeName;
      case PharmacySearchMode.address:
        return l10n.pharmacyModeAddress;
      case PharmacySearchMode.phone:
        return l10n.pharmacyModePhone;
      case PharmacySearchMode.manager:
        return l10n.pharmacyModeManager;
    }
  }

  String hintText(AppLocalizations l10n) {
    switch (this) {
      case PharmacySearchMode.name:
        return l10n.pharmacyHintName;
      case PharmacySearchMode.address:
        return l10n.pharmacyHintAddress;
      case PharmacySearchMode.phone:
        return l10n.pharmacyHintPhone;
      case PharmacySearchMode.manager:
        return l10n.pharmacyHintManager;
    }
  }
}

class PharmacyRepository {
  const PharmacyRepository();

  List<Pharmacy> getAll() => MockPharmacies.all;

  List<Pharmacy> search({
    required String query,
    required PharmacySearchMode mode,
  }) {
    final q = query.trim().toLowerCase();

    String targetValue(Pharmacy pharmacy) {
      switch (mode) {
        case PharmacySearchMode.name:
          return pharmacy.name;
        case PharmacySearchMode.address:
          return pharmacy.address;
        case PharmacySearchMode.phone:
          return pharmacy.phone;
        case PharmacySearchMode.manager:
          return pharmacy.manager;
      }
    }

    return MockPharmacies.all.where((pharmacy) {
      if (q.isEmpty) return true;
      return targetValue(pharmacy).toLowerCase().contains(q);
    }).toList();
  }
}
