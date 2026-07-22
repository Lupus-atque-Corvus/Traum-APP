import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'amount_entry_sheet.dart';
import 'barcode_scanner_screen.dart';
import 'food_api/food_source.dart';
import 'nutrition_providers.dart';

class MealTemplateSheet extends ConsumerStatefulWidget {
  final String mealType;
  final String date;

  const MealTemplateSheet({
    super.key,
    required this.mealType,
    required this.date,
  });

  @override
  ConsumerState<MealTemplateSheet> createState() =>
      _MealTemplateSheetState();
}

class _MealTemplateSheetState
    extends ConsumerState<MealTemplateSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final text = _searchCtrl.text.trim();
    // Lokale Liste reagiert sofort; die Multi-Source-Suche (Netzwerk) wird
    // debounced (400ms) — gleiches Muster wie im Produkte-Tab.
    ref.read(productSearchQueryProvider.notifier).state = text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(multiSourceSearchQueryProvider.notifier).state = text;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    ref.read(productSearchQueryProvider.notifier).state = '';
    ref.read(multiSourceSearchQueryProvider.notifier).state = '';
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  FoodProductsCompanion _toCompanion(FoodSearchResult r) =>
      FoodProductsCompanion.insert(
        name: r.name,
        brand: Value(r.brand),
        barcode: Value(r.barcode),
        imageUrl: Value(r.imageUrl),
        caloriesPer100g: r.kcalPer100g,
        proteinPer100g: r.proteinPer100g,
        carbsPer100g: r.carbsPer100g,
        fatPer100g: r.fatPer100g,
        sugarPer100g: Value(r.sugarPer100g),
        fiberPer100g: Value(r.fiberPer100g),
        saltPer100g: Value(r.saltPer100g),
        sourceApi: Value(r.source),
        sourceId: Value(r.sourceId),
        createdAt: DateTime.now(),
      );

  void _openAmount(BuildContext ctx, FoodProduct p) {
    Navigator.pop(ctx); // close template sheet first
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmountEntrySheet(
        product: p,
        mealType: widget.mealType,
        date: widget.date,
      ),
    );
  }

  /// Tap auf einen lokalen Produkt-Datensatz (Browse-Modus, kein Suchtext).
  void _handleLocalTap(BuildContext ctx, FoodProduct product) {
    _openAmount(ctx, product);
  }

  /// Tap auf einen Multi-Source-Suchtreffer — gleiche Cache-Logik wie im
  /// Produkte-Tab (lokale Treffer per ID zurückholen statt neu anlegen).
  Future<void> _handleSearchResultTap(
      BuildContext ctx, FoodSearchResult result) async {
    final dao = ref.read(foodProductsDaoProvider);
    FoodProduct? product;
    if (result.localId != null) {
      product = await dao.getById(result.localId!);
    }
    product ??= await dao.upsertFromSource(_toCompanion(result));
    if (result.localId == null) {
      ref.invalidate(allProductsProvider);
    }
    if (!ctx.mounted) return;
    _openAmount(ctx, product);
  }

  Future<void> _openScanner(BuildContext ctx) async {
    final product = await Navigator.push<FoodProduct>(
      ctx,
      MaterialPageRoute(
          builder: (_) => const BarcodeScannerScreen()),
    );
    if (product != null && ctx.mounted) {
      _openAmount(ctx, product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = ref.watch(productSearchQueryProvider);
    final searchActive = query.trim().isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: TraumColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TraumColors.surfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.searchFoodHint,
                  hintStyle: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundSubtle,
                      fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: TraumColors.onBackgroundMuted),
                  filled: true,
                  fillColor: TraumColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _openScanner(context),
              icon: const Icon(Icons.qr_code_scanner,
                  color: TraumColors.mintGreen),
            ),
          ]),
        ),
        Expanded(
          child: searchActive
              ? _MultiSourceResultsList(
                  l10n: l10n,
                  onTap: (r) => _handleSearchResultTap(context, r),
                )
              : _LocalBrowseList(
                  onTap: (p) => _handleLocalTap(context, p),
                ),
        ),
      ]),
    );
  }
}

/// Browse-Modus (kein Suchtext): zuletzt verwendete lokale Produkte.
class _LocalBrowseList extends ConsumerWidget {
  final void Function(FoodProduct) onTap;
  const _LocalBrowseList({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productSearchProvider);
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.noProductsFound,
                style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted)),
          );
        }
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (_, i) {
            final p = products[i];
            return ListTile(
              title: Text(p.name,
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontWeight: FontWeight.w500)),
              subtitle: Text(
                  '${p.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted,
                      fontSize: 12)),
              trailing: const Icon(
                  Icons.add_circle_outline,
                  color: TraumColors.mintGreen),
              onTap: () => onTap(p),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: TraumColors.mintGreen,
              strokeWidth: 2)),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Aktiver Suchmodus: Multi-Source-Ergebnisse (lokal + OpenFoodFacts + USDA),
/// gleiche Quelle wie der Produkte-Tab.
class _MultiSourceResultsList extends ConsumerWidget {
  final AppLocalizations l10n;
  final void Function(FoodSearchResult) onTap;
  const _MultiSourceResultsList({required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(multiSourceSearchProvider);
    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Text(l10n.noProductsFound,
                style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted)),
          );
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (_, i) {
            final r = results[i];
            return ListTile(
              title: Text(r.name,
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontWeight: FontWeight.w500)),
              subtitle: Text(
                  '${r.kcalPer100g.toStringAsFixed(0)} kcal / 100g'
                  '${r.brand != null ? ' · ${r.brand}' : ''}',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted,
                      fontSize: 12)),
              trailing: const Icon(
                  Icons.add_circle_outline,
                  color: TraumColors.mintGreen),
              onTap: () => onTap(r),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: TraumColors.mintGreen,
              strokeWidth: 2)),
      error: (_, _) => Center(
        child: Text(l10n.searchOffline,
            style: TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted)),
      ),
    );
  }
}
