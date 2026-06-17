import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../l10n/app_localizations.dart';
import 'notes_providers.dart';
import 'widgets/note_actions.dart';
import 'widgets/notes_common.dart';

/// Tag-Browser: verschachtelte Tags als aufklappbarer Baum, Tap zeigt die
/// gefilterte Notizliste.
class NotesTagsScreen extends ConsumerStatefulWidget {
  const NotesTagsScreen({super.key});

  @override
  ConsumerState<NotesTagsScreen> createState() => _NotesTagsScreenState();
}

class _TagNode {
  final String segment;
  final String fullPath;
  final Map<String, _TagNode> children = {};
  _TagNode(this.segment, this.fullPath);
}

class _NotesTagsScreenState extends ConsumerState<NotesTagsScreen> {
  final Set<String> _expanded = {};

  Future<void> _showTagNotes(String tag) async {
    final notes = await ref.read(notesRepositoryProvider).getNotesForTag(tag);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 10),
            Text('#$tag',
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: kNotesAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: controller,
                children: notes
                    .map((n) => NoteListTile(
                          note: n,
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push(Routes.noteDetailPath(n.id));
                          },
                          onLongPress: () => showNoteActions(context, ref, n),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TagNode _buildTree(List<String> tagNames) {
    final root = _TagNode('', '');
    for (final name in tagNames) {
      final parts = name.split('/');
      var node = root;
      var path = '';
      for (final part in parts) {
        path = path.isEmpty ? part : '$path/$part';
        node = node.children.putIfAbsent(part, () => _TagNode(part, path));
      }
    }
    return root;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tags = ref.watch(tagsStreamProvider);
    final counts = ref.watch(tagCountsProvider).value ?? const {};

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: BackButton(
            color: TraumColors.onBackground, onPressed: () => context.pop()),
        title: Text(l10n.notes_tags,
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700)),
      ),
      body: tags.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNotesAccent)),
        error: (e, _) =>
            NotesEmptyState(icon: Icons.error_outline, message: '$e'),
        data: (list) {
          if (list.isEmpty) {
            return NotesEmptyState(
                icon: Icons.tag_rounded, message: l10n.notes_no_tags);
          }
          final tree = _buildTree(list.map((t) => t.name).toList());
          final rows = <Widget>[];
          _appendNodes(rows, tree.children.values.toList(), 0, counts);
          return ListView(children: rows);
        },
      ),
    );
  }

  void _appendNodes(
      List<Widget> rows, List<_TagNode> nodes, int depth, Map<String, int> counts) {
    final sorted = [...nodes]..sort((a, b) => a.segment.compareTo(b.segment));
    for (final node in sorted) {
      final hasChildren = node.children.isNotEmpty;
      final isOpen = _expanded.contains(node.fullPath);
      final count = counts[node.fullPath];
      rows.add(InkWell(
        onTap: () {
          if (hasChildren) {
            setState(() {
              if (isOpen) {
                _expanded.remove(node.fullPath);
              } else {
                _expanded.add(node.fullPath);
              }
            });
          } else {
            _showTagNotes(node.fullPath);
          }
        },
        onLongPress: () => _showTagNotes(node.fullPath),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0 + depth * 16, 12, 16, 12),
          child: Row(
            children: [
              Icon(
                hasChildren
                    ? (isOpen
                        ? Icons.expand_more_rounded
                        : Icons.chevron_right_rounded)
                    : Icons.tag_rounded,
                size: 18,
                color: hasChildren
                    ? TraumColors.onBackgroundMuted
                    : kNotesAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(node.segment,
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackground,
                        fontSize: 15)),
              ),
              if (count != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: TraumColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(TraumRadius.chip),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackgroundMuted,
                          fontSize: 12)),
                ),
            ],
          ),
        ),
      ));
      if (hasChildren && isOpen) {
        _appendNodes(rows, node.children.values.toList(), depth + 1, counts);
      }
    }
  }
}
