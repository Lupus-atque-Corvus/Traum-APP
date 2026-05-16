import 'package:flutter/material.dart';
import '../theme/colors.dart';

class BudgetCategoryBar extends StatelessWidget {
  final String name;
  final double spent;
  final double limit;
  final Color color;
  final String currencySymbol;

  const BudgetCategoryBar({
    super.key,
    required this.name,
    required this.spent,
    required this.limit,
    this.color = TraumColors.amberGold,
    this.currencySymbol = '€',
  });

  @override
  Widget build(BuildContext context) {
    final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final overBudget = spent > limit && limit > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
              ),
            ),
            Text(
              '${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)} $currencySymbol',
              style: TextStyle(
                fontSize: 12,
                color: overBudget
                    ? TraumColors.roseRed
                    : TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: TraumColors.surfaceVariant,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: LayoutBuilder(
              builder: (_, constraints) => Container(
                width: constraints.maxWidth * ratio,
                decoration: BoxDecoration(
                  color: overBudget ? TraumColors.roseRed : color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
