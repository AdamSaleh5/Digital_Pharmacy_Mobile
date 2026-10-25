import 'package:digitalpharmacy/l10n/app_localizations.dart';
import '../utils/apple_review_mode.dart';

enum DrugSearchMode { scientific, trade, company, agent, all }

extension DrugSearchModeText on DrugSearchMode {
  String title(AppLocalizations l10n) {
    switch (this) {
      case DrugSearchMode.scientific:
        return scientificIndexNavLabel(l10n);
      case DrugSearchMode.trade:
        return l10n.navTrade;
      case DrugSearchMode.company:
        return l10n.navCompany;
      case DrugSearchMode.agent:
        return l10n.navAgent;
      case DrugSearchMode.all:
        return allProductsNavLabel(l10n);
    }
  }

  String subtitle(AppLocalizations l10n) {
    switch (this) {
      case DrugSearchMode.scientific:
        return scientificSearchSubtitle(l10n);
      case DrugSearchMode.trade:
        return l10n.searchSubtitleTrade;
      case DrugSearchMode.company:
        return companySearchSubtitle(l10n);
      case DrugSearchMode.agent:
        return l10n.searchSubtitleAgent;
      case DrugSearchMode.all:
        return allProductsSearchSubtitle(l10n);
    }
  }

  String hintText(AppLocalizations l10n) {
    switch (this) {
      case DrugSearchMode.scientific:
        return l10n.searchHintScientific;
      case DrugSearchMode.trade:
        return l10n.searchHintTrade;
      case DrugSearchMode.company:
        return l10n.searchHintCompany;
      case DrugSearchMode.agent:
        return l10n.searchHintAgent;
      case DrugSearchMode.all:
        return allProductsSearchHint(l10n);
    }
  }

  String emptyStateDescription(AppLocalizations l10n) {
    switch (this) {
      case DrugSearchMode.scientific:
        return l10n.emptyScientific;
      case DrugSearchMode.trade:
        return l10n.emptyTrade;
      case DrugSearchMode.company:
        return l10n.emptyCompany;
      case DrugSearchMode.agent:
        return l10n.emptyAgent;
      case DrugSearchMode.all:
        return allProductsEmptyLabel(l10n);
    }
  }
}
