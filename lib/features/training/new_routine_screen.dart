import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

class NewRoutineScreen extends ConsumerStatefulWidget {
  const NewRoutineScreen({super.key});

  @override
  ConsumerState<NewRoutineScreen> createState() => _NewRoutineScreenState();
}

class _NewRoutineScreenState extends ConsumerState<NewRoutineScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isActive = false;
  bool _saving = false;
  bool _daysInitialized = false;

  final _days = <_DayEntry>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_daysInitialized) {
      _daysInitialized = true;
      _days.add(_DayEntry(AppLocalizations.of(context)!.trainingDayA));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.newRoutine,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(AppLocalizations.of(context)!.routineName),
            const SizedBox(height: 6),
            _buildTextField(_nameCtrl, hint: AppLocalizations.of(context)!.routineNameHint),
            const SizedBox(height: 16),
            _buildLabel(AppLocalizations.of(context)!.descriptionOptional),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.descriptionHint,
                hintStyle: const TextStyle(
                    color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context)!.setAsActive,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontSize: 14)),
              value: _isActive,
              activeThumbColor: TraumColors.coralOrange,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(AppLocalizations.of(context)!.trainingDays,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              TextButton.icon(
                onPressed: () => setState(() => _days.add(_DayEntry(
                    AppLocalizations.of(context)!.trainingDayName(
                        String.fromCharCode(64 + _days.length + 1))))),
                icon: const Icon(Icons.add, size: 16, color: TraumColors.coralOrange),
                label: Text(AppLocalizations.of(context)!.addDay,
                    style: const TextStyle(color: TraumColors.coralOrange, fontFamily: 'DMSans', fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 8),
            ..._days.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: TraumColors.surface,
                borderRadius: BorderRadius.circular(TraumRadius.card),
              ),
              child: Row(children: [
                const Icon(Icons.drag_handle_rounded,
                    color: TraumColors.onBackgroundSubtle, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: e.value.ctrl,
                    style: const TextStyle(
                        color: TraumColors.onBackground, fontFamily: 'DMSans'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_days.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: TraumColors.onBackgroundSubtle, size: 18),
                    onPressed: () => setState(() => _days.removeAt(e.key)),
                  ),
              ]),
            )),
            const SizedBox(height: 28),
            GradientButton(
              label: _saving ? AppLocalizations.of(context)!.saving : AppLocalizations.of(context)!.createRoutineButton,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13));

  Widget _buildTextField(TextEditingController ctrl, {String? hint}) => TextField(
        controller: ctrl,
        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
          filled: true,
          fillColor: TraumColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TraumRadius.card),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)));
      return;
    }
    setState(() => _saving = true);
    final planId = await ref.read(trainingDaoProvider).insertPlan(
          WorkoutPlansCompanion.insert(
            name: _nameCtrl.text.trim(),
            description: Value(
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim()),
            isActive: Value(_isActive),
          ),
        );
    for (int i = 0; i < _days.length; i++) {
      final dayName = _days[i].ctrl.text.trim();
      if (dayName.isNotEmpty) {
        await ref.read(trainingDaoProvider).insertDay(
              WorkoutDaysCompanion.insert(
                planId: planId,
                name: dayName,
                sortOrder: Value(i),
              ),
            );
      }
    }
    if (mounted) context.go('/training/routines');
  }
}

class _DayEntry {
  final TextEditingController ctrl;
  _DayEntry(String name) : ctrl = TextEditingController(text: name);
}
