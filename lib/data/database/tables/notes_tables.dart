import 'package:drift/drift.dart';

/// Tabellen für das Notizen-Modul (Obsidian-artiges PKM).
///
/// Drift ist Source of Truth. Der Notiz-Inhalt liegt als Markdown-Rohtext in
/// [Notes.content]. Wikilinks und Tags werden beim Speichern geparst und in die
/// Index-Tabellen [NoteLinks] / [NoteTags] geschrieben, damit Backlinks,
/// Outgoing-Links, Tag-Browser und Graph reine SQL-Abfragen sind. Die
/// Volltextsuche läuft über eine separat (per customStatement) angelegte
/// FTS5-Virtual-Table `notes_fts`.

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text().withDefault(const Constant(''))();

  /// FK auf [NoteFolders.id]; NULL = Wurzelebene.
  IntColumn get folderId => integer().nullable()();

  BoolColumn get isDaily => boolean().withDefault(const Constant(false))();

  /// Gesetzt wenn [isDaily]; ISO-Datum als reines Datum.
  DateTimeColumn get dailyDate => dateTime().nullable()();

  BoolColumn get isBookmarked =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// YAML-Frontmatter als JSON gespeichert.
  TextColumn get propertiesJson =>
      text().withDefault(const Constant('{}'))();

  IntColumn get wordCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft-Delete für den Papierkorb.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class NoteFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Selbstreferenz für den Ordnerbaum; NULL = Wurzel.
  IntColumn get parentId => integer().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Index der Wikilinks zwischen Notizen. Wird bei jedem Speichern der
/// Quellnotiz neu aufgebaut.
class NoteLinks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceNoteId => integer()();

  /// NULL = unaufgelöste Verlinkung.
  IntColumn get targetNoteId => integer().nullable()();

  /// Der im `[[...]]` geschriebene Name (inkl. evtl. Heading/Block-Anker).
  TextColumn get targetTitleRaw => text()();

  /// 'link' | 'embed'.
  TextColumn get linkType => text().withDefault(const Constant('link'))();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Vollständiger Pfad, z. B. `projekt/traum`.
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
}

class NoteTags extends Table {
  IntColumn get noteId => integer()();
  IntColumn get tagId => integer()();

  @override
  Set<Column> get primaryKey => {noteId, tagId};
}

class NoteTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Markdown mit Platzhaltern (siehe Vorlagen-Service).
  TextColumn get content => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
}
