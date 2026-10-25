import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/utils/app_constants.dart';
import '../data/repository/drug_repository.dart';
import '../data/repository/pharmacy_repository.dart';
import '../services/ads/ad_service.dart';
import '../services/ads/ads_entitlement_controller.dart';
import '../services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/features/drugs/data/repository/medication_repository.dart';
import '../core/network/auth_session.dart';
import '../core/network/activation_api_adapter.dart';

class AppProvider extends ChangeNotifier {
  AppProvider({
    MedicationRepository? medicationRepository,
    AuthSession? authSession,
    EntitlementLookup? entitlementLookup,
    this.activationAdapter = const SwaggerActivationApiAdapter(),
  }) : medicationRepo = medicationRepository ?? MedicationRepository(),
       _authSession = authSession,
       _entitlementLookup =
           entitlementLookup ?? activationAdapter.statusLookup {
    _authSession?.addListener(_onAuthSessionChanged);
    _authSessionRevision = _authSession?.revision ?? 0;
  }

  final drugRepo = const DrugRepository();
  final pharmacyRepo = const PharmacyRepository();
  final MedicationRepository medicationRepo;
  final AuthSession? _authSession;
  int _authSessionRevision = 0;
  ActivationEntitlementRestorer? _entitlementRestorer;
  final EntitlementLookup? _entitlementLookup;
  final ActivationApiAdapter activationAdapter;
  bool _disposed = false;
  ActivationEntitlementRestorer? get activationRestorer => _entitlementRestorer;

  Future<void> restoreActivation() async {
    final lookup = _entitlementLookup;
    final restorer = _entitlementRestorer;
    if (lookup != null && restorer != null) await restorer.restore(lookup);
  }

  int get authSessionRevision => _authSessionRevision;
  int get dataScopeRevision => _authSessionRevision;
  final ads = AdService();

  PharmacySearchMode pharmacySearchMode = PharmacySearchMode.name;
  ThemeMode themeMode = ThemeMode.light;
  AppCountry selectedCountry = AppCountry.jordan;
  bool _countryExplicitlySelected = false;
  AppCountry? _detectedCountry;

  final Set<String> favoriteIds = {};
  final Map<String, String> _serverFavoriteNames = {};
  String get _favoriteApiPrefix =>
      'api|${ApiConfig.baseUrl}|${selectedCountry.name}|';

  String serverFavoriteKey(int id) => '$_favoriteApiPrefix$id';
  bool isServerFavorite(int id) => favoriteIds.contains(serverFavoriteKey(id));
  int get legacyFavoriteCount =>
      favoriteIds.where((id) => !id.startsWith('api|')).length;

  List<ServerFavorite> get serverFavorites => favoriteIds
      .where((key) => key.startsWith(_favoriteApiPrefix))
      .map(
        (key) => ServerFavorite(
          key: key,
          id: int.tryParse(key.substring(_favoriteApiPrefix.length)) ?? 0,
          name: _serverFavoriteNames[key] ?? '',
        ),
      )
      .where((item) => item.id > 0)
      .toList(growable: false);

  Future<void> toggleServerFavorite({
    required int id,
    required String name,
  }) async {
    if (id <= 0 || name.trim().isEmpty)
      throw ArgumentError('A server ID and name are required.');
    final key = serverFavoriteKey(id);
    if (!favoriteIds.remove(key)) {
      favoriteIds.add(key);
      _serverFavoriteNames[key] = name.trim();
    } else {
      _serverFavoriteNames.remove(key);
    }
    await _saveFavorites();
    notifyListeners();
  }

  final List<String> recentSearches = [];

  int _detailsOpenCount = 0;

  // Explicit legacy admin contexts may invalidate data caches, never the
  // installation entitlement. Production AppProvider has no admin session.
  void _onAuthSessionChanged() => invalidatePublicDataScope();

  void invalidatePublicDataScope() {
    _authSessionRevision++;
    medicationRepo.clearSessionCaches();
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    _entitlementRestorer = ActivationEntitlementRestorer(
      preferences: prefs,
      ads: AdsEntitlementController.instance,
    )..bootstrap();
    // Restore saved activation before any ad request. An optional deployment
    // lookup must not block main() from showing the app.
    unawaited(restoreActivation());
    if (_disposed) return;
    // Fresh installations show ads after consent; saved activations stay ad-free.
    ads.loadInterstitial();
    await _loadPrefs();
  }

  bool get shouldAskForCountry => !_countryExplicitlySelected;
  AppCountry? get detectedCountry => _detectedCountry;

  void setPharmacySearchMode(PharmacySearchMode m) {
    pharmacySearchMode = m;
    notifyListeners();
  }

  Future<void> setCountry(
    AppCountry country, {
    bool explicitSelection = true,
  }) async {
    if (selectedCountry == country &&
        _countryExplicitlySelected == explicitSelection) {
      return;
    }
    selectedCountry = country;
    _countryExplicitlySelected = explicitSelection;
    setAppCountry(country);
    medicationRepo.clearSessionCaches();
    notifyListeners();
    await _saveCountry();
  }

  void toggleFavorite(String id) {
    if (favoriteIds.contains(id)) {
      favoriteIds.remove(id);
      _serverFavoriteNames.remove(id);
    } else {
      favoriteIds.add(id);
    }
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String id) => favoriteIds.contains(id);

  void addRecent(String q) {
    final query = q.trim();
    if (query.isEmpty) return;

    recentSearches.removeWhere((e) => e.toLowerCase() == query.toLowerCase());
    recentSearches.insert(0, query);

    if (recentSearches.length > 8) {
      recentSearches.removeLast();
    }
    _saveRecent();
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  void onCompletedDrugDetails() {
    _detailsOpenCount++;
    if (_detailsOpenCount % AppConstants.interstitialEveryNDetailsOpens == 0) {
      final didShow = ads.showInterstitialIfReady();
      if (!didShow) {
        ads.loadInterstitial();
      }
    }
  }

  // --- SharedPrefs ---
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (_disposed) return;

    final favJson = prefs.getString(AppConstants.favKey);
    if (favJson != null) {
      favoriteIds
        ..clear()
        ..addAll(_savedStringList(favJson));
    }
    final namesJson = prefs.getString('server_favorite_names_v1');
    if (namesJson != null) {
      final names = _savedJson(namesJson);
      if (names is Map) {
        _serverFavoriteNames.addAll({
          for (final entry in names.entries)
            if (entry.key is String && entry.value is String)
              entry.key as String: entry.value as String,
        });
      }
    }

    final recentJson = prefs.getString(AppConstants.recentKey);
    if (recentJson != null) {
      recentSearches
        ..clear()
        ..addAll(_savedStringList(recentJson));
    }

    final storedTheme = prefs.getString(AppConstants.themeKey);
    if (storedTheme != null) {
      themeMode = storedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }

    final storedCountry = appCountryFromStorage(
      prefs.getString(AppConstants.countryKey),
    );
    final explicitCountrySelection =
        prefs.getBool(AppConstants.countryExplicitlySelectedKey) ?? false;

    _detectedCountry = appCountryFromCode(
      WidgetsBinding.instance.platformDispatcher.locale.countryCode,
    );

    selectedCountry = storedCountry ?? _detectedCountry ?? AppCountry.jordan;
    _countryExplicitlySelected =
        storedCountry != null && explicitCountrySelection;
    setAppCountry(selectedCountry);

    notifyListeners();
  }

  // An unreadable optional collection must not strand startup on the splash
  // screen. Keep the stored value untouched for recovery and retain valid
  // entries when an older/malformed collection contains mixed value types.
  static Object? _savedJson(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  static Iterable<String> _savedStringList(String value) {
    final decoded = _savedJson(value);
    return decoded is List ? decoded.whereType<String>() : const [];
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.favKey,
      jsonEncode(favoriteIds.toList()),
    );
    await prefs.setString(
      'server_favorite_names_v1',
      jsonEncode(_serverFavoriteNames),
    );
  }

  Future<void> _saveRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.recentKey, jsonEncode(recentSearches));
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.themeKey,
      themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> _saveCountry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.countryKey,
      appCountryStorageValue(selectedCountry),
    );
    await prefs.setBool(
      AppConstants.countryExplicitlySelectedKey,
      _countryExplicitlySelected,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _authSession?.removeListener(_onAuthSessionChanged);
    _entitlementRestorer?.dispose();
    ads.disposeInterstitial();
    ads.disposeAppOpen();
    super.dispose();
  }
}

class ServerFavorite {
  const ServerFavorite({
    required this.key,
    required this.id,
    required this.name,
  });
  final String key;
  final int id;
  final String name;
}
