import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'diaries_dao.g.dart';

@DriftAccessor(tables: [Diaries, DiaryEntries])
class DiariesDao extends DatabaseAccessor<TraumDatabase>
    with _$DiariesDaoMixin {
  DiariesDao(super.db);

  Future<List<Diary>> getAll() =>
      (select(diaries)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<Diary?> getById(int id) =>
      (select(diaries)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insert(DiariesCompanion d) => into(diaries).insert(d);

  Future<bool> updateDiary(Diary d) => update(diaries).replace(d);

  Future<int> entryCount(int diaryId) => (selectOnly(diaryEntries)
        ..addColumns([diaryEntries.id.count()])
        ..where(diaryEntries.diaryId.equals(diaryId)))
      .map((r) => r.read(diaryEntries.id.count())!)
      .getSingle();

  /// Löscht ein Tagebuch samt aller seiner Einträge (Medien-Dateien auf der
  /// Festplatte bleiben unberührt — das ist Sache des Aufrufers, der die
  /// Pfade vor dem Löschen aus der DB kennt).
  Future<void> deleteDiaryWithEntries(int id) => transaction(() async {
        await (delete(diaryEntries)..where((t) => t.diaryId.equals(id))).go();
        await (delete(diaries)..where((t) => t.id.equals(id))).go();
      });

  Future<int> nextSortOrder() async {
    final all = await getAll();
    return all.isEmpty
        ? 0
        : all.map((d) => d.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }
}
