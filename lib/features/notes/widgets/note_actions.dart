import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/traum_database.dart';
import '../../../l10n/app_localizations.dart';
import '../notes_providers.dart';
import 'notes_common.dart';

/// Kontextmenü (Long-Press) für eine Notiz.
Future<void> showNoteActions(
    BuildContext context, WidgetRef ref, Note note) async {
  final l10n = AppLocalizations.of(context)!;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabber(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(note.title,
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          _action(
            icon: Icons.drive_file_rename_outline_rounded,
            label: l10n.notes_rename,
            onTap: () async {
              Navigator.pop(ctx);
              final name = await showNotesTextDialog(context,
                  title: l10n.notes_rename,
                  initial: note.title,
                  hint: l10n.notes_note_title,
                  confirmLabel: l10n.notes_save,
                  cancelLabel: l10n.notes_cancel);
              if (name != null && name.isNotEmpty) {
                await ref.read(notesRepositoryProvider).renameNote(note.id, name);
              }
            },
          ),
          _action(
            icon: Icons.folder_open_rounded,
            label: l10n.notes_move_to_folder,
            onTap: () async {
              Navigator.pop(ctx);
              await _showFolderPicker(context, ref, note);
            },
          ),
          _action(
            icon: note.isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: l10n.notes_bookmarks,
            color: note.isBookmarked ? kNotesAccent : null,
            onTap: () {
              Navigator.pop(ctx);
              ref
                  .read(notesRepositoryProvider)
                  .setBookmarked(note.id, !note.isBookmarked);
            },
          ),
          _action(
            icon: note.isPinned
                ? Icons.push_pin_rounded
                : Icons.push_pin_outlined,
            label: note.isPinned ? l10n.notes_unpin : l10n.notes_pin,
            onTap: () {
              Navigator.pop(ctx);
              ref
                  .read(notesRepositoryProvider)
                  .setPinned(note.id, !note.isPinned);
            },
          ),
          _action(
            icon: Icons.ios_share_rounded,
            label: l10n.notes_export_md,
            onTap: () async {
              Navigator.pop(ctx);
              await exportNoteAsMarkdown(note);
            },
          ),
          _action(
            icon: Icons.delete_outline_rounded,
            label: l10n.notes_delete,
            color: TraumColors.error,
            onTap: () {
              Navigator.pop(ctx);
              ref.read(notesRepositoryProvider).softDelete(note.id);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Kontextmenü (Long-Press) für einen Ordner.
Future<void> showFolderActions(
    BuildContext context, WidgetRef ref, NoteFolder folder) async {
  final l10n = AppLocalizations.of(context)!;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabber(),
          _action(
            icon: Icons.drive_file_rename_outline_rounded,
            label: l10n.notes_rename,
            onTap: () async {
              Navigator.pop(ctx);
              final name = await showNotesTextDialog(context,
                  title: l10n.notes_rename,
                  initial: folder.name,
                  hint: l10n.notes_folder_name,
                  confirmLabel: l10n.notes_save,
                  cancelLabel: l10n.notes_cancel);
              if (name != null && name.isNotEmpty) {
                await ref.read(notesRepositoryProvider).renameFolder(folder.id, name);
              }
            },
          ),
          _action(
            icon: Icons.delete_outline_rounded,
            label: l10n.notes_delete,
            color: TraumColors.error,
            onTap: () {
              Navigator.pop(ctx);
              ref.read(notesRepositoryProvider).deleteFolder(folder.id);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _showFolderPicker(
    BuildContext context, WidgetRef ref, Note note) async {
  final l10n = AppLocalizations.of(context)!;
  final folders = await ref.read(notesRepositoryProvider).watchFolders().first;
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabber(),
          _action(
            icon: Icons.home_rounded,
            label: l10n.notes_root,
            onTap: () {
              Navigator.pop(ctx);
              ref.read(notesRepositoryProvider).moveToFolder(note.id, null);
            },
          ),
          ...folders.map((f) => _action(
                icon: Icons.folder_rounded,
                label: f.name,
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(notesRepositoryProvider).moveToFolder(note.id, f.id);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Exportiert eine einzelne Notiz als `.md`-Datei (inkl. Frontmatter, das
/// bereits Bestandteil von [Note.content] ist) und öffnet den Teilen-Dialog.
Future<void> exportNoteAsMarkdown(Note note) async {
  final dir = await getTemporaryDirectory();
  final safe = note.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final file = File(p.join(dir.path, '$safe.md'));
  await file.writeAsString(note.content);
  await Share.shareXFiles([XFile(file.path)], text: note.title);
}

Widget _grabber() => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: TraumColors.onBackgroundSubtle,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

Widget _action({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  Color? color,
}) {
  return ListTile(
    leading: Icon(icon, color: color ?? TraumColors.onBackgroundMuted),
    title: Text(label,
        style: TextStyle(
            fontFamily: 'DMSans',
            color: color ?? TraumColors.onBackground,
            fontSize: 15)),
    onTap: onTap,
  );
}
