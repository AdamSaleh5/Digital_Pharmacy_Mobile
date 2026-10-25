import 'package:digitalpharmacy/core/utils/price_presentation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/utils/phone_utils.dart';
import '../../../core/widgets/search_page_layout.dart';
import '../../../data/models/drug.dart';
import '../../../providers/app_provider.dart';

class DrugsPage extends StatefulWidget {
  const DrugsPage({super.key});

  @override
  State<DrugsPage> createState() => _DrugsPageState();
}

class _DrugsPageState extends State<DrugsPage> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final subtleColor = theme.colorScheme.onSurfaceVariant;
    final results = app.drugRepo.search(query: controller.text);

    final header = <Widget>[
      Text(
        l10n.drugsMatches(results.length),
        style: theme.textTheme.bodyMedium?.copyWith(color: subtleColor),
      ),
      const SizedBox(height: 12),
    ];

    final listChildren =
        results.isEmpty
            ? [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.drugsEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ]
            : results.map((drug) => _DrugCard(drug: drug)).toList();

    return SearchPageLayout(
      title: l10n.drugsPageTitle,
      subtitle: l10n.drugsPageSubtitle,
      controller: controller,
      hintText: l10n.drugsSearchHint,
      onChanged: (_) => setState(() {}),
      onSubmitted: app.addRecent,
      headerChildren: header,
      listChildren: listChildren,
    );
  }
}

class _DrugCard extends StatelessWidget {
  final Drug drug;
  const _DrugCard({required this.drug});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final sciColor = isDark ? const Color(0xFFD7E1FF) : const Color(0xFF4A5578);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drug.brandName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              drug.scientificName,
              style: TextStyle(color: sciColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _infoChip(
                  context,
                  Icons.factory_outlined,
                  l10n.labelCompany,
                  drug.company,
                ),
                _infoChip(
                  context,
                  Icons.handshake_outlined,
                  l10n.labelAgentName,
                  drug.agentName,
                ),
                _phoneChip(context, drug.agentNumber),
                _infoChip(
                  context,
                  Icons.numbers_outlined,
                  l10n.labelStrength,
                  drug.strength,
                ),
                _infoChip(
                  context,
                  Icons.attach_money,
                  l10n.labelPrice,
                  priceForDisplay(
                    formattedPrice: drug.formattedPriceJod,
                    currencyKnown: drug.priceCurrencyKnown,
                    l10n: l10n,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final bgColor = isDark ? const Color(0xFF1C2545) : const Color(0xFFF7F8FF);
    final borderColor =
        isDark ? const Color(0xFF2C3658) : const Color(0xFFE3E7FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2241);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            "$label: $value",
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }

  static Widget _phoneChip(BuildContext context, String number) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final bgColor = isDark ? const Color(0xFF18223F) : const Color(0xFFEFF7FF);
    final borderColor =
        isDark ? const Color(0xFF2C3658) : const Color(0xFFCCE4FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2241);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            number,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: 6),
            tooltip: l10n.tooltipCopy,
            icon: Icon(Icons.copy, size: 16, color: scheme.primary),
            onPressed: () => copyNumber(context, number),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: 2),
            tooltip: l10n.tooltipCall,
            icon: Icon(Icons.call, size: 16, color: scheme.primary),
            onPressed: () => callNumber(number),
          ),
        ],
      ),
    );
  }
}
