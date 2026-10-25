import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ads/ad_size_settings.dart';

/// Compact or responsive banner size control for SettingsPage.
class AdSizePreferenceTile extends StatelessWidget {
  const AdSizePreferenceTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdSizeSettings>.value(
      value: AdSizeSettings.instance,
      child: Consumer<AdSizeSettings>(
        builder: (context, settings, _) {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.ads_click_outlined),
                title: Text(isArabic ? 'حجم الإعلان' : 'Ad size'),
                subtitle: Text(
                  isArabic
                      ? 'اختر حجم الإعلانات المثبتة'
                      : 'Choose the size of anchored banners',
                ),
              ),
              const Divider(height: 0),
              RadioListTile<AdSizePreference>(
                value: AdSizePreference.compact,
                groupValue: settings.preference,
                onChanged: (value) {
                  if (value != null) settings.setPreference(value);
                },
                title: Text(isArabic ? 'مضغوط' : 'Compact'),
                subtitle: Text(
                  isArabic ? 'حجم قياسي صغير' : 'Standard small banner',
                ),
              ),
              RadioListTile<AdSizePreference>(
                value: AdSizePreference.responsive,
                groupValue: settings.preference,
                onChanged: (value) {
                  if (value != null) settings.setPreference(value);
                },
                title: Text(isArabic ? 'متجاوب' : 'Responsive'),
                subtitle: Text(
                  isArabic
                      ? 'يتكيف مع عرض الشاشة المتاح'
                      : 'Adapts to available screen width',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
