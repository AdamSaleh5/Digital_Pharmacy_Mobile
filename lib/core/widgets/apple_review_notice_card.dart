import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../utils/apple_review_mode.dart';

class AppleReviewNoticeCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const AppleReviewNoticeCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    if (!isIosReferenceMode) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3D08B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, size: 20, color: Color(0xFF8A5A00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.iosReferenceNoticeTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5D3B00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.iosReferenceNoticeBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7A5A1A),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
