import 'package:shared_preferences/shared_preferences.dart';
import '../database/traum_database.dart';

/// Legt das Standard-Tagebuch "Mein Tagebuch" einmalig an — nötig für
/// Neuinstallationen (die Migration, die Bestandsinstallationen ihr
/// Default-Tagebuch gibt, läuft dort nie: `onCreate` statt `onUpgrade`).
class DiarySeeder {
  static Future<void> seedIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool('diary_seeded') == true) return;
    // Schutz gegen Doppel-Seeding (z. B. nach App-Update mit Bestandsdaten,
    // deren Default-Tagebuch bereits über die Migration entstanden ist).
    if ((await db.diariesDao.getAll()).isNotEmpty) {
      await prefs.setBool('diary_seeded', true);
      return;
    }

    await db.diariesDao.insert(
      DiariesCompanion.insert(
        name: 'Mein Tagebuch',
        iconName: 'book',
        createdAt: DateTime.now(),
      ),
    );

    await prefs.setBool('diary_seeded', true);
  }
}
