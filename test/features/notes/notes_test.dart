import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/notes/notes_markdown_parser.dart';

/// Characterization tests for the notes (PKM) module:
/// the pure Obsidian-style markdown parser and the DAO link/tag index.
/// Locks in current behavior before dependency major-upgrades (Phase 4).
void main() {
  // ─── Pure parser ─────────────────────────────────────────────────────────────
  group('NotesMarkdownParser.extractLinks', () {
    test('plain, alias, anchor, block and embed links', () {
      final links = NotesMarkdownParser.extractLinks(
        'See [[Alpha]] and [[Beta|the beta]] and [[Gamma#Heading]] '
        'and [[Delta#^block1]] and ![[Embed]]',
      );
      expect(links.map((l) => l.target),
          ['Alpha', 'Beta', 'Gamma', 'Delta', 'Embed']);

      expect(links[1].alias, 'the beta');
      expect(links[2].anchor, 'Heading');
      expect(links[3].anchor, '^block1');
      expect(links[4].isEmbed, isTrue);
      expect(links[4].linkType, 'embed');
      expect(links[0].isEmbed, isFalse);
      expect(links[0].linkType, 'link');
    });

    test('anchor and alias combined keep bare target', () {
      final l = NotesMarkdownParser.extractLinks('[[Page#Sec|Shown]]').single;
      expect(l.target, 'Page');
      expect(l.anchor, 'Sec');
      expect(l.alias, 'Shown');
    });

    test('ignores links inside code, comments and frontmatter', () {
      // Must start exactly with '---' so the frontmatter anchor matches.
      const content = '---\n'
          'title: Note\n'
          'link: [[InFrontmatter]]\n'
          '---\n'
          'Real [[Visible]]\n'
          '`[[InlineCode]]`\n'
          '```\n'
          '[[FencedCode]]\n'
          '```\n'
          '%% [[InComment]] %%\n';
      final targets =
          NotesMarkdownParser.extractLinks(content).map((l) => l.target);
      expect(targets, ['Visible']);
    });
  });

  group('NotesMarkdownParser.extractTags', () {
    test('inline and nested tags, deduplicated', () {
      final tags = NotesMarkdownParser.extractTags(
          'A #project and #project/traum plus #project again');
      expect(tags.toSet(), {'project', 'project/traum'});
    });

    test('requires a boundary and a leading letter', () {
      final tags = NotesMarkdownParser.extractTags(
          'no#inline here #123 numeric but #valid yes');
      expect(tags, ['valid']);
    });

    test('ignores tags inside fenced code', () {
      const content = '#real\n```\n#fake\n```';
      expect(NotesMarkdownParser.extractTags(content), ['real']);
    });
  });

  group('NotesMarkdownParser frontmatter', () {
    const withFm = '---\ntitle: Hi\ntags: [a, b]\n---\nBody text';

    test('stripFrontmatter removes the leading block', () {
      expect(NotesMarkdownParser.stripFrontmatter(withFm), 'Body text');
    });

    test('extractFrontmatterRaw returns the yaml body', () {
      expect(NotesMarkdownParser.extractFrontmatterRaw(withFm),
          'title: Hi\ntags: [a, b]');
    });

    test('no frontmatter → null and unchanged body', () {
      const plain = 'Just body';
      expect(NotesMarkdownParser.extractFrontmatterRaw(plain), isNull);
      expect(NotesMarkdownParser.stripFrontmatter(plain), plain);
    });

    test('handles CRLF line endings', () {
      const crlf = '---\r\ntitle: Hi\r\n---\r\nBody';
      expect(NotesMarkdownParser.extractFrontmatterRaw(crlf), 'title: Hi');
      expect(NotesMarkdownParser.stripFrontmatter(crlf), 'Body');
    });
  });

  group('NotesMarkdownParser.wordCount & outline', () {
    test('counts visible words, stripping wikilink and markdown syntax', () {
      expect(NotesMarkdownParser.wordCount('one two three'), 3);
      expect(NotesMarkdownParser.wordCount('click [[Target]] now'), 2);
      expect(
          NotesMarkdownParser.wordCount('# Title\n\nHello **world**'), 3);
    });

    test('extractOutline returns ATX headings with levels, skipping code', () {
      const content = '# H1\n## H2\nbody\n```\n## not-a-heading\n```\n### H3';
      final outline = NotesMarkdownParser.extractOutline(content);
      expect(outline.map((o) => o.level), [1, 2, 3]);
      expect(outline.map((o) => o.text), ['H1', 'H2', 'H3']);
    });
  });

  // ─── DAO link & tag index (in-memory DB) ─────────────────────────────────────
  group('NotesDao links', () {
    late TraumDatabase db;
    setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<int> addNote(String title, {DateTime? deletedAt, DateTime? updatedAt}) =>
        db.notesDao.insertNote(NotesCompanion.insert(
          title: title,
          createdAt: DateTime(2026, 6, 1),
          updatedAt: updatedAt ?? DateTime(2026, 6, 1),
          deletedAt: Value(deletedAt),
        ));

    test('replaceLinks overwrites previous outgoing links', () async {
      await db.notesDao.replaceLinks(1, [
        NoteLinksCompanion.insert(sourceNoteId: 1, targetTitleRaw: 'A'),
        NoteLinksCompanion.insert(sourceNoteId: 1, targetTitleRaw: 'B'),
      ]);
      expect((await db.notesDao.getOutgoingLinks(1)).length, 2);

      await db.notesDao.replaceLinks(1, [
        NoteLinksCompanion.insert(sourceNoteId: 1, targetTitleRaw: 'C'),
      ]);
      final out = await db.notesDao.getOutgoingLinks(1);
      expect(out.map((l) => l.targetTitleRaw), ['C']);
    });

    test('getBacklinks finds links pointing at a note', () async {
      await db.notesDao.replaceLinks(1, [
        NoteLinksCompanion.insert(
            sourceNoteId: 1, targetTitleRaw: 'Target', targetNoteId: const Value(2)),
      ]);
      final back = await db.notesDao.getBacklinks(2);
      expect(back.single.sourceNoteId, 1);
    });

    test('resolveLinksForTitle links unresolved links case-insensitively', () async {
      final targetId = await addNote('My Note');
      await db.notesDao.replaceLinks(1, [
        NoteLinksCompanion.insert(sourceNoteId: 1, targetTitleRaw: 'My Note'),
      ]);
      expect(await db.notesDao.getAllResolvedLinks(), isEmpty);

      await db.notesDao.resolveLinksForTitle('my note', targetId);
      final resolved = await db.notesDao.getAllResolvedLinks();
      expect(resolved.single.targetNoteId, targetId);
    });

    test('unresolveLinksTo resets resolved links back to null', () async {
      await db.notesDao.replaceLinks(1, [
        NoteLinksCompanion.insert(
            sourceNoteId: 1, targetTitleRaw: 'X', targetNoteId: const Value(5)),
      ]);
      await db.notesDao.unresolveLinksTo(5);
      expect(await db.notesDao.getAllResolvedLinks(), isEmpty);
      expect((await db.notesDao.getOutgoingLinks(1)).single.targetNoteId, isNull);
    });
  });

  group('NotesDao tags', () {
    late TraumDatabase db;
    setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<int> addNote(String title, {DateTime? deletedAt}) =>
        db.notesDao.insertNote(NotesCompanion.insert(
          title: title,
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
          deletedAt: Value(deletedAt),
        ));

    test('ensureTag is idempotent', () async {
      final a = await db.notesDao.ensureTag('focus');
      final b = await db.notesDao.ensureTag('focus');
      expect(a.id, b.id);
      expect((await db.notesDao.getAllTags()).length, 1);
    });

    test('setNoteTags dedups input and replaces previous tags', () async {
      final noteId = await addNote('N');
      await db.notesDao.setNoteTags(noteId, ['a', 'b', 'a']);
      expect(await db.notesDao.getTagCounts(), {'a': 1, 'b': 1});

      // Replacing with a new set drops the old assignments.
      await db.notesDao.setNoteTags(noteId, ['c']);
      expect(await db.notesDao.getTagCounts(), {'c': 1});
    });

    test('getTagCounts and getNotesForTag ignore soft-deleted notes', () async {
      final active = await addNote('Active');
      final trashed = await addNote('Trashed', deletedAt: DateTime(2026, 6, 2));
      await db.notesDao.setNoteTags(active, ['shared']);
      await db.notesDao.setNoteTags(trashed, ['shared']);

      expect(await db.notesDao.getTagCounts(), {'shared': 1});
      final notes = await db.notesDao.getNotesForTag('shared');
      expect(notes.map((n) => n.id), [active]);
    });
  });
}
