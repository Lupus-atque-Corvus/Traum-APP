import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/graffiti_map/field_system/map_templates.dart';
import '../database/traum_database.dart';

/// Legt die Standard-Karten (Graffiti, Türme, Lost Places) einmalig an.
class MapCollectionSeeder {
  static Future<void> seedIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool('map_collections_seeded') == true) return;
    // Schutz gegen Doppel-Seeding (z. B. nach App-Update mit Bestandsdaten).
    if ((await db.mapCollectionsDao.getAll()).isNotEmpty) {
      await prefs.setBool('map_collections_seeded', true);
      return;
    }

    const templates = [
      MapTemplates.graffiti,
      MapTemplates.tuerme,
      MapTemplates.lostPlaces,
    ];
    for (final t in templates) {
      await db.mapCollectionsDao.insert(
        MapCollectionsCompanion.insert(
          name: t.name,
          iconName: t.iconName,
          colorHex: Value(t.colorHex),
          hasRating: Value(t.hasRating),
          multiPhoto: Value(t.multiPhoto),
          fieldConfig: Value(t.buildFieldConfig()),
          sortOrder: Value(templates.indexOf(t)),
          createdAt: DateTime.now(),
        ),
      );
    }

    await prefs.setBool('map_collections_seeded', true);
  }
}
