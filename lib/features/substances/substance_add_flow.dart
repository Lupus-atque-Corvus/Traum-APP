import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/models/substance_record.dart';
import '../../l10n/app_localizations.dart';
import 'my_substances_tab.dart' show showAddMedSheetFor, showAddSuppSheetFor;

/// Öffnet den passenden Add-Sheet aus "Meine Mittel", vorbefüllt mit Name und
/// Dosierungstext aus [record] — der Cross-Tab-Weg von der Datenbank-
/// Detailansicht (Task 15) zum bestehenden Add-Flow. Routet nach `klasse`.
void openAddFlowForRecord(BuildContext context, WidgetRef ref, SubstanceRecord record) {
  final lang = Localizations.localeOf(context).languageCode;
  if (record.klasse == SubstanceKlasse.medikament) {
    showAddMedSheetFor(
      context,
      ref,
      initialName: record.substance,
      initialDosage: record.dosierung.erwachsene(lang),
      onAdded: () => _showAddedSnackbar(context),
    );
  } else {
    showAddSuppSheetFor(
      context,
      ref,
      initialName: record.substance,
      initialCategory: record.kategorie,
      onAdded: () => _showAddedSnackbar(context),
    );
  }
}

void _showAddedSnackbar(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: TraumColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TraumRadius.chip)),
      content: Text(l10n.substanceAddedToMyMeds,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
      action: SnackBarAction(
        label: l10n.substanceAddedShow,
        textColor: TraumColors.coralOrange,
        onPressed: () {
          final controller = DefaultTabController.maybeOf(context);
          controller?.animateTo(0);
        },
      ),
    ),
  );
}
