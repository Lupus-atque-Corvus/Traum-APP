import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/notes_repository.dart';

/// Vault-Import/-Export als `.md`-Dateien (Zusatzfunktion, Abschnitt 11).
class NotesVaultService {
  final NotesRepository repo;
  NotesVaultService(this.repo);

  static final RegExp _illegal = RegExp(r'[\\/:*?"<>|]');

  String _sanitize(String name) {
    final cleaned = name.replaceAll(_illegal, '_').trim();
    return cleaned.isEmpty ? 'note' : cleaned;
  }

  // ─── Export ────────────────────────────────────────────────────────────────

  /// Exportiert alle aktiven Notizen als `.md`-Dateien in eine Ordnerstruktur
  /// (entsprechend `note_folders`), packt sie als ZIP und öffnet den Teilen-
  /// Dialog. Der Markdown-Rohtext enthält das YAML-Frontmatter bereits.
  Future<void> exportVault() async {
    final notes = await repo.watchActiveNotes().first;
    final folders = await repo.watchFolders().first;
    final folderById = {for (final f in folders) f.id: f};

    String folderPath(int? id) {
      final parts = <String>[];
      var current = id;
      final guard = <int>{};
      while (current != null && folderById.containsKey(current)) {
        if (!guard.add(current)) break; // Zyklusschutz
        final f = folderById[current]!;
        parts.insert(0, _sanitize(f.name));
        current = f.parentId;
      }
      return parts.join('/');
    }

    final archive = Archive();
    final usedNames = <String>{};
    for (final note in notes) {
      final dir = folderPath(note.folderId);
      var base = '${dir.isEmpty ? '' : '$dir/'}${_sanitize(note.title)}';
      var name = '$base.md';
      var i = 1;
      while (usedNames.contains(name)) {
        name = '$base ($i).md';
        i++;
      }
      usedNames.add(name);
      final bytes = note.content.codeUnits;
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) return;
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path,
        'traum-notes-${DateTime.now().millisecondsSinceEpoch}.zip'));
    await file.writeAsBytes(zipped);
    await Share.shareXFiles([XFile(file.path)], text: 'TRAUM Notes Vault');
  }

  // ─── Import ────────────────────────────────────────────────────────────────

  /// Importiert ein ZIP mit `.md`-Dateien: legt Ordner gemäß Pfad an, parst
  /// Frontmatter (über das Repository) und indiziert Wikilinks/Tags neu.
  /// Gibt die Anzahl importierter Notizen zurück.
  Future<int> importVaultZip(List<int> zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final folderCache = <String, int?>{'': null};
    var imported = 0;

    Future<int?> ensureFolderPath(String dirPath) async {
      if (folderCache.containsKey(dirPath)) return folderCache[dirPath];
      final segments = dirPath.split('/').where((s) => s.isNotEmpty).toList();
      var parentPath = '';
      int? parentId;
      for (final seg in segments) {
        final nextPath = parentPath.isEmpty ? seg : '$parentPath/$seg';
        if (folderCache.containsKey(nextPath)) {
          parentId = folderCache[nextPath];
        } else {
          parentId = await repo.createFolder(seg, parentId: parentId);
          folderCache[nextPath] = parentId;
        }
        parentPath = nextPath;
      }
      return parentId;
    }

    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (!file.name.toLowerCase().endsWith('.md')) continue;
      final content = String.fromCharCodes(file.content as List<int>);
      final dirPath = p.dirname(file.name);
      final normalizedDir = (dirPath == '.' ? '' : dirPath).replaceAll('\\', '/');
      final folderId = await ensureFolderPath(normalizedDir);
      final title = p.basenameWithoutExtension(file.name);
      await repo.createNote(
        title: title,
        content: content,
        folderId: folderId,
      );
      imported++;
    }
    return imported;
  }
}
