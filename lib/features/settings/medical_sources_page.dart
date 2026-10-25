import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../core/widgets/app_header.dart';
import '../../core/widgets/medical_references_card.dart';
import '../../core/widgets/soft_background.dart';

class MedicalSourcesPage extends StatelessWidget {
  const MedicalSourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppHeader(
        title: l10n.medicalSourcesPageTitle,
        subtitle: l10n.medicalSourcesPageSubtitle,
      ),
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    l10n.medicalSourcesIntro,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const MedicalReferencesCard(
                scientificName: 'Famotidine',
                tradeName: 'Amodine',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
