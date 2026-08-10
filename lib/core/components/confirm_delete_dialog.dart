import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../../l10n/app_localizations.dart';

/// Bestätigungsdialog vor einer Löschaktion (z.B. Swipe-to-Delete). Gibt
/// `true` zurück, wenn der Nutzer bestätigt hat, sonst `false`.
Future<bool> confirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: TraumColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackground,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackgroundMuted,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            l10n.cancel,
            style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackgroundMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.delete,
            style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.roseRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
