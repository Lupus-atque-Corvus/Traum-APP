import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../budget_scale.dart';

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
      padding: EdgeInsets.fromLTRB(bs(12), bs(4), bs(12), bs(9)),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: bs(24), height: bs(24),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(bs(12)),
            ),
            child: Icon(Icons.chevron_left,
                size: bs(16), color: TraumColors.onBackground),
          ),
        ),
        SizedBox(width: bs(8)),
        Expanded(child: Text(title, style: _t)),
        ...actions,
      ]),
    );
  }
}
