import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'notes_providers.dart';
import 'widgets/note_actions.dart';
import 'widgets/notes_common.dart';

/// Modul-Einstieg: File Explorer (Ordnerbaum) + zuletzt bearbeitet + Lesezeichen.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final Set<int> _expanded = {};

  Future<void> _createNote({int? folderId}) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(notesRepositoryProvider);
    final id = await repo.createNote(title: l10n.notes_untitled, folderId: folderId);
    if (mounted) context.push(Routes.noteDetailPath(id));
  }

  Future<void> _createFolder({int? parentId}) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await showNotesTextDialog(
      context,
      title: l10n.notes_new_folder,
      hint: l10n.notes_folder_name,
      confirmLabel: l10n.notes_create,
      cancelLabel: l10n.notes_cancel,
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(notesRepositoryProvider).createFolder(name, parentId: parentId);
    }
  }

  Future<void> _exportVault() async {
    await ref.read(notesVaultServiceProvider).exportVault();
  }

  Future<void> _importVault() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    final count =
        await ref.read(notesVaultServiceProvider).importVaultZip(bytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notes_import_done(count))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final folders = ref.watch(foldersStreamProvider);
    final allNotes = ref.watch(allNotesStreamProvider);
    final recent = ref.watch(recentNotesProvider);
    final bookmarks = ref.watch(bookmarkedNotesProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kNotesAccent,
        onPressed: () => _createNote(),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + 8),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: NotesHeaderTitle(
                title: l10n.notes_title,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.today_rounded, color: kNotesAccent),
                    tooltip: l10n.notes_daily,
                    onPressed: () => context.push(Routes.notesDaily),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: TraumColors.onBackgroundMuted),
                    tooltip: l10n.notes_trash,
                    onPressed: () => context.push(Routes.notesTrash),
                  ),
                  PopupMenuButton<String>(
                    color: TraumColors.surfaceElevated,
                    icon: const Icon(Icons.more_vert_rounded,
                        color: TraumColors.onBackgroundMuted),
                    onSelected: (v) {
                      if (v == 'export') _exportVault();
                      if (v == 'import') _importVault();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'export',
                        child: Row(children: [
                          const Icon(Icons.upload_file_rounded,
                              size: 18, color: TraumColors.onBackgroundMuted),
                          const SizedBox(width: 10),
                          Text(l10n.notes_export_vault,
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  color: TraumColors.onBackground)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'import',
                        child: Row(children: [
                          const Icon(Icons.download_rounded,
                              size: 18, color: TraumColors.onBackgroundMuted),
                          const SizedBox(width: 10),
                          Text(l10n.notes_import_vault,
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  color: TraumColors.onBackground)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Aktionsleiste ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  NotesPillButton(
                    icon: Icons.search_rounded,
                    label: l10n.notes_search,
                    onTap: () => context.push(Routes.notesSearch),
                  ),
                  const SizedBox(width: 8),
                  NotesPillButton(
                    icon: Icons.hub_rounded,
                    label: l10n.notes_graph,
                    onTap: () => context.push(Routes.notesGraph),
                  ),
                  const SizedBox(width: 8),
                  NotesPillButton(
                    icon: Icons.tag_rounded,
                    label: l10n.notes_tags,
                    onTap: () => context.push(Routes.notesTags),
                  ),
                  const SizedBox(width: 8),
                  NotesPillButton(
                    icon: Icons.dashboard_customize_outlined,
                    label: l10n.notes_templates,
                    onTap: () => context.push(Routes.notesTemplates),
                  ),
                ],
              ),
            ),
          ),

          // ── Lesezeichen ─────────────────────────────────────────────────
          ...bookmarks.maybeWhen(
            data: (list) => list.isEmpty
                ? const []
                : [
                    SliverToBoxAdapter(
                      child: NotesSectionLabel(l10n.notes_bookmarks,
                          icon: Icons.bookmark_rounded),
                    ),
                    SliverList.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => _tile(list[i]),
                    ),
                  ],
            orElse: () => const [],
          ),

          // ── Zuletzt bearbeitet ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: NotesSectionLabel(l10n.notes_recent,
                icon: Icons.history_rounded),
          ),
          recent.when(
            data: (list) => list.isEmpty
                ? SliverToBoxAdapter(
                    child: NotesEmptyState(
                        icon: Icons.notes_rounded, message: l10n.notes_no_notes))
                : SliverList.builder(
                    itemCount: list.length > 5 ? 5 : list.length,
                    itemBuilder: (_, i) => _tile(list[i]),
                  ),
            loading: () => const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: CircularProgressIndicator(color: kNotesAccent)))),
            error: (e, _) => SliverToBoxAdapter(
                child: NotesEmptyState(
                    icon: Icons.error_outline, message: '$e')),
          ),

          // ── File Explorer ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined,
                      size: 16, color: kNotesAccent),
                  const SizedBox(width: 6),
                  Text(
                    'Explorer',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.create_new_folder_outlined,
                        size: 20, color: TraumColors.onBackgroundMuted),
                    onPressed: () => _createFolder(),
                  ),
                ],
              ),
            ),
          ),
          _buildExplorer(folders, allNotes, l10n),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildExplorer(
    AsyncValue<List<NoteFolder>> foldersAsync,
    AsyncValue<List<Note>> notesAsync,
    AppLocalizations l10n,
  ) {
    final folders = foldersAsync.valueOrNull ?? [];
    final notes = notesAsync.valueOrNull ?? [];
    final rows = <Widget>[];
    _appendFolderLevel(rows, null, 0, folders, notes, l10n);
    if (rows.isEmpty) {
      return SliverToBoxAdapter(
        child: NotesEmptyState(
            icon: Icons.folder_open_outlined, message: l10n.notes_no_notes),
      );
    }
    return SliverList(delegate: SliverChildListDelegate(rows));
  }

  void _appendFolderLevel(
    List<Widget> rows,
    int? parentId,
    int depth,
    List<NoteFolder> folders,
    List<Note> notes,
    AppLocalizations l10n,
  ) {
    final childFolders =
        folders.where((f) => f.parentId == parentId).toList();
    for (final folder in childFolders) {
      final isOpen = _expanded.contains(folder.id);
      rows.add(_folderRow(folder, depth, isOpen, l10n));
      if (isOpen) {
        _appendFolderLevel(rows, folder.id, depth + 1, folders, notes, l10n);
        final folderNotes =
            notes.where((n) => n.folderId == folder.id).toList();
        for (final note in folderNotes) {
          rows.add(_noteRow(note, depth + 1));
        }
      }
    }
    // Notizen auf Wurzelebene.
    if (parentId == null) {
      final rootNotes = notes.where((n) => n.folderId == null).toList();
      for (final note in rootNotes) {
        rows.add(_noteRow(note, 0));
      }
    }
  }

  Widget _folderRow(
      NoteFolder folder, int depth, bool isOpen, AppLocalizations l10n) {
    return InkWell(
      onTap: () => setState(() {
        if (isOpen) {
          _expanded.remove(folder.id);
        } else {
          _expanded.add(folder.id);
        }
      }),
      onLongPress: () => showFolderActions(context, ref, folder),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.0 + depth * 16, 8, 16, 8),
        child: Row(
          children: [
            Icon(isOpen ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                size: 18, color: TraumColors.onBackgroundMuted),
            const SizedBox(width: 4),
            Icon(isOpen ? Icons.folder_open_rounded : Icons.folder_rounded,
                size: 18, color: kNotesAccent.withValues(alpha: 0.85)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_rounded,
                  size: 18, color: TraumColors.onBackgroundSubtle),
              onPressed: () => _createNote(folderId: folder.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteRow(Note note, int depth) {
    return InkWell(
      onTap: () => context.push(Routes.noteDetailPath(note.id)),
      onLongPress: () => showNoteActions(context, ref, note),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.0 + depth * 16 + 18, 7, 16, 7),
        child: Row(
          children: [
            Icon(note.isDaily ? Icons.today_outlined : Icons.description_outlined,
                size: 16, color: TraumColors.onBackgroundMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note.title.isEmpty ? '—' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontSize: 14),
              ),
            ),
            if (note.isPinned)
              const Icon(Icons.push_pin_rounded,
                  size: 13, color: TraumColors.onBackgroundSubtle),
            if (note.isBookmarked)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.bookmark_rounded, size: 13, color: kNotesAccent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Note note) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TraumRadius.card),
          ),
          child: NoteListTile(
            note: note,
            onTap: () => context.push(Routes.noteDetailPath(note.id)),
            onLongPress: () => showNoteActions(context, ref, note),
          ),
        ),
      );
}
