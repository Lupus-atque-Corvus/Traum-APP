import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/components/components.dart';
import '../../../data/database/traum_database.dart';
import '../../../l10n/app_localizations.dart';

class AbstinencePage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const AbstinencePage({super.key, required this.onNext});

  @override
  ConsumerState<AbstinencePage> createState() => _AbstinencePageState();
}

class _AbstinencePageState extends ConsumerState<AbstinencePage> {
  final _nameCtrl = TextEditingController();
  DateTime _start = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      setState(() => _saving = true);
      await ref.read(abstinenceDaoProvider).insertTracker(
            AbstinenceTrackersCompanion.insert(
              name: name,
              startDate: _start,
              isActive: const Value(true),
            ),
          );
    }
    widget.onNext();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
                primary: TraumColors.roseRed)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _start = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = TraumColors.roseRed;
    final dateStr =
        '${_start.day.toString().padLeft(2, '0')}.${_start.month.toString().padLeft(2, '0')}.${_start.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: TraumColors.gradientMedical,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: Colors.white, size: 44),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(l10n.obAbstinenceTitle,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: TraumColors.onBackground,
                            fontFamily: 'DMSans')),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(l10n.obAbstinenceSubtitle,
                        style: const TextStyle(
                            fontSize: 14,
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans'),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 24),
                  for (final f in [
                    l10n.obAbstinenceFeature1,
                    l10n.obAbstinenceFeature2,
                    l10n.obAbstinenceFeature3,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(f,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: TraumColors.onBackground,
                                    fontFamily: 'DMSans'))),
                      ]),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans'),
                    decoration: InputDecoration(
                      labelText: l10n.obAbstinenceQuickAdd,
                      hintText: l10n.obAbstinenceHint,
                      labelStyle: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans'),
                      filled: true,
                      fillColor: TraumColors.surface,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TraumRadius.card),
                          borderSide: BorderSide.none),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_nameCtrl.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      child: Row(children: [
                        const Icon(Icons.event_rounded,
                            color: accent, size: 18),
                        const SizedBox(width: 8),
                        Text('${l10n.obAbstinenceStart}: $dateStr',
                            style: const TextStyle(
                                color: TraumColors.onBackground,
                                fontFamily: 'DMSans',
                                fontSize: 13)),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: _nameCtrl.text.trim().isEmpty
                ? l10n.obUnderstood
                : l10n.next,
            onPressed: _saving ? null : _proceed,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
