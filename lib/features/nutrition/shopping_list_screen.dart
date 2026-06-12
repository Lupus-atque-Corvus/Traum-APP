import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'shopping/shopping_list_view.dart';

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
          itemsAsync.maybeWhen(
            data: (items) => items.any((i) => i.checked)
                ? IconButton(
                    icon: const Icon(Icons.cleaning_services_rounded,
                        color: TraumColors.mintGreen),
                    tooltip:
                        AppLocalizations.of(context)!.deleteCompletedTooltip,
                    onPressed: () => ref
                        .read(nutritionDaoProvider)
                        .deleteCheckedShoppingItems(),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: const ShoppingListView(standalone: true),
    );
  }
}
