import 'package:flutter/material.dart';
import '../../../core/components/components.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart';

class CategoryGrid extends StatelessWidget {
  final List<BudgetCategory> categories;
  final List<Transaction> transactions;
  final String currency;
  final void Function(BudgetCategory)? onCategoryTap;
  final VoidCallback? onShowAll;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.transactions,
    required this.currency,
    this.onCategoryTap,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final catWithLimit = categories
        .where(
            (c) => c.isExpense && c.monthlyLimit != null && c.monthlyLimit! > 0)
        .toList();

    if (catWithLimit.isEmpty) return const SizedBox.shrink();

    final spendingByCategory = <int, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      if (t.categoryId != null) {
        spendingByCategory[t.categoryId!] =
            (spendingByCategory[t.categoryId!] ?? 0) + t.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kategorien',
              style: TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (onShowAll != null)
              TextButton(
                onPressed: onShowAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Alle anzeigen ›',
                  style: TextStyle(
                    color: TraumColors.amberGold,
                    fontFamily: 'DMSans',
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: catWithLimit.length,
          itemBuilder: (_, i) {
            final cat = catWithLimit[i];
            final spent = spendingByCategory[cat.id] ?? 0;
            final limit = cat.monthlyLimit!;
            final ratio = (spent / limit).clamp(0.0, double.infinity);
            final isOver = ratio > 1.0;

            final gradient = isOver
                ? const LinearGradient(
                    colors: [TraumColors.roseRed, TraumColors.roseRed],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : ratio >= 0.7
                    ? LinearGradient(
                        colors: [
                          TraumColors.amberGold,
                          TraumColors.amberGold.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : TraumColors.gradientWarm;

            return TraumCard(
              padding: const EdgeInsets.all(12),
              onTap: onCategoryTap != null ? () => onCategoryTap!(cat) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      cat.emoji ?? '📦',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOver)
                      const Text('⚠️', style: TextStyle(fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)} $currency',
                    style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: GradientProgressBar(
                        value: ratio.clamp(0.0, 1.0),
                        gradient: gradient,
                        height: 6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(ratio * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: isOver
                            ? TraumColors.roseRed
                            : TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
