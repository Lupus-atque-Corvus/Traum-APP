import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'nutrition_providers.dart';

class AddCustomProductScreen extends ConsumerStatefulWidget {
  const AddCustomProductScreen({super.key});

  @override
  ConsumerState<AddCustomProductScreen> createState() =>
      _AddCustomProductScreenState();
}

class _AddCustomProductScreenState
    extends ConsumerState<AddCustomProductScreen> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  double _parse(TextEditingController ctrl) =>
      double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(foodProductsDaoProvider).insertProduct(
            FoodProductsCompanion.insert(
              name: _nameCtrl.text.trim(),
              brand: Value(_brandCtrl.text.trim().isNotEmpty
                  ? _brandCtrl.text.trim()
                  : null),
              caloriesPer100g: _parse(_kcalCtrl),
              proteinPer100g: _parse(_proteinCtrl),
              carbsPer100g: _parse(_carbsCtrl),
              fatPer100g: _parse(_fatCtrl),
              isCustom: const Value(true),
              createdAt: DateTime.now(),
            ),
          );
      ref.invalidate(allProductsProvider);
      ref.invalidate(productSearchProvider);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.surface,
        leading:
            const BackButton(color: TraumColors.onBackground),
        title: const Text(
          'Neues Produkt anlegen',
          style: TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackground,
              fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_nameCtrl, 'Name *',
                'z.B. Hausgemachte Bolognese'),
            const SizedBox(height: 8),
            _field(_brandCtrl, 'Marke (optional)',
                'z.B. Selbst gekocht'),
            const SizedBox(height: 16),
            const Text(
              'Nährwerte pro 100g',
              style: TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  color: TraumColors.onBackground,
                  fontSize: 15),
            ),
            const SizedBox(height: 8),
            _field(_kcalCtrl, 'Kalorien (kcal)', '0',
                type: TextInputType.number),
            const SizedBox(height: 8),
            _field(_proteinCtrl, 'Protein (g)', '0',
                type: TextInputType.number),
            const SizedBox(height: 8),
            _field(_carbsCtrl, 'Kohlenhydrate (g)', '0',
                type: TextInputType.number),
            const SizedBox(height: 8),
            _field(_fatCtrl, 'Fett (g)', '0',
                type: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TraumColors.mintGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Text(
                        'Speichern',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      String hint,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackground,
          fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundMuted,
            fontSize: 13),
        filled: true,
        fillColor: TraumColors.surfaceVariant,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }
}
