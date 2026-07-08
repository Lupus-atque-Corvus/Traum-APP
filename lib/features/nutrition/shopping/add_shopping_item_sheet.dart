import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/components.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/grocery_price_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/traum_database.dart';

/// Bottom sheet to add a shopping item. Suggests a price from the local
/// grocery price DB as the user types the name; the suggestion is editable.
class AddShoppingItemSheet extends ConsumerStatefulWidget {
  const AddShoppingItemSheet({super.key});

  @override
  ConsumerState<AddShoppingItemSheet> createState() =>
      _AddShoppingItemSheetState();
}

class _AddShoppingItemSheetState extends ConsumerState<AddShoppingItemSheet> {
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _isUrgent = false;
  bool _priceEditedManually = false;
  bool _saving = false;
  String? _suggestionLabel;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (_priceEditedManually) {
      // Name changed but price is user-owned: drop any stale suggestion label.
      if (_suggestionLabel != null) setState(() => _suggestionLabel = null);
      return;
    }
    final entries = ref.read(groceryPriceEntriesProvider).value ?? [];
    final match = GroceryPriceService.match(value, entries);
    if (match != null) {
      _priceCtrl.text = match.price.toStringAsFixed(2).replaceAll('.', ',');
      if (_unitCtrl.text.isEmpty && match.unit != null) {
        _unitCtrl.text = match.unit!;
      }
    }
    setState(() => _suggestionLabel = match != null ? '≈ ${match.name}' : null);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)));
      return;
    }
    setState(() => _saving = true);
    final price =
        double.tryParse(_priceCtrl.text.replaceAll(',', '.').trim());
    try {
      await ref.read(nutritionDaoProvider).insertShoppingItem(
            ShoppingListItemsCompanion.insert(
              name: _nameCtrl.text.trim(),
              quantity: Value(
                  double.tryParse(_quantityCtrl.text.replaceAll(',', '.'))),
              unit: Value(_unitCtrl.text.trim().isEmpty
                  ? null
                  : _unitCtrl.text.trim()),
              priceEstimated: Value(price),
              isUrgent: Value(_isUrgent),
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.saveFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
        filled: true,
        fillColor: TraumColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TraumRadius.card),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    // Keep the price-entries provider alive and warm so _onNameChanged can
    // read it synchronously via ref.read on the same frame.
    ref.watch(groceryPriceEntriesProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: TraumColors.onBackgroundSubtle,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.addProduct,
              style: TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            key: const Key('add_item_name'),
            controller: _nameCtrl,
            autofocus: true,
            onChanged: _onNameChanged,
            style: const TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: _dec('Was brauchst du?'),
          ),
          if (_suggestionLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(_suggestionLabel!,
                  style: const TextStyle(
                      color: TraumColors.mintGreen,
                      fontFamily: 'DMSans',
                      fontSize: 12)),
            ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _quantityCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                decoration: _dec('Menge'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _unitCtrl,
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                decoration: _dec('Einheit'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            key: const Key('add_item_price'),
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => _priceEditedManually = v.isNotEmpty,
            style: const TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: _dec('Preis (€) — geschätzt'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isUrgent,
            onChanged: (v) => setState(() => _isUrgent = v),
            activeThumbColor: TraumColors.roseRed,
            title: Text(AppLocalizations.of(context)!.urgent,
                style: TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontSize: 14)),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: _saving ? 'Speichern…' : 'Hinzufügen',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
