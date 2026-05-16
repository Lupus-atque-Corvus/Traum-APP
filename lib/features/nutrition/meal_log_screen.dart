import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

class MealLogScreen extends ConsumerStatefulWidget {
  const MealLogScreen({super.key});

  @override
  ConsumerState<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends ConsumerState<MealLogScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  String _mealType = 'snack';
  bool _saving = false;

  static const _mealTypes = [
    ('breakfast', 'Frühstück'),
    ('lunch', 'Mittagessen'),
    ('dinner', 'Abendessen'),
    ('snack', 'Snack'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(
      StreamProvider((ref) => ref.watch(nutritionDaoProvider).watchAllTemplates()),
    );

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text('Mahlzeit eintragen',
            style: TextStyle(
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
            // Quick select from templates
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schnellauswahl',
                        style: TextStyle(
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: templates.take(10).map((t) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _fillFromTemplate(t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: TraumColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t.name,
                                  style: const TextStyle(
                                      color: TraumColors.onBackgroundMuted,
                                      fontFamily: 'DMSans',
                                      fontSize: 12)),
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // Meal type
            const Text('Mahlzeit',
                style: TextStyle(
                    color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: _mealTypes.map((mt) {
              final selected = mt.$1 == _mealType;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _mealType = mt.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? TraumColors.mintGreenDim
                            : TraumColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: selected
                                ? TraumColors.mintGreen
                                : Colors.transparent),
                      ),
                      child: Center(
                        child: Text(mt.$2,
                            style: TextStyle(
                                color: selected
                                    ? TraumColors.mintGreen
                                    : TraumColors.onBackgroundMuted,
                                fontFamily: 'DMSans',
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400),
                            textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            _buildField('Lebensmittel', _nameCtrl, hint: 'z.B. Haferflocken'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildField('Menge (g)', _amountCtrl, hint: '100', numeric: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildField('Kalorien (kcal)', _kcalCtrl, hint: '350', numeric: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildField('Protein (g)', _proteinCtrl, hint: '12', numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildField('Kohlenhydrate (g)', _carbsCtrl, hint: '50', numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildField('Fett (g)', _fatCtrl, hint: '8', numeric: true)),
            ]),
            const SizedBox(height: 28),
            GradientButton(
              label: _saving ? 'Speichern…' : 'Eintragen',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  void _fillFromTemplate(MealTemplate t) {
    final factor = 1.0;
    _nameCtrl.text = t.name;
    _amountCtrl.text = t.servingSizeG.toStringAsFixed(0);
    _kcalCtrl.text = (t.kcalPer100g * t.servingSizeG * factor / 100).toStringAsFixed(0);
    _proteinCtrl.text = (t.proteinPer100g * t.servingSizeG * factor / 100).toStringAsFixed(1);
    _carbsCtrl.text = (t.carbsPer100g * t.servingSizeG * factor / 100).toStringAsFixed(1);
    _fatCtrl.text = (t.fatPer100g * t.servingSizeG * factor / 100).toStringAsFixed(1);
    setState(() {});
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String? hint, bool numeric = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    ]);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name ist ein Pflichtfeld')));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final kcal = double.tryParse(_kcalCtrl.text.replaceAll(',', '.')) ?? 0;
    setState(() => _saving = true);
    await ref.read(nutritionDaoProvider).insertLog(
          NutritionLogsCompanion.insert(
            logDate: DateTime.now(),
            mealType: Value(_mealType),
            foodName: _nameCtrl.text.trim(),
            amountGrams: amount,
            kcal: kcal,
            proteinG: Value(double.tryParse(_proteinCtrl.text.replaceAll(',', '.')) ?? 0),
            carbsG: Value(double.tryParse(_carbsCtrl.text.replaceAll(',', '.')) ?? 0),
            fatG: Value(double.tryParse(_fatCtrl.text.replaceAll(',', '.')) ?? 0),
          ),
        );
    if (mounted) context.go('/nutrition');
  }
}
