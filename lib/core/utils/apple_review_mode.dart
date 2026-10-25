import 'package:flutter/foundation.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

bool get isIosReferenceMode =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get shouldHideDirectMedicalFieldsOnIos => isIosReferenceMode;

String homeDirectoryTitle(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosDirectoryHomeTitle : l10n.homeHeaderTitle;

String homeDirectorySubtitle(AppLocalizations l10n) =>
    isIosReferenceMode
        ? l10n.iosDirectoryHomeSubtitle
        : l10n.homeHeaderSubtitle;

String homeDirectoryHelper(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosDirectoryHomeHelper : l10n.homeHeaderHelper;

String scientificIndexNavLabel(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosScientificIndexNav : l10n.navScientific;

String allProductsNavLabel(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosAllProductsNav : l10n.navAllDrugs;

String scientificSearchSubtitle(AppLocalizations l10n) =>
    isIosReferenceMode
        ? l10n.iosSearchSubtitleScientific
        : l10n.searchSubtitleScientific;

String companySearchSubtitle(AppLocalizations l10n) =>
    isIosReferenceMode
        ? l10n.iosSearchSubtitleCompany
        : l10n.searchSubtitleCompany;

String allProductsSearchSubtitle(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosSearchSubtitleAll : l10n.searchSubtitleAll;

String allProductsSearchHint(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosSearchHintAll : l10n.searchHintDrug;

String allProductsEmptyLabel(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosEmptyAll : l10n.emptyAll;

String scientificProductsTitle(AppLocalizations l10n) =>
    isIosReferenceMode
        ? l10n.iosScientificDrugsTitle
        : l10n.scientificDrugsTitle;

String scientificProductsCount(AppLocalizations l10n, int count) =>
    isIosReferenceMode
        ? l10n.iosScientificDrugsCount(count)
        : l10n.scientificDrugsCount(count);

String scientificProductsEmpty(AppLocalizations l10n) =>
    isIosReferenceMode
        ? l10n.iosScientificDrugsEmpty
        : l10n.scientificDrugsEmpty;

String productNameLabel(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosProductNameLabel : l10n.drugCardTrade;

String referenceInfoLabel(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosReferenceInfoLabel : l10n.labelUsage;

String similarProductsLabel(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosSimilarProductsLabel : l10n.labelAlternatives;

String viewSimilarProductsLabel(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosViewSimilarProducts : l10n.viewAlternatives;

String relatedProductsPageTitle(AppLocalizations l10n, String drugName) =>
    isIosReferenceMode
        ? l10n.iosSimilarProductsForDrug(drugName)
        : l10n.alternativesForDrug(drugName);

String noRelatedProductsFoundLabel(AppLocalizations l10n) =>
    isIosReferenceMode
        ? l10n.iosNoSimilarProductsFound
        : l10n.noAlternativesFound;

String productFormsLabel(AppLocalizations l10n) =>
    isIosReferenceMode ? l10n.iosProductFormsLabel : l10n.pharmaceuticalForms;
