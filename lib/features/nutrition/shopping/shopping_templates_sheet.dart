import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/daos/nutrition_dao.dart';

/// Save the current list as a named template, or add a saved template's items
/// to the list.
class ShoppingTemplatesSheet extends ConsumerWidget {
  const ShoppingTemplatesSheet({super.key});

  Future<void> _saveCurrent(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final items = await ref.read(nutritionDaoProvider).watchAllShoppingItems().first;
    if (items.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Liste ist leer')));
      return;
    }
    final ctrl = TextEditingController();
    if (!context.mounted) return;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: const Text('Vorlage speichern',
            style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: const InputDecoration(hintText: 'z.B. Wocheneinkauf'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Speichern')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(nutritionDaoProvider).saveTemplateFromItems(
          name,
          items
              .map((i) => ShoppingTemplateDraft(
                  name: i.name,
                  category: i.category,
                  quantity: i.quantity,
                  unit: i.unit))
              .toList(),
        );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates =
        ref.watch(shoppingTemplatesStreamProvider).value ?? [];
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
          const Text('Vorlagen',
              style: TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 12),
          if (templates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Noch keine Vorlagen gespeichert.',
                  style: TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans')),
            ),
          ...templates.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: TraumColors.surface,
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                ),
                child: ListTile(
                  title: Text(t.name,
                      style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: TraumColors.roseRed),
                    onPressed: () => ref
                        .read(nutritionDaoProvider)
                        .deleteShoppingTemplate(t.id),
                  ),
                  onTap: () async {
                    await ref
                        .read(nutritionDaoProvider)
                        .applyShoppingTemplate(t.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              )),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _saveCurrent(context, ref),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: TraumColors.surfaceVariant,
                borderRadius: BorderRadius.circular(TraumRadius.card),
              ),
              child: const Center(
                child: Text('+ Aktuelle Liste als Vorlage speichern',
                    style: TextStyle(
                        color: TraumColors.mintGreen,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
