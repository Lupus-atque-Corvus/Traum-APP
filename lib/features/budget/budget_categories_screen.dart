import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'widgets/icon_picker_grid.dart';

class BudgetCategoriesScreen extends ConsumerWidget {
  const BudgetCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(allBudgetCategoriesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.surface,
        leading: BackButton(color: TraumColors.onBackground),
        title: const Text(
          'Budget-Kategorien',
          style: TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: TraumColors.amberGold),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _AddCategorySheet(),
            ),
          ),
        ],
      ),
      body: catsAsync.when(
        data: (cats) {
          if (cats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Noch keine Kategorien.\nTippe auf + um eine anzulegen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cats.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: TraumColors.surfaceVariant),
            itemBuilder: (_, i) {
              final cat = cats[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: TraumColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(cat.emoji ?? '📦',
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                title: Text(
                  cat.name,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  cat.isExpense ? 'Ausgabe' : 'Einnahme',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted,
                    fontSize: 12,
                  ),
                ),
                trailing: cat.monthlyLimit != null
                    ? Text(
                        '${cat.monthlyLimit!.toStringAsFixed(0)} € / Mo.',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.amberGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : null,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: TraumColors.amberGold),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _AddCategorySheet extends ConsumerStatefulWidget {
  const _AddCategorySheet();

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  String _selectedIconName = 'category';
  bool _isExpense = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final limit =
          double.tryParse(_limitCtrl.text.trim().replaceAll(',', '.'));
      await ref.read(budgetDaoProvider).insertCategory(
            BudgetCategoriesCompanion.insert(
              name: name,
              emoji: Value(_selectedIconName),
              isExpense: Value(_isExpense),
              monthlyLimit: Value(limit),
              color: const Value(null),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      decoration: const BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategorie anlegen',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              color: TraumColors.onBackground,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _field(_nameCtrl, 'Name *', 'z.B. Lebensmittel'),
          const SizedBox(height: 8),
          _field(_limitCtrl, 'Monatslimit (optional)', '0',
              type: TextInputType.number),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Typ:',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontSize: 14)),
            const SizedBox(width: 12),
            _chip('Ausgabe', _isExpense,
                () => setState(() => _isExpense = true)),
            const SizedBox(width: 8),
            _chip('Einnahme', !_isExpense,
                () => setState(() => _isExpense = false)),
          ]),
          const SizedBox(height: 12),
          IconPickerGrid(
            selectedIconName: _selectedIconName,
            onSelected: (name) => setState(() => _selectedIconName = name),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: TraumColors.amberGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Speichern',
                      style: TextStyle(
                          fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(
          fontFamily: 'DMSans', color: TraumColors.onBackground, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundMuted,
            fontSize: 13),
        hintStyle: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundSubtle,
            fontSize: 13),
        filled: true,
        fillColor: TraumColors.surfaceVariant,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? TraumColors.amberGold.withValues(alpha: 0.2)
                : TraumColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? Border.all(color: TraumColors.amberGold)
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              color: selected
                  ? TraumColors.amberGold
                  : TraumColors.onBackgroundMuted,
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
}
