import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;
  late int diaryA;
  late int diaryB;

  setUp(() async {
    db = TraumDatabase.forTesting(NativeDatabase.memory());
    diaryA = await db.diariesDao.insert(DiariesCompanion.insert(
        name: 'A', iconName: 'book', createdAt: DateTime.now()));
    diaryB = await db.diariesDao.insert(DiariesCompanion.insert(
        name: 'B', iconName: 'book', createdAt: DateTime.now()));
  });
  tearDown(() => db.close());

  Future<void> addEntry(int diaryId, String date,
          {String note = '', DateTime? createdAt}) =>
      db.diaryDao.upsertEntry(DiaryEntriesCompanion.insert(
        diaryId: Value(diaryId),
        date: date,
        mediaPath: '/tmp/$diaryId-$date.jpg',
        mediaType: 'photo',
        note: Value(note),
        createdAt: createdAt ?? DateTime.now(),
        updatedAt: createdAt ?? DateTime.now(),
      ));

  test('entries stay scoped to their diary across all query methods',
      () async {
    await addEntry(diaryA, '2026-01-01');
    await addEntry(diaryA, '2026-01-15');
    await addEntry(diaryB, '2026-01-01');

    expect(await db.diaryDao.getTotalCount(diaryA), 2);
    expect(await db.diaryDao.getTotalCount(diaryB), 1);

    final aMonth = await db.diaryDao.getEntriesForMonth(diaryA, 2026, 1);
    expect(aMonth, hasLength(2));
    final bMonth = await db.diaryDao.getEntriesForMonth(diaryB, 2026, 1);
    expect(bMonth, hasLength(1));

    expect(await db.diaryDao.getDatesWithEntries(diaryA),
        ['2026-01-15', '2026-01-01']);
    expect(await db.diaryDao.getDatesWithEntries(diaryB), ['2026-01-01']);
  });

  test('getEntryForDate only matches within the given diary', () async {
    await addEntry(diaryA, '2026-02-01', note: 'von A');
    await addEntry(diaryB, '2026-02-01', note: 'von B');

    final a = await db.diaryDao.getEntryForDate(diaryA, '2026-02-01');
    final b = await db.diaryDao.getEntryForDate(diaryB, '2026-02-01');
    expect(a!.note, 'von A');
    expect(b!.note, 'von B');

    // Zwei Tagebücher können denselben Tag unabhängig belegen — die
    // "ein Eintrag pro Tag"-Regel gilt pro Tagebuch, nicht global.
    expect(await db.diaryDao.getEntryForDate(diaryA, '2026-03-01'), isNull);
  });

  test('getLastEntry returns the most recent entry of that diary only',
      () async {
    await addEntry(diaryA, '2026-01-01',
        createdAt: DateTime(2026, 1, 1, 10));
    await addEntry(diaryA, '2026-01-02',
        createdAt: DateTime(2026, 1, 2, 10));
    await addEntry(diaryB, '2026-01-05',
        createdAt: DateTime(2026, 1, 5, 10));

    final last = await db.diaryDao.getLastEntry(diaryA);
    expect(last!.date, '2026-01-02');
  });

  test('getAllEntries returns every entry regardless of date, scoped to diary',
      () async {
    await addEntry(diaryA, '2020-01-01');
    await addEntry(diaryA, '2026-06-01');
    await addEntry(diaryB, '2026-06-01');

    expect(await db.diaryDao.getAllEntries(diaryA), hasLength(2));
    expect(await db.diaryDao.getAllEntries(diaryB), hasLength(1));
  });
}
