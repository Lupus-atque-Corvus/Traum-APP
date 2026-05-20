import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../l10n/app_localizations.dart';
import '../health_score_result.dart';

class FaktorDetailCard extends StatelessWidget {
  final FaktorScore faktor;
  final List<int> history; // 7-day scores

  const FaktorDetailCard({
    super.key,
    required this.faktor,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = faktorModulFarbe(faktor.name);
    final icon = faktorIcon(faktor.name);
    final bewertung = faktorBewertung(faktor.score, l10n);
    final farbe = faktorFarbe(faktor.score);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  faktor.name,
                  style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${faktor.score}',
                  style: TextStyle(
                    color: farbe,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const TextSpan(
                  text: ' /100',
                  style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            bewertung,
            style: TextStyle(
              color: farbe,
              fontFamily: 'DMSans',
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          if (history.isNotEmpty) _MiniBarChart(history: history),
          const SizedBox(height: 10),
          Text(
            faktorHinweis(faktor.name, l10n),
            style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 10,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<int> history;

  const _MiniBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final data = history.take(7).toList();
    return SizedBox(
      height: 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((e) {
          final val = e.value / 100;
          final color = e.value >= 85
              ? TraumColors.mintGreen
              : e.value >= 70
                  ? TraumColors.amberGold
                  : TraumColors.coralOrange;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                height: 32 * val.clamp(0.05, 1.0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
