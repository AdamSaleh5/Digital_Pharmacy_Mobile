// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DigitalPharmacy';

  @override
  String get appTagline => 'Digital Pharmacy';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Close';

  @override
  String get commonAdPlaceholder => 'Ad space';

  @override
  String get commonComingSoon => 'Coming soon';

  @override
  String get commonCopySuccess => 'Number copied';

  @override
  String get commonCall => 'Call';

  @override
  String get actionRetry => 'Retry';

  @override
  String get errorLoadingData => 'An error occurred while loading data';

  @override
  String get apiAuthenticationRequired =>
      'The service is not accessible. Please try again later.';

  @override
  String get authSettingsTitle => 'API account';

  @override
  String get authHttpsSetupNeeded =>
      'Sign-in is disabled for this API address. Check the app\'s API configuration.';

  @override
  String get authHttpRiskNotice =>
      'This connection uses HTTP. Your password and token are not encrypted in transit. Use this sign-in only on a trusted network. The token stays in memory and is never saved or logged.';

  @override
  String get notificationsSettingsTitle => 'Push notifications';

  @override
  String get notificationsNotEnabled =>
      'Notifications are not enabled for this app.';

  @override
  String get notificationsPermissionDenied =>
      'Notification permission is denied.';

  @override
  String get notificationsPermissionProvisional =>
      'Notifications are enabled quietly.';

  @override
  String get notificationsPermissionEnabled => 'Notifications are enabled.';

  @override
  String get notificationsUnsupported =>
      'Push notifications are unavailable on this platform.';

  @override
  String get notificationsEnableAction => 'Enable notifications';

  @override
  String get notificationsDeniedHelp =>
      'To enable later, allow notifications for this app in your device settings.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authSignInAction => 'Sign in';

  @override
  String get authSignOutAction => 'Sign out';

  @override
  String get authSigningIn => 'Signing in…';

  @override
  String get authSignedInMemory =>
      'Signed in for this app session only. The token is not saved.';

  @override
  String get authLoginFailed =>
      'Sign-in failed. Check the details and try again.';

  @override
  String get authInvalidTokenResponse =>
      'The login response did not include a usable access token.';

  @override
  String get apiContractUnavailable =>
      'This feature is unavailable until the API provides the response fields and IDs it needs.';

  @override
  String get apiDetailsUnavailable =>
      'Details are unavailable until the API provides a medication ID.';

  @override
  String get errorLoadingPharmacies =>
      'An error occurred while loading pharmacies';

  @override
  String get drugNotFound => 'Drug not found.';

  @override
  String get viewAlternatives => 'View alternatives';

  @override
  String get noAlternativesFound => 'No alternatives found for this drug.';

  @override
  String alternativesForDrug(String drugName) {
    return 'Alternatives for $drugName';
  }

  @override
  String alternativesFoundCount(int count) {
    return 'Found $count alternatives';
  }

  @override
  String get alternativesLoading => 'Loading alternatives…';

  @override
  String get homeHeaderTitle => 'Find your medicine or pharmacy';

  @override
  String get homeHeaderSubtitle =>
      'Choose the right search mode and type the name to view results.';

  @override
  String get homeHeaderHelper =>
      'Search by scientific name, trade name, company, agent, or pharmacy.';

  @override
  String get homeRemoveAds => 'Remove ads: Get an activation code';

  @override
  String get activationTitle => 'Activation code';

  @override
  String get activationDescription =>
      'Enter your activation code. Ads stop after the server confirms activation for this installation.';

  @override
  String get activationHttpRiskNotice =>
      'Activation is unavailable until a secure connection is configured. Your saved ad setting is unchanged.';

  @override
  String get activationCodeLabel => 'Activation code';

  @override
  String get activationSubmit => 'Verify code';

  @override
  String get activationChecking => 'Checking code…';

  @override
  String get activationUnconfirmed =>
      'The server did not confirm the code\'s status. Your current ad setting has not changed.';

  @override
  String get activationVerificationFailed =>
      'Unable to verify the code. Please try again later.';

  @override
  String get activationSignInRequired =>
      'Sign in to your API account in Settings before verifying a code.';

  @override
  String get activationOpenSettings => 'Open Settings';

  @override
  String get activationDeviceUnavailable =>
      'Unable to obtain the device messaging token. Check your connection and try again.';

  @override
  String get activationCodeRequired => 'Enter an activation code.';

  @override
  String get homeActionScientificTitle => 'Search by scientific name';

  @override
  String get homeActionScientificSubtitle =>
      'Alternatives and accurate results';

  @override
  String get homeActionTradeTitle => 'Search by trade name';

  @override
  String get homeActionTradeSubtitle => 'Search the popular names';

  @override
  String get homeActionCompanyTitle => 'Search by company';

  @override
  String get homeActionCompanySubtitle => 'Browse by manufacturer';

  @override
  String get homeActionAgentTitle => 'Search by agent';

  @override
  String get homeActionAgentSubtitle => 'Find the supplier';

  @override
  String get homeActionPharmacyTitle => 'Pharmacy and warehouse directory';

  @override
  String get homeActionPharmacySubtitle => 'Pharmacy directory';

  @override
  String get homeTipsTitle => 'Quick tips';

  @override
  String get homeTip1 =>
      'Use the scientific name to discover cheaper alternatives.';

  @override
  String get homeTip2 =>
      'Try filters to narrow results by company or dosage form.';

  @override
  String get homeTip3 => 'Save favorite drugs for fast access later.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Customize your experience';

  @override
  String get settingsInfoCard =>
      'Update your preferences and data directly from the settings page.';

  @override
  String get settingsThemeTitle => 'Dark mode';

  @override
  String get settingsThemeSubtitle => 'Switch between dark and light';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Arabic / English';

  @override
  String get settingsPrivacyTitle => 'Privacy policy';

  @override
  String get settingsPrivacySubtitle => 'Learn how we protect your data.';

  @override
  String get settingsMedicalTitle => 'Medical notice';

  @override
  String get settingsMedicalSubtitle => 'Information for reference only.';

  @override
  String get settingsAlertTitle => 'Notice';

  @override
  String get settingsAlertBody =>
      'DigitalPharmacy provides reference information only and does not replace medical advice.';

  @override
  String get settingsVersionLabel => 'DigitalPharmacy v1.0.0';

  @override
  String get settingsVersionDescription =>
      'Made with ❤️ to make finding medicine easier.';

  @override
  String get settingsLanguageArabic => 'Arabic';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageSectionTitle => 'Language';

  @override
  String get settingsLanguageSectionSubtitle => 'Choose the interface language';

  @override
  String get settingsCountrySectionTitle => 'Country & Currency';

  @override
  String get settingsPrivacyOpenError => 'Could not open privacy policy link';

  @override
  String get medicalReferencesTitle => 'Medical references';

  @override
  String get medicalReferencesSubtitle =>
      'Review these external medical sources for citation and verification before relying on any medical information in the app.';

  @override
  String get medicalReferencesOpenCta => 'Open medical sources';

  @override
  String get medicalReferencesSheetTitle => 'Medical sources';

  @override
  String get medicalReferencesSheetSubtitle =>
      'Choose one of the following sources to open the external reference and verify the information.';

  @override
  String get medicalReferenceOpenError =>
      'Could not open the medical reference link';

  @override
  String get medicalSourceDailyMed => 'DailyMed';

  @override
  String get medicalSourceMedlinePlus => 'MedlinePlus';

  @override
  String get medicalSourceNhs => 'NHS';

  @override
  String get medicalSourcesEntryTitle => 'Medical sources';

  @override
  String get medicalSourcesEntrySubtitle =>
      'Open the citations and references used for medical information.';

  @override
  String get medicalSourcesPageTitle => 'Medical sources';

  @override
  String get medicalSourcesPageSubtitle =>
      'Citations for the medical information shown in the app';

  @override
  String get medicalSourcesIntro =>
      'Drug usage, alternatives, and other medical information shown in the app are for reference only. Please verify them using the external sources below and consult a doctor or pharmacist before making any medical decision.';

  @override
  String get iosReferenceNoticeTitle => 'Reference directory only';

  @override
  String get iosReferenceNoticeBody =>
      'This section shows a reference index of drug products and general descriptive information only. The app is not a healthcare provider and does not offer diagnosis, prescriptions, or treatment advice.';

  @override
  String get iosDirectoryHomeTitle => 'Drug index and pharmacy directory';

  @override
  String get iosDirectoryHomeSubtitle =>
      'Browse drug and pharmacy listings by name, company, agent, or category.';

  @override
  String get iosDirectoryHomeHelper =>
      'Content shown in the app is descriptive and reference-only for general lookup.';

  @override
  String get iosScientificIndexNav => 'Product index by scientific name';

  @override
  String get iosAllProductsNav => 'Product index';

  @override
  String get iosSearchSubtitleScientific =>
      'Browse products linked to the scientific name.';

  @override
  String get iosSearchSubtitleCompany => 'Browse products by manufacturer.';

  @override
  String get iosSearchSubtitleAll => 'Browse the full available product index.';

  @override
  String get iosSearchHintAll =>
      'Search by product name, scientific name, company, or agent…';

  @override
  String get iosEmptyAll =>
      'No matching results were found in the product index.';

  @override
  String get iosScientificDrugsTitle => 'Product index by scientific name';

  @override
  String iosScientificDrugsCount(int count) {
    return 'Products count: $count';
  }

  @override
  String get iosScientificDrugsEmpty =>
      'No products are currently listed for this scientific name.';

  @override
  String get iosProductNameLabel => 'Product name';

  @override
  String get iosReferenceInfoLabel => 'Reference note';

  @override
  String get iosSimilarProductsLabel => 'Similar products';

  @override
  String get iosViewSimilarProducts => 'View similar products';

  @override
  String iosSimilarProductsForDrug(String drugName) {
    return 'Similar products for $drugName';
  }

  @override
  String get iosNoSimilarProductsFound =>
      'No similar products are currently listed for this item.';

  @override
  String get iosProductFormsLabel => 'Available product forms';

  @override
  String get countryJordan => 'Jordan';

  @override
  String get countryPalestine => 'Palestine';

  @override
  String get countryConfirmTitle => 'Confirm country';

  @override
  String countryConfirmMessage(String country) {
    return 'Are you from $country?';
  }

  @override
  String get countryChooseTitle => 'Choose your country';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get navHome => 'Home';

  @override
  String get navScientific => 'Search by scientific name';

  @override
  String get navTrade => 'Search by trade name';

  @override
  String get navCompany => 'Search by company';

  @override
  String get navAgent => 'Search by agent';

  @override
  String get navPharmacy => 'Search by pharmacy';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAllDrugs => 'Drug search';

  @override
  String get drawerActivate => 'Activate extra features';

  @override
  String get searchSubtitleScientific =>
      'Search scientific names and find alternatives.';

  @override
  String get searchSubtitleTrade => 'Search the popular trade names.';

  @override
  String get searchSubtitleCompany => 'Browse drugs by manufacturer.';

  @override
  String get searchSubtitleAgent => 'Browse products by agent.';

  @override
  String get searchSubtitleAll => 'The same pharmacy experience for all drugs.';

  @override
  String get snackCopiedDrug => 'Drug info copied';

  @override
  String get snackComingSoon => 'Coming soon';

  @override
  String get labelCompany => 'Company';

  @override
  String get labelForm => 'Dosage form';

  @override
  String get labelStrength => 'Strength';

  @override
  String get labelPrice => 'Price';

  @override
  String get labelOrigin => 'Origin';

  @override
  String get labelScientificName => 'Scientific name';

  @override
  String get labelTradeName => 'Trade name';

  @override
  String get labelManufacturer => 'Manufacturer';

  @override
  String get labelAgentName => 'Agent name';

  @override
  String get labelAgentNumber => 'Agent number';

  @override
  String get labelAgent => 'Agent';

  @override
  String get labelUsage => 'Usage';

  @override
  String get labelDosageForms => 'Dosage forms';

  @override
  String get labelAlternatives => 'Alternatives';

  @override
  String get actionShowForms => 'Pharmaceutical forms';

  @override
  String get actionShowAlternatives => 'Show alternatives';

  @override
  String get tooltipCopy => 'Copy';

  @override
  String get tooltipCall => 'Call';

  @override
  String get dosageFormsTitle => 'Dosage forms';

  @override
  String get dosageFormsPrice => 'Price';

  @override
  String get dosageFormsClose => 'Close';

  @override
  String get pharmaceuticalForms => 'Pharmaceutical forms';

  @override
  String get loadingForms => 'Loading forms...';

  @override
  String get noFormsAvailable => 'No pharmaceutical forms available.';

  @override
  String get formsLoadFailed => 'Failed to load forms.';

  @override
  String get valueNotAvailable => 'Not available';

  @override
  String get drugCardTrade => 'Trade name';

  @override
  String get drugCardCompany => 'Company';

  @override
  String get drugCardAgent => 'Agent';

  @override
  String get drugCardScientific => 'Scientific name';

  @override
  String get drugCardButtonForms => 'Dosage forms';

  @override
  String get pharmaciesTitle => 'Pharmacy Directory';

  @override
  String get pharmaciesSubtitle => 'Directory with quick search';

  @override
  String get pharmacyModeName => 'Pharmacy name';

  @override
  String get pharmacyModeAddress => 'Address';

  @override
  String get pharmacyModeManager => 'Manager name';

  @override
  String get pharmacyModePhone => 'Phone number';

  @override
  String get pharmacyHintName => 'Type the pharmacy name';

  @override
  String get pharmacyHintAddress => 'Type the address';

  @override
  String get pharmacyHintManager => 'Type the manager\'s name';

  @override
  String get pharmacyHintPhone => 'Type the phone number';

  @override
  String pharmaciesSearchBy(String mode) {
    return 'Search by: $mode';
  }

  @override
  String pharmaciesMatches(int count) {
    return 'Matching pharmacies: $count';
  }

  @override
  String get pharmaciesEmpty => 'No pharmacies found. Try another filter.';

  @override
  String get pharmacyDetailsSubtitle => 'Pharmacy info';

  @override
  String get pharmacyAddress => 'Address';

  @override
  String get pharmacyManager => 'Manager';

  @override
  String get pharmacyPhone => 'Phone';

  @override
  String get favoritesTitle => 'Favorite drugs';

  @override
  String get favoritesSubtitle => 'Everything you saved in one place';

  @override
  String get favoritesCardTitle => 'Your personal list';

  @override
  String favoritesCardSubtitle(int count) {
    return '$count saved medications';
  }

  @override
  String get favoritesSearchHint => 'Search inside favorites…';

  @override
  String get favoritesEmpty =>
      'No favorite drugs yet.\nAdd them from the details page.';

  @override
  String get queryBarHint => 'Type a phrase to search…';

  @override
  String resultsCount(int count) {
    return 'Results: $count';
  }

  @override
  String matchingResultsCount(int count) {
    return 'Matching results: $count';
  }

  @override
  String get drugsPageTitle => 'Drugs';

  @override
  String get drugsPageSubtitle => 'Pharmacy-style explorer for all drugs';

  @override
  String get drugsSearchHint =>
      'Search by drug name, scientific name, company, or agent…';

  @override
  String drugsMatches(int count) {
    return 'Matching drugs: $count';
  }

  @override
  String get drugsEmpty => 'No matching drugs. Try another term.';

  @override
  String get tradeDetailsSubtitle => 'Trade name details';

  @override
  String tradeDetailsCount(int count) {
    return 'Matching formulations: $count';
  }

  @override
  String get tradeDetailsEmpty => 'No data available for this trade name.';

  @override
  String get companyDrugsSubtitle => 'Products from this company';

  @override
  String get catalogCountryUnverified =>
      'The API has no verified country mapping for this catalog; results may not match the selected country.';

  @override
  String get companyDrugsEmpty => 'No registered drugs for this company.';

  @override
  String get agentDrugsSubtitle => 'Drugs for this agent';

  @override
  String get agentDrugsEmpty => 'No registered drugs for this agent.';

  @override
  String get scientificDrugsTitle => 'Scientific name drugs';

  @override
  String scientificDrugsCount(int count) {
    return 'Drugs: $count';
  }

  @override
  String get scientificDrugsEmpty =>
      'No drugs currently recorded for this scientific name.';

  @override
  String searchResultsCount(int count) {
    return 'Results: $count';
  }

  @override
  String get searchNoResults => 'No matching results. Try another keyword.';

  @override
  String get searchHintScientific => 'Type the scientific name…';

  @override
  String get searchHintTrade => 'Type the trade name…';

  @override
  String get searchHintCompany => 'Type the company name…';

  @override
  String get searchHintAgent => 'Type the agent name…';

  @override
  String get searchHintDrug => 'Search by drug or company name…';

  @override
  String get emptyScientific =>
      'No drugs registered for this scientific name yet.';

  @override
  String get emptyTrade => 'No data for this trade name.';

  @override
  String get emptyCompany => 'No drugs for this company.';

  @override
  String get emptyAgent => 'No drugs registered for this agent.';

  @override
  String get emptyAll => 'No matching results. Try a different phrase.';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSectionSubtitle => 'Choose your preferred language';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get adPrivacyOptions => 'Ad privacy choices';

  @override
  String get reportAdTitle => 'Report an inappropriate ad';

  @override
  String get reportAdDescription =>
      'Report harmful or age-inappropriate advertising to Google.';

  @override
  String get storeEntitlementUnavailable =>
      'Custom activation codes are unavailable on this platform. Ad-free access requires a supported store entitlement.';

  @override
  String get loadMoreResults => 'Load more results';

  @override
  String get addFavorite => 'Save medication';

  @override
  String get removeFavorite => 'Remove saved medication';

  @override
  String get legacyFavoritesRetained =>
      'Your earlier saved items are retained. Select them again from the server catalogue to link their current details.';

  @override
  String get activationConfirmed => 'Activation confirmed. All ads are off.';

  @override
  String get activationNotSaved =>
      'The server confirmed activation, but the app could not save it. Ads are paused; try again.';

  @override
  String get activationRejected => 'The activation code was not accepted.';

  @override
  String get selectionCountryChanged =>
      'Country changed. Go back and choose a result for the selected country.';

  @override
  String get priceCurrencyUnspecified => 'currency unspecified';
}
