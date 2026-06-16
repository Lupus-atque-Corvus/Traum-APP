import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../core/components/components.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

class CycleSettingsSheet extends StatefulWidget {
  final DateTime? menarcheDate;
  final int? lutealPhaseOverride;
  final Future<void> Function(CycleProfileCompanion) onSave;

  const CycleSettingsSheet({
    super.key,
    required this.menarcheDate,
    required this.lutealPhaseOverride,
    required this.onSave,
  });

  @override
  State<CycleSettingsSheet> createState() => _CycleSettingsSheetState();
}

class _CycleSettingsSheetState extends State<CycleSettingsSheet> {
  late DateTime? _menarche;
  late int _luteal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _menarche = widget.menarcheDate;
    _luteal = widget.lutealPhaseOverride ?? 14;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(CycleProfileCompanion(
      id: const Value(0),
      menarcheDate: Value(_menarche),
      lutealPhaseOverride: Value(_luteal),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Title
            Text(
              l10n.cycleSettingsTitle,
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),

            // Menarche date tile
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.menarcheTitle,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                ),
              ),
              trailing: Text(
                _menarche != null
                    ? '${_menarche!.day.toString().padLeft(2, '0')}.${_menarche!.month.toString().padLeft(2, '0')}.${_menarche!.year}'
                    : l10n.menarcheNotSet,
                style: const TextStyle(
                  color: TraumColors.periodRose,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _menarche ?? DateTime(now.year - 13),
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: TraumColors.periodRose),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _menarche = picked);
              },
            ),
            const SizedBox(height: 8),

            // Luteal phase slider
            Text(
              l10n.lutealPhaseTitle,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Slider(
              value: _luteal.toDouble(),
              min: 10,
              max: 16,
              divisions: 6,
              activeColor: TraumColors.periodRose,
              label: '$_luteal',
              onChanged: (v) => setState(() => _luteal = v.round()),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_luteal',
                style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            GradientButton(
              key: const ValueKey('save_cycle_settings'),
              label: l10n.saveLog,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
