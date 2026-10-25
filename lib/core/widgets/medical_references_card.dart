import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/medical_reference_links.dart';

class MedicalReferencesCard extends StatelessWidget {
  final String scientificName;
  final String tradeName;
  final EdgeInsetsGeometry? margin;

  const MedicalReferencesCard({
    super.key,
    required this.scientificName,
    required this.tradeName,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final links = buildMedicalReferenceLinks(
      scientificName: scientificName,
      tradeName: tradeName,
      dailyMedLabel: l10n.medicalSourceDailyMed,
      medlinePlusLabel: l10n.medicalSourceMedlinePlus,
      nhsLabel: l10n.medicalSourceNhs,
    );

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.medicalReferencesTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.medicalReferencesSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showReferencesSheet(context, links),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.medicalReferencesOpenCta),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReferencesSheet(
    BuildContext context,
    List<MedicalReferenceLink> links,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.medicalReferencesSheetTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.medicalReferencesSheetSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...links.map(
                    (link) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.link_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        link.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _openReference(context, link.url);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _openReference(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.medicalReferenceOpenError,
          ),
        ),
      );
    }
  }
}
