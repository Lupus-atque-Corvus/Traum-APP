import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class NumpadWidget extends StatelessWidget {
  final String displayValue;
  final ValueChanged<String> onChanged;

  const NumpadWidget({
    super.key,
    required this.displayValue,
    required this.onChanged,
  });

  void _handleKey(String key) {
    String current = displayValue;

    if (key == '⌫') {
      if (current.isEmpty) return;
      onChanged(current.substring(0, current.length - 1));
      return;
    }

    if (key == ',') {
      if (current.contains(',')) return;
      if (current.isEmpty) {
        onChanged('0,');
      } else {
        onChanged('$current,');
      }
      return;
    }

    // Limit to 2 decimal places
    if (current.contains(',')) {
      final decimalPart = current.split(',')[1];
      if (decimalPart.length >= 2) return;
    }

    // Prevent leading zeros (e.g. "00" → "0")
    if (current == '0' && key != ',') {
      onChanged(key);
      return;
    }

    onChanged('$current$key');
  }

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      [',', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: row.map((key) {
              final isDelete = key == '⌫';
              final isComma = key == ',';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Material(
                    color: isDelete
                        ? TraumColors.heroInner
                        : TraumColors.numKey,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _handleKey(key),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        child: isDelete
                            ? const Icon(
                                Icons.backspace_outlined,
                                color: TraumColors.onBackgroundMuted,
                                size: 16,
                              )
                            : Text(
                                key,
                                style: TextStyle(
                                  color: isComma
                                      ? TraumColors.textBright
                                      : TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: isComma ? FontWeight.w300 : FontWeight.w600,
                                  fontSize: isComma ? 22 : 20,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
