import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'notes_providers.dart';
import 'widgets/notes_common.dart';

/// Suche + Quick-Switcher. Live-Titelfilter oben, FTS-Volltexttreffer mit
/// Snippet-Hervorhebung darunter, plus „Notiz anlegen“ bei keinem Treffer.
class NotesSearchScreen extends ConsumerStatefulWidget {
  const NotesSearchScreen({super.key});

  @override
  ConsumerState<NotesSearchScreen> createState() => _NotesSearchScreenState();
}

class _NotesSearchScreenState extends ConsumerState<NotesSearchScreen> {
  String _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createNamed(String title) async {
    final id = await ref.read(notesRepositoryProvider).createNote(title: title);
    if (mounted) context.pushReplacement(Routes.noteDetailPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = _query.isEmpty
        ? const AsyncValue<List<Note>>.data([])
        : ref.watch(titleSearchProvider(_query));
    final fts = _query.trim().isEmpty
        ? const AsyncValue<List<NoteSearchHit>>.data([])
        : ref.watch(noteSearchProvider(_query));

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: BackButton(
            color: TraumColors.onBackground, onPressed: () => context.pop()),
        title: Text(l10n.notes_search,
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              cursorColor: kNotesAccent,
              style: const TextStyle(
                  fontFamily: 'DMSans', color: TraumColors.onBackground),
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.search_rounded, color: kNotesAccent),
                hintText: l10n.notes_quick_switcher_hint,
                hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.input),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _query.trim().isEmpty
                ? NotesEmptyState(
                    icon: Icons.search_rounded, message: l10n.notes_search_hint)
                : ListView(
                    children: [
                      // Quick-Switcher (Titel)
                      ...?titles.valueOrNull?.map((n) => NoteListTile(
                            note: n,
                            onTap: () => context
                                .pushReplacement(Routes.noteDetailPath(n.id)),
                          )),
                      _createRow(l10n, titles.valueOrNull ?? const []),
                      // Volltext
                      ...?fts.valueOrNull?.where((h) =>
                          !(titles.valueOrNull ?? const [])
                              .any((t) => t.id == h.note.id)).map(
                            (h) => _snippetTile(h),
                          ),
                      if ((fts.valueOrNull ?? const []).isEmpty &&
                          (titles.valueOrNull ?? const []).isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(l10n.notes_no_results,
                                style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    color: TraumColors.onBackgroundSubtle)),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _createRow(AppLocalizations l10n, List<Note> titles) {
    final q = _query.trim();
    if (q.isEmpty) return const SizedBox.shrink();
    final exact = titles.any((t) => t.title.toLowerCase() == q.toLowerCase());
    if (exact) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _createNamed(q),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kNotesAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: kNotesAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, color: kNotesAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l10n.notes_create_note_named(q),
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: kNotesAccent,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _snippetTile(NoteSearchHit hit) {
    return InkWell(
      onTap: () => context.pushReplacement(Routes.noteDetailPath(hit.note.id)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: TraumColors.surfaceVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hit.note.title,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            _HighlightedSnippet(snippet: hit.snippet),
          ],
        ),
      ),
    );
  }
}

/// Rendert das FTS-Snippet mit Hervorhebung der ⟦…⟧-Marker.
class _HighlightedSnippet extends StatelessWidget {
  final String snippet;
  const _HighlightedSnippet({required this.snippet});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final re = RegExp(r'⟦(.*?)⟧');
    var last = 0;
    for (final m in re.allMatches(snippet)) {
      if (m.start > last) {
        spans.add(TextSpan(text: snippet.substring(last, m.start)));
      }
      spans.add(TextSpan(
          text: m.group(1),
          style: const TextStyle(
              color: kNotesAccent, fontWeight: FontWeight.w700)));
      last = m.end;
    }
    if (last < snippet.length) {
      spans.add(TextSpan(text: snippet.substring(last)));
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundMuted,
            fontSize: 13),
        children: spans,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
