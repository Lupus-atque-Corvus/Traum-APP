import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/models/substance_info.dart';
import 'substance_detail_sheet.dart';

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
    return Scaffold(
      backgroundColor: TraumColors.background,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: InputDecoration(
              hintText: 'Substanz suchen…',
              hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle,
                  fontFamily: 'DMSans'),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: TraumColors.onBackgroundSubtle),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: TraumColors.onBackgroundSubtle),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: TraumColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        Expanded(
          child: _query.isEmpty
              ? _CategoryGrid(onCategoryTap: (cat) {
                  _ctrl.text = cat;
                  setState(() => _query = cat);
                })
              : _SearchResults(query: _query),
        ),
      ]),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final void Function(String) onCategoryTap;
  const _CategoryGrid({required this.onCategoryTap});

  static const _cats = [
    ('Vitamine', Icons.brightness_5_rounded, TraumColors.mintGreen),
    ('Mineralien', Icons.grain_rounded, TraumColors.indigoBlue),
    ('Schmerzmittel', Icons.healing_rounded, TraumColors.roseRed),
    ('Antidiabetika', Icons.bloodtype_rounded, TraumColors.coralOrange),
    ('Omega-3', Icons.water_drop_rounded, TraumColors.indigoBlue),
    ('Adaptogene', Icons.eco_rounded, TraumColors.mintGreen),
    ('Antidepressiva', Icons.psychology_rounded, TraumColors.coralOrange),
    ('Herz-Kreislauf', Icons.favorite_rounded, TraumColors.roseRed),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
        children: _cats.map((c) => GestureDetector(
          onTap: () => onCategoryTap(c.$1),
          child: Container(
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
              border: Border.all(color: c.$3.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const SizedBox(width: 14),
              Icon(c.$2, color: c.$3, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(c.$1,
                    style: const TextStyle(color: TraumColors.onBackground,
                        fontFamily: 'DMSans', fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ]),
          ),
        )).toList(),
      );
}

class _SearchResults extends ConsumerWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(substanceSearchProvider(query));
    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_off_rounded, size: 48,
                  color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('Keine Ergebnisse für "$query"',
                  style: const TextStyle(color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans', fontSize: 14)),
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
          child: CircularProgressIndicator(color: TraumColors.coralOrange)),
      error: (e, _) => Center(
          child: Text('Fehler: $e',
              style: const TextStyle(color: TraumColors.roseRed,
                  fontFamily: 'DMSans'))),
    );
  }
}

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
            width: 40, height: 40,
            decoration: BoxDecoration(color: dimColor, shape: BoxShape.circle),
            child: Icon(
              isMed ? Icons.medication_rounded : Icons.science_rounded,
              color: color, size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(substance.name,
                  style: const TextStyle(color: TraumColors.onBackground,
                      fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
              Row(children: [
                if (substance.category != null) ...[
                  Text(substance.category!,
                      style: const TextStyle(color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans', fontSize: 12)),
                  const SizedBox(width: 6),
                ],
                if (substance.evidenceGrade != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: TraumColors.mintGreenDim,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Evidenz ${substance.evidenceGrade}',
                        style: const TextStyle(color: TraumColors.mintGreen,
                            fontFamily: 'DMSans', fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                if (!substance.isLocal) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: TraumColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Online',
                        style: TextStyle(color: TraumColors.onBackgroundSubtle,
                            fontFamily: 'DMSans', fontSize: 10)),
                  ),
                ],
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: TraumColors.onBackgroundSubtle, size: 18),
        ]),
      ),
    );
  }
}
