import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../health_score_result.dart';

class FaktorRow extends StatelessWidget {
  final FaktorScore faktor;
  final VoidCallback? onTap;

  const FaktorRow({super.key, required this.faktor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = faktorModulFarbe(faktor.name);
    final icon = faktorIcon(faktor.name);
    final bewertung = faktorBewertung(faktor.score, l10n);
    final farbe = faktorFarbe(faktor.score);
    final fraction = (faktor.score / 100).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                faktor.name,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '${faktor.score}',
              style: TextStyle(
                color: farbe,
                fontFamily: 'DMSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              bewertung,
              style: TextStyle(
                color: farbe,
                fontFamily: 'DMSans',
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: TraumColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(farbe),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                color: TraumColors.onBackgroundSubtle, size: 18),
          ],
        ),
      ),
    );
  }
}
