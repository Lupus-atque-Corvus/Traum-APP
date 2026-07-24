// lib/features/substances/database_tab.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/models/substance_record.dart';
import '../../l10n/app_localizations.dart';
import 'substance_detail_sheet.dart';

final _typeFilterProvider = StateProvider.autoDispose<SubstanceKlasse?>((ref) => null);
final _pflanzlichOnlyProvider = StateProvider.autoDispose<bool>((ref) => false);

class DatabaseTab extends ConsumerStatefulWidget {
  const DatabaseTab({super.key});

  @override
  ConsumerState<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends ConsumerState<DatabaseTab> {
  final _ctrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeFilter = ref.watch(_typeFilterProvider);
    final pflanzlichOnly = ref.watch(_pflanzlichOnlyProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: InputDecoration(
              hintText: l10n.searchSubstanceHint,
              hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
              prefixIcon: const Icon(Icons.search_rounded, color: TraumColors.onBackgroundSubtle),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: TraumColors.onBackgroundSubtle),
                      onPressed: () {
                        _debounce?.cancel();
                        _ctrl.clear();
                        setState(() => _query = '');
                      })
                  : null,
              filled: true,
              fillColor: TraumColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                if (mounted && _ctrl.text == v) setState(() => _query = v.trim());
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _FilterChip(
              label: l10n.substanceFilterAll,
              active: typeFilter == null,
              onTap: () => ref.read(_typeFilterProvider.notifier).state = null,
            ),
            _FilterChip(
              label: l10n.substanceMedications,
              active: typeFilter == SubstanceKlasse.medikament,
              color: TraumColors.roseRed,
              onTap: () => ref.read(_typeFilterProvider.notifier).state =
                  typeFilter == SubstanceKlasse.medikament ? null : SubstanceKlasse.medikament,
            ),
            _FilterChip(
              label: l10n.substanceSupplements,
              active: typeFilter == SubstanceKlasse.supplement,
              color: TraumColors.indigoBlue,
              onTap: () => ref.read(_typeFilterProvider.notifier).state =
                  typeFilter == SubstanceKlasse.supplement ? null : SubstanceKlasse.supplement,
            ),
            _FilterChip(
              label: '🌿 ${l10n.substanceFilterPflanzlich}',
              active: pflanzlichOnly,
              color: TraumColors.mintGreen,
              onTap: () => ref.read(_pflanzlichOnlyProvider.notifier).state = !pflanzlichOnly,
            ),
          ]),
        ),
        Expanded(
          child: _query.isEmpty
              ? _CategoryGrid(onCategoryTap: (cat) {
                  _debounce?.cancel();
                  _ctrl.text = cat;
                  setState(() => _query = cat);
                })
              : _SearchResults(
                  query: _query, typeFilter: typeFilter, pflanzlichOnly: pflanzlichOnly),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, this.color = TraumColors.lavender, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.2) : TraumColors.surface,
            borderRadius: BorderRadius.circular(TraumRadius.chip),
            border: Border.all(color: active ? color : TraumColors.surfaceVariant),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? color : TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ),
      );
}

/// Icon-Zuordnung für die ~12 realen ATC-Top-Kategorien aus der Referenz-DB.
/// Unbekannte/neue Kategorien fallen auf ein generisches Icon zurück, statt
/// einen Kategorienamen zu verstecken (siehe CLAUDE.md §6 der Datenbank).
IconData _categoryIcon(String kategorie) {
  switch (kategorie) {
    case 'Nervensystem': return Icons.psychology_rounded;
    case 'Herz-Kreislauf-System': return Icons.favorite_rounded;
    case 'Antiinfektiva (systemisch)': return Icons.coronavirus_rounded;
    case 'Atemwege': return Icons.air_rounded;
    case 'Alimentäres System und Stoffwechsel': return Icons.restaurant_rounded;
    case 'Muskel- und Skelettsystem': return Icons.fitness_center_rounded;
    case 'Blut und blutbildende Organe': return Icons.bloodtype_rounded;
    case 'Dermatika': return Icons.face_retouching_natural_rounded;
    case 'Sinnesorgane': return Icons.visibility_rounded;
    case 'Urogenitalsystem und Sexualhormone': return Icons.spa_rounded;
    case 'Antineoplastische und immunmodulierende Mittel': return Icons.shield_rounded;
    default: return Icons.category_rounded;
  }
}

class _CategoryGrid extends ConsumerWidget {
  final void Function(String) onCategoryTap;
  const _CategoryGrid({required this.onCategoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(substanceCategoriesProvider);
    return catsAsync.when(
      data: (cats) => GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
        children: cats
            .map((c) => GestureDetector(
                  onTap: () => onCategoryTap(c),
                  child: Container(
                    decoration: BoxDecoration(
                      color: TraumColors.surface,
                      borderRadius: BorderRadius.circular(TraumRadius.card),
                      border: Border.all(color: TraumColors.lavender.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      const SizedBox(width: 14),
                      Icon(_categoryIcon(c), color: TraumColors.lavender, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(c,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.coralOrange)),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final SubstanceKlasse? typeFilter;
  final bool pflanzlichOnly;
  const _SearchResults({required this.query, this.typeFilter, required this.pflanzlichOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final resultsAsync = ref.watch(substanceSearchProvider(query));
    return resultsAsync.when(
      data: (all) {
        var results = typeFilter != null ? all.where((s) => s.klasse == typeFilter).toList() : all;
        if (pflanzlichOnly) results = results.where((s) => s.pflanzlich).toList();
        if (results.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(l10n.noResultsForQuery(query),
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 14)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: results.length,
          itemBuilder: (ctx, i) => _ResultCard(record: results[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.coralOrange)),
      error: (e, _) => Center(
          child: Text(l10n.errorWithDetail(e.toString()),
              style: const TextStyle(color: TraumColors.roseRed, fontFamily: 'DMSans'))),
    );
  }
}

Color _statusColor(DatenStatus status) {
  switch (status) {
    case DatenStatus.vollstaendig: return TraumColors.mintGreen;
    case DatenStatus.teilweise: return TraumColors.amberGold;
    case DatenStatus.nurChemie: return TraumColors.onBackgroundSubtle;
  }
}

String _statusLabel(AppLocalizations l10n, DatenStatus status) {
  switch (status) {
    case DatenStatus.vollstaendig: return l10n.substanceStatusVollstaendig;
    case DatenStatus.teilweise: return l10n.substanceStatusTeilweise;
    case DatenStatus.nurChemie: return l10n.substanceStatusNurChemie;
  }
}

class _ResultCard extends ConsumerWidget {
  final SubstanceRecord record;
  const _ResultCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final isMed = record.klasse == SubstanceKlasse.medikament;
    final color = isMed ? TraumColors.roseRed : TraumColors.indigoBlue;
    final dimColor = isMed ? TraumColors.roseRedDim : TraumColors.indigoBlueDim;
    final snippet = record.beschreibung(lang) ?? record.effekt(lang);
    final statusColor = _statusColor(record.datenStatus);

    return GestureDetector(
      onTap: () => showSubstanceDetailSheet(context, ref, record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: dimColor, borderRadius: BorderRadius.circular(6)),
              child: Text(isMed ? l10n.substanceKlasseMed : l10n.substanceKlasseSupp,
                  style: TextStyle(
                      color: color, fontFamily: 'DMSans', fontSize: 9, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(record.substance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(_statusLabel(l10n, record.datenStatus),
                  style: TextStyle(
                      color: statusColor, fontFamily: 'DMSans', fontSize: 9, fontWeight: FontWeight.w600)),
            ),
          ]),
          if (record.kategorie != null) ...[
            const SizedBox(height: 4),
            Text(record.kategorie!,
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
          ],
          if (snippet != null) ...[
            const SizedBox(height: 6),
            Text(snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 12, height: 1.4)),
          ],
          if (record.pflanzlich || record.quellenTags.any((t) => t.startsWith('wikipedia'))) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              if (record.pflanzlich) _SourceChip(label: '🌿 ${l10n.substancePflanzlich}'),
              if (record.quellenTags.any((t) => t.startsWith('wikipedia')))
                _SourceChip(label: '📖 Wikipedia'),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  const _SourceChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration:
            BoxDecoration(color: TraumColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: const TextStyle(color: TraumColors.lavender, fontFamily: 'DMSans', fontSize: 9)),
      );
}
