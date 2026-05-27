import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';

class BudgetAmpel extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final String currency;

  const BudgetAmpel({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (totalBudget <= 0) return const SizedBox.shrink();

    final ratio = totalSpent / totalBudget;
    final Color color;
    final String message;

    if (ratio < 0.7) {
      color = TraumColors.mintGreen;
      final remaining = totalBudget - totalSpent;
      message =
          'Noch ${remaining.toStringAsFixed(2)} $currency Budget übrig';
    } else if (ratio < 1.0) {
      color = TraumColors.amberGold;
      final remaining = totalBudget - totalSpent;
      message =
          '${(ratio * 100).toStringAsFixed(0)}% verbraucht · Noch ${remaining.toStringAsFixed(2)} $currency übrig';
    } else {
      color = TraumColors.roseRed;
      final over = totalSpent - totalBudget;
      message =
          'Budget um ${over.toStringAsFixed(2)} $currency überschritten';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: color,
              fontFamily: 'DMSans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ]),
    );
  }
}
