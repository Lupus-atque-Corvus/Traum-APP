import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../budget_category_icons.dart';

class IconPickerGrid extends StatefulWidget {
  final String? selectedIconName;
  final ValueChanged<String> onSelected;

  const IconPickerGrid({
    super.key,
    this.selectedIconName,
    required this.onSelected,
  });

  @override
  State<IconPickerGrid> createState() => _IconPickerGridState();
}

class _IconPickerGridState extends State<IconPickerGrid> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedIconName;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ICON WÄHLEN',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: TraumColors.onBackgroundMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: kBudgetCategoryIcons.length,
          itemBuilder: (_, i) {
            final entry = kBudgetCategoryIcons.entries.elementAt(i);
            final isSelected = _selected == entry.key;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = entry.key);
                widget.onSelected(entry.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? TraumColors.amberGold.withValues(alpha: 0.2)
                      : TraumColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? TraumColors.amberGold
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  entry.value,
                  size: 20,
                  color: isSelected
                      ? TraumColors.amberGold
                      : TraumColors.onBackgroundMuted,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
