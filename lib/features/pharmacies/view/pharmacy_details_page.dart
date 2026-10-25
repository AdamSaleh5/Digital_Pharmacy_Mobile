import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/utils/phone_utils.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../core/widgets/sticky_banner_ad.dart';
import '../../../data/models/pharmacy.dart';

class PharmacyDetailsPage extends StatelessWidget {
  final Pharmacy pharmacy;
  const PharmacyDetailsPage({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      bottomNavigationBar: const StickyBannerAd(),
      appBar: AppHeader(
        title: pharmacy.name,
        subtitle: l10n.pharmacyDetailsSubtitle,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          ),
          child: Icon(
            Icons.local_pharmacy_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _infoCard(
                context,
                icon: Icons.place_outlined,
                title: l10n.pharmacyAddress,
                value: pharmacy.address,
              ),
              _phoneCard(context, pharmacy.phone),
              _infoCard(
                context,
                icon: Icons.badge_outlined,
                title: l10n.pharmacyManager,
                value: pharmacy.manager,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(value),
      ),
    );
  }

  Widget _phoneCard(BuildContext context, String phone) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.phone,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          l10n.pharmacyPhone,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(phone),
        onTap: () => callNumber(phone),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: l10n.tooltipCopy,
              icon: const Icon(Icons.copy),
              onPressed: () => copyNumber(context, phone),
            ),
            IconButton(
              tooltip: l10n.tooltipCall,
              icon: const Icon(Icons.call),
              onPressed: () => callNumber(phone),
            ),
          ],
        ),
      ),
    );
  }
}
