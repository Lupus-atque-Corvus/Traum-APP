import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'nutrition_providers.dart';

class AmountEntrySheet extends ConsumerStatefulWidget {
  final FoodProduct product;
  final String mealType;
  final String date;

  const AmountEntrySheet({
    super.key,
    required this.product,
    required this.mealType,
    required this.date,
  });

  @override
  ConsumerState<AmountEntrySheet> createState() =>
      _AmountEntrySheetState();
}

class _AmountEntrySheetState
    extends ConsumerState<AmountEntrySheet> {
  final _ctrl = TextEditingController(text: '100');
  bool _saving = false;
  double _grams = 100;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onAmountChanged(String v) {
    final parsed =
        double.tryParse(v.replaceAll(',', '.')) ?? 0;
    setState(() => _grams = parsed);
  }

  double get _factor => _grams / 100;
  double get _calories =>
      widget.product.caloriesPer100g * _factor;
  double get _protein =>
      widget.product.proteinPer100g * _factor;
  double get _carbs => widget.product.carbsPer100g * _factor;
  double get _fat => widget.product.fatPer100g * _factor;

  Future<void> _save() async {
    if (_grams <= 0) return;
    setState(() => _saving = true);
    try {
      final micros = productMicrosPer100g(widget.product).scale(_factor);
      await ref.read(mealEntriesDaoProvider).insertEntry(
            MealEntriesCompanion.insert(
              date: widget.date,
              mealType: widget.mealType,
              productId: widget.product.id,
              amountGrams: _grams,
              calories: _calories,
              protein: _protein,
              carbs: _carbs,
              fat: _fat,
              loggedAt: DateTime.now(),
              microsJson: Value(micros.toNullableJson()),
            ),
          );
      await ref
          .read(foodProductsDaoProvider)
          .incrementUseCount(widget.product.id);
      ref.invalidate(todaysMealsProvider);
      ref.invalidate(todaysMacrosProvider);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final kcalGoal = ref.watch(kcalGoalNotifierProvider);

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: TraumColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin:
                    const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TraumColors.surfaceVariant,
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.product.name,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontSize: 18),
            ),
            if (widget.product.brand != null)
              Text(
                widget.product.brand!,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted,
                    fontSize: 13),
              ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  onChanged: _onAmountChanged,
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    suffixText: 'g',
                    suffixStyle: const TextStyle(
                        fontFamily: 'DMSans',
                        color:
                            TraumColors.onBackgroundMuted),
                    filled: true,
                    fillColor:
                        TraumColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final label in ['100', '150', '200'])
                      GestureDetector(
                        onTap: () {
                          _ctrl.text = label;
                          _onAmountChanged(label);
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                TraumColors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text('${label}g',
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 12,
                                  color: TraumColors
                                      .onBackgroundMuted)),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _MacroRow('Kalorien', _calories,
                kcalGoal.toDouble(),
                TraumColors.coralOrange, 'kcal'),
            _MacroRow(
                'Protein', _protein, 160,
                TraumColors.indigoBlue, 'g'),
            _MacroRow(
                'Carbs', _carbs, 250,
                TraumColors.amberGold, 'g'),
            _MacroRow('Fett', _fat, 70,
                TraumColors.cyanBlue, 'g'),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TraumColors.mintGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(50)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : Text(
                        'Zu ${_mealLabel(widget.mealType)} hinzufügen',
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mealLabel(String type) => switch (type) {
        'breakfast' => 'Frühstück',
        'lunch' => 'Mittag',
        'dinner' => 'Abend',
        'snack' => 'Snack',
        _ => type,
      };
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;
  final String unit;

  const _MacroRow(
      this.label, this.value, this.goal, this.color, this.unit);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted,
                    fontSize: 13)),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${value.toStringAsFixed(0)} $unit',
              style: TextStyle(
                  fontFamily: 'DMSans',
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (goal > 0 ? value / goal : 0.0)
                    .clamp(0.0, 1.0)
                    .toDouble(),
                minHeight: 6,
                backgroundColor: TraumColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ]),
      );
}
