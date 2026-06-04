import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:yaml/yaml.dart';

import '../../features/notes/notes_markdown_parser.dart';
import '../database/traum_database.dart';

/// Kapselt alle Drift-Zugriffe des Notizen-Moduls inklusive der Index-Pflege
/// (Wikilinks, Tags, Wortzahl, Properties). Widgets/Provider greifen nur hier
/// zu, niemals direkt auf den DAO – so bleibt die Indexlogik an einer Stelle.
class NotesRepository {
  final NotesDao _dao;

  NotesRepository(this._dao);

  // ─── Lesen ────────────────────────────────────────────────────────────────

  Stream<List<Note>> watchActiveNotes() => _dao.watchActiveNotes();
  Stream<List<Note>> watchNotesInFolder(int? folderId) =>
      _dao.watchNotesInFolder(folderId);
  Stream<List<Note>> watchRecentNotes(int limit) => _dao.watchRecentNotes(limit);
  Stream<List<Note>> watchBookmarkedNotes() => _dao.watchBookmarkedNotes();
  Stream<List<Note>> watchTrashedNotes() => _dao.watchTrashedNotes();
  Stream<List<NoteFolder>> watchFolders() => _dao.watchFolders();
  Stream<Note?> watchNote(int id) => _dao.watchNote(id);
  Future<Note?> getNote(int id) => _dao.getNote(id);
  Future<Note?> getNoteByTitle(String title) => _dao.getNoteByTitle(title);

  Stream<List<Note>> watchDailyNotes() => _dao.watchDailyNotes();
  Future<Note?> getDailyNote(DateTime date) => _dao.getDailyNote(date);

  Stream<List<Tag>> watchAllTags() => _dao.watchAllTags();
  Future<Map<String, int>> getTagCounts() => _dao.getTagCounts();
  Future<List<Note>> getNotesForTag(String tag) => _dao.getNotesForTag(tag);

  Stream<List<NoteTemplate>> watchTemplates() => _dao.watchTemplates();
  Future<NoteTemplate?> getTemplate(int id) => _dao.getTemplate(id);

  Future<List<NoteSearchHit>> search(String q) => _dao.search(q);
  Future<List<Note>> searchTitles(String q) => _dao.searchTitles(q);

  // ─── Backlinks / Outgoing ─────────────────────────────────────────────────

  Future<List<NoteLink>> getOutgoingLinks(int noteId) =>
      _dao.getOutgoingLinks(noteId);
  Future<List<NoteLink>> getBacklinks(int noteId) => _dao.getBacklinks(noteId);
  Future<List<NoteLink>> getAllResolvedLinks() => _dao.getAllResolvedLinks();

  // ─── Notiz anlegen ──────────────────────────────────────────────────────

  /// Legt eine neue Notiz an und löst bislang offene Links auf ihren Titel auf.
  Future<int> createNote({
    required String title,
    String content = '',
    int? folderId,
    bool isDaily = false,
    DateTime? dailyDate,
  }) async {
    final now = DateTime.now();
    final id = await _dao.insertNote(NotesCompanion.insert(
      title: title,
      content: Value(content),
      folderId: Value(folderId),
      isDaily: Value(isDaily),
      dailyDate: Value(dailyDate),
      wordCount: Value(NotesMarkdownParser.wordCount(content)),
      propertiesJson: Value(_extractPropertiesJson(content)),
      createdAt: now,
      updatedAt: now,
    ));
    // Bestehende unaufgelöste Links, die jetzt auflösbar sind, verbinden.
    await _resolveIncomingFor(title, id);
    // Eigene Links/Tags indexieren.
    await _reindex(id, content);
    return id;
  }

  // ─── Notiz speichern (Inhalt/Titel) ─────────────────────────────────────

  /// Speichert Inhalt (und optional Titel) und baut den kompletten Index neu auf.
  Future<void> saveNoteContent(int id, String content, {String? title}) async {
    final resolvedTitle = title ?? _deriveTitle(content);
    await _dao.updateNoteFields(
      id,
      NotesCompanion(
        content: Value(content),
        title: Value(resolvedTitle),
        wordCount: Value(NotesMarkdownParser.wordCount(content)),
        propertiesJson: Value(_extractPropertiesJson(content)),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _resolveIncomingFor(resolvedTitle, id);
    await _reindex(id, content);
  }

  Future<void> renameNote(int id, String title) async {
    await _dao.updateNoteFields(
      id,
      NotesCompanion(title: Value(title), updatedAt: Value(DateTime.now())),
    );
    await _resolveIncomingFor(title, id);
  }

  // ─── Flags / Verschieben ─────────────────────────────────────────────────

  Future<void> setBookmarked(int id, bool value) => _dao.updateNoteFields(
      id, NotesCompanion(isBookmarked: Value(value)));
  Future<void> setPinned(int id, bool value) =>
      _dao.updateNoteFields(id, NotesCompanion(isPinned: Value(value)));
  Future<void> moveToFolder(int noteId, int? folderId) =>
      _dao.moveNoteToFolder(noteId, folderId);

  // ─── Löschen / Wiederherstellen ───────────────────────────────────────────

  Future<void> softDelete(int id) async {
    await _dao.unresolveLinksTo(id);
    await _dao.softDeleteNote(id);
  }

  Future<void> restore(int id) async {
    await _dao.restoreNote(id);
    final note = await _dao.getNote(id);
    if (note != null) {
      await _resolveIncomingFor(note.title, id);
      await _reindex(id, note.content);
    }
  }

  Future<void> deletePermanently(int id) async {
    await _dao.unresolveLinksTo(id);
    await _dao.hardDeleteNote(id);
  }

  // ─── Ordner ─────────────────────────────────────────────────────────────

  Future<int> createFolder(String name, {int? parentId}) =>
      _dao.insertFolder(NoteFoldersCompanion.insert(
        name: name,
        parentId: Value(parentId),
        createdAt: DateTime.now(),
      ));

  Future<void> renameFolder(int id, String name) => _dao.renameFolder(id, name);
  Future<void> deleteFolder(int id) => _dao.deleteFolder(id);

  // ─── Vorlagen ───────────────────────────────────────────────────────────

  Future<int> createTemplate(String name, String content) =>
      _dao.insertTemplate(NoteTemplatesCompanion.insert(
        name: name,
        content: Value(content),
        createdAt: DateTime.now(),
      ));

  Future<void> updateTemplate(int id, String name, String content) =>
      _dao.updateTemplate(
        id,
        NoteTemplatesCompanion(name: Value(name), content: Value(content)),
      );

  Future<void> deleteTemplate(int id) => _dao.deleteTemplate(id);

  // ─── Interne Indexpflege ──────────────────────────────────────────────────

  Future<void> _reindex(int noteId, String content) async {
    final links = NotesMarkdownParser.extractLinks(content);
    final companions = <NoteLinksCompanion>[];
    for (final link in links) {
      final target = await _resolveTarget(link.target);
      companions.add(NoteLinksCompanion.insert(
        sourceNoteId: noteId,
        targetNoteId: Value(target?.id),
        targetTitleRaw: link.target,
        linkType: Value(link.linkType),
      ));
    }
    await _dao.replaceLinks(noteId, companions);

    final tags = NotesMarkdownParser.extractTags(content);
    await _dao.setNoteTags(noteId, tags);
  }

  /// Verbindet offene Links, die auf [title] (oder einen Alias der Notiz)
  /// zeigen, mit [noteId].
  Future<void> _resolveIncomingFor(String title, int noteId) async {
    await _dao.resolveLinksForTitle(title, noteId);
  }

  /// Löst einen Link-Zielnamen über Titel oder Alias auf.
  Future<Note?> _resolveTarget(String rawTarget) async {
    final byTitle = await _dao.getNoteByTitle(rawTarget);
    if (byTitle != null) return byTitle;
    // Alias-Auflösung: durchsucht properties_json.aliases der aktiven Notizen.
    final all = await _dao.getActiveNotes();
    final wanted = rawTarget.toLowerCase();
    for (final note in all) {
      for (final alias in _aliasesOf(note)) {
        if (alias.toLowerCase() == wanted) return note;
      }
    }
    return null;
  }

  List<String> _aliasesOf(Note note) {
    try {
      final map = jsonDecode(note.propertiesJson) as Map<String, dynamic>;
      final aliases = map['aliases'];
      if (aliases is List) {
        return aliases.map((e) => e.toString()).toList();
      }
      if (aliases is String && aliases.isNotEmpty) return [aliases];
    } catch (_) {}
    return const [];
  }

  /// YAML-Frontmatter → JSON-String für `properties_json`.
  String _extractPropertiesJson(String content) {
    final raw = NotesMarkdownParser.extractFrontmatterRaw(content);
    if (raw == null || raw.trim().isEmpty) return '{}';
    try {
      final yaml = loadYaml(raw);
      if (yaml is YamlMap) {
        return jsonEncode(_yamlToJson(yaml));
      }
    } catch (_) {}
    return '{}';
  }

  dynamic _yamlToJson(dynamic node) {
    if (node is YamlMap) {
      return {
        for (final entry in node.entries)
          entry.key.toString(): _yamlToJson(entry.value),
      };
    }
    if (node is YamlList) {
      return node.map(_yamlToJson).toList();
    }
    return node;
  }

  /// Leitet aus dem Inhalt einen Titel ab, falls keiner gesetzt ist:
  /// Frontmatter `title`, sonst erste Überschrift/Zeile, sonst „Unbenannt“.
  String _deriveTitle(String content) {
    final raw = NotesMarkdownParser.extractFrontmatterRaw(content);
    if (raw != null) {
      try {
        final yaml = loadYaml(raw);
        if (yaml is YamlMap && yaml['title'] != null) {
          return yaml['title'].toString();
        }
      } catch (_) {}
    }
    final body = NotesMarkdownParser.stripFrontmatter(content).trimLeft();
    for (final line in body.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      return t.replaceFirst(RegExp(r'^#{1,6}\s+'), '').trim();
    }
    return 'Unbenannt';
  }
}
