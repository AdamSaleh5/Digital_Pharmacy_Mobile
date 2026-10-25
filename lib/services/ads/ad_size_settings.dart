import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AdSizePreference { compact, responsive }

/// Persisted independently so settings UI can embed [AdSizePreferenceTile]
/// without coupling preferences to authentication or provider state.
class AdSizeSettings extends ChangeNotifier {
  AdSizeSettings._() {
    _ready = load();
  }

  static final AdSizeSettings instance = AdSizeSettings._();
  static const preferenceKey = 'ad_banner_size_v1';

  AdSizePreference _preference = AdSizePreference.responsive;
  late final Future<void> _ready;
  AdSizePreference get preference => _preference;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _preference =
        prefs.getString(preferenceKey) == 'compact'
            ? AdSizePreference.compact
            : AdSizePreference.responsive;
    notifyListeners();
  }

  Future<void> setPreference(AdSizePreference value) async {
    await _ready;
    if (_preference == value) return;
    _preference = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, value.name);
  }

  Future<AdSize> resolveSize(
    int availableWidth, {
    Orientation orientation = Orientation.portrait,
  }) async {
    await _ready;
    if (_preference == AdSizePreference.compact) return AdSize.banner;
    if (availableWidth < 320) return AdSize.banner;
    final width = availableWidth.clamp(320, 1200);
    return await AdSize.getAnchoredAdaptiveBannerAdSize(orientation, width) ??
        AdSize.banner;
  }
}
