import 'package:flutter/material.dart';
import '../../../core/components/traum_sub_header.dart';
import '../budget_scale.dart';

/// Thin Budget-specific wrapper around the shared [TraumSubHeader] —
/// pins the scale to [kBudgetScale] so every existing call site
/// (`debts_screen.dart`, `recurring_screen.dart`, `savings_screen.dart`,
/// `budget_categories_screen.dart`, `transaction_list_screen.dart`) keeps
/// rendering exactly the pixel sizes from `PIXELGENAUE_SPEZIFIKATION.md`.
class BudgetSubHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const BudgetSubHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return TraumSubHeader(title: title, actions: actions, scale: kBudgetScale);
  }
}
