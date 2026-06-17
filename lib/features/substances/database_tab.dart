import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/models/substance_info.dart';
import 'substance_detail_sheet.dart';

// ─── State-Provider für aktiven Typ-Filter ───────────────────────────────────
final _typeFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

class DatabaseTab extends ConsumerStatefulWidget {
  const DatabaseTab({super.key});

  @override
  ConsumerState<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends ConsumerState<DatabaseTab> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeFilter = ref.watch(_typeFilterProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      body: Column(children: [
        // Offline-Status-Banner
        _OfflineStatusBanner(),
        // Suchfeld
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: InputDecoration(
              hintText: 'Substanz suchen…',
              hintStyle: const TextStyle(
                  color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: TraumColors.onBackgroundSubtle),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: TraumColors.onBackgroundSubtle),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                      })
                  : null,
              filled: true,
              fillColor: TraumColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && _ctrl.text == v) {
                  setState(() => _query = v.trim());
                }
              });
            },
          ),
        ),
        // Typ-Filter-Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            _TypeChip(
              label: 'Alle',
              active: typeFilter == null,
              onTap: () =>
                  ref.read(_typeFilterProvider.notifier).state = null,
            ),
            const SizedBox(width: 8),
            _TypeChip(
              label: 'Medikamente',
              active: typeFilter == 'medication',
              color: TraumColors.roseRed,
              onTap: () => ref.read(_typeFilterProvider.notifier).state =
                  typeFilter == 'medication' ? null : 'medication',
            ),
            const SizedBox(width: 8),
            _TypeChip(
              label: 'Supplements',
              active: typeFilter == 'supplement',
              color: TraumColors.indigoBlue,
              onTap: () => ref.read(_typeFilterProvider.notifier).state =
                  typeFilter == 'supplement' ? null : 'supplement',
            ),
          ]),
        ),
        // Inhalt
        Expanded(
          child: _query.isEmpty
              ? _CategoryGrid(onCategoryTap: (cat) {
                  _ctrl.text = cat;
                  setState(() => _query = cat);
                })
              : _SearchResults(query: _query, typeFilter: typeFilter),
        ),
      ]),
    );
  }
}

// ─── Typ-Filter-Chip ─────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.active,
    this.color = TraumColors.lavender,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.2) : TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.chip),
          border: Border.all(
            color: active ? color : TraumColors.surfaceVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Kategorie-Grid ──────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final void Function(String) onCategoryTap;
  const _CategoryGrid({required this.onCategoryTap});

  static const _cats = [
    ('Vitamine', Icons.brightness_5_rounded, TraumColors.mintGreen),
    ('Mineralien', Icons.grain_rounded, TraumColors.indigoBlue),
    ('Omega-3', Icons.water_drop_rounded, TraumColors.cyanBlue),
    ('Aminosäuren', Icons.science_rounded, TraumColors.indigoBlue),
    ('Adaptogene', Icons.eco_rounded, TraumColors.mintGreen),
    ('Antioxidantien', Icons.shield_rounded, TraumColors.amberGold),
    ('Schmerzmittel', Icons.healing_rounded, TraumColors.roseRed),
    ('Herz-Kreislauf', Icons.favorite_rounded, TraumColors.roseRed),
    ('Antidepressiva', Icons.psychology_rounded, TraumColors.lavender),
    ('Antibiotika', Icons.coronavirus_rounded, TraumColors.coralOrange),
    ('Antidiabetika', Icons.bloodtype_rounded, TraumColors.coralOrange),
    ('Darmgesundheit', Icons.spa_rounded, TraumColors.mintGreen),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: _cats
          .map((c) => GestureDetector(
                onTap: () => onCategoryTap(c.$1),
                child: Container(
                  decoration: BoxDecoration(
                    color: TraumColors.surface,
                    borderRadius:
                        BorderRadius.circular(TraumRadius.card),
                    border: Border.all(
                        color: c.$3.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 14),
                    Icon(c.$2, color: c.$3, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(c.$1,
                          style: const TextStyle(
                              color: TraumColors.onBackground,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ]),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Suchergebnisse ──────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  final String query;
  final String? typeFilter;
  const _SearchResults({required this.query, this.typeFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(substanceSearchProvider(query));
    return resultsAsync.when(
      data: (all) {
        final results = typeFilter != null
            ? all.where((s) => s.type == typeFilter).toList()
            : all;
        if (results.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_off_rounded,
                  size: 48,
                  color:
                      TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('Keine Ergebnisse für "$query"',
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 14)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: results.length,
          itemBuilder: (ctx, i) => _ResultCard(substance: results[i]),
        );
      },
      loading: () => const Center(
          child:
              CircularProgressIndicator(color: TraumColors.coralOrange)),
      error: (e, _) => Center(
          child: Text('Fehler: $e',
              style: const TextStyle(
                  color: TraumColors.roseRed, fontFamily: 'DMSans'))),
    );
  }
}

// ─── Ergebnis-Karte ───────────────────────────────────────────────────────────

class _ResultCard extends ConsumerWidget {
  final SubstanceInfo substance;
  const _ResultCard({required this.substance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMed = substance.type == 'medication';
    final color = isMed ? TraumColors.roseRed : TraumColors.indigoBlue;
    final dimColor = isMed ? TraumColors.roseRedDim : TraumColors.indigoBlueDim;

    return GestureDetector(
      onTap: () => showSubstanceDetailSheet(context, substance),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: dimColor, shape: BoxShape.circle),
            child: Icon(
              isMed ? Icons.medication_rounded : Icons.science_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(substance.name,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Row(children: [
                if (substance.category != null) ...[
                  Expanded(
                    child: Text(substance.category!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                ],
                if (substance.evidenceGrade != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: TraumColors.mintGreenDim,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Evidenz ${substance.evidenceGrade}',
                        style: const TextStyle(
                            color: TraumColors.mintGreen,
                            fontFamily: 'DMSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
              ]),
              if (substance.commonDosage != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.straighten_rounded,
                      size: 12, color: TraumColors.onBackgroundSubtle),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(substance.commonDosage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: TraumColors.onBackgroundSubtle,
                            fontFamily: 'DMSans',
                            fontSize: 11)),
                  ),
                ]),
              ],
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: TraumColors.onBackgroundSubtle, size: 18),
        ]),
      ),
    );
  }
}

// ─── Offline-Status-Banner ────────────────────────────────────────────────────

class _OfflineStatusBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(substanceDbCountProvider);
    return countAsync.when(
      data: (count) {
        if (count > 0) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TraumColors.mintGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(TraumRadius.chip),
              border: Border.all(
                  color: TraumColors.mintGreen.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.offline_bolt_rounded,
                  color: TraumColors.mintGreen, size: 16),
              const SizedBox(width: 8),
              Text('$count Einträge offline verfügbar',
                  style: const TextStyle(
                      color: TraumColors.mintGreen,
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ]),
          );
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: TraumColors.surfaceVariant,
            borderRadius: BorderRadius.circular(TraumRadius.chip),
          ),
          child: const Row(children: [
            Icon(Icons.wifi_rounded,
                color: TraumColors.onBackgroundSubtle, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Wird beim nächsten Start initialisiert…',
                style: TextStyle(
                    color: TraumColors.onBackgroundSubtle,
                    fontFamily: 'DMSans',
                    fontSize: 12),
              ),
            ),
          ]),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
