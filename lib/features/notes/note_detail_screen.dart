import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'markdown/note_markdown_view.dart';
import 'markdown/notes_syntax_controller.dart';
import 'notes_markdown_parser.dart';
import 'notes_providers.dart';
import 'notes_template_service.dart';
import 'widgets/note_actions.dart';
import 'widgets/notes_common.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final int noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

enum _Panel { backlinks, outgoing, outline }

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late final NotesSyntaxController _contentCtrl;
  late final TextEditingController _titleCtrl;
  Timer? _debounce;
  bool _editing = true;
  bool _panelOpen = false;
  _Panel _panel = _Panel.backlinks;
  bool _loaded = false;
  String _untitled = 'Unbenannt';

  @override
  void initState() {
    super.initState();
    _contentCtrl = NotesSyntaxController();
    _titleCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_loaded) {
      try {
        _flush();
      } catch (_) {
        // Beim Verwerfen kann der Provider-Container bereits entsorgt sein.
      }
    }
    _contentCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _flush);
  }

  void _flush() {
    final title = _titleCtrl.text.trim();
    ref.read(notesRepositoryProvider).saveNoteContent(
          widget.noteId,
          _contentCtrl.text,
          title: title.isEmpty ? _untitled : title,
        );
  }

  void _applyExternalContent(String newContent) {
    _contentCtrl.text = newContent;
    _flush();
  }

  Future<void> _insertTemplate() async {
    final l10n = AppLocalizations.of(context)!;
    final templates = await ref.read(notesRepositoryProvider).watchTemplates().first;
    if (!mounted) return;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notes_no_templates)),
      );
      return;
    }
    final chosen = await showModalBottomSheet<NoteTemplate>(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: templates
              .map((t) => ListTile(
                    leading: const Icon(Icons.dashboard_customize_outlined,
                        color: kNotesAccent),
                    title: Text(t.name,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackground)),
                    onTap: () => Navigator.pop(ctx, t),
                  ))
              .toList(),
        ),
      ),
    );
    if (chosen == null) return;
    final applied = NotesTemplateService.apply(chosen.content,
        title: _titleCtrl.text.trim());
    final sel = _contentCtrl.selection;
    final text = _contentCtrl.text;
    final at = sel.isValid ? sel.start : text.length;
    final newText = text.replaceRange(at, sel.isValid ? sel.end : at, applied);
    _contentCtrl.text = newText;
    _onChanged();
  }

  Future<void> _openWikilink(String target, String? anchor) async {
    final repo = ref.read(notesRepositoryProvider);
    final existing = await repo.getNoteByTitle(target);
    if (!mounted) return;
    if (existing != null) {
      context.push(Routes.noteDetailPath(existing.id));
    } else {
      final id = await repo.createNote(title: target);
      if (mounted) context.push(Routes.noteDetailPath(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _untitled = l10n.notes_untitled;
    final noteAsync = ref.watch(noteStreamProvider(widget.noteId));

    return noteAsync.when(
      loading: () => const Scaffold(
        backgroundColor: TraumColors.background,
        body: Center(child: CircularProgressIndicator(color: kNotesAccent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: TraumColors.background,
        body: Center(
            child: Text('$e',
                style: const TextStyle(color: TraumColors.onBackground))),
      ),
      data: (note) {
        if (note == null) {
          return Scaffold(
            backgroundColor: TraumColors.background,
            appBar: _bareAppBar(),
            body: NotesEmptyState(
                icon: Icons.delete_outline_rounded, message: l10n.notes_no_notes),
          );
        }
        if (!_loaded) {
          _contentCtrl.text = note.content;
          _titleCtrl.text = note.title;
          _loaded = true;
        }
        return _buildLoaded(context, l10n, note);
      },
    );
  }

  AppBar _bareAppBar() => AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: BackButton(
            color: TraumColors.onBackground,
            onPressed: () => context.pop()),
      );

  Widget _buildLoaded(BuildContext context, AppLocalizations l10n, Note note) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: BackButton(
            color: TraumColors.onBackground, onPressed: () => context.pop()),
        title: _ModeToggle(
          editing: _editing,
          onChanged: (v) {
            if (!v) _flush();
            setState(() => _editing = v);
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
                note.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: note.isBookmarked
                    ? kNotesAccent
                    : TraumColors.onBackgroundMuted),
            onPressed: () => ref
                .read(notesRepositoryProvider)
                .setBookmarked(note.id, !note.isBookmarked),
          ),
          PopupMenuButton<String>(
            color: TraumColors.surfaceElevated,
            icon: const Icon(Icons.more_vert_rounded,
                color: TraumColors.onBackgroundMuted),
            onSelected: (v) async {
              switch (v) {
                case 'pin':
                  ref
                      .read(notesRepositoryProvider)
                      .setPinned(note.id, !note.isPinned);
                  break;
                case 'move':
                  await showNoteActions(context, ref, note);
                  break;
                case 'template':
                  await _insertTemplate();
                  break;
                case 'export':
                  await exportNoteAsMarkdown(note);
                  break;
                case 'delete':
                  ref.read(notesRepositoryProvider).softDelete(note.id);
                  if (mounted) context.pop();
                  break;
              }
            },
            itemBuilder: (_) => [
              _menuItem('pin',
                  note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  note.isPinned ? l10n.notes_unpin : l10n.notes_pin),
              _menuItem('move', Icons.folder_open_rounded, l10n.notes_move_to_folder),
              _menuItem('template', Icons.dashboard_customize_outlined,
                  l10n.notes_insert_template),
              _menuItem('export', Icons.ios_share_rounded, l10n.notes_export_md),
              _menuItem('delete', Icons.delete_outline_rounded, l10n.notes_delete),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Titel
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: TextField(
              controller: _titleCtrl,
              onChanged: (_) => _onChanged(),
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackground,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: l10n.notes_note_title,
                hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle),
              ),
            ),
          ),
          if (!_editing) _PropertiesBar(propertiesJson: note.propertiesJson),
          Expanded(
            child: _editing
                ? _buildEditor(l10n)
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    physics: const BouncingScrollPhysics(),
                    child: NoteMarkdownView(
                      content: _contentCtrl.text,
                      onTapWikilink: _openWikilink,
                      onTapTag: (_) => context.push(Routes.notesTags),
                      onContentChanged: _applyExternalContent,
                    ),
                  ),
          ),
          _buildPanel(l10n, note),
        ],
      ),
    );
  }

  Widget _buildEditor(AppLocalizations l10n) {
    return TextField(
      controller: _contentCtrl,
      onChanged: (_) => _onChanged(),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      cursorColor: kNotesAccent,
      style: const TextStyle(
          fontFamily: 'DMSans', color: TraumColors.onBackground, fontSize: 15.5),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        border: InputBorder.none,
        hintText: l10n.notes_empty_note_hint,
        hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle),
      ),
    );
  }

  Widget _buildPanel(AppLocalizations l10n, Note note) {
    return Container(
      decoration: const BoxDecoration(
        color: TraumColors.bottomNav,
        border: Border(top: BorderSide(color: TraumColors.surfaceVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panel-Kopf
          Row(
            children: [
              _panelTab(l10n.notes_backlinks, _Panel.backlinks),
              _panelTab(l10n.notes_outgoing_links, _Panel.outgoing),
              _panelTab(l10n.notes_outline, _Panel.outline),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('${note.wordCount} ${l10n.notes_word_count}',
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundSubtle,
                        fontSize: 12)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                    _panelOpen
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: TraumColors.onBackgroundMuted),
                onPressed: () => setState(() => _panelOpen = !_panelOpen),
              ),
            ],
          ),
          if (_panelOpen)
            SizedBox(
              height: 180,
              child: _panelContent(l10n, note),
            ),
        ],
      ),
    );
  }

  Widget _panelTab(String label, _Panel panel) {
    final active = _panel == panel;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _panel = panel;
        _panelOpen = true;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? kNotesAccent : TraumColors.onBackgroundMuted,
          ),
        ),
      ),
    );
  }

  Widget _panelContent(AppLocalizations l10n, Note note) {
    switch (_panel) {
      case _Panel.backlinks:
        final backlinks = ref.watch(backlinksProvider(note.id));
        return backlinks.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Center(child: Text('$e')),
          data: (refs) => refs.isEmpty
              ? Center(
                  child: Text(l10n.notes_no_backlinks,
                      style: const TextStyle(
                          color: TraumColors.onBackgroundSubtle,
                          fontFamily: 'DMSans')))
              : ListView(
                  children: refs
                      .map((r) => _linkRow(r.note.title, () =>
                          context.push(Routes.noteDetailPath(r.note.id))))
                      .toList(),
                ),
        );
      case _Panel.outgoing:
        final outgoing = ref.watch(outgoingLinksProvider(note.id));
        return outgoing.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            if (data.resolved.isEmpty && data.unresolved.isEmpty) {
              return Center(
                  child: Text(l10n.notes_no_outgoing_links,
                      style: const TextStyle(
                          color: TraumColors.onBackgroundSubtle,
                          fontFamily: 'DMSans')));
            }
            return ListView(
              children: [
                ...data.resolved.map((r) => _linkRow(r.note.title,
                    () => context.push(Routes.noteDetailPath(r.note.id)))),
                if (data.unresolved.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(l10n.notes_unresolved_links,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackgroundSubtle,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ...data.unresolved.map((l) => _linkRow(
                      l.targetTitleRaw,
                      () => _openWikilink(l.targetTitleRaw, null),
                      unresolved: true,
                    )),
              ],
            );
          },
        );
      case _Panel.outline:
        final outline = NotesMarkdownParser.extractOutline(_contentCtrl.text);
        if (outline.isEmpty) {
          return Center(
              child: Text(l10n.notes_no_outline,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans')));
        }
        return ListView(
          children: outline
              .map((h) => Padding(
                    padding: EdgeInsets.fromLTRB(16.0 + (h.level - 1) * 14, 6, 16, 6),
                    child: Text(h.text,
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackground,
                            fontSize: 14 - (h.level - 1) * 0.5,
                            fontWeight:
                                h.level <= 2 ? FontWeight.w600 : FontWeight.w400)),
                  ))
              .toList(),
        );
    }
  }

  Widget _linkRow(String title, VoidCallback onTap, {bool unresolved = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(unresolved ? Icons.link_off_rounded : Icons.north_east_rounded,
                size: 15,
                color: unresolved ? TraumColors.error : kNotesAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontSize: 13.5)),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: TraumColors.onBackgroundMuted),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'DMSans', color: TraumColors.onBackground)),
        ],
      ),
    );
  }
}

/// Pill-Toggle Edit/Reading (analog Obsidian Strg+E).
class _ModeToggle extends StatelessWidget {
  final bool editing;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.editing, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.chip),
        border: Border.all(color: TraumColors.surfaceVariant),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(l10n.notes_edit_mode, Icons.edit_outlined, editing,
              () => onChanged(true)),
          _seg(l10n.notes_reading_mode, Icons.menu_book_outlined, !editing,
              () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _seg(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kNotesAccent.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(TraumRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: active ? kNotesAccent : TraumColors.onBackgroundMuted),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? kNotesAccent : TraumColors.onBackgroundMuted)),
          ],
        ),
      ),
    );
  }
}

/// Kompakte Eigenschaftsleiste aus dem Frontmatter.
class _PropertiesBar extends StatelessWidget {
  final String propertiesJson;
  const _PropertiesBar({required this.propertiesJson});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> props;
    try {
      props = jsonDecode(propertiesJson) as Map<String, dynamic>;
    } catch (_) {
      props = const {};
    }
    if (props.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.input),
        border: Border.all(color: TraumColors.surfaceVariant),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: props.entries.map((e) {
          final value = e.value is List
              ? (e.value as List).join(', ')
              : '${e.value}';
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${e.key}: ',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontSize: 12)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
