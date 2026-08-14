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
    diaryA = await db.diariesDao.insert(
      DiariesCompanion.insert(
        name: 'A',
        iconName: 'book',
        createdAt: DateTime.now(),
      ),
    );
    diaryB = await db.diariesDao.insert(
      DiariesCompanion.insert(
        name: 'B',
        iconName: 'book',
        createdAt: DateTime.now(),
      ),
    );
  });
  tearDown(() => db.close());

  Future<void> addEntry(
    int diaryId,
    String date, {
    String note = '',
    DateTime? createdAt,
  }) => db.diaryDao.upsertEntry(
    DiaryEntriesCompanion.insert(
      diaryId: Value(diaryId),
      date: date,
      mediaPath: '/tmp/$diaryId-$date.jpg',
      mediaType: 'photo',
      note: Value(note),
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: createdAt ?? DateTime.now(),
    ),
  );

  test('entries stay scoped to their diary across all query methods', () async {
    await addEntry(diaryA, '2026-01-01');
    await addEntry(diaryA, '2026-01-15');
    await addEntry(diaryB, '2026-01-01');

    expect(await db.diaryDao.getTotalCount(diaryA), 2);
    expect(await db.diaryDao.getTotalCount(diaryB), 1);

    final aMonth = await db.diaryDao.getEntriesForMonth(diaryA, 2026, 1);
    expect(aMonth, hasLength(2));
    final bMonth = await db.diaryDao.getEntriesForMonth(diaryB, 2026, 1);
    expect(bMonth, hasLength(1));

    expect(await db.diaryDao.getDatesWithEntries(diaryA), [
      '2026-01-15',
      '2026-01-01',
    ]);
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

  test(
    'getLastEntry returns the most recent entry of that diary only',
    () async {
      await addEntry(diaryA, '2026-01-01', createdAt: DateTime(2026, 1, 1, 10));
      await addEntry(diaryA, '2026-01-02', createdAt: DateTime(2026, 1, 2, 10));
      await addEntry(diaryB, '2026-01-05', createdAt: DateTime(2026, 1, 5, 10));

      final last = await db.diaryDao.getLastEntry(diaryA);
      expect(last!.date, '2026-01-02');
    },
  );

  test(
    'getAllEntries returns every entry regardless of date, scoped to diary',
    () async {
      await addEntry(diaryA, '2020-01-01');
      await addEntry(diaryA, '2026-06-01');
      await addEntry(diaryB, '2026-06-01');

      expect(await db.diaryDao.getAllEntries(diaryA), hasLength(2));
      expect(await db.diaryDao.getAllEntries(diaryB), hasLength(1));
    },
  );

  test('upsertEntry twice for the same diary+date updates the existing row '
      'instead of creating a duplicate', () async {
    await addEntry(diaryA, '2026-04-01', note: 'erster Versuch');
    // Simulates a double-tap on the capture buttons: a second capture flow
    // for the same day lands here before the first one is visible on screen.
    await addEntry(diaryA, '2026-04-01', note: 'zweiter Versuch');

    expect(await db.diaryDao.getTotalCount(diaryA), 1);
    final entry = await db.diaryDao.getEntryForDate(diaryA, '2026-04-01');
    expect(entry!.note, 'zweiter Versuch');

    // Same date is still independent per diary — no cross-diary clobbering.
    await addEntry(diaryB, '2026-04-01', note: 'von B');
    expect(await db.diaryDao.getTotalCount(diaryB), 1);
    expect(
      (await db.diaryDao.getEntryForDate(diaryA, '2026-04-01'))!.note,
      'zweiter Versuch',
    );
  });

  test('searchEntries matches case-insensitively on the note, scoped to '
      'diary and newest first', () async {
    await addEntry(
      diaryA,
      '2026-05-01',
      note: 'Waldspaziergang mit Regen',
      createdAt: DateTime(2026, 5, 1),
    );
    await addEntry(
      diaryA,
      '2026-05-10',
      note: 'Sonniger Tag am See',
      createdAt: DateTime(2026, 5, 10),
    );
    await addEntry(
      diaryA,
      '2026-05-15',
      note: 'Noch mehr Regen heute',
      createdAt: DateTime(2026, 5, 15),
    );
    await addEntry(
      diaryB,
      '2026-05-01',
      note: 'Regen auch hier',
      createdAt: DateTime(2026, 5, 1),
    );

    final hits = await db.diaryDao.searchEntries(diaryA, 'regen');
    expect(hits.map((e) => e.date), ['2026-05-15', '2026-05-01']);

    expect(await db.diaryDao.searchEntries(diaryA, 'xyz'), isEmpty);
  });

  test('searchEntries treats % and _ in the query as literal characters, '
      'not SQL LIKE wildcards', () async {
    await addEntry(
      diaryA,
      '2026-06-01',
      note: '50% geschafft',
      createdAt: DateTime(2026, 6, 1),
    );
    await addEntry(
      diaryA,
      '2026-06-02',
      note: 'Ganz normaler Tag',
      createdAt: DateTime(2026, 6, 2),
    );

    // A query of only wildcard characters must match just the entry that
    // literally contains that character — not every row. This regressed
    // once when "%" was interpolated straight into a LIKE pattern without
    // escaping, so `LIKE '%%%'` matched everything, including the entry
    // with no "%" in it at all.
    final percentHits = await db.diaryDao.searchEntries(diaryA, '%');
    expect(percentHits.map((e) => e.date), ['2026-06-01']);
    expect(await db.diaryDao.searchEntries(diaryA, '_'), isEmpty);

    final hits = await db.diaryDao.searchEntries(diaryA, '50%');
    expect(hits.map((e) => e.date), ['2026-06-01']);
  });
}
