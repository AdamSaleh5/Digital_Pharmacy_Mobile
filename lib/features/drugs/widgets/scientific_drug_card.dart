import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/utils/apple_review_mode.dart';
import '../../../core/widgets/apple_review_notice_card.dart';
import '../../../core/utils/phone_actions.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../data/models/drug.dart';
import '../../../core/widgets/golden_gradient_button.dart';

class ScientificDrugCard extends StatelessWidget {
  final Drug drug;
  final VoidCallback onShowForms;

  const ScientificDrugCard({
    super.key,
    required this.drug,
    required this.onShowForms,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final gradient = LinearGradient(
      colors:
          isDark
              ? const [Color(0xFF1E293B), Color(0xFF243447)]
              : const [Color(0xFFF4F8FF), Color(0xFFE8F0FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final textColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final labelColor =
        isDark ? Colors.white.withValues(alpha: .7) : const Color(0xFF64748B);
    final valueColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155);

    return PressableScale(
      onTap: () => _showContactOptions(context, drug.agentNumber),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          border:
              isDark
                  ? Border.all(color: Colors.white.withValues(alpha: .08))
                  : null,
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: const Color(0xFF90A6C8).withValues(alpha: .20),
                      blurRadius: 22,
                      offset: const Offset(0, 14),
                    ),
                  ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppleReviewNoticeCard(margin: EdgeInsets.only(bottom: 14)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productNameLabel(l10n),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),
                Text(
                  drug.brandName,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 6),
                Divider(thickness: 1, color: labelColor.withValues(alpha: .3)),
              ],
            ),
            const SizedBox(height: 20),
            // 1️⃣ MAIN INFO
            Row(
              children: [
                Expanded(
                  child: _infoRow(
                    context,
                    icon: Icons.handshake_outlined,
                    label: l10n.labelAgent,
                    value: drug.agentName,
                    labelColor: labelColor,
                    valueColor: valueColor,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoRow(
                    context,
                    icon: Icons.business_outlined,
                    label: l10n.labelCompany,
                    value: drug.company,
                    labelColor: labelColor,
                    valueColor: valueColor,
                    maxLines: 5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2️⃣ DETAILS (LESS VISUAL WEIGHT)
            _softSection(
              isDark: isDark,
              child: Column(
                children: [
                  _infoRow(
                    context,
                    icon: Icons.science_outlined,
                    label: l10n.labelScientificName,
                    value: drug.scientificName,
                    labelColor: labelColor,
                    valueColor: valueColor,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 10),
                  if (!shouldHideDirectMedicalFieldsOnIos)
                    _infoRow(
                      context,
                      icon: Icons.medical_information_outlined,
                      label: referenceInfoLabel(l10n),
                      value: _displayValue(drug.usage, l10n.valueNotAvailable),
                      labelColor: labelColor,
                      valueColor: valueColor,
                      maxLines: 5,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3️⃣ ACTIONS
            _phoneRow(
              context,
              labelColor: labelColor,
              valueColor: valueColor,
              phone: drug.agentNumber,
            ),

            const SizedBox(height: 18),

            GoldenGradientButton(
              label: productFormsLabel(l10n),
              onPressed: onShowForms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    TextAlign align = TextAlign.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    TextStyle? valueStyle,
    List<Widget>? actionButtons,
    int maxLines = 2,
  }) {
    final theme = Theme.of(context);
    final textWidget = Expanded(
      child: Text(
        value,
        textAlign: align,
        maxLines: maxLines,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        style:
            valueStyle ??
            theme.textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
      ),
    );

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: labelColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [textWidget, if (actionButtons != null) ...actionButtons],
        ),
      ],
    );
  }

  void _showContactOptions(BuildContext context, String number) {}

  Widget _phoneRow(
    BuildContext context, {
    required Color labelColor,
    required Color valueColor,
    required String phone,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final iconColor = theme.colorScheme.primary;
    final background =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.primary.withValues(alpha: .15)
            : theme.colorScheme.primary.withValues(alpha: .08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_outlined, size: 16, color: labelColor),
            const SizedBox(width: 4),
            Text(
              l10n.labelAgentNumber,
              style: theme.textTheme.labelMedium?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                phone.isEmpty ? "-" : phone,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _actionCircle(
              context,
              icon: Icons.copy,
              tooltip: l10n.tooltipCopy,
              background: background,
              iconColor: iconColor,
              onTap:
                  phone.trim().isEmpty ? null : () => copyPhone(context, phone),
            ),
            const SizedBox(width: 6),
            _actionCircle(
              context,
              icon: Icons.call,
              tooltip: l10n.tooltipCall,
              background: background,
              iconColor: iconColor,
              onTap: phone.trim().isEmpty ? null : () => callPhone(phone),
            ),
          ],
        ),
      ],
    );
  }

  String _displayValue(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Widget _actionCircle(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color background,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabledColor = iconColor.withValues(alpha: .4);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        splashRadius: 20,
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                onTap == null ? background.withValues(alpha: .4) : background,
            border:
                isDark
                    ? Border.all(color: Colors.white.withValues(alpha: .08))
                    : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? disabledColor : iconColor,
          ),
        ),
      ),
    );
  }

  Widget _softSection({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: .05)
                : Colors.white.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
