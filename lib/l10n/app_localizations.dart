import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'DigitalPharmacy'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Digital Pharmacy'**
  String get appTagline;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonAdPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ad space'**
  String get commonAdPlaceholder;

  /// No description provided for @commonComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get commonComingSoon;

  /// No description provided for @commonCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Number copied'**
  String get commonCopySuccess;

  /// No description provided for @commonCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get commonCall;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading data'**
  String get errorLoadingData;

  /// No description provided for @apiAuthenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'The service is not accessible. Please try again later.'**
  String get apiAuthenticationRequired;

  /// No description provided for @authSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'API account'**
  String get authSettingsTitle;

  /// No description provided for @authHttpsSetupNeeded.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is disabled for this API address. Check the app\'s API configuration.'**
  String get authHttpsSetupNeeded;

  /// No description provided for @authHttpRiskNotice.
  ///
  /// In en, this message translates to:
  /// **'This connection uses HTTP. Your password and token are not encrypted in transit. Use this sign-in only on a trusted network. The token stays in memory and is never saved or logged.'**
  String get authHttpRiskNotice;

  /// No description provided for @notificationsSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get notificationsSettingsTitle;

  /// No description provided for @notificationsNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not enabled for this app.'**
  String get notificationsNotEnabled;

  /// No description provided for @notificationsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is denied.'**
  String get notificationsPermissionDenied;

  /// No description provided for @notificationsPermissionProvisional.
  ///
  /// In en, this message translates to:
  /// **'Notifications are enabled quietly.'**
  String get notificationsPermissionProvisional;

  /// No description provided for @notificationsPermissionEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are enabled.'**
  String get notificationsPermissionEnabled;

  /// No description provided for @notificationsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Push notifications are unavailable on this platform.'**
  String get notificationsUnsupported;

  /// No description provided for @notificationsEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notificationsEnableAction;

  /// No description provided for @notificationsDeniedHelp.
  ///
  /// In en, this message translates to:
  /// **'To enable later, allow notifications for this app in your device settings.'**
  String get notificationsDeniedHelp;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInAction;

  /// No description provided for @authSignOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOutAction;

  /// No description provided for @authSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get authSigningIn;

  /// No description provided for @authSignedInMemory.
  ///
  /// In en, this message translates to:
  /// **'Signed in for this app session only. The token is not saved.'**
  String get authSignedInMemory;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Check the details and try again.'**
  String get authLoginFailed;

  /// No description provided for @authInvalidTokenResponse.
  ///
  /// In en, this message translates to:
  /// **'The login response did not include a usable access token.'**
  String get authInvalidTokenResponse;

  /// No description provided for @apiContractUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This feature is unavailable until the API provides the response fields and IDs it needs.'**
  String get apiContractUnavailable;

  /// No description provided for @apiDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Details are unavailable until the API provides a medication ID.'**
  String get apiDetailsUnavailable;

  /// No description provided for @errorLoadingPharmacies.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading pharmacies'**
  String get errorLoadingPharmacies;

  /// No description provided for @drugNotFound.
  ///
  /// In en, this message translates to:
  /// **'Drug not found.'**
  String get drugNotFound;

  /// No description provided for @viewAlternatives.
  ///
  /// In en, this message translates to:
  /// **'View alternatives'**
  String get viewAlternatives;

  /// No description provided for @noAlternativesFound.
  ///
  /// In en, this message translates to:
  /// **'No alternatives found for this drug.'**
  String get noAlternativesFound;

  /// No description provided for @alternativesForDrug.
  ///
  /// In en, this message translates to:
  /// **'Alternatives for {drugName}'**
  String alternativesForDrug(String drugName);

  /// No description provided for @alternativesFoundCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count} alternatives'**
  String alternativesFoundCount(int count);

  /// No description provided for @alternativesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading alternatives…'**
  String get alternativesLoading;

  /// No description provided for @homeHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your medicine or pharmacy'**
  String get homeHeaderTitle;

  /// No description provided for @homeHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the right search mode and type the name to view results.'**
  String get homeHeaderSubtitle;

  /// No description provided for @homeHeaderHelper.
  ///
  /// In en, this message translates to:
  /// **'Search by scientific name, trade name, company, agent, or pharmacy.'**
  String get homeHeaderHelper;

  /// No description provided for @homeRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads: Get an activation code'**
  String get homeRemoveAds;

  /// No description provided for @activationTitle.
  ///
  /// In en, this message translates to:
  /// **'Activation code'**
  String get activationTitle;

  /// No description provided for @activationDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your activation code. Ads stop after the server confirms activation for this installation.'**
  String get activationDescription;

  /// No description provided for @activationHttpRiskNotice.
  ///
  /// In en, this message translates to:
  /// **'Activation is unavailable until a secure connection is configured. Your saved ad setting is unchanged.'**
  String get activationHttpRiskNotice;

  /// No description provided for @activationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Activation code'**
  String get activationCodeLabel;

  /// No description provided for @activationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get activationSubmit;

  /// No description provided for @activationChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking code…'**
  String get activationChecking;

  /// No description provided for @activationUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'The server did not confirm the code\'s status. Your current ad setting has not changed.'**
  String get activationUnconfirmed;

  /// No description provided for @activationVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify the code. Please try again later.'**
  String get activationVerificationFailed;

  /// No description provided for @activationSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your API account in Settings before verifying a code.'**
  String get activationSignInRequired;

  /// No description provided for @activationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get activationOpenSettings;

  /// No description provided for @activationDeviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to obtain the device messaging token. Check your connection and try again.'**
  String get activationDeviceUnavailable;

  /// No description provided for @activationCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an activation code.'**
  String get activationCodeRequired;

  /// No description provided for @homeActionScientificTitle.
  ///
  /// In en, this message translates to:
  /// **'Search by scientific name'**
  String get homeActionScientificTitle;

  /// No description provided for @homeActionScientificSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alternatives and accurate results'**
  String get homeActionScientificSubtitle;

  /// No description provided for @homeActionTradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Search by trade name'**
  String get homeActionTradeTitle;

  /// No description provided for @homeActionTradeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search the popular names'**
  String get homeActionTradeSubtitle;

  /// No description provided for @homeActionCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search by company'**
  String get homeActionCompanyTitle;

  /// No description provided for @homeActionCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse by manufacturer'**
  String get homeActionCompanySubtitle;

  /// No description provided for @homeActionAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Search by agent'**
  String get homeActionAgentTitle;

  /// No description provided for @homeActionAgentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the supplier'**
  String get homeActionAgentSubtitle;

  /// No description provided for @homeActionPharmacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy and warehouse directory'**
  String get homeActionPharmacyTitle;

  /// No description provided for @homeActionPharmacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy directory'**
  String get homeActionPharmacySubtitle;

  /// No description provided for @homeTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick tips'**
  String get homeTipsTitle;

  /// No description provided for @homeTip1.
  ///
  /// In en, this message translates to:
  /// **'Use the scientific name to discover cheaper alternatives.'**
  String get homeTip1;

  /// No description provided for @homeTip2.
  ///
  /// In en, this message translates to:
  /// **'Try filters to narrow results by company or dosage form.'**
  String get homeTip2;

  /// No description provided for @homeTip3.
  ///
  /// In en, this message translates to:
  /// **'Save favorite drugs for fast access later.'**
  String get homeTip3;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your experience'**
  String get settingsSubtitle;

  /// No description provided for @settingsInfoCard.
  ///
  /// In en, this message translates to:
  /// **'Update your preferences and data directly from the settings page.'**
  String get settingsInfoCard;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between dark and light'**
  String get settingsThemeSubtitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Arabic / English'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn how we protect your data.'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsMedicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical notice'**
  String get settingsMedicalTitle;

  /// No description provided for @settingsMedicalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Information for reference only.'**
  String get settingsMedicalSubtitle;

  /// No description provided for @settingsAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get settingsAlertTitle;

  /// No description provided for @settingsAlertBody.
  ///
  /// In en, this message translates to:
  /// **'DigitalPharmacy provides reference information only and does not replace medical advice.'**
  String get settingsAlertBody;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'DigitalPharmacy v1.0.0'**
  String get settingsVersionLabel;

  /// No description provided for @settingsVersionDescription.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ to make finding medicine easier.'**
  String get settingsVersionDescription;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get settingsLanguageArabic;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSectionTitle;

  /// No description provided for @settingsLanguageSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the interface language'**
  String get settingsLanguageSectionSubtitle;

  /// No description provided for @settingsCountrySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Country & Currency'**
  String get settingsCountrySectionTitle;

  /// No description provided for @settingsPrivacyOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open privacy policy link'**
  String get settingsPrivacyOpenError;

  /// No description provided for @medicalReferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical references'**
  String get medicalReferencesTitle;

  /// No description provided for @medicalReferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review these external medical sources for citation and verification before relying on any medical information in the app.'**
  String get medicalReferencesSubtitle;

  /// No description provided for @medicalReferencesOpenCta.
  ///
  /// In en, this message translates to:
  /// **'Open medical sources'**
  String get medicalReferencesOpenCta;

  /// No description provided for @medicalReferencesSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical sources'**
  String get medicalReferencesSheetTitle;

  /// No description provided for @medicalReferencesSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the following sources to open the external reference and verify the information.'**
  String get medicalReferencesSheetSubtitle;

  /// No description provided for @medicalReferenceOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the medical reference link'**
  String get medicalReferenceOpenError;

  /// No description provided for @medicalSourceDailyMed.
  ///
  /// In en, this message translates to:
  /// **'DailyMed'**
  String get medicalSourceDailyMed;

  /// No description provided for @medicalSourceMedlinePlus.
  ///
  /// In en, this message translates to:
  /// **'MedlinePlus'**
  String get medicalSourceMedlinePlus;

  /// No description provided for @medicalSourceNhs.
  ///
  /// In en, this message translates to:
  /// **'NHS'**
  String get medicalSourceNhs;

  /// No description provided for @medicalSourcesEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical sources'**
  String get medicalSourcesEntryTitle;

  /// No description provided for @medicalSourcesEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the citations and references used for medical information.'**
  String get medicalSourcesEntrySubtitle;

  /// No description provided for @medicalSourcesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical sources'**
  String get medicalSourcesPageTitle;

  /// No description provided for @medicalSourcesPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Citations for the medical information shown in the app'**
  String get medicalSourcesPageSubtitle;

  /// No description provided for @medicalSourcesIntro.
  ///
  /// In en, this message translates to:
  /// **'Drug usage, alternatives, and other medical information shown in the app are for reference only. Please verify them using the external sources below and consult a doctor or pharmacist before making any medical decision.'**
  String get medicalSourcesIntro;

  /// No description provided for @iosReferenceNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference directory only'**
  String get iosReferenceNoticeTitle;

  /// No description provided for @iosReferenceNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'This section shows a reference index of drug products and general descriptive information only. The app is not a healthcare provider and does not offer diagnosis, prescriptions, or treatment advice.'**
  String get iosReferenceNoticeBody;

  /// No description provided for @iosDirectoryHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Drug index and pharmacy directory'**
  String get iosDirectoryHomeTitle;

  /// No description provided for @iosDirectoryHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse drug and pharmacy listings by name, company, agent, or category.'**
  String get iosDirectoryHomeSubtitle;

  /// No description provided for @iosDirectoryHomeHelper.
  ///
  /// In en, this message translates to:
  /// **'Content shown in the app is descriptive and reference-only for general lookup.'**
  String get iosDirectoryHomeHelper;

  /// No description provided for @iosScientificIndexNav.
  ///
  /// In en, this message translates to:
  /// **'Product index by scientific name'**
  String get iosScientificIndexNav;

  /// No description provided for @iosAllProductsNav.
  ///
  /// In en, this message translates to:
  /// **'Product index'**
  String get iosAllProductsNav;

  /// No description provided for @iosSearchSubtitleScientific.
  ///
  /// In en, this message translates to:
  /// **'Browse products linked to the scientific name.'**
  String get iosSearchSubtitleScientific;

  /// No description provided for @iosSearchSubtitleCompany.
  ///
  /// In en, this message translates to:
  /// **'Browse products by manufacturer.'**
  String get iosSearchSubtitleCompany;

  /// No description provided for @iosSearchSubtitleAll.
  ///
  /// In en, this message translates to:
  /// **'Browse the full available product index.'**
  String get iosSearchSubtitleAll;

  /// No description provided for @iosSearchHintAll.
  ///
  /// In en, this message translates to:
  /// **'Search by product name, scientific name, company, or agent…'**
  String get iosSearchHintAll;

  /// No description provided for @iosEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'No matching results were found in the product index.'**
  String get iosEmptyAll;

  /// No description provided for @iosScientificDrugsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product index by scientific name'**
  String get iosScientificDrugsTitle;

  /// No description provided for @iosScientificDrugsCount.
  ///
  /// In en, this message translates to:
  /// **'Products count: {count}'**
  String iosScientificDrugsCount(int count);

  /// No description provided for @iosScientificDrugsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No products are currently listed for this scientific name.'**
  String get iosScientificDrugsEmpty;

  /// No description provided for @iosProductNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get iosProductNameLabel;

  /// No description provided for @iosReferenceInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference note'**
  String get iosReferenceInfoLabel;

  /// No description provided for @iosSimilarProductsLabel.
  ///
  /// In en, this message translates to:
  /// **'Similar products'**
  String get iosSimilarProductsLabel;

  /// No description provided for @iosViewSimilarProducts.
  ///
  /// In en, this message translates to:
  /// **'View similar products'**
  String get iosViewSimilarProducts;

  /// No description provided for @iosSimilarProductsForDrug.
  ///
  /// In en, this message translates to:
  /// **'Similar products for {drugName}'**
  String iosSimilarProductsForDrug(String drugName);

  /// No description provided for @iosNoSimilarProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No similar products are currently listed for this item.'**
  String get iosNoSimilarProductsFound;

  /// No description provided for @iosProductFormsLabel.
  ///
  /// In en, this message translates to:
  /// **'Available product forms'**
  String get iosProductFormsLabel;

  /// No description provided for @countryJordan.
  ///
  /// In en, this message translates to:
  /// **'Jordan'**
  String get countryJordan;

  /// No description provided for @countryPalestine.
  ///
  /// In en, this message translates to:
  /// **'Palestine'**
  String get countryPalestine;

  /// No description provided for @countryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm country'**
  String get countryConfirmTitle;

  /// No description provided for @countryConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you from {country}?'**
  String countryConfirmMessage(String country);

  /// No description provided for @countryChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your country'**
  String get countryChooseTitle;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navScientific.
  ///
  /// In en, this message translates to:
  /// **'Search by scientific name'**
  String get navScientific;

  /// No description provided for @navTrade.
  ///
  /// In en, this message translates to:
  /// **'Search by trade name'**
  String get navTrade;

  /// No description provided for @navCompany.
  ///
  /// In en, this message translates to:
  /// **'Search by company'**
  String get navCompany;

  /// No description provided for @navAgent.
  ///
  /// In en, this message translates to:
  /// **'Search by agent'**
  String get navAgent;

  /// No description provided for @navPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Search by pharmacy'**
  String get navPharmacy;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navAllDrugs.
  ///
  /// In en, this message translates to:
  /// **'Drug search'**
  String get navAllDrugs;

  /// No description provided for @drawerActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate extra features'**
  String get drawerActivate;

  /// No description provided for @searchSubtitleScientific.
  ///
  /// In en, this message translates to:
  /// **'Search scientific names and find alternatives.'**
  String get searchSubtitleScientific;

  /// No description provided for @searchSubtitleTrade.
  ///
  /// In en, this message translates to:
  /// **'Search the popular trade names.'**
  String get searchSubtitleTrade;

  /// No description provided for @searchSubtitleCompany.
  ///
  /// In en, this message translates to:
  /// **'Browse drugs by manufacturer.'**
  String get searchSubtitleCompany;

  /// No description provided for @searchSubtitleAgent.
  ///
  /// In en, this message translates to:
  /// **'Browse products by agent.'**
  String get searchSubtitleAgent;

  /// No description provided for @searchSubtitleAll.
  ///
  /// In en, this message translates to:
  /// **'The same pharmacy experience for all drugs.'**
  String get searchSubtitleAll;

  /// No description provided for @snackCopiedDrug.
  ///
  /// In en, this message translates to:
  /// **'Drug info copied'**
  String get snackCopiedDrug;

  /// No description provided for @snackComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get snackComingSoon;

  /// No description provided for @labelCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get labelCompany;

  /// No description provided for @labelForm.
  ///
  /// In en, this message translates to:
  /// **'Dosage form'**
  String get labelForm;

  /// No description provided for @labelStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get labelStrength;

  /// No description provided for @labelPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get labelPrice;

  /// No description provided for @labelOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get labelOrigin;

  /// No description provided for @labelScientificName.
  ///
  /// In en, this message translates to:
  /// **'Scientific name'**
  String get labelScientificName;

  /// No description provided for @labelTradeName.
  ///
  /// In en, this message translates to:
  /// **'Trade name'**
  String get labelTradeName;

  /// No description provided for @labelManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get labelManufacturer;

  /// No description provided for @labelAgentName.
  ///
  /// In en, this message translates to:
  /// **'Agent name'**
  String get labelAgentName;

  /// No description provided for @labelAgentNumber.
  ///
  /// In en, this message translates to:
  /// **'Agent number'**
  String get labelAgentNumber;

  /// No description provided for @labelAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get labelAgent;

  /// No description provided for @labelUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get labelUsage;

  /// No description provided for @labelDosageForms.
  ///
  /// In en, this message translates to:
  /// **'Dosage forms'**
  String get labelDosageForms;

  /// No description provided for @labelAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Alternatives'**
  String get labelAlternatives;

  /// No description provided for @actionShowForms.
  ///
  /// In en, this message translates to:
  /// **'Pharmaceutical forms'**
  String get actionShowForms;

  /// No description provided for @actionShowAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Show alternatives'**
  String get actionShowAlternatives;

  /// No description provided for @tooltipCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get tooltipCopy;

  /// No description provided for @tooltipCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get tooltipCall;

  /// No description provided for @dosageFormsTitle.
  ///
  /// In en, this message translates to:
  /// **'Dosage forms'**
  String get dosageFormsTitle;

  /// No description provided for @dosageFormsPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get dosageFormsPrice;

  /// No description provided for @dosageFormsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dosageFormsClose;

  /// No description provided for @pharmaceuticalForms.
  ///
  /// In en, this message translates to:
  /// **'Pharmaceutical forms'**
  String get pharmaceuticalForms;

  /// No description provided for @loadingForms.
  ///
  /// In en, this message translates to:
  /// **'Loading forms...'**
  String get loadingForms;

  /// No description provided for @noFormsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No pharmaceutical forms available.'**
  String get noFormsAvailable;

  /// No description provided for @formsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load forms.'**
  String get formsLoadFailed;

  /// No description provided for @valueNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get valueNotAvailable;

  /// No description provided for @drugCardTrade.
  ///
  /// In en, this message translates to:
  /// **'Trade name'**
  String get drugCardTrade;

  /// No description provided for @drugCardCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get drugCardCompany;

  /// No description provided for @drugCardAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get drugCardAgent;

  /// No description provided for @drugCardScientific.
  ///
  /// In en, this message translates to:
  /// **'Scientific name'**
  String get drugCardScientific;

  /// No description provided for @drugCardButtonForms.
  ///
  /// In en, this message translates to:
  /// **'Dosage forms'**
  String get drugCardButtonForms;

  /// No description provided for @pharmaciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Directory'**
  String get pharmaciesTitle;

  /// No description provided for @pharmaciesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Directory with quick search'**
  String get pharmaciesSubtitle;

  /// No description provided for @pharmacyModeName.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy name'**
  String get pharmacyModeName;

  /// No description provided for @pharmacyModeAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get pharmacyModeAddress;

  /// No description provided for @pharmacyModeManager.
  ///
  /// In en, this message translates to:
  /// **'Manager name'**
  String get pharmacyModeManager;

  /// No description provided for @pharmacyModePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get pharmacyModePhone;

  /// No description provided for @pharmacyHintName.
  ///
  /// In en, this message translates to:
  /// **'Type the pharmacy name'**
  String get pharmacyHintName;

  /// No description provided for @pharmacyHintAddress.
  ///
  /// In en, this message translates to:
  /// **'Type the address'**
  String get pharmacyHintAddress;

  /// No description provided for @pharmacyHintManager.
  ///
  /// In en, this message translates to:
  /// **'Type the manager\'s name'**
  String get pharmacyHintManager;

  /// No description provided for @pharmacyHintPhone.
  ///
  /// In en, this message translates to:
  /// **'Type the phone number'**
  String get pharmacyHintPhone;

  /// No description provided for @pharmaciesSearchBy.
  ///
  /// In en, this message translates to:
  /// **'Search by: {mode}'**
  String pharmaciesSearchBy(String mode);

  /// No description provided for @pharmaciesMatches.
  ///
  /// In en, this message translates to:
  /// **'Matching pharmacies: {count}'**
  String pharmaciesMatches(int count);

  /// No description provided for @pharmaciesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pharmacies found. Try another filter.'**
  String get pharmaciesEmpty;

  /// No description provided for @pharmacyDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy info'**
  String get pharmacyDetailsSubtitle;

  /// No description provided for @pharmacyAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get pharmacyAddress;

  /// No description provided for @pharmacyManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get pharmacyManager;

  /// No description provided for @pharmacyPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get pharmacyPhone;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite drugs'**
  String get favoritesTitle;

  /// No description provided for @favoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you saved in one place'**
  String get favoritesSubtitle;

  /// No description provided for @favoritesCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal list'**
  String get favoritesCardTitle;

  /// No description provided for @favoritesCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} saved medications'**
  String favoritesCardSubtitle(int count);

  /// No description provided for @favoritesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search inside favorites…'**
  String get favoritesSearchHint;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorite drugs yet.\nAdd them from the details page.'**
  String get favoritesEmpty;

  /// No description provided for @queryBarHint.
  ///
  /// In en, this message translates to:
  /// **'Type a phrase to search…'**
  String get queryBarHint;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'Results: {count}'**
  String resultsCount(int count);

  /// No description provided for @matchingResultsCount.
  ///
  /// In en, this message translates to:
  /// **'Matching results: {count}'**
  String matchingResultsCount(int count);

  /// No description provided for @drugsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Drugs'**
  String get drugsPageTitle;

  /// No description provided for @drugsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy-style explorer for all drugs'**
  String get drugsPageSubtitle;

  /// No description provided for @drugsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by drug name, scientific name, company, or agent…'**
  String get drugsSearchHint;

  /// No description provided for @drugsMatches.
  ///
  /// In en, this message translates to:
  /// **'Matching drugs: {count}'**
  String drugsMatches(int count);

  /// No description provided for @drugsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching drugs. Try another term.'**
  String get drugsEmpty;

  /// No description provided for @tradeDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trade name details'**
  String get tradeDetailsSubtitle;

  /// No description provided for @tradeDetailsCount.
  ///
  /// In en, this message translates to:
  /// **'Matching formulations: {count}'**
  String tradeDetailsCount(int count);

  /// No description provided for @tradeDetailsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data available for this trade name.'**
  String get tradeDetailsEmpty;

  /// No description provided for @companyDrugsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Products from this company'**
  String get companyDrugsSubtitle;

  /// No description provided for @catalogCountryUnverified.
  ///
  /// In en, this message translates to:
  /// **'The API has no verified country mapping for this catalog; results may not match the selected country.'**
  String get catalogCountryUnverified;

  /// No description provided for @companyDrugsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No registered drugs for this company.'**
  String get companyDrugsEmpty;

  /// No description provided for @agentDrugsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drugs for this agent'**
  String get agentDrugsSubtitle;

  /// No description provided for @agentDrugsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No registered drugs for this agent.'**
  String get agentDrugsEmpty;

  /// No description provided for @scientificDrugsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scientific name drugs'**
  String get scientificDrugsTitle;

  /// No description provided for @scientificDrugsCount.
  ///
  /// In en, this message translates to:
  /// **'Drugs: {count}'**
  String scientificDrugsCount(int count);

  /// No description provided for @scientificDrugsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No drugs currently recorded for this scientific name.'**
  String get scientificDrugsEmpty;

  /// No description provided for @searchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'Results: {count}'**
  String searchResultsCount(int count);

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results. Try another keyword.'**
  String get searchNoResults;

  /// No description provided for @searchHintScientific.
  ///
  /// In en, this message translates to:
  /// **'Type the scientific name…'**
  String get searchHintScientific;

  /// No description provided for @searchHintTrade.
  ///
  /// In en, this message translates to:
  /// **'Type the trade name…'**
  String get searchHintTrade;

  /// No description provided for @searchHintCompany.
  ///
  /// In en, this message translates to:
  /// **'Type the company name…'**
  String get searchHintCompany;

  /// No description provided for @searchHintAgent.
  ///
  /// In en, this message translates to:
  /// **'Type the agent name…'**
  String get searchHintAgent;

  /// No description provided for @searchHintDrug.
  ///
  /// In en, this message translates to:
  /// **'Search by drug or company name…'**
  String get searchHintDrug;

  /// No description provided for @emptyScientific.
  ///
  /// In en, this message translates to:
  /// **'No drugs registered for this scientific name yet.'**
  String get emptyScientific;

  /// No description provided for @emptyTrade.
  ///
  /// In en, this message translates to:
  /// **'No data for this trade name.'**
  String get emptyTrade;

  /// No description provided for @emptyCompany.
  ///
  /// In en, this message translates to:
  /// **'No drugs for this company.'**
  String get emptyCompany;

  /// No description provided for @emptyAgent.
  ///
  /// In en, this message translates to:
  /// **'No drugs registered for this agent.'**
  String get emptyAgent;

  /// No description provided for @emptyAll.
  ///
  /// In en, this message translates to:
  /// **'No matching results. Try a different phrase.'**
  String get emptyAll;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @languageSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSectionSubtitle;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @adPrivacyOptions.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy choices'**
  String get adPrivacyOptions;

  /// No description provided for @reportAdTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an inappropriate ad'**
  String get reportAdTitle;

  /// No description provided for @reportAdDescription.
  ///
  /// In en, this message translates to:
  /// **'Report harmful or age-inappropriate advertising to Google.'**
  String get reportAdDescription;

  /// No description provided for @storeEntitlementUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Custom activation codes are unavailable on this platform. Ad-free access requires a supported store entitlement.'**
  String get storeEntitlementUnavailable;

  /// No description provided for @loadMoreResults.
  ///
  /// In en, this message translates to:
  /// **'Load more results'**
  String get loadMoreResults;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Save medication'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove saved medication'**
  String get removeFavorite;

  /// No description provided for @legacyFavoritesRetained.
  ///
  /// In en, this message translates to:
  /// **'Your earlier saved items are retained. Select them again from the server catalogue to link their current details.'**
  String get legacyFavoritesRetained;

  /// No description provided for @activationConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Activation confirmed. All ads are off.'**
  String get activationConfirmed;

  /// No description provided for @activationNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The server confirmed activation, but the app could not save it. Ads are paused; try again.'**
  String get activationNotSaved;

  /// No description provided for @activationRejected.
  ///
  /// In en, this message translates to:
  /// **'The activation code was not accepted.'**
  String get activationRejected;

  /// No description provided for @selectionCountryChanged.
  ///
  /// In en, this message translates to:
  /// **'Country changed. Go back and choose a result for the selected country.'**
  String get selectionCountryChanged;

  /// No description provided for @priceCurrencyUnspecified.
  ///
  /// In en, this message translates to:
  /// **'currency unspecified'**
  String get priceCurrencyUnspecified;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
