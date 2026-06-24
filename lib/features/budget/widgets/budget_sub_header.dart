import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class BudgetSubHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const BudgetSubHeader({super.key, required this.title, this.actions = const []});

  static const _t = TextStyle(
      fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 15,
      color: TraumColors.onBackground);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 9),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chevron_left,
                size: 16, color: TraumColors.onBackground),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: _t)),
        ...actions,
      ]),
    );
  }
}
