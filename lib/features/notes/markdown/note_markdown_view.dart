import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/traum_database.dart';
import '../notes_markdown_parser.dart';
import '../notes_providers.dart';
import 'notes_markdown_syntaxes.dart';

/// Reading-Mode-Renderer mit den TRAUM/Obsidian-Erweiterungen.
class NoteMarkdownView extends ConsumerWidget {
  final String content;

  /// Klick auf `[[Wikilink]]` → Zielname + optionaler Anker.
  final void Function(String target, String? anchor) onTapWikilink;

  /// Klick auf `#tag`.
  final void Function(String tag) onTapTag;

  /// Abhaken einer Aufgabe schreibt den geänderten Rohtext zurück.
  final void Function(String newContent)? onContentChanged;

  const NoteMarkdownView({
    super.key,
    required this.content,
    required this.onTapWikilink,
    required this.onTapTag,
    this.onContentChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(allNotesStreamProvider).value ?? const <Note>[];

    // Titel/Alias-Index für die Link-Auflösung und Embed-Expansion.
    final byTitle = <String, Note>{};
    for (final n in notes) {
      byTitle[n.title.toLowerCase()] = n;
    }

    bool isResolved(String target) => byTitle.containsKey(target.toLowerCase());

    final body = _expandEmbeds(
      NotesMarkdownParser.stripFrontmatter(content),
      byTitle,
    );

    final extensionSet = md.ExtensionSet(
      [
        CalloutSyntax(),
        LatexBlockSyntax(),
        ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      ],
      [
        WikiLinkSyntax(),
        CommentSyntax(),
        HighlightSyntax(),
        TagSyntax(),
        LatexInlineSyntax(),
        ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
      ],
    );

    // Aufgaben-Index für das Zurückschreiben beim Abhaken.
    final taskCounter = _Counter();

    return MarkdownBody(
      data: body,
      selectable: true,
      extensionSet: extensionSet,
      onTapLink: (text, href, title) => _openExternal(href),
      checkboxBuilder: onContentChanged == null
          ? null
          : (checked) => _TaskCheckbox(
                checked: checked,
                index: taskCounter.next(),
                onToggle: _toggleTask,
              ),
      builders: {
        'wikilink':
            WikiLinkBuilder(onTap: onTapWikilink, isResolved: isResolved),
        'mark': HighlightBuilder(),
        'tag': TagBuilder(onTap: onTapTag),
        'callout': CalloutBuilder(),
        'latex': LatexElementBuilder(
          textStyle: const TextStyle(color: TraumColors.onBackground),
        ),
      },
      styleSheet: _styleSheet(context),
    );
  }

  void _toggleTask(int index, bool currentlyChecked) {
    if (onContentChanged == null) return;
    final lines = content.split('\n');
    var seen = -1;
    final taskLine = RegExp(r'^(\s*[-*+]\s*\[)( |x|X)(\].*)$');
    for (var i = 0; i < lines.length; i++) {
      final m = taskLine.firstMatch(lines[i]);
      if (m == null) continue;
      seen++;
      if (seen == index) {
        final nowChecked = m.group(2)!.toLowerCase() == 'x';
        final replacement = nowChecked ? ' ' : 'x';
        lines[i] = '${m.group(1)}$replacement${m.group(3)}';
        onContentChanged!(lines.join('\n'));
        return;
      }
    }
  }

  Future<void> _openExternal(String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Ersetzt Text-Embeds `![[Notiz]]` / `![[Notiz#Abschnitt]]` durch den
  /// Inhalt der Zielnotiz (Tiefe 1; verschachtelte Embeds werden im
  /// eingebetteten Inhalt entfernt, um Schleifen zu vermeiden).
  String _expandEmbeds(String input, Map<String, Note> byTitle) {
    return input.replaceAllMapped(
      RegExp(r'!\[\[([^\]\[]+?)\]\]'),
      (m) {
        var inner = m.group(1)!.trim();
        String? section;
        final hash = inner.indexOf('#');
        if (hash >= 0) {
          section = inner.substring(hash + 1).trim();
          inner = inner.substring(0, hash).trim();
        }
        final target = byTitle[inner.toLowerCase()];
        if (target == null) {
          // Bild oder unaufgelöst → unverändert (Builder zeigt Platzhalter).
          return m.group(0)!;
        }
        var embedded =
            NotesMarkdownParser.stripFrontmatter(target.content);
        if (section != null) {
          embedded = _extractSection(embedded, section);
        }
        // Verschachtelte Embeds im eingebetteten Inhalt neutralisieren.
        embedded = embedded.replaceAll(RegExp(r'!\[\[([^\]\[]+?)\]\]'), '');
        return '\n\n> [!quote] $inner\n${embedded.split('\n').map((l) => '> $l').join('\n')}\n\n';
      },
    );
  }

  /// Extrahiert den Abschnitt ab einer Überschrift bis zur nächsten gleich-
  /// oder höherrangigen Überschrift.
  String _extractSection(String content, String heading) {
    final lines = content.split('\n');
    final headingRe = RegExp(r'^(#{1,6})\s+(.*)$');
    var startLevel = 0;
    var start = -1;
    for (var i = 0; i < lines.length; i++) {
      final m = headingRe.firstMatch(lines[i]);
      if (m != null &&
          m.group(2)!.trim().toLowerCase() == heading.toLowerCase()) {
        startLevel = m.group(1)!.length;
        start = i;
        break;
      }
    }
    if (start < 0) return content;
    final out = <String>[lines[start]];
    for (var i = start + 1; i < lines.length; i++) {
      final m = headingRe.firstMatch(lines[i]);
      if (m != null && m.group(1)!.length <= startLevel) break;
      out.add(lines[i]);
    }
    return out.join('\n');
  }

  MarkdownStyleSheet _styleSheet(BuildContext context) {
    const base = TextStyle(
      fontFamily: 'DMSans',
      color: TraumColors.onBackground,
      fontSize: 15.5,
      height: 1.5,
    );
    return MarkdownStyleSheet(
      p: base,
      h1: base.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
      h2: base.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      h3: base.copyWith(fontSize: 19, fontWeight: FontWeight.w600),
      h4: base.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      h5: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      h6: base.copyWith(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: TraumColors.onBackgroundMuted),
      listBullet: base,
      blockquote: base.copyWith(color: TraumColors.onBackgroundMuted),
      a: const TextStyle(
          fontFamily: 'DMSans', color: kNotesLinkColor,
          decoration: TextDecoration.underline),
      code: const TextStyle(
        fontFamily: 'monospace',
        color: TraumColors.cyanBlue,
        backgroundColor: TraumColors.surfaceVariant,
        fontSize: 13.5,
      ),
      codeblockDecoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.input),
        border: Border.all(color: TraumColors.surfaceVariant),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.input),
        border: const Border(
            left: BorderSide(color: kNotesLinkColor, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: TraumColors.surfaceVariant, width: 1)),
      ),
      tableBorder: TableBorder.all(color: TraumColors.surfaceVariant),
      tableHead: base.copyWith(fontWeight: FontWeight.w700),
      tableBody: base.copyWith(fontSize: 14),
    );
  }
}

class _Counter {
  int _v = 0;
  int next() => _v++;
}

class _TaskCheckbox extends StatelessWidget {
  final bool checked;
  final int index;
  final void Function(int index, bool currentlyChecked) onToggle;

  const _TaskCheckbox({
    required this.checked,
    required this.index,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(index, checked),
      child: Padding(
        padding: const EdgeInsets.only(right: 6, top: 2),
        child: Icon(
          checked
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 20,
          color: checked ? TraumColors.mintGreen : TraumColors.onBackgroundMuted,
        ),
      ),
    );
  }
}

/// Rendert einen Callout-Container im Soft-UI-Look mit verschachteltem Markdown.
class CalloutBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final type = element.attributes['type'] ?? 'note';
    final title = element.attributes['title'] ?? '';
    final body = element.textContent;
    final style = calloutStyle(type);
    final heading = title.isNotEmpty
        ? title
        : '${type[0].toUpperCase()}${type.substring(1)}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(TraumRadius.input),
        border: Border(left: BorderSide(color: style.color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 18, color: style.color),
              const SizedBox(width: 6),
              Text(
                heading,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: style.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (body.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            MarkdownBody(
              data: body,
              selectable: false,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontSize: 14.5,
                    height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
