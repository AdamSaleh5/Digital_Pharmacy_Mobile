import 'package:digitalpharmacy/core/utils/price_presentation.dart';
import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/utils/apple_review_mode.dart';
import '../../../core/widgets/apple_review_notice_card.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/widgets/medical_references_card.dart';
import '../../../data/models/drug.dart';
import '../../../core/widgets/golden_gradient_button.dart';

class DrugInfoCard extends StatefulWidget {
  final Drug drug;
  final VoidCallback? onShowAlternatives;
  final bool showActionButton;
  final String? actionLabel;
  final bool hideFormAndPrice;
  final bool showFormsButton;
  final VoidCallback? onShowForms;
  final bool compact;
  final Widget? trailing;

  const DrugInfoCard({
    super.key,
    required this.drug,
    this.onShowAlternatives,
    this.showActionButton = true,
    this.actionLabel,
    this.hideFormAndPrice = false,
    this.showFormsButton = false,
    this.onShowForms,
    this.compact = false,
    this.trailing,
  });

  @override
  State<DrugInfoCard> createState() => _DrugInfoCardState();
}

class _DrugInfoCardState extends State<DrugInfoCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final labelColor =
        isDark ? const Color(0xFFB8C4E3) : const Color(0xFF6B7280);
    final surface =
        isDark ? const Color(0xFF111C2E) : theme.colorScheme.surface;
    final borderColor =
        isDark ? Colors.white.withOpacity(.08) : const Color(0xFFE4E7F5);
    final shadow =
        isDark
            ? null
            : [
              BoxShadow(
                color: const Color(0xFF94A3B8).withOpacity(.18),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ];

    final buttonLabel = widget.actionLabel ?? viewSimilarProductsLabel(l10n);

    return GestureDetector(
      onTap: widget.compact ? () => setState(() => expanded = !expanded) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.drug.brandName,
                      maxLines: 10,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState:
                    widget.compact && !expanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppleReviewNoticeCard(
                      margin: EdgeInsets.only(bottom: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.drug.scientificName,
                      maxLines: 20,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _infoRow(
                      context,
                      Icons.factory_outlined,
                      l10n.labelCompany,
                      widget.drug.company,
                      labelColor,
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      context,
                      Icons.handshake_outlined,
                      l10n.labelAgentName,
                      widget.drug.agentName,
                      labelColor,
                    ),
                    const SizedBox(height: 8),
                    if (!shouldHideDirectMedicalFieldsOnIos) ...[
                      _infoRow(
                        context,
                        Icons.medical_information_outlined,
                        referenceInfoLabel(l10n),
                        _usageValue(widget.drug.usage, l10n.valueNotAvailable),
                        labelColor,
                      ),
                      const SizedBox(height: 14),
                    ],
                    MedicalReferencesCard(
                      scientificName: widget.drug.scientificName,
                      tradeName: widget.drug.brandName,
                    ),
                    const SizedBox(height: 8),
                    _phoneRow(context, labelColor, widget.drug.agentNumber),
                    if (!widget.hideFormAndPrice) ...[
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        Icons.science_outlined,
                        l10n.labelForm,
                        widget.drug.dosageFormsLabel,
                        labelColor,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        Icons.attach_money,
                        l10n.labelPrice,
                        priceForDisplay(
                          formattedPrice: widget.drug.formattedPriceJod,
                          currencyKnown: widget.drug.priceCurrencyKnown,
                          l10n: l10n,
                        ),
                        labelColor,
                      ),
                    ],
                    if (widget.showFormsButton &&
                        widget.onShowForms != null) ...[
                      const SizedBox(height: 20),
                      GoldenGradientButton(
                        label: productFormsLabel(l10n),
                        onPressed: widget.onShowForms!,
                      ),
                    ],
                    if (widget.showActionButton &&
                        widget.onShowAlternatives != null) ...[
                      const SizedBox(height: 20),
                      AlternativesGradientButton(
                        label: buttonLabel,
                        onPressed: widget.onShowAlternatives!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color labelColor,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 10,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _phoneRow(BuildContext context, Color labelColor, String number) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.phone, size: 16, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.labelAgentNumber,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                number,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                ),
              ),
            ],
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

String _usageValue(String value, String fallback) {
  final text = value.trim();
  return text.isEmpty ? fallback : text;
}
