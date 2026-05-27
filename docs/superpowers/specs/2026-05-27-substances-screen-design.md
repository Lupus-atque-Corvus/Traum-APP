# Substances Screen Design Spec
_2026-05-27_

## Goal
Combine the existing Supplements and Medication tabs into a single "Mittel" screen with two internal tabs: **Meine Mittel** (user's personal list) and **Datenbank** (substance lookup). Add a hybrid local+API substance database and an automatic interaction checker.

## Architecture

### Screen Structure
- `/supplements` and `/medication` routes both redirect to `/substances`
- `SubstancesScreen` is a `DefaultTabController` with two tabs
- Tab 1 `MySubstancesTab`: unified list of user's supplements + medications, interaction banner
- Tab 2 `DatabaseTab`: substance search (local-first, API fallback, cached)

### Data Layers
1. **Bundled JSON** (`assets/substances.json`): ~30 curated common substances with interactions
2. **Drift cache table** (`SubstanceCaches`): API-fetched substances stored locally after first lookup
3. **OpenFDA API**: fallback for medications not found locally
4. **PubChem API**: fallback for supplements not found locally
5. **Existing tables** (`Supplements`, `Medications` + logs): unchanged, user data stays intact

### Interaction Checker
- On app start and on every change to user's active substances
- Checks all active substance pairs against `interactions` field in bundled JSON + cache
- Riverpod `interactionAlertsProvider` → feeds banner in MySubstancesTab
- Severity levels: `major` (red), `moderate` (amber)

## Key Models (pure Dart, no Drift)
```dart
class SubstanceInfo {
  final String id;
  final String name;
  final String type; // 'medication' | 'supplement'
  final String? category;
  final String? mechanism;
  final String? halfLife;
  final String? commonDosage;
  final String? evidenceGrade; // A-D, supplements only
  final List<AdverseEventInfo> adverseEvents;
  final List<InteractionInfo> interactions;
}

class AdverseEventInfo {
  final String name;
  final double? frequencyPercent;
}

class InteractionInfo {
  final String withId;
  final String withName;
  final String severity; // major | moderate | minor
  final String description;
}

class InteractionAlert {
  final String substanceA;
  final String substanceB;
  final String severity;
  final String description;
}
```

## New Drift Table
```dart
class SubstanceCaches extends Table {
  TextColumn get substanceId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get dataJson => text()(); // full SubstanceInfo as JSON
  TextColumn get source => text()(); // 'openfda' | 'pubchem'
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {substanceId};
}
```

## UI Design Decisions
- **Substance type badge**: indigo pill for supplements, rose-red pill for medications
- **Interaction banner**: dismissible Card at top of MySubstancesTab, orange/red gradient, tap → shows list of alerts
- **Today status card**: kept from MedicationScreen, shows medication timing dots
- **FAB**: opens bottom sheet with type selector (Supplement / Medikament) → then existing form
- **Search in DatabaseTab**: debounce 300ms, spinner during API call, "Quelle: Lokal / OpenFDA / PubChem" chip on each result
- **Detail sheet**: `showModalBottomSheet` with DraggableScrollableSheet, sections: Info | Dosierung | Nebenwirkungen | Interaktionen | Add-Button

## API Endpoints
- OpenFDA drug labels: `https://api.fda.gov/drug/label.json?search=openfda.generic_name:%22<query>%22&limit=3`
- PubChem: `https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/<query>/JSON`

## Navigation Changes
- `Routes.substances = '/substances'` added
- `Routes.supplements` → redirect to `/substances`
- `Routes.medication` → redirect to `/substances`
- Navigation label: `Mittel` (replaces both `Supplements` and `Medikamente`)
- `moduleRoutes`: remove `supplements` + `medication`, add `substances`

## Files Created
- `lib/features/substances/substances_screen.dart`
- `lib/features/substances/my_substances_tab.dart`
- `lib/features/substances/database_tab.dart`
- `lib/features/substances/substance_detail_sheet.dart`
- `lib/data/database/tables/substance_tables.dart`
- `lib/data/database/daos/substance_dao.dart`
- `lib/data/models/substance_info.dart`
- `lib/data/services/substance_api_service.dart`
- `lib/data/repositories/substance_repository.dart`
- `lib/core/services/interaction_service.dart`
- `assets/substances.json`

## Files Modified
- `lib/data/database/traum_database.dart`
- `lib/core/providers/database_provider.dart`
- `lib/core/navigation/routes.dart`
- `lib/core/navigation/router.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_de.arb`
- `pubspec.yaml` (add asset)
