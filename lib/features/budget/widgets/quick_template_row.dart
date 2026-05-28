import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/providers/database_provider.dart';
import '../../../data/database/traum_database.dart';
import '../budget_providers.dart';

class QuickTemplateRow extends ConsumerWidget {
  final void Function(QuickTemplate) onTemplateTap;
  final VoidCallback onNewTap;

  const QuickTemplateRow({
    super.key,
    required this.onTemplateTap,
    required this.onNewTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(quickTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return Row(children: [
            _NewChip(onTap: onNewTap),
          ]);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...templates.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onTemplateTap(t),
                      onLongPress: () => _confirmDelete(context, ref, t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: TraumColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  TraumColors.amberGold.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(
                                color: TraumColors.onBackground,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (t.defaultAmount != null)
                              Text(
                                '${t.defaultAmount!.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  color: TraumColors.onBackgroundMuted,
                                  fontFamily: 'DMSans',
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )),
              _NewChip(onTap: onNewTap),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, QuickTemplate t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TraumColors.surface,
        title: const Text('Vorlage löschen?',
            style: TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: Text('„${t.name}" wird gelöscht.',
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen',
                style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen',
                style: TextStyle(
                    color: TraumColors.roseRed, fontFamily: 'DMSans')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(budgetDaoProvider).deleteTemplate(t.id);
    }
  }
}

class _NewChip extends StatelessWidget {
  final VoidCallback onTap;

  const _NewChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: TraumColors.amberGoldDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TraumColors.amberGold),
        ),
        child: const Text(
          '+ Neu',
          style: TextStyle(
            color: TraumColors.amberGold,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
