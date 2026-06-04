import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'notes_dao.g.dart';

/// Ein FTS5-Suchtreffer: die Notiz plus ein hervorgehobenes Snippet.
class NoteSearchHit {
  final Note note;
  final String snippet;
  const NoteSearchHit(this.note, this.snippet);
}

@DriftAccessor(
  tables: [Notes, NoteFolders, NoteLinks, Tags, NoteTags, NoteTemplates],
)
class NotesDao extends DatabaseAccessor<TraumDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  // ─── Notizen ────────────────────────────────────────────────────────────

  /// Aktive (nicht soft-gelöschte) Notizen.
  Stream<List<Note>> watchActiveNotes() =>
      (select(notes)..where((t) => t.deletedAt.isNull())).watch();

  Future<List<Note>> getActiveNotes() =>
      (select(notes)..where((t) => t.deletedAt.isNull())).get();

  Stream<List<Note>> watchNotesInFolder(int? folderId) {
    final q = select(notes)..where((t) => t.deletedAt.isNull());
    if (folderId == null) {
      q.where((t) => t.folderId.isNull());
    } else {
      q.where((t) => t.folderId.equals(folderId));
    }
    q.orderBy([(t) => OrderingTerm(expression: t.title)]);
    return q.watch();
  }

  Future<Note?> getNote(int id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Note?> watchNote(int id) =>
      (select(notes)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Findet eine Notiz anhand des exakten Titels (case-insensitive),
  /// nur unter den aktiven Notizen. Für Wikilink-Auflösung.
  Future<Note?> getNoteByTitle(String title) => (select(notes)
        ..where((t) => t.deletedAt.isNull() & t.title.lower().equals(title.toLowerCase()))
        ..limit(1))
      .getSingleOrNull();

  Stream<List<Note>> watchRecentNotes(int limit) => (select(notes)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
        ..limit(limit))
      .watch();

  Stream<List<Note>> watchBookmarkedNotes() => (select(notes)
        ..where((t) => t.deletedAt.isNull() & t.isBookmarked.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Stream<List<Note>> watchTrashedNotes() => (select(notes)
        ..where((t) => t.deletedAt.isNotNull())
        ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
      .watch();

  Future<int> insertNote(NotesCompanion entry) => into(notes).insert(entry);

  Future<bool> updateNote(NotesCompanion entry) =>
      update(notes).replace(entry);

  Future<int> updateNoteFields(int id, NotesCompanion entry) =>
      (update(notes)..where((t) => t.id.equals(id))).write(entry);

  /// Soft-Delete: in den Papierkorb verschieben.
  Future<int> softDeleteNote(int id) => (update(notes)
        ..where((t) => t.id.equals(id)))
      .write(NotesCompanion(deletedAt: Value(DateTime.now())));

  Future<int> restoreNote(int id) => (update(notes)..where((t) => t.id.equals(id)))
      .write(const NotesCompanion(deletedAt: Value(null)));

  /// Endgültig löschen inkl. abhängiger Index-Zeilen.
  Future<void> hardDeleteNote(int id) async {
    await (delete(noteLinks)..where((t) => t.sourceNoteId.equals(id))).go();
    await (delete(noteTags)..where((t) => t.noteId.equals(id))).go();
    await (delete(notes)..where((t) => t.id.equals(id))).go();
  }

  // ─── Daily Notes ──────────────────────────────────────────────────────────

  Future<Note?> getDailyNote(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return (select(notes)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.isDaily.equals(true) &
              t.dailyDate.equals(day))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<List<Note>> watchDailyNotes() => (select(notes)
        ..where((t) => t.deletedAt.isNull() & t.isDaily.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.dailyDate)]))
      .watch();

  // ─── Ordner ─────────────────────────────────────────────────────────────

  Stream<List<NoteFolder>> watchFolders() => (select(noteFolders)
        ..orderBy([
          (t) => OrderingTerm(expression: t.sortOrder),
          (t) => OrderingTerm(expression: t.name),
        ]))
      .watch();

  Future<List<NoteFolder>> getFolders() => select(noteFolders).get();

  Future<int> insertFolder(NoteFoldersCompanion entry) =>
      into(noteFolders).insert(entry);

  Future<int> renameFolder(int id, String name) =>
      (update(noteFolders)..where((t) => t.id.equals(id)))
          .write(NoteFoldersCompanion(name: Value(name)));

  /// Löscht einen Ordner; enthaltene Notizen wandern zur Wurzel,
  /// Unterordner wandern eine Ebene hoch zum parent.
  Future<void> deleteFolder(int id) async {
    final folder =
        await (select(noteFolders)..where((t) => t.id.equals(id))).getSingleOrNull();
    await (update(notes)..where((t) => t.folderId.equals(id)))
        .write(const NotesCompanion(folderId: Value(null)));
    await (update(noteFolders)..where((t) => t.parentId.equals(id)))
        .write(NoteFoldersCompanion(parentId: Value(folder?.parentId)));
    await (delete(noteFolders)..where((t) => t.id.equals(id))).go();
  }

  Future<int> moveNoteToFolder(int noteId, int? folderId) =>
      (update(notes)..where((t) => t.id.equals(noteId)))
          .write(NotesCompanion(folderId: Value(folderId)));

  // ─── Links ──────────────────────────────────────────────────────────────

  /// Ersetzt alle ausgehenden Links der Quellnotiz durch [links].
  Future<void> replaceLinks(int sourceNoteId, List<NoteLinksCompanion> links) async {
    await (delete(noteLinks)..where((t) => t.sourceNoteId.equals(sourceNoteId)))
        .go();
    if (links.isNotEmpty) {
      await batch((b) => b.insertAll(noteLinks, links));
    }
  }

  Future<List<NoteLink>> getOutgoingLinks(int noteId) =>
      (select(noteLinks)..where((t) => t.sourceNoteId.equals(noteId))).get();

  Future<List<NoteLink>> getBacklinks(int noteId) =>
      (select(noteLinks)..where((t) => t.targetNoteId.equals(noteId))).get();

  /// Versucht, bislang unaufgelöste Links auf [title] mit [noteId] zu verbinden.
  Future<void> resolveLinksForTitle(String title, int noteId) async {
    await (update(noteLinks)
          ..where((t) =>
              t.targetNoteId.isNull() &
              t.targetTitleRaw.lower().equals(title.toLowerCase())))
        .write(NoteLinksCompanion(targetNoteId: Value(noteId)));
  }

  /// Setzt Links, deren Ziel die Notiz [noteId] war, wieder auf unaufgelöst
  /// (z. B. wenn die Notiz gelöscht wurde).
  Future<void> unresolveLinksTo(int noteId) async {
    await (update(noteLinks)..where((t) => t.targetNoteId.equals(noteId)))
        .write(const NoteLinksCompanion(targetNoteId: Value(null)));
  }

  Future<List<NoteLink>> getAllResolvedLinks() =>
      (select(noteLinks)..where((t) => t.targetNoteId.isNotNull())).get();

  // ─── Tags ─────────────────────────────────────────────────────────────────

  Future<Tag> ensureTag(String name) async {
    final existing =
        await (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing;
    final id = await into(tags).insert(
      TagsCompanion.insert(name: name, createdAt: DateTime.now()),
    );
    return (select(tags)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> setNoteTags(int noteId, List<String> tagNames) async {
    await (delete(noteTags)..where((t) => t.noteId.equals(noteId))).go();
    for (final name in tagNames.toSet()) {
      final tag = await ensureTag(name);
      await into(noteTags).insert(
        NoteTagsCompanion.insert(noteId: noteId, tagId: tag.id),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  Future<List<Tag>> getAllTags() =>
      (select(tags)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();

  Stream<List<Tag>> watchAllTags() =>
      (select(tags)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();

  /// Liefert (tagName -> Anzahl aktiver Notizen).
  Future<Map<String, int>> getTagCounts() async {
    final rows = await customSelect(
      'SELECT t.name AS name, COUNT(*) AS cnt '
      'FROM note_tags nt '
      'JOIN tags t ON t.id = nt.tag_id '
      'JOIN notes n ON n.id = nt.note_id '
      'WHERE n.deleted_at IS NULL '
      'GROUP BY t.id',
      readsFrom: {tags, noteTags, notes},
    ).get();
    return {
      for (final r in rows) r.read<String>('name'): r.read<int>('cnt'),
    };
  }

  Future<List<Note>> getNotesForTag(String tagName) async {
    final rows = await customSelect(
      'SELECT n.* FROM notes n '
      'JOIN note_tags nt ON nt.note_id = n.id '
      'JOIN tags t ON t.id = nt.tag_id '
      'WHERE t.name = ? AND n.deleted_at IS NULL '
      'ORDER BY n.updated_at DESC',
      variables: [Variable.withString(tagName)],
      readsFrom: {notes, noteTags, tags},
    ).get();
    return rows.map((r) => notes.map(r.data)).toList();
  }

  // ─── Vorlagen ───────────────────────────────────────────────────────────

  Stream<List<NoteTemplate>> watchTemplates() =>
      (select(noteTemplates)..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .watch();

  Future<NoteTemplate?> getTemplate(int id) =>
      (select(noteTemplates)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTemplate(NoteTemplatesCompanion entry) =>
      into(noteTemplates).insert(entry);

  Future<int> updateTemplate(int id, NoteTemplatesCompanion entry) =>
      (update(noteTemplates)..where((t) => t.id.equals(id))).write(entry);

  Future<int> deleteTemplate(int id) =>
      (delete(noteTemplates)..where((t) => t.id.equals(id))).go();

  // ─── Volltextsuche (FTS5) ─────────────────────────────────────────────────

  Future<List<NoteSearchHit>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    // Ohne fts5-Modul gibt es keine notes_fts-Tabelle → leeres Ergebnis.
    if (!attachedDatabase.ftsAvailable) return [];
    // Präfix-Match auf das letzte Token für „suche während des Tippens“.
    final match = '${_escapeFts(trimmed)}*';
    final rows = await customSelect(
      'SELECT n.*, '
      "snippet(notes_fts, 1, '⟦', '⟧', '…', 12) AS snip "
      'FROM notes_fts f '
      'JOIN notes n ON n.id = f.rowid '
      'WHERE notes_fts MATCH ? AND n.deleted_at IS NULL '
      'ORDER BY rank '
      'LIMIT 50',
      variables: [Variable.withString(match)],
      readsFrom: {notes},
    ).get();
    return rows
        .map((r) => NoteSearchHit(notes.map(r.data), r.read<String>('snip')))
        .toList();
  }

  /// Schneller Titel-Filter für den Quick-Switcher.
  Future<List<Note>> searchTitles(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return (select(notes)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(30))
          .get();
    }
    return (select(notes)
          ..where((t) => t.deletedAt.isNull() & t.title.lower().like('%$q%'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(30))
        .get();
  }

  /// Maskiert FTS5-Sonderzeichen, indem das Token in Anführungszeichen gesetzt
  /// wird. Mehrere Wörter werden als einzelne Phrasen verknüpft.
  String _escapeFts(String input) {
    final tokens = input
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '"${t.replaceAll('"', '""')}"');
    return tokens.join(' ');
  }
}
