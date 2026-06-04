import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../data/database/traum_database.dart';
import 'notes_vault_service.dart';

export '../../core/providers/repository_providers.dart' show notesRepositoryProvider;

final notesVaultServiceProvider = Provider<NotesVaultService>(
  (ref) => NotesVaultService(ref.watch(notesRepositoryProvider)),
);

// ─── Listen ──────────────────────────────────────────────────────────────────

final foldersStreamProvider = StreamProvider.autoDispose<List<NoteFolder>>(
  (ref) => ref.watch(notesRepositoryProvider).watchFolders(),
);

final allNotesStreamProvider = StreamProvider.autoDispose<List<Note>>(
  (ref) => ref.watch(notesRepositoryProvider).watchActiveNotes(),
);

final recentNotesProvider = StreamProvider.autoDispose<List<Note>>(
  (ref) => ref.watch(notesRepositoryProvider).watchRecentNotes(15),
);

final bookmarkedNotesProvider = StreamProvider.autoDispose<List<Note>>(
  (ref) => ref.watch(notesRepositoryProvider).watchBookmarkedNotes(),
);

final trashedNotesProvider = StreamProvider.autoDispose<List<Note>>(
  (ref) => ref.watch(notesRepositoryProvider).watchTrashedNotes(),
);

final noteStreamProvider =
    StreamProvider.autoDispose.family<Note?, int>((ref, id) {
  return ref.watch(notesRepositoryProvider).watchNote(id);
});

final dailyNotesStreamProvider = StreamProvider.autoDispose<List<Note>>(
  (ref) => ref.watch(notesRepositoryProvider).watchDailyNotes(),
);

final templatesStreamProvider = StreamProvider.autoDispose<List<NoteTemplate>>(
  (ref) => ref.watch(notesRepositoryProvider).watchTemplates(),
);

// ─── Tags ──────────────────────────────────────────────────────────────────

final tagsStreamProvider = StreamProvider.autoDispose<List<Tag>>(
  (ref) => ref.watch(notesRepositoryProvider).watchAllTags(),
);

final tagCountsProvider = FutureProvider.autoDispose<Map<String, int>>(
  (ref) {
    // Bei jeder Notizänderung neu berechnen.
    ref.watch(allNotesStreamProvider);
    return ref.watch(notesRepositoryProvider).getTagCounts();
  },
);

final notesForTagProvider =
    FutureProvider.autoDispose.family<List<Note>, String>((ref, tag) {
  ref.watch(allNotesStreamProvider);
  return ref.watch(notesRepositoryProvider).getNotesForTag(tag);
});

// ─── Suche ──────────────────────────────────────────────────────────────────

final noteSearchProvider =
    FutureProvider.autoDispose.family<List<NoteSearchHit>, String>((ref, q) {
  return ref.watch(notesRepositoryProvider).search(q);
});

final titleSearchProvider =
    FutureProvider.autoDispose.family<List<Note>, String>((ref, q) {
  return ref.watch(notesRepositoryProvider).searchTitles(q);
});

// ─── Backlinks / Outgoing ────────────────────────────────────────────────────

/// Ein aufgelöster Link inkl. der zugehörigen Notiz.
class NoteRef {
  final NoteLink link;
  final Note note;
  const NoteRef(this.link, this.note);
}

/// Ergebnis des Outgoing-Panels: aufgelöste Links + unaufgelöste Rohziele.
class OutgoingLinks {
  final List<NoteRef> resolved;
  final List<NoteLink> unresolved;
  const OutgoingLinks(this.resolved, this.unresolved);
}

final backlinksProvider =
    FutureProvider.autoDispose.family<List<NoteRef>, int>((ref, id) async {
  ref.watch(noteStreamProvider(id));
  ref.watch(allNotesStreamProvider);
  final repo = ref.watch(notesRepositoryProvider);
  final links = await repo.getBacklinks(id);
  final refs = <NoteRef>[];
  for (final link in links) {
    final src = await repo.getNote(link.sourceNoteId);
    if (src != null && src.deletedAt == null) refs.add(NoteRef(link, src));
  }
  return refs;
});

final outgoingLinksProvider =
    FutureProvider.autoDispose.family<OutgoingLinks, int>((ref, id) async {
  ref.watch(noteStreamProvider(id));
  ref.watch(allNotesStreamProvider);
  final repo = ref.watch(notesRepositoryProvider);
  final links = await repo.getOutgoingLinks(id);
  final resolved = <NoteRef>[];
  final unresolved = <NoteLink>[];
  for (final link in links) {
    final targetId = link.targetNoteId;
    if (targetId != null) {
      final target = await repo.getNote(targetId);
      if (target != null && target.deletedAt == null) {
        resolved.add(NoteRef(link, target));
        continue;
      }
    }
    unresolved.add(link);
  }
  return OutgoingLinks(resolved, unresolved);
});

// ─── Graph ──────────────────────────────────────────────────────────────────

class NotesGraphData {
  final List<Note> nodes;

  /// Kanten als (sourceId, targetId) aufgelöster Links.
  final List<(int, int)> edges;

  /// Anzahl eingehender Links je Notiz-ID (für die Knotengröße).
  final Map<int, int> inDegree;

  const NotesGraphData(this.nodes, this.edges, this.inDegree);
}

final graphDataProvider = FutureProvider.autoDispose<NotesGraphData>((ref) async {
  ref.watch(allNotesStreamProvider);
  final repo = ref.watch(notesRepositoryProvider);
  final notes = await repo.watchActiveNotes().first;
  final ids = {for (final n in notes) n.id};
  final links = await repo.getAllResolvedLinks();
  final edges = <(int, int)>[];
  final inDegree = <int, int>{for (final n in notes) n.id: 0};
  for (final l in links) {
    final t = l.targetNoteId;
    if (t != null && ids.contains(l.sourceNoteId) && ids.contains(t)) {
      edges.add((l.sourceNoteId, t));
      inDegree[t] = (inDegree[t] ?? 0) + 1;
    }
  }
  return NotesGraphData(notes, edges, inDegree);
});
