// lib/features/substances/substance_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/models/substance_record.dart';
import '../../l10n/app_localizations.dart';
import 'substance_add_flow.dart';
import '../../core/components/inline_error.dart';

void showSubstanceDetailSheet(
  BuildContext context,
  WidgetRef ref,
  SubstanceRecord record,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SubstanceDetailSheet(record: record),
  );
}

class _SubstanceDetailSheet extends ConsumerStatefulWidget {
  final SubstanceRecord record;
  const _SubstanceDetailSheet({required this.record});

  @override
  ConsumerState<_SubstanceDetailSheet> createState() =>
      _SubstanceDetailSheetState();
}

class _SubstanceDetailSheetState extends ConsumerState<_SubstanceDetailSheet> {
  final _effektKey = GlobalKey();
  final _wechselwirkungenKey = GlobalKey();
  final _dosierungKey = GlobalKey();
  final _chemieKey = GlobalKey();
  bool _chemieExpanded = false;

  void _jumpTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final record = widget.record;
    final isMed = record.klasse == SubstanceKlasse.medikament;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: TraumColors.surfaceElevated,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TraumRadius.card),
          ),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isMed
                        ? TraumColors.roseRedDim
                        : TraumColors.indigoBlueDim,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMed ? Icons.medication_rounded : Icons.science_rounded,
                    color: isMed ? TraumColors.roseRed : TraumColors.indigoBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.substance,
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Badge(
                            label: isMed
                                ? l10n.substanceKlasseMed
                                : l10n.substanceKlasseSupp,
                            color: isMed
                                ? TraumColors.roseRed
                                : TraumColors.indigoBlue,
                          ),
                          if (record.kategorie != null)
                            _Badge(
                              label: record.kategorie!,
                              color: TraumColors.lavender,
                            ),
                          _Badge(
                            label: _statusLabel(l10n, record.datenStatus),
                            color: _statusColor(record.datenStatus),
                          ),
                          if (record.pflanzlich)
                            _Badge(
                              label: '🌿 ${l10n.substancePflanzlich}',
                              color: TraumColors.mintGreen,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _JumpChip(
                  label: l10n.substanceSectionEffekt,
                  onTap: () => _jumpTo(_effektKey),
                ),
                _JumpChip(
                  label: l10n.substanceSectionWechselwirkungen,
                  onTap: () => _jumpTo(_wechselwirkungenKey),
                ),
                _JumpChip(
                  label: l10n.substanceSectionDosierung,
                  onTap: () => _jumpTo(_dosierungKey),
                ),
                _JumpChip(
                  label: l10n.substanceSectionChemie,
                  onTap: () => _jumpTo(_chemieKey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Field(
              label: l10n.substanceFieldBeschreibung,
              value: record.beschreibung(lang),
            ),
            Container(key: _effektKey),
            _Field(
              label: l10n.substanceFieldEffekt,
              value: record.effekt(lang),
            ),
            _Field(
              label: l10n.substanceFieldIndikation,
              value: record.indikation(lang),
            ),
            Container(key: _wechselwirkungenKey),
            _WechselwirkungenBlock(
              text: record.wechselwirkungen(lang),
              l10n: l10n,
            ),
            _Field(
              label: l10n.substanceFieldWarnungen,
              value: record.warnungen(lang),
            ),
            _Field(
              label: l10n.substanceFieldKontraindikationen,
              value: record.kontraindikationen(lang),
            ),
            _Field(
              label: l10n.substanceFieldSpeziellePopulationen,
              value: record.spezellePopulationen(lang),
            ),
            Container(key: _dosierungKey),
            _DosierungTable(record: record, lang: lang, l10n: l10n),
            _TopNebenwirkungenSection(record: record, lang: lang, l10n: l10n),
            Container(key: _chemieKey),
            _ChemieSection(
              record: record,
              expanded: _chemieExpanded,
              onToggle: () =>
                  setState(() => _chemieExpanded = !_chemieExpanded),
              l10n: l10n,
            ),
            _AttributionFooter(record: record, l10n: l10n),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: TraumColors.coralOrange,
                  foregroundColor: TraumColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  openAddFlowForRecord(context, ref, record);
                },
                child: Text(
                  l10n.substanceAddToMyMeds,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(DatenStatus status) {
  switch (status) {
    case DatenStatus.vollstaendig:
      return TraumColors.mintGreen;
    case DatenStatus.teilweise:
      return TraumColors.amberGold;
    case DatenStatus.nurChemie:
      return TraumColors.onBackgroundSubtle;
  }
}

String _statusLabel(AppLocalizations l10n, DatenStatus status) {
  switch (status) {
    case DatenStatus.vollstaendig:
      return l10n.substanceStatusVollstaendig;
    case DatenStatus.teilweise:
      return l10n.substanceStatusTeilweise;
    case DatenStatus.nurChemie:
      return l10n.substanceStatusNurChemie;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontFamily: 'DMSans',
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _JumpChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _JumpChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.chip),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
          fontSize: 11,
        ),
      ),
    ),
  );
}

/// Zeigt ein Feld nur, wenn ein Wert vorhanden ist; NULL wird bewusst NICHT
/// gerendert (statt einer leeren "keine Angabe"-Zeile für jedes fehlende
/// Feld, was die Detailansicht bei vielen `teilweise`/`nur_chemie`-Substanzen
/// unlesbar machen würde). Pflichtfelder mit expliziter "keine Angabe"-Anzeige
/// sind die Dosierungs-Tabelle (_DosierungTable) und Wechselwirkungen
/// (_WechselwirkungenBlock), da diese sicherheitsrelevant sind.
class _Field extends StatelessWidget {
  final String label;
  final String? value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value!,
            style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WechselwirkungenBlock extends StatelessWidget {
  final String? text;
  final AppLocalizations l10n;
  const _WechselwirkungenBlock({required this.text, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.substanceSectionWechselwirkungen,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TraumColors.roseRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(TraumRadius.chip),
              border: Border(
                left: BorderSide(color: TraumColors.roseRed, width: 3),
              ),
            ),
            child: Text(
              text != null && text!.trim().isNotEmpty
                  ? text!
                  : l10n.substanceKeineAngabe,
              style: TextStyle(
                color: text != null && text!.trim().isNotEmpty
                    ? TraumColors.roseRed.withValues(alpha: 0.9)
                    : TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DosierungTable extends StatelessWidget {
  final SubstanceRecord record;
  final String lang;
  final AppLocalizations l10n;
  const _DosierungTable({
    required this.record,
    required this.lang,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      (l10n.substanceDosisErwachsene, record.dosierung.erwachsene(lang)),
      (l10n.substanceDosisKinder, record.dosierung.kinder(lang)),
      (l10n.substanceDosisSenioren, record.dosierung.senioren(lang)),
      (
        l10n.substanceDosisSchwangerschaft,
        record.dosierung.schwangerschaft(lang),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.substanceSectionDosierung,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      r.$1,
                      style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$2 ?? l10n.substanceKeineAngabe,
                      style: TextStyle(
                        color: r.$2 != null
                            ? TraumColors.onBackgroundMuted
                            : TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (record.maxDosisHinweis != null) ...[
            const SizedBox(height: 4),
            Text(
              '⚠ ${record.maxDosisHinweis}',
              style: const TextStyle(
                color: TraumColors.amberGold,
                fontFamily: 'DMSans',
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopNebenwirkungenSection extends ConsumerWidget {
  final SubstanceRecord record;
  final String lang;
  final AppLocalizations l10n;
  const _TopNebenwirkungenSection({
    required this.record,
    required this.lang,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(substanceRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder(
        future: repo.topNebenwirkungen(record.id),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.substanceSectionTopNebenwirkungen,
                  style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                ...items.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: TraumColors.coralOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            n.label(lang),
                            style: const TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (n.meldungen != null)
                          Text(
                            '${n.meldungen}',
                            style: const TextStyle(
                              color: TraumColors.onBackgroundSubtle,
                              fontFamily: 'DMSans',
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (e, _) => InlineError(e),
    );
  }
}

class _ChemieSection extends StatelessWidget {
  final SubstanceRecord record;
  final bool expanded;
  final VoidCallback onToggle;
  final AppLocalizations l10n;
  const _ChemieSection({
    required this.record,
    required this.expanded,
    required this.onToggle,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('SMILES', record.smiles),
      ('InChIKey', record.inchikey),
      ('IUPAC', record.iupacName),
      (l10n.substanceChemieMolekulargewicht, record.molekulargewicht),
    ].where((r) => r.$2 != null).toList();
    if (rows.isEmpty && record.summenformel == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: TraumColors.surface,
                borderRadius: BorderRadius.circular(TraumRadius.chip),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.substanceSectionChemie,
                      style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: TraumColors.onBackgroundMuted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            if (record.summenformel != null)
              _ChemieRow(
                label: l10n.substanceChemieSummenformel,
                value: record.summenformel!,
              ),
            ...rows.map((r) => _ChemieRow(label: r.$1, value: r.$2!)),
          ],
        ],
      ),
    );
  }
}

class _ChemieRow extends StatelessWidget {
  final String label;
  final String value;
  const _ChemieRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AttributionFooter extends StatelessWidget {
  final SubstanceRecord record;
  final AppLocalizations l10n;
  const _AttributionFooter({required this.record, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final hasWiki = record.quellenTags.any(
      (t) => t.startsWith('wikipedia') || t == 'wikidata',
    );
    if (!hasWiki && record.quellenTags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (record.quellenTags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: record.quellenTags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: TraumColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: TraumColors.onBackgroundSubtle,
                          fontFamily: 'DMSans',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          if (hasWiki) ...[
            const SizedBox(height: 8),
            Text(
              l10n.substanceWikipediaAttribution,
              style: const TextStyle(
                color: TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans',
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
