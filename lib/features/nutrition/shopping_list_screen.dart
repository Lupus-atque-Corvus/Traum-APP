import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(allShoppingItemsStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.shoppingList,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        actions: [
          itemsAsync.when(
            data: (items) => items.any((i) => i.checked)
                ? IconButton(
                    icon: const Icon(Icons.cleaning_services_rounded,
                        color: TraumColors.amberGold),
                    tooltip: AppLocalizations.of(context)!.deleteCompletedTooltip,
                    onPressed: () =>
                        ref.read(nutritionDaoProvider).deleteCheckedShoppingItems(),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.amberGold,
        onPressed: () => _showAddItemSheet(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.shopping_cart_rounded,
                    size: 64,
                    color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.shoppingListEmpty,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.tapToAddProduct,
                    style: TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            );
          }

          final unchecked = items.where((i) => !i.checked).toList();
          final checked = items.where((i) => i.checked).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              if (unchecked.isNotEmpty) ...[
                ...unchecked.map((item) => _ShoppingItem(
                      item: item,
                      onToggle: (v) => ref.read(nutritionDaoProvider).updateShoppingItem(
                            ShoppingListItemsCompanion(
                              id: Value(item.id),
                              name: Value(item.name),
                              category: Value(item.category),
                              quantity: Value(item.quantity),
                              unit: Value(item.unit),
                              checked: Value(v),
                            ),
                          ),
                      onDelete: () =>
                          ref.read(nutritionDaoProvider).deleteShoppingItem(item.id),
                    )),
              ],
              if (checked.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(AppLocalizations.of(context)!.completed,
                      style: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
                ...checked.map((item) => _ShoppingItem(
                      item: item,
                      onToggle: (v) => ref.read(nutritionDaoProvider).updateShoppingItem(
                            ShoppingListItemsCompanion(
                              id: Value(item.id),
                              name: Value(item.name),
                              category: Value(item.category),
                              quantity: Value(item.quantity),
                              unit: Value(item.unit),
                              checked: Value(v),
                            ),
                          ),
                      onDelete: () =>
                          ref.read(nutritionDaoProvider).deleteShoppingItem(item.id),
                    )),
              ],
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: TraumColors.amberGold)),
        error: (e, _) => Center(
            child: Text('${AppLocalizations.of(context)!.error}: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddItemSheet(
        onAdd: (c) => ref.read(nutritionDaoProvider).insertShoppingItem(c),
      ),
    );
  }
}

class _ShoppingItem extends StatelessWidget {
  final ShoppingListItem item;
  final void Function(bool) onToggle;
  final VoidCallback onDelete;

  const _ShoppingItem({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: CheckboxListTile(
          value: item.checked,
          onChanged: (v) => onToggle(v ?? false),
          activeColor: TraumColors.amberGold,
          checkColor: Colors.white,
          title: Text(
            item.name,
            style: TextStyle(
                color: item.checked
                    ? TraumColors.onBackgroundSubtle
                    : TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w500,
                decoration:
                    item.checked ? TextDecoration.lineThrough : null),
          ),
          subtitle: item.quantity != null || item.unit != null
              ? Text(
                  '${item.quantity != null ? item.quantity!.toStringAsFixed(item.quantity! == item.quantity!.floorToDouble() ? 0 : 1) : ''}'
                  '${item.unit != null ? ' ${item.unit}' : ''}',
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 12),
                )
              : null,
        ),
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final Future<void> Function(ShoppingListItemsCompanion) onAdd;
  const _AddItemSheet({required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: TraumColors.onBackgroundSubtle,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.addProduct,
              style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.itemHint,
              hintStyle: const TextStyle(
                  color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
              filled: true, fillColor: TraumColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _quantityCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.quantity,
                  hintStyle: const TextStyle(
                      color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
                  filled: true, fillColor: TraumColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TraumRadius.card),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _unitCtrl,
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.unitHint,
                  hintStyle: const TextStyle(
                      color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
                  filled: true, fillColor: TraumColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TraumRadius.card),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          GradientButton(
            label: _saving ? AppLocalizations.of(context)!.saving : AppLocalizations.of(context)!.add,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(ShoppingListItemsCompanion.insert(
      name: _nameCtrl.text.trim(),
      quantity: Value(double.tryParse(_quantityCtrl.text.replaceAll(',', '.'))),
      unit: Value(_unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim()),
    ));
    if (mounted) Navigator.pop(context);
  }
}
