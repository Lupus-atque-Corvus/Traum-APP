import '../database/traum_database.dart';

/// Kapselt Zugriffe auf Tagebücher (`Diaries`) und ihre Einträge
/// (`DiaryEntries`) — Screens rufen ausschließlich diese Klasse, nie die
/// DAOs direkt (Non-Negotiable #5).
class DiaryRepository {
  final DiaryDao _entriesDao;
  final DiariesDao _diariesDao;
  DiaryRepository(this._entriesDao, this._diariesDao);

  // ─── Tagebücher ─────────────────────────────────────────────────────────
  Future<List<Diary>> getAllDiaries() => _diariesDao.getAll();
  Future<Diary?> getDiaryById(int id) => _diariesDao.getById(id);
  Future<int> createDiary(DiariesCompanion d) => _diariesDao.insert(d);
  Future<bool> updateDiary(Diary d) => _diariesDao.updateDiary(d);
  Future<void> deleteDiaryWithEntries(int id) =>
      _diariesDao.deleteDiaryWithEntries(id);
  Future<int> nextDiarySortOrder() => _diariesDao.nextSortOrder();
  Future<int> diaryEntryCount(int diaryId) => _diariesDao.entryCount(diaryId);

  // ─── Einträge ───────────────────────────────────────────────────────────
  Future<DiaryEntry?> getEntryForDate(int diaryId, String date) =>
      _entriesDao.getEntryForDate(diaryId, date);
  Future<List<DiaryEntry>> getEntriesForMonth(
          int diaryId, int year, int month) =>
      _entriesDao.getEntriesForMonth(diaryId, year, month);
  Future<List<DiaryEntry>> getRecentEntries(int diaryId, int days) =>
      _entriesDao.getRecentEntries(diaryId, days);
  Future<List<DiaryEntry>> getAllEntries(int diaryId) =>
      _entriesDao.getAllEntries(diaryId);
  Future<void> upsertEntry(DiaryEntriesCompanion entry) =>
      _entriesDao.upsertEntry(entry);
  Future<void> deleteEntry(int id) => _entriesDao.deleteEntry(id);
  Future<List<String>> getDatesWithEntries(int diaryId) =>
      _entriesDao.getDatesWithEntries(diaryId);
  Future<DiaryEntry?> getLastEntry(int diaryId) =>
      _entriesDao.getLastEntry(diaryId);
  Future<int> getTotalCount(int diaryId) => _entriesDao.getTotalCount(diaryId);
  Future<List<String>> getDatesLastYear(int diaryId) =>
      _entriesDao.getDatesLastYear(diaryId);
  Future<List<DiaryEntry>> searchEntries(int diaryId, String query) =>
      _entriesDao.searchEntries(diaryId, query);
}
