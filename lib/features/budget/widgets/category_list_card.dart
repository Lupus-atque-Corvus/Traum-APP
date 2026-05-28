import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/traum_card.dart';
import '../../../core/theme/colors.dart';
import '../budget_helpers.dart';
import '../budget_providers.dart';

const _kSegmentColors = [
  TraumColors.coralOrange,
  TraumColors.mintGreen,
  TraumColors.cyanBlue,
  TraumColors.lavender,
  TraumColors.amberGold,
  TraumColors.roseRed,
];

class CategoryListCard extends ConsumerWidget {
  const CategoryListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedBudgetMonthProvider);
    final ym = (month.year, month.month);
    final catsAsync = ref.watch(categoryExpensesProvider(ym));

    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text(
              'Ausgaben nach Kategorien',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                color: TraumColors.onBackground,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.more_horiz,
                color: TraumColors.onBackgroundMuted),
          ]),
          const SizedBox(height: 12),
          catsAsync.when(
            data: (cats) {
              if (cats.isEmpty) return const SizedBox.shrink();
              final total =
                  cats.fold(0.0, (s, c) => s + c.amount);
              return Column(
                children: cats.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  final barColor =
                      _kSegmentColors[i % _kSegmentColors.length];
                  final ratio =
                      total > 0 ? cat.amount / total : 0.0;
                  final percent = total > 0
                      ? (cat.amount / total * 100).round()
                      : 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            cat.category.emoji ?? '💰',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.category.name,
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                color: TraumColors.onBackground,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 3,
                                backgroundColor: TraumColors.surfaceVariant,
                                valueColor:
                                    AlwaysStoppedAnimation(barColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '€${fmtAmount(cat.amount)}',
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              color: TraumColors.onBackground,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: TraumColors.onBackgroundMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ]),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
