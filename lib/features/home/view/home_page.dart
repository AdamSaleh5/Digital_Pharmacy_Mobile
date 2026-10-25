import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/models/drug_search_mode.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/apple_review_mode.dart';
import '../../../core/utils/store_entitlement_policy.dart';
import '../../../core/widgets/drawer_controller_scope.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../core/widgets/inline_native_ad_card.dart';
import '../../../data/repository/pharmacy_repository.dart';
import '../../../providers/app_provider.dart';
import '../../pharmacies/view/pharmacies_page.dart';
import '../../search/view/search_results_page.dart';
import '../../activation/view/activation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _phoneHeaderExpandedHeight = 90;
  static const double _tabletHeaderExpandedHeight = 104;

  void _openSmartSearch(BuildContext context, DrugSearchMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(initialQuery: '', searchMode: mode),
      ),
    );
  }

  void _openPharmacies(BuildContext context) {
    final app = context.read<AppProvider>();
    app.setPharmacySearchMode(PharmacySearchMode.name);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PharmaciesPage(showStandaloneBanner: true),
      ),
    );
  }

  void _openActivation(BuildContext context) {
    if (!supportsCustomActivationCode) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ActivationPage()));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTabletLike = screenWidth >= 800;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor =
        isDark ? const Color(0xFF2D45A4) : const Color(0xFF5C6FFF);
    final l10n = AppLocalizations.of(context)!;
    final actions = _buildActions(context, l10n);
    final gridActions = actions.take(4).toList();
    final heroAction = actions.length > 4 ? actions[4] : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: statusColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SoftBackground(
          child: CustomScrollView(
            slivers:
                isTabletLike
                    ? _buildTabletSlivers(
                      context: context,
                      l10n: l10n,
                      width: screenWidth,
                      gridActions: gridActions,
                      heroAction: heroAction,
                    )
                    : _buildPhoneSlivers(
                      context: context,
                      l10n: l10n,
                      gridActions: gridActions,
                      heroAction: heroAction,
                    ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPhoneSlivers({
    required BuildContext context,
    required AppLocalizations l10n,
    required List<_HomeAction> gridActions,
    required _HomeAction? heroAction,
  }) {
    const contentSidePadding = 16.0;
    final topRowActions = gridActions.take(2).toList();
    final bottomRowActions = gridActions.skip(2).take(2).toList();

    return [
      _HomeSliverAppBar(
        expandedHeight: _phoneHeaderExpandedHeight,
        horizontalPadding: contentSidePadding,
        maxContentWidth: double.infinity,
        l10n: l10n,
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          contentSidePadding,
          16,
          contentSidePadding,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              _PhoneActionRow(actions: topRowActions),
              const SizedBox(height: 16),
              const _HomeShowcaseCard(isTabletLike: false),
              const SizedBox(height: 16),
              _PhoneActionRow(actions: bottomRowActions),
            ],
          ),
        ),
      ),
      if (heroAction != null)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            contentSidePadding,
            16,
            contentSidePadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _HomeGridCard(data: heroAction, wide: true),
          ),
        ),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: contentSidePadding),
          child: InlineNativeAdCard(
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      if (supportsCustomActivationCode)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            contentSidePadding,
            24,
            contentSidePadding,
            24,
          ),
          sliver: SliverToBoxAdapter(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: () => _openActivation(context),
              child: Text(
                l10n.homeRemoveAds,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 96)),
    ];
  }

  List<Widget> _buildTabletSlivers({
    required BuildContext context,
    required AppLocalizations l10n,
    required double width,
    required List<_HomeAction> gridActions,
    required _HomeAction? heroAction,
  }) {
    final maxContentWidth = width >= 1280 ? 1120.0 : 1000.0;
    final sidePadding = ((width - maxContentWidth) / 2).clamp(22.0, 96.0);

    return [
      _HomeSliverAppBar(
        expandedHeight: _tabletHeaderExpandedHeight,
        horizontalPadding: sidePadding,
        maxContentWidth: maxContentWidth,
        l10n: l10n,
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(sidePadding, 18, sidePadding, 0),
        sliver: SliverToBoxAdapter(child: _TabletHeroSection(l10n: l10n)),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(sidePadding, 14, sidePadding, 0),
        sliver: SliverToBoxAdapter(child: _TabletInAppPromoSection(l10n: l10n)),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(sidePadding, 14, sidePadding, 0),
        sliver: SliverToBoxAdapter(
          child:
              heroAction == null
                  ? const SizedBox.shrink()
                  : _TabletFeaturedActionCard(action: heroAction),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(sidePadding, 22, sidePadding, 0),
        sliver: SliverToBoxAdapter(
          child: _TabletSectionHeading(title: homeDirectoryTitle(l10n)),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(sidePadding, 14, sidePadding, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.9,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = gridActions[index];
            return _TabletActionCard(action: item);
          }, childCount: gridActions.length),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: const InlineNativeAdCard(
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      if (supportsCustomActivationCode)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(sidePadding, 20, sidePadding, 24),
          sliver: SliverToBoxAdapter(
            child: _TabletPromoCard(
              ctaLabel: l10n.homeRemoveAds,
              onTap: () => _openActivation(context),
            ),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 104)),
    ];
  }

  List<_HomeAction> _buildActions(BuildContext context, AppLocalizations l10n) {
    return [
      _HomeAction(
        title:
            isIosReferenceMode
                ? scientificIndexNavLabel(l10n)
                : l10n.homeActionScientificTitle,
        subtitle:
            isIosReferenceMode
                ? scientificSearchSubtitle(l10n)
                : l10n.homeActionScientificSubtitle,
        icon: Icons.biotech_outlined,
        onTap: () => _openSmartSearch(context, DrugSearchMode.scientific),
      ),
      _HomeAction(
        title: l10n.homeActionTradeTitle,
        subtitle:
            isIosReferenceMode
                ? l10n.searchSubtitleTrade
                : l10n.homeActionTradeSubtitle,
        icon: Icons.medical_services_outlined,
        onTap: () => _openSmartSearch(context, DrugSearchMode.trade),
      ),
      _HomeAction(
        title: l10n.homeActionCompanyTitle,
        subtitle:
            isIosReferenceMode
                ? companySearchSubtitle(l10n)
                : l10n.homeActionCompanySubtitle,
        icon: Icons.business_outlined,
        onTap: () => _openSmartSearch(context, DrugSearchMode.company),
      ),
      _HomeAction(
        title: l10n.homeActionAgentTitle,
        subtitle:
            isIosReferenceMode
                ? l10n.searchSubtitleAgent
                : l10n.homeActionAgentSubtitle,
        icon: Icons.handshake_outlined,
        onTap: () => _openSmartSearch(context, DrugSearchMode.agent),
      ),
      _HomeAction(
        title: l10n.homeActionPharmacyTitle,
        subtitle: l10n.homeActionPharmacySubtitle,
        icon: Icons.local_pharmacy_outlined,
        onTap: () => _openPharmacies(context),
      ),
    ];
  }
}

class _PhoneActionRow extends StatelessWidget {
  final List<_HomeAction> actions;

  const _PhoneActionRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          Expanded(child: _HomeGridCard(data: actions[i])),
          if (i != actions.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

Widget _buildLogoAsset({
  BoxFit fit = BoxFit.contain,
  Alignment alignment = Alignment.center,
  FilterQuality filterQuality = FilterQuality.medium,
}) {
  return Image.asset(
    'assets/logo/logo_g_mk.jpeg',
    fit: fit,
    alignment: alignment,
    filterQuality: filterQuality,
    errorBuilder: (context, error, stackTrace) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFEFF3FF)),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 34,
            color: Color(0xFF7B88B8),
          ),
        ),
      );
    },
  );
}

class _HomeGridCard extends StatefulWidget {
  final _HomeAction data;
  final bool wide;

  const _HomeGridCard({required this.data, this.wide = false});

  @override
  State<_HomeGridCard> createState() => _HomeGridCardState();
}

class _HomeGridCardState extends State<_HomeGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1F2A44) : const Color(0xFFE4E7F5);
    final iconBackground =
        isDark ? const Color(0xFF182340) : const Color(0xFFE6EBFF);
    final textColor =
        isDark ? const Color(0xFFF4F6FF) : const Color(0xFF0F172A);
    final iconColor = isDark ? AppTheme.accent : AppTheme.primary;

    final circleSize = widget.wide ? 64.0 : 56.0;

    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeInOut,
      scale: _pressed ? 0.97 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          splashColor: iconColor.withValues(alpha: .18),
          highlightColor: iconColor.withValues(alpha: .12),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onTap: widget.data.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: borderColor),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: .14),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .28),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: widget.wide ? 140 : 150,
                maxHeight: double.infinity,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: .06)
                                : const Color(0xFFD7DEFF),
                      ),
                    ),
                    child: Icon(widget.data.icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.data.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabletHeroSection extends StatelessWidget {
  final AppLocalizations l10n;

  const _TabletHeroSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient:
            isDark
                ? const LinearGradient(
                  colors: [Color(0xFF1B2550), Color(0xFF2A2F62)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
                : const LinearGradient(
                  colors: [Color(0xFFF3F6FF), Color(0xFFE8EEFF)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
        border: Border.all(
          color: isDark ? const Color(0xFF2F3D6A) : const Color(0xFFD9E1FF),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homeDirectoryTitle(l10n),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1D2A4A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  homeDirectorySubtitle(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? const Color(0xFFC8D4FF)
                            : const Color(0xFF4A5B89),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 86,
            height: 86,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: isDark ? .08 : .85),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF3A4A7A) : const Color(0xFFD4DDFF),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildLogoAsset(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletInAppPromoSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _TabletInAppPromoSection({required this.l10n});

  static const List<String> _promoAssets = ['assets/logo/logo_g_mk.jpeg'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0xFF121B34) : const Color(0xFFF8FAFF),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3553) : const Color(0xFFDDE4FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  homeDirectoryHelper(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final promoHeight = (constraints.maxWidth * 0.34).clamp(
                220.0,
                300.0,
              );
              return SizedBox(
                height: promoHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: PageView.builder(
                    // Carousel-ready structure for future internal promo slides.
                    itemCount: _promoAssets.length,
                    itemBuilder: (context, index) {
                      return ColoredBox(
                        color:
                            isDark
                                ? const Color(0xFF1B2646)
                                : const Color(0xFFEEF3FF),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: _buildLogoAsset(
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TabletFeaturedActionCard extends StatelessWidget {
  final _HomeAction action;

  const _TabletFeaturedActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: action.onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: .12),
                ),
                child: Icon(action.icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back_ios_new
                    : Icons.arrow_forward_ios,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletSectionHeading extends StatelessWidget {
  final String title;

  const _TabletSectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      textAlign: TextAlign.start,
    );
  }
}

class _TabletActionCard extends StatelessWidget {
  final _HomeAction action;

  const _TabletActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF141D36) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: action.onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF2A3553) : const Color(0xFFE4E7F5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: .14),
                ),
                child: Icon(
                  action.icon,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletPromoCard extends StatelessWidget {
  final String ctaLabel;
  final VoidCallback onTap;

  const _TabletPromoCard({required this.ctaLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0xFF121B34) : const Color(0xFFF8FAFF),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3553) : const Color(0xFFDDE4FF),
        ),
      ),
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          ctaLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _HomeShowcaseCard extends StatelessWidget {
  final bool isTabletLike;

  const _HomeShowcaseCard({required this.isTabletLike});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: isTabletLike ? 180 : 158,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: isDark ? const Color(0xFF1A2441) : const Color(0xFFF6F8FF),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3553) : const Color(0xFFE4E7F5),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: .12),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildLogoAsset(
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSliverAppBar extends StatelessWidget {
  final double expandedHeight;
  final double horizontalPadding;
  final double maxContentWidth;
  final AppLocalizations l10n;

  const _HomeSliverAppBar({
    required this.expandedHeight,
    required this.horizontalPadding,
    required this.maxContentWidth,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final drawerScope = DrawerControllerScope.maybeOf(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final collapsedHeight = topPadding + kToolbarHeight;
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      toolbarHeight: kToolbarHeight,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final currentHeight = constraints.biggest.height;
          final availableRange = (expandedHeight - collapsedHeight).clamp(
            1.0,
            double.infinity,
          );
          final rawT = (currentHeight - collapsedHeight) / availableRange;
          final clampedT = rawT.clamp(0.0, 1.0);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final gradient =
              isDark
                  ? AppTheme.darkHeaderGradient
                  : AppTheme.lightHeaderGradient;
          final bottomRadius = (32 - (18 * clampedT)).clamp(14.0, 32.0);
          final contentTop = lerpDouble(0, 18, clampedT)!;

          return Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(bottomRadius),
                bottomRight: Radius.circular(bottomRadius),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isDark
                          ? Colors.black.withValues(alpha: .35)
                          : AppTheme.primary.withValues(alpha: .25),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Stack(
                children: [
                  Positioned(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: contentTop,
                    child: Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: SizedBox(
                          height: kToolbarHeight,
                          child: _AppBarTopRow(
                            progress: clampedT,
                            l10n: l10n,
                            onMenuTap: drawerScope?.openDrawer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Positioned(
                  //   left: 16,
                  //   right: 16,
                  //   top: contentTop + kToolbarHeight + headerSpacing,
                  //   child: ClipRect(
                  //     child: AnimatedSize(
                  //       duration: const Duration(milliseconds: 200),
                  //       curve: Curves.easeInOut,
                  //       alignment: Alignment.topCenter,
                  //       child: AnimatedOpacity(
                  //         duration: const Duration(milliseconds: 180),
                  //         curve: Curves.easeOut,
                  //         opacity: showDetails ? 1 : 0,
                  //         child: showDetails
                  //             ? Padding(
                  //                 padding: EdgeInsets.only(bottom: contentBottom),
                  //                 child: _HeaderDescription(l10n: l10n),
                  //               )
                  //             : const SizedBox.shrink(),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AppBarTopRow extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final double progress;
  final AppLocalizations l10n;

  const _AppBarTopRow({
    this.onMenuTap,
    required this.progress,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final menuAction =
        onMenuTap ??
        () {
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold != null && scaffold.hasEndDrawer) {
            scaffold.openEndDrawer();
          }
        };
    final circleRadius = lerpDouble(18, 26, progress)!;
    final spacerWidth = lerpDouble(8, 12, progress)!;
    final titleSize = lerpDouble(14, 16, progress)!;
    final subtitleSize = lerpDouble(11, 12, progress)!;
    final buttonSize = lerpDouble(36, 44, progress)!;
    final iconSize = lerpDouble(18, 22, progress)!;
    final iconSpacing = lerpDouble(6, 8, progress)!;

    return Row(
      children: [
        Container(
          width: circleRadius * 2,
          height: circleRadius * 2,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .18),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/logo/logo_g_mk.jpeg',
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: Color(0xFFEFF3FF),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF7B88B8),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(width: spacerWidth),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Digital Pharmacy Mk', //l10n.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: titleSize,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Drugs index', //l10n.appTagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFE0EAFF),
                  fontSize: subtitleSize,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
        ),
        _RoundedIconButton(
          icon: Icons.tips_and_updates_outlined,
          size: buttonSize,
          iconSize: iconSize,
          onTap: () => _showTips(context),
        ),
        SizedBox(width: iconSpacing),
        _RoundedIconButton(
          icon: Icons.menu_rounded,
          size: buttonSize,
          iconSize: iconSize,
          onTap: menuAction,
        ),
      ],
    );
  }
}

class _RoundedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  const _RoundedIconButton({
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Colors.white.withValues(alpha: isDark ? .18 : .22);
    final iconColor = Colors.white.withValues(alpha: onTap == null ? .5 : 1);
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}

class _HomeAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

void _showTips(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder:
        (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeTipsTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text("• ${l10n.homeTip1}"),
              const SizedBox(height: 6),
              Text("• ${l10n.homeTip2}"),
              const SizedBox(height: 6),
              Text("• ${l10n.homeTip3}"),
            ],
          ),
        ),
  );
}
