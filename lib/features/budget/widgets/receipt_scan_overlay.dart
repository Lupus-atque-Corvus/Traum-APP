import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class ReceiptScanOverlay extends StatelessWidget {
  const ReceiptScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TraumColors.background.withValues(alpha: 0.92),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: TraumColors.amberGold),
            SizedBox(height: 16),
            Text(
              'Kassenzettel wird analysiert...',
              style: TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
