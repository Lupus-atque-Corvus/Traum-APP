import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'diary_provider.dart';
import 'diary_visuals.dart';

/// Anlegen oder Bearbeiten eines Tagebuchs (Name, Icon, Farbe). Im
/// Bearbeiten-Modus zusätzlich ein Löschen-Button, gesperrt beim letzten
/// verbleibenden Tagebuch.
class DiaryEditSheet extends ConsumerStatefulWidget {
  final Diary? diary;
  const DiaryEditSheet({super.key, this.diary});

  @override
  ConsumerState<DiaryEditSheet> createState() => _DiaryEditSheetState();
}

class _DiaryEditSheetState extends ConsumerState<DiaryEditSheet> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = 'book';
  String _selectedColor = '9B8EC4';
  bool _saving = false;

  bool get _isEditing => widget.diary != null;

  @override
  void initState() {
    super.initState();
    final d = widget.diary;
    if (d != null) {
      _nameCtrl.text = d.name;
      _selectedIcon = d.iconName;
      _selectedColor = d.colorHex ?? '9B8EC4';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.diaryEnterName)));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(diaryRepositoryProvider);
      final existing = widget.diary;
      if (existing != null) {
        await repo.updateDiary(
          existing.copyWith(
            name: name,
            iconName: _selectedIcon,
            colorHex: Value(_selectedColor),
          ),
        );
      } else {
        final newId = await repo.createDiary(
          DiariesCompanion.insert(
            name: name,
            iconName: _selectedIcon,
            colorHex: Value(_selectedColor),
            sortOrder: Value(await repo.nextDiarySortOrder()),
            createdAt: DateTime.now(),
          ),
        );
        await ref.read(activeDiaryProvider.notifier).set(newId);
      }
      ref.invalidate(diariesProvider);
      ref.invalidate(activeDiaryInfoProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final existing = widget.diary;
    if (existing == null) return;

    final all = await ref.read(diaryRepositoryProvider).getAllDiaries();
    if (!mounted) return;
    if (all.length <= 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.diaryCannotDeleteLast)));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surface,
        title: Text(
          l10n.diaryDeleteDiaryTitle,
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackground,
          ),
        ),
        content: Text(
          l10n.diaryDeleteDiaryMessage,
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: TraumColors.onBackgroundMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: TraumColors.roseRed),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(diaryRepositoryProvider);
      final entries = await repo.getAllEntries(existing.id);
      for (final e in entries) {
        try {
          final f = File(e.mediaPath);
          if (await f.exists()) await f.delete();
        } catch (_) {}
        final thumb = e.thumbnailPath;
        if (thumb != null) {
          try {
            final f = File(thumb);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
      }
      await repo.deleteDiaryWithEntries(existing.id);

      if (ref.read(activeDiaryProvider) == existing.id) {
        final remaining = all.where((d) => d.id != existing.id).toList();
        if (remaining.isNotEmpty) {
          await ref.read(activeDiaryProvider.notifier).set(remaining.first.id);
        }
      }
      ref.invalidate(diariesProvider);
      ref.invalidate(activeDiaryInfoProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final accent = _selectedColor.isNotEmpty
        ? Color(int.parse('0xFF$_selectedColor'))
        : TraumColors.lavender;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TraumColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              _isEditing ? l10n.diaryEditEditTitle : l10n.diaryEditCreateTitle,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                color: TraumColors.onBackground,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel(l10n.diaryNameLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              autofocus: !_isEditing,
              style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
              ),
              decoration: InputDecoration(
                hintText: l10n.diaryNameHint,
                hintStyle: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackgroundSubtle,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: TraumColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel(l10n.diaryIconLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kSelectableDiaryIcons.map((ic) {
                final sel = _selectedIcon == ic;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ic),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: sel
                          ? accent.withValues(alpha: 0.18)
                          : TraumColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? accent : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      diaryIcon(ic),
                      color: sel ? accent : TraumColors.onBackgroundMuted,
                      size: 21,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            _sectionLabel(l10n.diaryColorLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kSelectableDiaryColors.map((hex) {
                final c = Color(int.parse('0xFF$hex'));
                final sel = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: sel
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TraumColors.lavender,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.save,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving ? null : _delete,
                child: Text(
                  l10n.diaryDeleteDiaryButton,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.roseRed,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontFamily: 'DMSans',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: TraumColors.onBackgroundMuted,
      letterSpacing: 0.6,
    ),
  );
}
