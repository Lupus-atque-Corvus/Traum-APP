import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'markdown/note_markdown_view.dart';
import 'notes_providers.dart';
import 'widgets/notes_common.dart';

/// Verwaltung der Notiz-Vorlagen (CRUD + Markdown-Vorschau).
class NotesTemplatesScreen extends ConsumerWidget {
  const NotesTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final templates = ref.watch(templatesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: BackButton(
            color: TraumColors.onBackground, onPressed: () => context.pop()),
        title: Text(l10n.notes_templates,
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kNotesAccent,
        onPressed: () => _editTemplate(context, ref, null),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: templates.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNotesAccent)),
        error: (e, _) =>
            NotesEmptyState(icon: Icons.error_outline, message: '$e'),
        data: (list) => list.isEmpty
            ? NotesEmptyState(
                icon: Icons.dashboard_customize_outlined,
                message: l10n.notes_no_templates)
            : ListView(
                children: list
                    .map((t) => Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: TraumColors.surface,
                            borderRadius:
                                BorderRadius.circular(TraumRadius.card),
                            border: Border.all(color: TraumColors.surfaceVariant),
                          ),
                          child: ListTile(
                            leading: const Icon(
                                Icons.dashboard_customize_outlined,
                                color: kNotesAccent),
                            title: Text(t.name,
                                style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    color: TraumColors.onBackground,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              t.content.replaceAll('\n', ' '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  color: TraumColors.onBackgroundMuted,
                                  fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: TraumColors.error),
                              onPressed: () => ref
                                  .read(notesRepositoryProvider)
                                  .deleteTemplate(t.id),
                            ),
                            onTap: () => _editTemplate(context, ref, t),
                          ),
                        ))
                    .toList(),
              ),
      ),
    );
  }

  void _editTemplate(
      BuildContext context, WidgetRef ref, NoteTemplate? template) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _TemplateEditor(template: template),
    );
  }
}

class _TemplateEditor extends ConsumerStatefulWidget {
  final NoteTemplate? template;
  const _TemplateEditor({this.template});

  @override
  ConsumerState<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<_TemplateEditor> {
  late final TextEditingController _name;
  late final TextEditingController _content;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.template?.name ?? '');
    _content = TextEditingController(text: widget.template?.content ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(notesRepositoryProvider);
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (widget.template == null) {
      await repo.createTemplate(name, _content.text);
    } else {
      await repo.updateTemplate(widget.template!.id, name, _content.text);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: l10n.notes_template_name,
                      hintStyle:
                          const TextStyle(color: TraumColors.onBackgroundSubtle),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                      _preview ? Icons.edit_outlined : Icons.menu_book_outlined,
                      color: kNotesAccent),
                  onPressed: () => setState(() => _preview = !_preview),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text(l10n.notes_save,
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: kNotesAccent,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const Divider(color: TraumColors.surfaceVariant),
            Expanded(
              child: _preview
                  ? SingleChildScrollView(
                      child: NoteMarkdownView(
                        content: _content.text,
                        onTapWikilink: (_, __) {},
                        onTapTag: (_) {},
                      ),
                    )
                  : TextField(
                      controller: _content,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: kNotesAccent,
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackground,
                          fontSize: 15),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            '{{title}} · {{date}} · {{date:yyyy-MM-dd}} · {{time}}',
                        hintStyle:
                            TextStyle(color: TraumColors.onBackgroundSubtle),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
