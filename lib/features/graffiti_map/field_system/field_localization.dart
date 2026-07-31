import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/database/traum_database.dart';
import 'map_templates.dart';

/// Übersetzt einen Feld-Key (z.B. "condition") in das aktuell aktive Label.
/// Wirkt sowohl auf frisch aus [PredefinedFields] gebaute Felder als auch auf
/// bereits in `field_config`/`customFields` gespeicherte JSON-Daten — der Key
/// ist die stabile, seit dem Speichern unveränderte Kennung; das mitgespeicherte
/// `label` wird nur noch als Fallback für unbekannte (eigene) Felder verwendet.
String localizedFieldLabel(BuildContext context, String key, String fallback) {
  final l10n = AppLocalizations.of(context)!;
  return switch (key) {
    'condition' => l10n.mapFieldCondition,
    'access' => l10n.mapFieldAccess,
    'visited' => l10n.mapFieldVisited,
    'danger' => l10n.mapFieldDanger,
    'hidden' => l10n.mapFieldHidden,
    'towerType' => l10n.mapFieldTowerType,
    'towerHeight' => l10n.mapFieldTowerHeight,
    'towerOperator' => l10n.mapFieldTowerOperator,
    _ => fallback,
  };
}

/// Übersetzt einen gespeicherten Options-Rohwert (z.B. "Verfallen") in das
/// aktuell aktive Label. Die Speicherung in `customFields` bleibt unverändert
/// deutsch — nur die Anzeige übersetzt; unbekannte (eigene) Werte kommen
/// unverändert durch.
String localizedOptionValue(BuildContext context, String rawValue) {
  final l10n = AppLocalizations.of(context)!;
  return switch (rawValue) {
    'Verfallen' => l10n.mapOptionDecayed,
    'Teilweise erhalten' => l10n.mapOptionPartiallyPreserved,
    'Gut erhalten' => l10n.mapOptionWellPreserved,
    'Frei zugänglich' => l10n.mapOptionFreelyAccessible,
    'Zaun' => l10n.mapOptionFence,
    'Verschlossen' => l10n.mapOptionLocked,
    'Gefährlich' => l10n.mapOptionDangerous,
    'Geplant' => l10n.mapOptionPlanned,
    'Besucht' => l10n.mapOptionVisited,
    'Funkmast' => l10n.mapOptionRadioMast,
    'Sendemast' => l10n.mapOptionTransmissionMast,
    'Sonstige' => l10n.mapOptionOtherType,
    _ => rawValue,
  };
}

/// Übersetzt den Namen einer gespeicherten [MapCollection] — nur wenn Icon
/// UND Name exakt einer der 3 mitgelieferten Karten entsprechen. Sobald der
/// User eine Karte umbenannt hat (oder eine eigene mit zufällig gleichem
/// Icon anlegt), greift das nicht mehr und der gespeicherte Name bleibt
/// unangetastet — kein Risiko, eigene Bezeichnungen zu überschreiben.
String localizedCollectionName(BuildContext context, MapCollection c) {
  final l10n = AppLocalizations.of(context)!;
  return switch ((c.iconName, c.name)) {
    ('spray', 'Graffiti') => l10n.mapTemplateGraffiti,
    ('tower', 'Türme') => l10n.mapTemplateTowers,
    ('home_broken', 'Lost Places') => l10n.mapTemplateLostPlaces,
    _ => c.name,
  };
}

/// Übersetzt den Namen einer der 4 fest vorgegebenen [MapTemplate]s in der
/// Vorlagen-Auswahl (kein User-Datenrisiko, da [MapTemplates.all] eine feste
/// Konstante ist).
String localizedTemplateDisplayName(BuildContext context, MapTemplate t) {
  final l10n = AppLocalizations.of(context)!;
  return switch (t.iconName) {
    'spray' => l10n.mapTemplateGraffiti,
    'tower' => l10n.mapTemplateTowers,
    'home_broken' => l10n.mapTemplateLostPlaces,
    _ => l10n.mapTemplateCustom,
  };
}
