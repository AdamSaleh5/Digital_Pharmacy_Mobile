import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import '../../core/models/drug_search_mode.dart';
import '../../core/utils/apple_review_mode.dart';
import '../../core/widgets/drawer_controller_scope.dart';
import '../../core/widgets/ad_banner_placement.dart';
import '../favorites/view/favorites_page.dart';
import '../home/view/home_page.dart';
import '../pharmacies/view/pharmacies_page.dart';
import '../search/view/search_results_page.dart';
import '../settings/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.bannerOverride});

  /// Lets layout regressions reserve a real bottom slot without an ad SDK.
  @visibleForTesting
  final Widget? bannerOverride;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  static const _pages = [HomePage(), FavoritesPage(), SettingsPage()];

  List<_NavDestination> _buildDestinations(AppLocalizations l10n) {
    return [
      _NavDestination.page(
        label: l10n.navHome,
        icon: Icons.home_outlined,
        pageIndex: 0,
      ),
      _NavDestination.search(
        label: scientificIndexNavLabel(l10n),
        icon: Icons.biotech_outlined,
        mode: DrugSearchMode.scientific,
      ),
      _NavDestination.search(
        label: l10n.navTrade,
        icon: Icons.medical_services_outlined,
        mode: DrugSearchMode.trade,
      ),
      _NavDestination.search(
        label: l10n.navCompany,
        icon: Icons.factory_outlined,
        mode: DrugSearchMode.company,
      ),
      _NavDestination.search(
        label: l10n.navAgent,
        icon: Icons.handshake_outlined,
        mode: DrugSearchMode.agent,
      ),
      _NavDestination.pharmacy(
        label: l10n.navPharmacy,
        icon: Icons.local_pharmacy_outlined,
      ),
      _NavDestination.search(
        label: allProductsNavLabel(l10n),
        icon: Icons.medication_outlined,
        mode: DrugSearchMode.all,
      ),
      _NavDestination.page(
        label: l10n.navFavorites,
        icon: Icons.star_border,
        pageIndex: 1,
      ),
      _NavDestination.page(
        label: l10n.navSettings,
        icon: Icons.settings_outlined,
        pageIndex: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = _buildDestinations(l10n);
    return Scaffold(
      key: _scaffoldKey,
      extendBody: false,
      endDrawerEnableOpenDragGesture: true,
      drawerScrimColor: Colors.black.withValues(alpha: .35),
      endDrawer: _AppDrawer(
        currentPageIndex: _selectedIndex,
        destinations: destinations,
        l10n: l10n,
        onSelect: (destination) {
          _scaffoldKey.currentState?.closeEndDrawer();
          _handleDestination(destination);
        },
      ),
      body: DrawerControllerScope(
        openDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: _buildBannerBar(),
    );
  }

  void _handleDestination(_NavDestination destination) {
    switch (destination.kind) {
      case _DestinationKind.page:
        final pageIndex = destination.pageIndex ?? 0;
        if (pageIndex != _selectedIndex) {
          setState(() => _selectedIndex = pageIndex);
        }
        break;
      case _DestinationKind.search:
        final mode = destination.mode;
        if (mode != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => SearchResultsPage(initialQuery: '', searchMode: mode),
            ),
          );
        }
        break;
      case _DestinationKind.pharmacy:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PharmaciesPage(showStandaloneBanner: true),
          ),
        );
        break;
    }
  }

  Widget _buildBannerBar() {
    if (widget.bannerOverride != null) return widget.bannerOverride!;
    return const AdBannerPlacement(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
    );
  }
}

Widget _buildDrawerLogo() {
  return Image.asset(
    'assets/logo/logo_g_mk.jpeg',
    width: 56,
    height: 56,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        width: 56,
        height: 56,
        color: const Color(0xFFEFF3FF),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF7B88B8),
        ),
      );
    },
  );
}

enum _DestinationKind { page, search, pharmacy }

class _NavDestination {
  final String label;
  final IconData icon;
  final _DestinationKind kind;
  final int? pageIndex;
  final DrugSearchMode? mode;
  const _NavDestination._({
    required this.label,
    required this.icon,
    required this.kind,
    this.pageIndex,
    this.mode,
  });

  const _NavDestination.page({
    required String label,
    required IconData icon,
    required int pageIndex,
  }) : this._(
         label: label,
         icon: icon,
         kind: _DestinationKind.page,
         pageIndex: pageIndex,
       );

  const _NavDestination.search({
    required String label,
    required IconData icon,
    required DrugSearchMode mode,
  }) : this._(
         label: label,
         icon: icon,
         kind: _DestinationKind.search,
         mode: mode,
       );

  const _NavDestination.pharmacy({
    required String label,
    required IconData icon,
  }) : this._(label: label, icon: icon, kind: _DestinationKind.pharmacy);
}

class _AppDrawer extends StatelessWidget {
  final int currentPageIndex;
  final ValueChanged<_NavDestination> onSelect;
  final List<_NavDestination> destinations;
  final AppLocalizations l10n;
  const _AppDrawer({
    required this.currentPageIndex,
    required this.onSelect,
    required this.destinations,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: Directionality.of(context),
      child: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C7CFF), Color(0xFF7A5DFF)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.primary,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    ClipOval(child: _buildDrawerLogo()),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.appTagline,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...destinations.map((destination) {
                final selected =
                    destination.kind == _DestinationKind.page &&
                    destination.pageIndex == currentPageIndex;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(
                    destination.icon,
                    color:
                        selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                  ),
                  title: Text(
                    destination.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color:
                          selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing:
                      selected
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : const Icon(Icons.arrow_back_ios_new, size: 14),
                  onTap: () => onSelect(destination),
                );
              }),
              // Padding(
              //   padding: const EdgeInsets.all(16),
              //   child: OutlinedButton.icon(
              //     onPressed: () {},
              //     icon: const Icon(Icons.workspace_premium_outlined),
              //     label: Text(l10n.drawerActivate),
              //     style: OutlinedButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(vertical: 14),
              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
