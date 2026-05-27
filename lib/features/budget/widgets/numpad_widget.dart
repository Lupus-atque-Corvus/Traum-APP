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
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              final isDelete = key == '⌫';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: isDelete
                        ? TraumColors.surfaceVariant
                        : TraumColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _handleKey(key),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: isDelete
                            ? const Icon(
                                Icons.backspace_outlined,
                                color: TraumColors.onBackgroundMuted,
                                size: 20,
                              )
                            : Text(
                                key,
                                style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
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
