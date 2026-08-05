import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/repositories/diary_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seedIfNeeded creates exactly one default diary and is idempotent',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await DiarySeeder.seedIfNeeded(db, prefs);
    final afterFirst = await db.diariesDao.getAll();
    expect(afterFirst, hasLength(1));
    expect(afterFirst.single.name, 'Mein Tagebuch');

    // Zweiter Aufruf darf kein weiteres Tagebuch anlegen.
    await DiarySeeder.seedIfNeeded(db, prefs);
    final afterSecond = await db.diariesDao.getAll();
    expect(afterSecond, hasLength(1));
  });

  test('does not seed when a diary already exists (migrated install)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.diariesDao.insert(DiariesCompanion.insert(
        name: 'Bestand', iconName: 'book', createdAt: DateTime.now()));

    await DiarySeeder.seedIfNeeded(db, prefs);

    final all = await db.diariesDao.getAll();
    expect(all, hasLength(1));
    expect(all.single.name, 'Bestand');
  });
}
