import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/traum_database.dart';

/// Akzentfarbe des Notizen-Moduls (aus dem bestehenden Gradient-System).
const Color kNotesAccent = TraumColors.lavender;

/// Großer Seitentitel im Soft-UI-Stil.
class NotesHeaderTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const NotesHeaderTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontSize: 24,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// Abschnittsüberschrift innerhalb einer Liste.
class NotesSectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  const NotesSectionLabel(this.label, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: kNotesAccent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackgroundMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft-UI-Karte als Listeneintrag für eine Notiz.
class NoteListTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? snippet;

  const NoteListTile({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
    this.snippet,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: TraumColors.surfaceVariant),
        ),
        child: Row(
          children: [
            Icon(
              note.isDaily
                  ? Icons.today_rounded
                  : Icons.description_outlined,
              color: kNotesAccent.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isEmpty ? '—' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (snippet != null && snippet!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        snippet!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackgroundMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (note.isPinned)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.push_pin_rounded,
                    size: 15, color: TraumColors.onBackgroundMuted),
              ),
            if (note.isBookmarked)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.bookmark_rounded,
                    size: 15, color: kNotesAccent),
              ),
          ],
        ),
      ),
    );
  }
}

/// Einfacher Soft-UI-Button mit Icon + Label.
class NotesPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const NotesPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled
              ? kNotesAccent.withValues(alpha: 0.18)
              : TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.chip),
          border: Border.all(
            color: filled
                ? kNotesAccent.withValues(alpha: 0.4)
                : TraumColors.surfaceVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: filled ? kNotesAccent : TraumColors.onBackgroundMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DMSans',
                color: filled ? kNotesAccent : TraumColors.onBackgroundMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zentrierter Leerstatus.
class NotesEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const NotesEmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: TraumColors.onBackgroundSubtle),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundSubtle,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Einfacher Text-Eingabedialog (für Titel/Ordnernamen).
Future<String?> showNotesTextDialog(
  BuildContext context, {
  required String title,
  String? initial,
  required String confirmLabel,
  required String cancelLabel,
  String? hint,
}) {
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: TraumColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TraumRadius.dialog),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackground,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(
            fontFamily: 'DMSans', color: TraumColors.onBackground),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle),
          filled: true,
          fillColor: TraumColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TraumRadius.input),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(cancelLabel,
              style: const TextStyle(
                  fontFamily: 'DMSans', color: TraumColors.onBackgroundMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(confirmLabel,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: kNotesAccent,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
