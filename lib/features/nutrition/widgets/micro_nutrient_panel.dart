import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart';
import '../micro_nutrients.dart';
import '../nutrition_providers.dart';
import 'nutrient_bar_row.dart';

/// Aufklappbarer Bereich in der Makro-Karte: Mikronährstoff-Balken +
/// "Supplements heute"-Abhakliste. Standard eingeklappt.
class MicroNutrientPanel extends ConsumerStatefulWidget {
  final String dateStr;
  const MicroNutrientPanel({super.key, required this.dateStr});

  @override
  ConsumerState<MicroNutrientPanel> createState() =>
      _MicroNutrientPanelState();
}

class _MicroNutrientPanelState extends ConsumerState<MicroNutrientPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 18,
                  color: TraumColors.mintGreen),
              const SizedBox(width: 4),
              const Text('Mikronährstoffe & Supplements',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TraumColors.mintGreen)),
            ]),
          ),
        ),
        if (_expanded) _buildExpanded(),
      ],
    );
  }

  Widget _buildExpanded() {
    final microsAsync = ref.watch(dailyMicrosProvider(widget.dateStr));
    return microsAsync.when(
      data: (micros) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final meta in kNutrientCatalog)
            NutrientBarRow(
              label: meta.label,
              current: micros[meta.key],
              goal: meta.dailyRef,
              unit: meta.unit,
            ),
          const SizedBox(height: 12),
          _SupplementsToday(dateStr: widget.dateStr),
        ],
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
            child: CircularProgressIndicator(
                color: TraumColors.mintGreen, strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SupplementsToday extends ConsumerWidget {
  final String dateStr;
  const _SupplementsToday({required this.dateStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppsAsync = ref.watch(supplementsStreamProvider);
    final logsAsync = ref.watch(supplementLogsTodayProvider);

    return suppsAsync.when(
      data: (supps) {
        final active = supps.where((s) => s.isActive).toList();
        if (active.isEmpty) return const SizedBox.shrink();
        final logs = logsAsync.valueOrNull ?? const [];
        final takenIds = logs.map((l) => l.supplementId).toSet();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SUPPLEMENTS HEUTE',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: TraumColors.indigoBlue,
                    letterSpacing: 0.6)),
            const SizedBox(height: 4),
            ...active.map((s) {
              final taken = takenIds.contains(s.id);
              final dose =
                  '${s.dosageAmount ?? ''} ${s.dosageUnit ?? ''}'.trim();
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: TraumColors.indigoBlue,
                value: taken,
                title: Text(s.name,
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        color: TraumColors.onBackground)),
                subtitle: dose.isEmpty
                    ? null
                    : Text(dose,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            color: TraumColors.onBackgroundMuted)),
                onChanged: (_) => _toggle(ref, s, taken, logs),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _toggle(
      WidgetRef ref, Supplement s, bool taken, List<SupplementLog> logs) async {
    final dao = ref.read(supplementDaoProvider);
    if (taken) {
      for (final l in logs.where((l) => l.supplementId == s.id)) {
        await dao.deleteLog(l.id);
      }
    } else {
      await dao.insertLog(SupplementLogsCompanion.insert(
        supplementId: s.id,
        takenAt: DateTime.now(),
      ));
    }
    ref.invalidate(supplementLogsTodayProvider);
    ref.invalidate(dailyMicrosProvider(dateStr));
  }
}
