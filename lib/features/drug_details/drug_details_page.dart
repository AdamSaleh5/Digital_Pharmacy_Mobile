import 'package:digitalpharmacy/core/utils/price_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/apple_review_mode.dart';
import '../../../core/widgets/apple_review_notice_card.dart';
import '../../../core/widgets/golden_gradient_button.dart';
import '../../../core/widgets/medical_references_card.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/ad_banner_placement.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../data/models/drug.dart';
import '../../../providers/app_provider.dart';
import '../drugs/widgets/dosage_forms_sheet.dart';
import '../drugs/view/medication_alternatives_page.dart';

class DrugDetailsPage extends StatefulWidget {
  final String drugId;
  const DrugDetailsPage({super.key, required this.drugId});

  @override
  State<DrugDetailsPage> createState() => _DrugDetailsPageState();
}

class _DrugDetailsPageState extends State<DrugDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final drug = app.drugRepo.byId(widget.drugId);
    final l10n = AppLocalizations.of(context)!;

    if (drug == null) {
      return Scaffold(body: Center(child: Text(l10n.drugNotFound)));
    }

    final isFav = app.isFavorite(drug.id);
    return Scaffold(
      appBar: AppHeader(
        title: drug.brandName,
        subtitle: drug.scientificName,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          ),
          child: Icon(
            Icons.medication_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => app.toggleFavorite(drug.id),
            icon: Icon(isFav ? Icons.star : Icons.star_outline),
          ),
          IconButton(
            onPressed: () async {
              final text =
                  "${l10n.appName}\n"
                  "${l10n.labelTradeName}: ${drug.brandName}\n"
                  "${l10n.labelScientificName}: ${drug.scientificName}\n"
                  "${l10n.labelCompany}: ${drug.company}\n"
                  "${l10n.labelAgentName}: ${drug.agentName}\n"
                  "${l10n.labelAgentNumber}: ${drug.agentNumber}\n"
                  "${l10n.labelDosageForms}: ${drug.dosageFormsLabel}\n"
                  "${l10n.labelStrength}: ${drug.strength}\n"
                  "${l10n.labelAlternatives}: ${drug.alternatives}";
              await Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.snackCopiedDrug)));
            },
            icon: const Icon(Icons.copy_outlined),
          ),
          const SizedBox(width: 8),
        ],
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
                    colors: [Color(0xFF4B6BFB), Color(0xFF6B5AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppleReviewNoticeCard(
                      margin: EdgeInsets.only(bottom: 16),
                    ),
                    Text(
                      drug.brandName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      drug.scientificName,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _pill(l10n.labelCompany, drug.company),
                        _pill(l10n.labelForm, drug.dosageFormsLabel),
                        _pill(l10n.labelStrength, drug.strength),
                        _pill(
                          l10n.labelPrice,
                          priceForDisplay(
                            formattedPrice: drug.formattedPriceJod,
                            currencyKnown: drug.priceCurrencyKnown,
                            l10n: l10n,
                          ),
                        ),
                        _pill(l10n.labelOrigin, drug.country),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _tile(
                        context,
                        Icons.science_outlined,
                        l10n.labelScientificName,
                        drug.scientificName,
                      ),
                      const Divider(height: 26),
                      _tile(
                        context,
                        Icons.local_offer_outlined,
                        l10n.labelTradeName,
                        drug.brandName,
                      ),
                      const Divider(height: 26),
                      _tile(
                        context,
                        Icons.factory_outlined,
                        l10n.labelManufacturer,
                        drug.company,
                      ),
                      const Divider(height: 26),
                      _tile(
                        context,
                        Icons.handshake_outlined,
                        l10n.labelAgentName,
                        drug.agentName,
                      ),
                      const Divider(height: 26),
                      if (!shouldHideDirectMedicalFieldsOnIos) ...[
                        _tile(
                          context,
                          Icons.medical_information_outlined,
                          referenceInfoLabel(l10n),
                          drug.usage.trim().isEmpty
                              ? l10n.valueNotAvailable
                              : drug.usage,
                        ),
                        const Divider(height: 26),
                      ],
                      _phoneTile(context, drug.agentNumber),
                      const Divider(height: 26),
                      _tile(
                        context,
                        Icons.medical_services_outlined,
                        l10n.labelForm,
                        drug.dosageFormsLabel,
                      ),
                      const Divider(height: 26),
                      _tile(
                        context,
                        Icons.numbers_outlined,
                        l10n.labelStrength,
                        drug.strength,
                      ),
                      const Divider(height: 26),
                      _tile(
                        context,
                        Icons.swap_horiz,
                        similarProductsLabel(l10n),
                        drug.alternatives,
                      ),
                      const Divider(height: 26),
                      _tile(
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
                ),
              ),
              const SizedBox(height: 18),
              MedicalReferencesCard(
                scientificName: drug.scientificName,
                tradeName: drug.brandName,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GoldenGradientButton(
                      label: productFormsLabel(l10n),
                      onPressed: () => _showDosageFormsSheet(context, drug),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AlternativesGradientButton(
                      label: viewSimilarProductsLabel(l10n),
                      onPressed: () => _openAlternativesPage(context, drug),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBannerBar(),
    );
  }

  static Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tileBg = isDark ? const Color(0xFF1B2440) : const Color(0xFFEFF2FF);
    final iconColor = isDark ? AppTheme.accent : scheme.primary;
    final valueColor =
        isDark ? const Color(0xFFB8C5EA) : const Color(0xFF5B647C);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: tileBg,
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 3,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: valueColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _phoneTile(BuildContext context, String number) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final tileBg = isDark ? const Color(0xFF1B2440) : const Color(0xFFEFF2FF);
    final iconColor = isDark ? AppTheme.accent : scheme.primary;
    final valueColor =
        isDark ? const Color(0xFFB8C5EA) : const Color(0xFF5B647C);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: tileBg,
          ),
          child: Icon(Icons.phone, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.labelAgentNumber,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(number, style: TextStyle(color: valueColor)),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.tooltipCopy,
          icon: const Icon(Icons.copy),
          onPressed: () => copyNumber(context, number),
        ),
        IconButton(
          tooltip: l10n.tooltipCall,
          icon: const Icon(Icons.call),
          onPressed: () => callNumber(number),
        ),
      ],
    );
  }

  static Widget _pill(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: .18),
      ),
      child: Text(
        "$k: $v",
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showDosageFormsSheet(BuildContext context, Drug drug) {
    final id = int.tryParse(drug.id);
    if (id == null) return;
    final repo = context.read<AppProvider>().medicationRepo;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DosageFormsSheet(
            drugName: drug.brandName,
            loadForms: (token) async {
              final items = await repo.fetchFormsOnce(
                medId: id,
                country: kAppCountry,
                cancelToken: token,
              );
              return items
                  .map(
                    (item) => DosageFormPrice(
                      formName: item.pharmaceuticalForm,
                      priceJod: item.price,
                      priceCurrencyKnown: false,
                    ),
                  )
                  .where((form) => form.formName.trim().isNotEmpty)
                  .toList();
            },
          ),
    );
  }

  void _openAlternativesPage(BuildContext context, Drug drug) {
    final id = int.tryParse(drug.id);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noAlternativesFound),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => MedicationAlternativesPage(
              medicationId: id,
              drugName: drug.brandName,
              scientificName: drug.scientificName,
            ),
      ),
    );
  }

  Widget _buildBannerBar() {
    return const AdBannerPlacement(padding: EdgeInsets.fromLTRB(16, 0, 16, 12));
  }
}
