// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ديجيتال فارماسي';

  @override
  String get appTagline => 'Digital Pharmacy';

  @override
  String get commonOk => 'حسناً';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonAdPlaceholder => 'مساحة إعلانية';

  @override
  String get commonComingSoon => 'قريباً';

  @override
  String get commonCopySuccess => 'تم نسخ الرقم';

  @override
  String get commonCall => 'اتصال';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get errorLoadingData => 'حدث خطأ أثناء تحميل البيانات';

  @override
  String get apiAuthenticationRequired =>
      'يتعذر الوصول إلى الخدمة. يرجى المحاولة لاحقاً.';

  @override
  String get authSettingsTitle => 'حساب API';

  @override
  String get authHttpsSetupNeeded =>
      'تم تعطيل تسجيل الدخول لعنوان API هذا. تحقق من إعداد عنوان API في التطبيق.';

  @override
  String get authHttpRiskNotice =>
      'يستخدم هذا الاتصال HTTP. لا تُشفّر كلمة المرور والرمز أثناء النقل. استخدم تسجيل الدخول هذا على شبكة موثوقة فقط. يبقى الرمز في الذاكرة ولا يُحفظ أو يُسجّل.';

  @override
  String get notificationsSettingsTitle => 'الإشعارات الفورية';

  @override
  String get notificationsNotEnabled => 'الإشعارات غير مفعّلة لهذا التطبيق.';

  @override
  String get notificationsPermissionDenied => 'تم رفض إذن الإشعارات.';

  @override
  String get notificationsPermissionProvisional => 'الإشعارات مفعّلة بصمت.';

  @override
  String get notificationsPermissionEnabled => 'الإشعارات مفعّلة.';

  @override
  String get notificationsUnsupported =>
      'الإشعارات الفورية غير متاحة على هذه المنصة.';

  @override
  String get notificationsEnableAction => 'تفعيل الإشعارات';

  @override
  String get notificationsDeniedHelp =>
      'لتفعيلها لاحقاً، اسمح بإشعارات هذا التطبيق من إعدادات الجهاز.';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authSignInAction => 'تسجيل الدخول';

  @override
  String get authSignOutAction => 'تسجيل الخروج';

  @override
  String get authSigningIn => 'جارٍ تسجيل الدخول…';

  @override
  String get authSignedInMemory =>
      'تظل الجلسة داخل التطبيق فقط، ولا يُحفظ رمز الدخول.';

  @override
  String get authLoginFailed =>
      'تعذر تسجيل الدخول. تحقق من البيانات وحاول مجدداً.';

  @override
  String get authInvalidTokenResponse =>
      'لم تتضمن استجابة الدخول رمز وصول صالحاً.';

  @override
  String get apiContractUnavailable =>
      'هذه الميزة غير متاحة حتى يوفّر API الحقول والمعرّفات اللازمة.';

  @override
  String get apiDetailsUnavailable =>
      'التفاصيل غير متاحة حتى يوفّر API معرّف الدواء.';

  @override
  String get errorLoadingPharmacies => 'حدث خطأ أثناء تحميل الصيدليات';

  @override
  String get drugNotFound => 'الدواء غير موجود.';

  @override
  String get viewAlternatives => 'عرض بدائل هذا الدواء';

  @override
  String get noAlternativesFound => 'لا توجد بدائل لهذا الدواء';

  @override
  String alternativesForDrug(String drugName) {
    return 'بدائل $drugName';
  }

  @override
  String alternativesFoundCount(int count) {
    return 'تم العثور على $count بدائل';
  }

  @override
  String get alternativesLoading => 'جارٍ تحميل البدائل...';

  @override
  String get homeHeaderTitle => 'ابحث عن دوائك أو الصيدلية';

  @override
  String get homeHeaderSubtitle =>
      'اختر طريقة البحث المناسبة ثم اكتب الاسم للحصول على النتائج.';

  @override
  String get homeHeaderHelper =>
      'يمكنك البحث بالاسم العلمي، التجاري، الشركة، الوكيل أو الصيدلية.';

  @override
  String get homeRemoveAds => 'لإزالة الإعلانات: احصل على كود التفعيل';

  @override
  String get activationTitle => 'كود التفعيل';

  @override
  String get activationDescription =>
      'أدخل كود التفعيل. تتوقف الإعلانات بعد تأكيد الخادم تفعيل هذا التثبيت.';

  @override
  String get activationHttpRiskNotice =>
      'التفعيل غير متاح حتى يتم إعداد اتصال آمن. لم يتغير إعداد الإعلانات المحفوظ.';

  @override
  String get activationCodeLabel => 'كود التفعيل';

  @override
  String get activationSubmit => 'تحقق من الكود';

  @override
  String get activationChecking => 'جارٍ التحقق من الكود…';

  @override
  String get activationUnconfirmed =>
      'لم يؤكّد الخادم حالة الكود. لم يتغير وضع الإعلانات الحالي.';

  @override
  String get activationVerificationFailed =>
      'تعذر التحقق من الكود. يرجى المحاولة لاحقاً.';

  @override
  String get activationSignInRequired =>
      'سجّل الدخول إلى حساب API من الإعدادات قبل التحقق من الكود.';

  @override
  String get activationOpenSettings => 'فتح الإعدادات';

  @override
  String get activationDeviceUnavailable =>
      'تعذر الحصول على رمز الجهاز من Firebase. تحقق من الاتصال ثم أعد المحاولة.';

  @override
  String get activationCodeRequired => 'أدخل كود التفعيل.';

  @override
  String get homeActionScientificTitle => 'البحث بالاسم العلمي';

  @override
  String get homeActionScientificSubtitle => 'بدائل ونتائج دقيقة';

  @override
  String get homeActionTradeTitle => 'البحث بالاسم التجاري';

  @override
  String get homeActionTradeSubtitle => 'ابحث بالاسم الشائع';

  @override
  String get homeActionCompanyTitle => 'البحث باسم الشركة';

  @override
  String get homeActionCompanySubtitle => 'حسب الشركة المصنّعة';

  @override
  String get homeActionAgentTitle => 'البحث باسم الوكيل';

  @override
  String get homeActionAgentSubtitle => 'اعثر على المورد';

  @override
  String get homeActionPharmacyTitle => 'دليل الصيدليات والمستودعات';

  @override
  String get homeActionPharmacySubtitle => 'دليل الصيدليات';

  @override
  String get homeTipsTitle => 'نصائح سريعة';

  @override
  String get homeTip1 => 'استخدم الاسم العلمي للعثور على بدائل أرخص.';

  @override
  String get homeTip2 => 'جرّب الفلاتر لتضييق النتائج حسب الشركة أو الشكل.';

  @override
  String get homeTip3 => 'يمكنك حفظ الأدوية المفضلة للوصول السريع لاحقاً.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSubtitle => 'خصّص تجربتك';

  @override
  String get settingsInfoCard =>
      'خصّص تجربتك وحدّث بياناتك بسهولة من صفحة الإعدادات.';

  @override
  String get settingsThemeTitle => 'الوضع الليلي';

  @override
  String get settingsThemeSubtitle => 'تبديل بين الداكن والفاتح';

  @override
  String get settingsLanguageTitle => 'اللغة';

  @override
  String get settingsLanguageSubtitle => 'العربية / الإنجليزية';

  @override
  String get settingsPrivacyTitle => 'سياسة الخصوصية';

  @override
  String get settingsPrivacySubtitle => 'تعرف على كيفية حماية بياناتك.';

  @override
  String get settingsMedicalTitle => 'تنبيه طبي';

  @override
  String get settingsMedicalSubtitle => 'المعلومات للاستدلال فقط.';

  @override
  String get settingsAlertTitle => 'تنبيه';

  @override
  String get settingsAlertBody =>
      'DigitalPharmacy يوفر معلومات مرجعية فقط ولا يغني عن استشارة الطبيب أو الصيدلي.';

  @override
  String get settingsVersionLabel => 'DigitalPharmacy v1.0.0';

  @override
  String get settingsVersionDescription => 'صنع بحب ❤️ لتسهيل إيجاد الدواء.';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageSectionTitle => 'اللغة';

  @override
  String get settingsLanguageSectionSubtitle => 'اختر لغة الواجهة';

  @override
  String get settingsCountrySectionTitle => 'الدولة والعملة';

  @override
  String get settingsPrivacyOpenError => 'تعذر فتح رابط سياسة الخصوصية';

  @override
  String get medicalReferencesTitle => 'المصادر الطبية';

  @override
  String get medicalReferencesSubtitle =>
      'راجع هذه المصادر الطبية الخارجية للتوثيق والتحقق قبل الاعتماد على أي معلومة طبية داخل التطبيق.';

  @override
  String get medicalReferencesOpenCta => 'عرض المصادر الطبية';

  @override
  String get medicalReferencesSheetTitle => 'المصادر الطبية';

  @override
  String get medicalReferencesSheetSubtitle =>
      'اختر أحد المصادر التالية لفتح المرجع الخارجي والتحقق من المعلومة.';

  @override
  String get medicalReferenceOpenError => 'تعذر فتح رابط المصدر الطبي';

  @override
  String get medicalSourceDailyMed => 'DailyMed';

  @override
  String get medicalSourceMedlinePlus => 'MedlinePlus';

  @override
  String get medicalSourceNhs => 'NHS';

  @override
  String get medicalSourcesEntryTitle => 'المصادر الطبية';

  @override
  String get medicalSourcesEntrySubtitle =>
      'افتح التوثيقات والمراجع الخاصة بالمعلومات الطبية داخل التطبيق.';

  @override
  String get medicalSourcesPageTitle => 'المصادر الطبية';

  @override
  String get medicalSourcesPageSubtitle =>
      'توثيقات للمعلومات الطبية المعروضة داخل التطبيق';

  @override
  String get medicalSourcesIntro =>
      'معلومات الاستخدام والبدائل وغيرها من المعلومات الطبية داخل التطبيق هي للاستدلال فقط. يُرجى التحقق منها من المصادر الخارجية التالية واستشارة الطبيب أو الصيدلي قبل اتخاذ أي قرار طبي.';

  @override
  String get iosReferenceNoticeTitle => 'دليل مرجعي فقط';

  @override
  String get iosReferenceNoticeBody =>
      'هذا القسم يعرض فهرسًا مرجعيًا للمنتجات الدوائية ومعلومات تعريفية عامة فقط. لا يُعد هذا التطبيق مزود خدمة صحية ولا يقدم تشخيصًا أو وصفًا أو نصيحة علاجية.';

  @override
  String get iosDirectoryHomeTitle => 'فهرس الأدوية ودليل الصيدليات';

  @override
  String get iosDirectoryHomeSubtitle =>
      'استعرض قوائم الأدوية والصيدليات حسب الاسم أو الشركة أو الوكيل أو الفئة.';

  @override
  String get iosDirectoryHomeHelper =>
      'المحتوى داخل التطبيق مرجعي وتعريفي ويُستخدم للاستدلال العام فقط.';

  @override
  String get iosScientificIndexNav => 'فهرس المنتجات حسب الاسم العلمي';

  @override
  String get iosAllProductsNav => 'فهرس المنتجات';

  @override
  String get iosSearchSubtitleScientific =>
      'استعرض المنتجات المرتبطة بالاسم العلمي.';

  @override
  String get iosSearchSubtitleCompany => 'استعرض المنتجات حسب الشركة المصنّعة.';

  @override
  String get iosSearchSubtitleAll => 'استعرض كامل فهرس المنتجات المتاح.';

  @override
  String get iosSearchHintAll =>
      'ابحث باسم المنتج أو الاسم العلمي أو الشركة أو الوكيل…';

  @override
  String get iosEmptyAll => 'لا توجد نتائج مطابقة ضمن فهرس المنتجات.';

  @override
  String get iosScientificDrugsTitle => 'فهرس المنتجات حسب الاسم العلمي';

  @override
  String iosScientificDrugsCount(int count) {
    return 'عدد المنتجات: $count';
  }

  @override
  String get iosScientificDrugsEmpty =>
      'لا توجد منتجات مسجلة لهذا الاسم العلمي حاليًا.';

  @override
  String get iosProductNameLabel => 'اسم المنتج';

  @override
  String get iosReferenceInfoLabel => 'معلومة مرجعية';

  @override
  String get iosSimilarProductsLabel => 'منتجات مشابهة';

  @override
  String get iosViewSimilarProducts => 'عرض منتجات مشابهة';

  @override
  String iosSimilarProductsForDrug(String drugName) {
    return 'منتجات مشابهة لـ $drugName';
  }

  @override
  String get iosNoSimilarProductsFound =>
      'لا توجد منتجات مشابهة ظاهرة حاليًا لهذا المنتج.';

  @override
  String get iosProductFormsLabel => 'أشكال المنتج المتاحة';

  @override
  String get countryJordan => 'الأردن';

  @override
  String get countryPalestine => 'فلسطين';

  @override
  String get countryConfirmTitle => 'تأكيد الدولة';

  @override
  String countryConfirmMessage(String country) {
    return 'هل أنت من $country؟';
  }

  @override
  String get countryChooseTitle => 'اختر دولتك';

  @override
  String get commonYes => 'نعم';

  @override
  String get commonNo => 'لا';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navScientific => 'البحث بالاسم العلمي';

  @override
  String get navTrade => 'البحث بالاسم التجاري';

  @override
  String get navCompany => 'البحث باسم الشركة';

  @override
  String get navAgent => 'البحث باسم الوكيل';

  @override
  String get navPharmacy => 'البحث باسم الصيدلية';

  @override
  String get navFavorites => 'المفضلة';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navAllDrugs => 'البحث عن دواء';

  @override
  String get drawerActivate => 'تفعيل مزايا إضافية';

  @override
  String get searchSubtitleScientific =>
      'ابحث بالأسماء العلمية واحصل على البدائل.';

  @override
  String get searchSubtitleTrade => 'ابحث بالأسماء التجارية الشائعة.';

  @override
  String get searchSubtitleCompany => 'اعرض الأدوية حسب الشركة المصنّعة.';

  @override
  String get searchSubtitleAgent => 'استعرض المنتجات حسب الوكيل.';

  @override
  String get searchSubtitleAll => 'نفس تجربة الصيدليات لكن لكامل الأدوية.';

  @override
  String get snackCopiedDrug => 'تم نسخ معلومات الدواء';

  @override
  String get snackComingSoon => 'قريباً';

  @override
  String get labelCompany => 'الشركة';

  @override
  String get labelForm => 'الشكل';

  @override
  String get labelStrength => 'العيار';

  @override
  String get labelPrice => 'السعر';

  @override
  String get labelOrigin => 'المنشأ';

  @override
  String get labelScientificName => 'الاسم العلمي';

  @override
  String get labelTradeName => 'الاسم التجاري';

  @override
  String get labelManufacturer => 'المصنّع';

  @override
  String get labelAgentName => 'اسم الوكيل';

  @override
  String get labelAgentNumber => 'رقم الوكيل';

  @override
  String get labelAgent => 'الوكيل';

  @override
  String get labelUsage => 'الاستخدام';

  @override
  String get labelDosageForms => 'الأشكال الصيدلانية';

  @override
  String get labelAlternatives => 'البدائل';

  @override
  String get actionShowForms => 'الأشكال الصيدلانية';

  @override
  String get actionShowAlternatives => 'عرض البدائل';

  @override
  String get tooltipCopy => 'نسخ';

  @override
  String get tooltipCall => 'اتصال';

  @override
  String get dosageFormsTitle => 'الأشكال الصيدلانية';

  @override
  String get dosageFormsPrice => 'السعر';

  @override
  String get dosageFormsClose => 'إغلاق';

  @override
  String get pharmaceuticalForms => 'الأشكال الصيدلانية';

  @override
  String get loadingForms => 'جاري تحميل الأشكال...';

  @override
  String get noFormsAvailable => 'لا توجد أشكال صيدلانية متاحة.';

  @override
  String get formsLoadFailed => 'حدث خطأ أثناء تحميل الأشكال.';

  @override
  String get valueNotAvailable => 'غير متوفر';

  @override
  String get drugCardTrade => 'اسم الدواء';

  @override
  String get drugCardCompany => 'الشركة';

  @override
  String get drugCardAgent => 'الوكيل';

  @override
  String get drugCardScientific => 'الاسم العلمي';

  @override
  String get drugCardButtonForms => 'الأشكال الصيدلانية';

  @override
  String get pharmaciesTitle => 'دليل الصيدليات';

  @override
  String get pharmaciesSubtitle => 'دليل الصيدليات مع البحث السريع';

  @override
  String get pharmacyModeName => 'اسم الصيدلية';

  @override
  String get pharmacyModeAddress => 'العنوان';

  @override
  String get pharmacyModeManager => 'اسم المسؤول';

  @override
  String get pharmacyModePhone => 'رقم الهاتف';

  @override
  String get pharmacyHintName => 'اكتب اسم الصيدلية للبحث';

  @override
  String get pharmacyHintAddress => 'اكتب العنوان للبحث';

  @override
  String get pharmacyHintManager => 'اكتب اسم المسؤول للبحث';

  @override
  String get pharmacyHintPhone => 'اكتب رقم الهاتف للبحث';

  @override
  String pharmaciesSearchBy(String mode) {
    return 'البحث حسب: $mode';
  }

  @override
  String pharmaciesMatches(int count) {
    return 'عدد الصيدليات المطابقة: $count';
  }

  @override
  String get pharmaciesEmpty =>
      'لم يتم العثور على صيدليات مطابقة. جرّب تصنيفاً آخر.';

  @override
  String get pharmacyDetailsSubtitle => 'بيانات الصيدلية';

  @override
  String get pharmacyAddress => 'العنوان';

  @override
  String get pharmacyManager => 'اسم المسؤول';

  @override
  String get pharmacyPhone => 'الهاتف';

  @override
  String get favoritesTitle => 'الأدوية المفضلة';

  @override
  String get favoritesSubtitle => 'كل ما حفظته في مكان واحد';

  @override
  String get favoritesCardTitle => 'قائمتك الخاصة';

  @override
  String favoritesCardSubtitle(int count) {
    return '$count وصفة محفوظة';
  }

  @override
  String get favoritesSearchHint => 'ابحث داخل المفضلة…';

  @override
  String get favoritesEmpty =>
      'لا يوجد أدوية مفضلة بعد.\nأضف الأدوية من صفحة التفاصيل.';

  @override
  String get queryBarHint => 'اكتب عبارة للبحث…';

  @override
  String resultsCount(int count) {
    return 'عدد النتائج: $count';
  }

  @override
  String matchingResultsCount(int count) {
    return 'عدد النتائج المطابقة: $count';
  }

  @override
  String get drugsPageTitle => 'الأدوية';

  @override
  String get drugsPageSubtitle => 'نفس تجربة الصيدليات لكن لكامل الأدوية';

  @override
  String get drugsSearchHint =>
      'ابحث باسم الدواء أو الاسم العلمي أو الشركة أو الوكيل…';

  @override
  String drugsMatches(int count) {
    return 'عدد الأدوية المطابقة: $count';
  }

  @override
  String get drugsEmpty => 'لا توجد نتائج مطابقة. جرّب كلمة أخرى.';

  @override
  String get tradeDetailsSubtitle => 'تفاصيل الاسم التجاري';

  @override
  String tradeDetailsCount(int count) {
    return 'عدد التركيبات المطابقة: $count';
  }

  @override
  String get tradeDetailsEmpty => 'لا توجد بيانات متاحة لهذا الاسم التجاري.';

  @override
  String get companyDrugsSubtitle => 'منتجات هذه الشركة';

  @override
  String get catalogCountryUnverified =>
      'لا يوفّر API ربطًا موثوقًا للدولة ضمن هذا الدليل؛ قد لا تطابق النتائج الدولة المحددة.';

  @override
  String get companyDrugsEmpty => 'لا توجد أدوية مسجّلة لهذه الشركة.';

  @override
  String get agentDrugsSubtitle => 'الأدوية التابعة لهذا الوكيل';

  @override
  String get agentDrugsEmpty => 'لا توجد أدوية مسجّلة لهذا الوكيل.';

  @override
  String get scientificDrugsTitle => 'أدوية الاسم العلمي';

  @override
  String scientificDrugsCount(int count) {
    return 'عدد الأدوية: $count';
  }

  @override
  String get scientificDrugsEmpty =>
      'لا توجد أدوية مسجلة لهذا الاسم العلمي حالياً.';

  @override
  String searchResultsCount(int count) {
    return 'عدد النتائج: $count';
  }

  @override
  String get searchNoResults => 'لا توجد نتائج مطابقة. جرّب عبارة أخرى.';

  @override
  String get searchHintScientific => 'اكتب الاسم العلمي…';

  @override
  String get searchHintTrade => 'اكتب الاسم التجاري…';

  @override
  String get searchHintCompany => 'اكتب اسم الشركة…';

  @override
  String get searchHintAgent => 'اكتب اسم الوكيل…';

  @override
  String get searchHintDrug => 'ابحث باسم الدواء أو الشركة…';

  @override
  String get emptyScientific => 'لا توجد أدوية مسجلة لهذا الاسم العلمي حالياً.';

  @override
  String get emptyTrade => 'لا توجد بيانات لهذا الاسم التجاري.';

  @override
  String get emptyCompany => 'لا توجد أدوية تابعة لهذه الشركة.';

  @override
  String get emptyAgent => 'لا توجد أدوية مسجلة لهذا الوكيل.';

  @override
  String get emptyAll => 'لا توجد نتائج مطابقة. جرّب عبارة مختلفة.';

  @override
  String get languageSectionTitle => 'اللغة';

  @override
  String get languageSectionSubtitle => 'اختر اللغة المفضلة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get adPrivacyOptions => 'خيارات خصوصية الإعلانات';

  @override
  String get reportAdTitle => 'الإبلاغ عن إعلان غير مناسب';

  @override
  String get reportAdDescription =>
      'أبلغ Google عن إعلان ضار أو غير مناسب للعمر.';

  @override
  String get storeEntitlementUnavailable =>
      'أكواد التفعيل الخاصة غير متاحة على هذه المنصة. تتطلب إزالة الإعلانات استحقاقاً مدعوماً من المتجر.';

  @override
  String get loadMoreResults => 'عرض المزيد من النتائج';

  @override
  String get addFavorite => 'حفظ الدواء';

  @override
  String get removeFavorite => 'إزالة الدواء المحفوظ';

  @override
  String get legacyFavoritesRetained =>
      'العناصر المحفوظة سابقاً ما زالت محفوظة. أعد اختيارها من دليل الخادم لربط تفاصيلها الحالية.';

  @override
  String get activationConfirmed => 'تم تأكيد التفعيل. جميع الإعلانات متوقفة.';

  @override
  String get activationNotSaved =>
      'أكّد الخادم التفعيل، لكن تعذّر حفظه في التطبيق. الإعلانات معلّقة؛ أعد المحاولة.';

  @override
  String get activationRejected => 'لم يُقبل كود التفعيل.';

  @override
  String get selectionCountryChanged =>
      'تغيّرت الدولة. ارجع واختر نتيجة تخص الدولة المحددة.';

  @override
  String get priceCurrencyUnspecified => 'العملة غير محددة';
}
