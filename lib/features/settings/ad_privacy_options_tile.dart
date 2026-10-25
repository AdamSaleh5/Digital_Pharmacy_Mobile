import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/ads/ad_consent_service.dart';

class AdPrivacyOptionsTile extends StatelessWidget {
  const AdPrivacyOptionsTile({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AdConsentService.instance,
    builder: (context, _) {
      final consent = AdConsentService.instance;
      if (!consent.privacyOptionsRequired) return const SizedBox.shrink();
      return Card(
        child: ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(AppLocalizations.of(context)!.adPrivacyOptions),
          onTap:
              consent.showingPrivacyOptions ? null : consent.showPrivacyOptions,
        ),
      );
    },
  );
}
