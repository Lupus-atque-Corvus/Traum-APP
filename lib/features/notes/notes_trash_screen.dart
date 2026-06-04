import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'notes_providers.dart';
import 'widgets/notes_common.dart';

/// Papierkorb: soft-gelöschte Notizen wiederherstellen oder endgültig löschen.
class NotesTrashScreen extends ConsumerWidget {
  const NotesTrashScreen({super.key});

  Future<bool> _confirm(BuildContext context, String message) async {
    final l10n = AppLocalizations.of(context)!;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TraumRadius.dialog)),
        content: Text(message,
            style: const TextStyle(
                fontFamily: 'DMSans', color: TraumColors.onBackground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.notes_cancel,
                style: const TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.notes_delete_permanently,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final trashed = ref.watch(trashedNotesProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: BackButton(
            color: TraumColors.onBackground, onPressed: () => context.pop()),
        title: Text(l10n.notes_trash,
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700)),
      ),
      body: trashed.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNotesAccent)),
        error: (e, _) =>
            NotesEmptyState(icon: Icons.error_outline, message: '$e'),
        data: (list) => list.isEmpty
            ? NotesEmptyState(
                icon: Icons.delete_outline_rounded, message: l10n.notes_no_trash)
            : ListView(
                children: list
                    .map((n) => _trashRow(context, ref, l10n, n))
                    .toList(),
              ),
      ),
    );
  }

  Widget _trashRow(
      BuildContext context, WidgetRef ref, AppLocalizations l10n, Note note) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(color: TraumColors.surfaceVariant),
      ),
      child: ListTile(
        leading: const Icon(Icons.description_outlined,
            color: TraumColors.onBackgroundMuted),
        title: Text(note.title,
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.notes_restore,
              icon: const Icon(Icons.restore_rounded, color: TraumColors.mintGreen),
              onPressed: () => ref.read(notesRepositoryProvider).restore(note.id),
            ),
            IconButton(
              tooltip: l10n.notes_delete_permanently,
              icon: const Icon(Icons.delete_forever_rounded,
                  color: TraumColors.error),
              onPressed: () async {
                if (await _confirm(
                    context, l10n.notes_confirm_delete_permanently)) {
                  await ref
                      .read(notesRepositoryProvider)
                      .deletePermanently(note.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
