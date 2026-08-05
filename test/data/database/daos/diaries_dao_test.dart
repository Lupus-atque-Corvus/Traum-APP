import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;

  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> insertDiary(String name, {int sortOrder = 0}) =>
      db.diariesDao.insert(DiariesCompanion.insert(
        name: name,
        iconName: 'book',
        sortOrder: Value(sortOrder),
        createdAt: DateTime.now(),
      ));

  test('insert + getById + updateDiary round-trip', () async {
    final id = await insertDiary('Meins');
    final loaded = await db.diariesDao.getById(id);
    expect(loaded!.name, 'Meins');

    await db.diariesDao.updateDiary(loaded.copyWith(name: 'Umbenannt'));
    final updated = await db.diariesDao.getById(id);
    expect(updated!.name, 'Umbenannt');
  });

  test('getAll orders by sortOrder', () async {
    await insertDiary('B', sortOrder: 1);
    await insertDiary('A', sortOrder: 0);

    final all = await db.diariesDao.getAll();
    expect(all.map((d) => d.name).toList(), ['A', 'B']);
  });

  test('nextSortOrder returns 0 for the first diary, then increments', () async {
    expect(await db.diariesDao.nextSortOrder(), 0);
    await insertDiary('Erstes', sortOrder: 0);
    expect(await db.diariesDao.nextSortOrder(), 1);
    await insertDiary('Zweites', sortOrder: 1);
    expect(await db.diariesDao.nextSortOrder(), 2);
  });

  test('entryCount reflects only entries of the given diary', () async {
    final a = await insertDiary('A');
    final b = await insertDiary('B');
    await db.diaryDao.upsertEntry(DiaryEntriesCompanion.insert(
      diaryId: Value(a),
      date: '2026-01-01',
      mediaPath: '/tmp/a1.jpg',
      mediaType: 'photo',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    await db.diaryDao.upsertEntry(DiaryEntriesCompanion.insert(
      diaryId: Value(a),
      date: '2026-01-02',
      mediaPath: '/tmp/a2.jpg',
      mediaType: 'photo',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    expect(await db.diariesDao.entryCount(a), 2);
    expect(await db.diariesDao.entryCount(b), 0);
  });

  test('deleteDiaryWithEntries removes the diary and all its entries',
      () async {
    final a = await insertDiary('A');
    final b = await insertDiary('B');
    await db.diaryDao.upsertEntry(DiaryEntriesCompanion.insert(
      diaryId: Value(a),
      date: '2026-01-01',
      mediaPath: '/tmp/a1.jpg',
      mediaType: 'photo',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    await db.diaryDao.upsertEntry(DiaryEntriesCompanion.insert(
      diaryId: Value(b),
      date: '2026-01-01',
      mediaPath: '/tmp/b1.jpg',
      mediaType: 'photo',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await db.diariesDao.deleteDiaryWithEntries(a);

    expect(await db.diariesDao.getById(a), isNull);
    expect(await db.diaryDao.getAllEntries(a), isEmpty);
    // Das andere Tagebuch und sein Eintrag bleiben unangetastet.
    expect(await db.diariesDao.getById(b), isNotNull);
    expect(await db.diaryDao.getAllEntries(b), hasLength(1));
  });
}
