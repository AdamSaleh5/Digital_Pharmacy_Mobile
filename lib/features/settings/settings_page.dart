import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/soft_background.dart';
import 'medical_sources_page.dart';
import 'ad_size_preference_tile.dart';
import 'ad_privacy_options_tile.dart';
import 'notification_settings_section.dart';
import '../../providers/app_provider.dart';

const String _privacyPolicyUrl =
    'https://doc-hosting.flycricket.io/free-privacy-policy-privacy-policy/9e41afc9-6886-4a4e-a8e7-4728a4ad7c6b/privacy';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showAppleMedicalSources =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    String countryName(AppCountry country) =>
        country == AppCountry.jordan
            ? l10n.countryJordan
            : l10n.countryPalestine;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.settingsTitle,
        subtitle: l10n.settingsSubtitle,
      ),
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4B6BFB), Color(0xFF73A2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_suggest_outlined,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.settingsInfoCard,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const NotificationSettingsSection(),
              const SizedBox(height: 12),
              const Card(child: AdSizePreferenceTile()),
              const AdPrivacyOptionsTile(),
              const SizedBox(height: 12),
              Consumer<AppProvider>(
                builder:
                    (context, app, _) => Card(
                      child: SwitchListTile(
                        title: Text(l10n.settingsThemeTitle),
                        subtitle: Text(l10n.settingsThemeSubtitle),
                        value: app.themeMode == ThemeMode.dark,
                        onChanged: (_) => app.toggleTheme(),
                        secondary: Icon(
                          app.themeMode == ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                      ),
                    ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      ListTile(
                        leading: _SettingIcon(icon: Icons.language_outlined),
                        title: Text(
                          l10n.settingsLanguageSectionTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(l10n.settingsLanguageSectionSubtitle),
                      ),
                      const Divider(height: 0),
                      Consumer<LocaleProvider>(
                        builder: (context, localeProvider, _) {
                          final current = localeProvider.locale;
                          return Column(
                            children: [
                              RadioListTile<Locale>(
                                title: Text(l10n.settingsLanguageArabic),
                                value: const Locale('ar'),
                                groupValue: current,
                                onChanged: (value) {
                                  if (value != null)
                                    localeProvider.setLocale(value);
                                },
                              ),
                              RadioListTile<Locale>(
                                title: Text(l10n.settingsLanguageEnglish),
                                value: const Locale('en'),
                                groupValue: current,
                                onChanged: (value) {
                                  if (value != null)
                                    localeProvider.setLocale(value);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const _SettingIcon(icon: Icons.flag_outlined),
                        title: Text(
                          l10n.settingsCountrySectionTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Consumer<AppProvider>(
                          builder: (context, app, _) {
                            final country = countryName(app.selectedCountry);
                            final symbol = appCurrencySymbol(
                              app.selectedCountry,
                            );
                            return Text('$country  •  $symbol');
                          },
                        ),
                      ),
                      const Divider(height: 0),
                      Consumer<AppProvider>(
                        builder: (context, app, _) {
                          return Column(
                            children: [
                              RadioListTile<AppCountry>(
                                title: Text(countryName(AppCountry.jordan)),
                                subtitle: const Text('د.أ'),
                                value: AppCountry.jordan,
                                groupValue: app.selectedCountry,
                                onChanged: (value) {
                                  if (value != null) {
                                    app.setCountry(value);
                                  }
                                },
                              ),
                              RadioListTile<AppCountry>(
                                title: Text(countryName(AppCountry.palestine)),
                                subtitle: const Text('₪'),
                                value: AppCountry.palestine,
                                groupValue: app.selectedCountry,
                                onChanged: (value) {
                                  if (value != null) {
                                    app.setCountry(value);
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              _SettingCard(
                icon: Icons.flag_outlined,
                title: l10n.reportAdTitle,
                subtitle: l10n.reportAdDescription,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final opened = await launchUrl(
                    Uri.parse(
                      'https://support.google.com/ads/troubleshooter/4578507',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.settingsPrivacyOpenError)),
                    );
                  }
                },
              ),
              _SettingCard(
                icon: Icons.privacy_tip_outlined,
                title: l10n.settingsPrivacyTitle,
                subtitle: l10n.settingsPrivacySubtitle,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final opened = await launchUrl(
                    Uri.parse(_privacyPolicyUrl),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.settingsPrivacyOpenError)),
                    );
                  }
                },
              ),
              if (showAppleMedicalSources)
                _SettingCard(
                  icon: Icons.menu_book_outlined,
                  title: l10n.medicalSourcesEntryTitle,
                  subtitle: l10n.medicalSourcesEntrySubtitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicalSourcesPage(),
                      ),
                    );
                  },
                ),
              _SettingCard(
                icon: Icons.info_outline,
                title: l10n.settingsMedicalTitle,
                subtitle: l10n.settingsMedicalSubtitle,
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: Text(l10n.settingsAlertTitle),
                          content: Text(l10n.settingsAlertBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.commonOk),
                            ),
                          ],
                        ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        l10n.settingsVersionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.settingsVersionDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: _SettingIcon(icon: icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  final IconData icon;
  const _SettingIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.primary.withOpacity(.1),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}
