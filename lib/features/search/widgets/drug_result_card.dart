import 'package:digitalpharmacy/core/utils/price_presentation.dart';
import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/utils/apple_review_mode.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../data/models/drug.dart';

class DrugResultCard extends StatelessWidget {
  final Drug drug;
  final VoidCallback onTap;
  final VoidCallback onShowDosageForms;

  const DrugResultCard({
    super.key,
    required this.drug,
    required this.onTap,
    required this.onShowDosageForms,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context)!;
    final sciColor =
        brightness == Brightness.dark ? Colors.white70 : Colors.black54;
    final chipColor =
        brightness == Brightness.dark
            ? Colors.white.withOpacity(.15)
            : const Color(0xFFE8F0FF);
    final chipTextColor =
        brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drug.brandName,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                drug.scientificName,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: sciColor, fontWeight: FontWeight.w600),
              ),
              if (!shouldHideDirectMedicalFieldsOnIos) ...[
                const SizedBox(height: 6),
                Text(
                  '${referenceInfoLabel(l10n)}: ${_displayText(drug.usage, l10n.valueNotAvailable)}',
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _infoRow(Icons.factory_outlined, l10n.labelCompany, drug.company),
              const SizedBox(height: 6),
              _infoRow(
                Icons.handshake_outlined,
                l10n.labelAgentName,
                drug.agentName,
              ),
              const SizedBox(height: 6),
              _phoneRow(context, drug.agentNumber),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    backgroundColor: chipColor,
                    avatar: const Icon(Icons.attach_money, size: 16),
                    label: Text(
                      priceForDisplay(
                        formattedPrice: drug.formattedPriceJod,
                        currencyKnown: drug.priceCurrencyKnown,
                        l10n: l10n,
                      ),
                      style: TextStyle(
                        color: chipTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Chip(
                    backgroundColor: chipColor,
                    avatar: const Icon(Icons.numbers_outlined, size: 16),
                    label: Text(
                      '${l10n.labelStrength}: ${drug.strength}',
                      style: TextStyle(
                        color: chipTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onShowDosageForms,
                  icon: const Icon(Icons.medical_services_outlined),
                  label: Text(productFormsLabel(l10n)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4B6BFB)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "$label: $value",
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _phoneRow(BuildContext context, String number) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        const Icon(Icons.phone, size: 18, color: Color(0xFF4B6BFB)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${l10n.labelAgentNumber}: $number',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: l10n.tooltipCopy,
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () => copyNumber(context, number),
        ),
        IconButton(
          tooltip: l10n.tooltipCall,
          icon: const Icon(Icons.call, size: 18),
          onPressed: () => callNumber(number),
        ),
      ],
    );
  }
}

String _displayText(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}
