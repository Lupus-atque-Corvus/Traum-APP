import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../l10n/app_localizations.dart';

/// Zurück-Chevron in einem abgerundeten Quadrat + fetter Titel — der
/// gemeinsame Unterseiten-Header-Stil, ursprünglich in Budgets eigenem
/// `BudgetSubHeader` entwickelt (siehe `PIXELGENAUE_SPEZIFIKATION.md`) und
/// hier als geteilte Komponente für alle Module nutzbar gemacht.
///
/// [scale] multipliziert die Struktur-Maße (Paddings, Button-Größe, Radius)
/// — Budget bleibt darüber pixelgenau beim bestehenden `kBudgetScale`;
/// andere Module lassen es bei 1.0 (Rohmaße wie ursprünglich in der
/// Spezifikation). Die Schriftgröße bleibt bewusst unskaliert (wie im
/// ursprünglichen `BudgetSubHeader`): Budget skaliert Text stattdessen über
/// den ambienten `BudgetTextScale`-MediaQuery-Wrapper der Screens, die ihn
/// verwenden — würde [scale] hier zusätzlich die Schriftgröße multiplizieren,
/// summierte sich das zu einer doppelten Skalierung.
///
/// Die Farb-Parameter erlauben eine transparente Variante über Fotos/Videos
/// (z.B. Tagebuch-Eintragsansicht) statt der Standard-Optik auf solidem
/// Hintergrund.
class TraumSubHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final double scale;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color textColor;
  final VoidCallback? onBack;

  const TraumSubHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.scale = 1.0,
    this.iconBackgroundColor = TraumColors.surface,
    this.iconColor = TraumColors.onBackground,
    this.textColor = TraumColors.onBackground,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    double s(num v) => v * scale;
    return Padding(
      padding: EdgeInsets.fromLTRB(s(12), s(4), s(12), s(9)),
      child: Row(children: [
        Semantics(
          button: true,
          label: AppLocalizations.of(context)!.back,
          child: GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: Container(
              width: s(24),
              height: s(24),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(s(12)),
              ),
              child: Icon(Icons.chevron_left, size: s(16), color: iconColor),
            ),
          ),
        ),
        SizedBox(width: s(8)),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: textColor,
            ),
          ),
        ),
        ...actions,
      ]),
    );
  }
}
