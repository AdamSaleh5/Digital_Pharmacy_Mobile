import 'package:flutter/material.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../core/widgets/inline_native_ad_card.dart';
import '../../../core/config/app_config.dart';
import '../../../providers/app_provider.dart';
import '../../search/view/medication_selection_results_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String q = "";

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context)!;

    final favDrugs = app.serverFavorites;

    final filtered =
        favDrugs.where((d) {
          final query = q.trim().toLowerCase();
          if (query.isEmpty) return true;
          return d.name.toLowerCase().contains(query);
        }).toList();

    return Scaffold(
      appBar: AppHeader(
        title: l10n.favoritesTitle,
        subtitle: l10n.favoritesSubtitle,
      ),
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (app.legacyFavoriteCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(l10n.legacyFavoritesRetained),
                ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC857), Color(0xFFFF9A62)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.favoritesCardTitle,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            l10n.favoritesCardSubtitle(favDrugs.length),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.favoritesSearchHint,
                ),
              ),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.black45,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.favoritesEmpty, textAlign: TextAlign.center),
                    ],
                  ),
                )
              else
                ...interleaveNativeAds(
                  filtered.asMap().entries.map((entry) {
                    final d = entry.value;
                    return _favoritesAnimated(
                      order: entry.key,
                      child: Dismissible(
                        key: ValueKey(d.key),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9A62), Color(0xFFFF6B6B)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => app.toggleFavorite(d.key),
                        child: Card(
                          child: ListTile(
                            title: Text(d.name.isEmpty ? '#${d.id}' : d.name),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => MedicationSelectionResultsPage(
                                        id: d.id,
                                        title:
                                            d.name.isEmpty
                                                ? '#${d.id}'
                                                : d.name,
                                        searchType:
                                            MedicationSearchType.tradeName,
                                      ),
                                ),
                              );
                              if (context.mounted) app.onCompletedDrugDetails();
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _favoritesAnimated({required int order, required Widget child}) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 320 + order * 80),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: child,
        ),
      );
    },
  );
}
