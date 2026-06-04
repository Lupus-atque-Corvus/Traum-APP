import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';

/// Obsidian-Erweiterungen für das `markdown`-Paket plus die zugehörigen
/// flutter_markdown_plus-Builder.

// ─── Inline-Syntaxen ──────────────────────────────────────────────────────────

/// `[[Ziel]]`, `[[Ziel|Alias]]`, `[[Ziel#Anker]]`, optional mit `!` (Embed).
class WikiLinkSyntax extends md.InlineSyntax {
  WikiLinkSyntax() : super(r'(!?)\[\[([^\]\[]+?)\]\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isEmbed = match.group(1) == '!';
    var inner = match.group(2)!.trim();
    String? alias;
    String? anchor;
    final pipe = inner.indexOf('|');
    if (pipe >= 0) {
      alias = inner.substring(pipe + 1).trim();
      inner = inner.substring(0, pipe).trim();
    }
    final hash = inner.indexOf('#');
    if (hash >= 0) {
      anchor = inner.substring(hash + 1).trim();
      inner = inner.substring(0, hash).trim();
    }
    final el = md.Element.withTag('wikilink')
      ..attributes['target'] = inner
      ..attributes['embed'] = '$isEmbed'
      ..attributes['display'] = alias ?? (anchor != null ? '$inner#$anchor' : inner);
    if (anchor != null) el.attributes['anchor'] = anchor;
    parser.addNode(el);
    return true;
  }
}

/// `==Text==`.
class HighlightSyntax extends md.InlineSyntax {
  HighlightSyntax() : super(r'==([^=\n]+)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match.group(1)!));
    return true;
  }
}

/// Inline-Tag `#tag` / `#eltern/kind`. Nur am Zeilenanfang oder nach Whitespace.
class TagSyntax extends md.InlineSyntax {
  TagSyntax()
      : super(r'(^|\s)#([\p{L}][\p{L}\p{N}_/-]*)',
            caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // Führendes Whitespace erhalten.
    final lead = match.group(1) ?? '';
    if (lead.isNotEmpty) parser.addNode(md.Text(lead));
    parser.addNode(md.Element.text('tag', match.group(2)!));
    return true;
  }
}

/// `%% versteckter Kommentar %%` – wird nicht gerendert.
class CommentSyntax extends md.InlineSyntax {
  CommentSyntax() : super(r'%%[\s\S]*?%%');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    return true; // konsumieren, nichts ausgeben
  }
}

// ─── Block-Syntax: Callouts ───────────────────────────────────────────────────

/// `> [!type] Titel` mit folgenden `>`-Zeilen als Inhalt.
class CalloutSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern =>
      RegExp(r'^ {0,3}>\s?\[!(\w+)\]([+-]?)\s*(.*)$', caseSensitive: false);

  @override
  bool canParse(md.BlockParser parser) =>
      pattern.hasMatch(parser.current.content);

  @override
  md.Node parse(md.BlockParser parser) {
    final first = pattern.firstMatch(parser.current.content)!;
    final type = first.group(1)!.toLowerCase();
    final title = (first.group(3) ?? '').trim();
    parser.advance();

    final bodyLines = <String>[];
    final quote = RegExp(r'^ {0,3}>\s?');
    while (!parser.isDone && quote.hasMatch(parser.current.content)) {
      bodyLines.add(parser.current.content.replaceFirst(quote, ''));
      parser.advance();
    }

    final el = md.Element('callout', [md.Text(bodyLines.join('\n'))]);
    el.attributes['type'] = type;
    el.attributes['title'] = title;
    return el;
  }
}

// ─── Builder ──────────────────────────────────────────────────────────────────

class WikiLinkBuilder extends MarkdownElementBuilder {
  final void Function(String target, String? anchor) onTap;
  final bool Function(String target) isResolved;

  WikiLinkBuilder({required this.onTap, required this.isResolved});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final target = element.attributes['target'] ?? '';
    final anchor = element.attributes['anchor'];
    final display = element.attributes['display'] ?? target;
    final embed = element.attributes['embed'] == 'true';
    final resolved = isResolved(target);

    if (embed) {
      // Verbleibende Embeds (z. B. Bilder) → Platzhalter.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('⧉ $display',
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted,
                fontStyle: FontStyle.italic)),
      );
    }

    final color = resolved ? kNotesLinkColor : TraumColors.error;
    return GestureDetector(
      onTap: () => onTap(target, anchor),
      child: Text(
        display,
        style: TextStyle(
          fontFamily: 'DMSans',
          color: color,
          decoration: TextDecoration.underline,
          decorationColor: color.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class HighlightBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: TraumColors.amberGold.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(element.textContent,
          style: const TextStyle(
              fontFamily: 'DMSans', color: TraumColors.onBackground)),
    );
  }
}

class TagBuilder extends MarkdownElementBuilder {
  final void Function(String tag) onTap;
  TagBuilder({required this.onTap});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final tag = element.textContent;
    return GestureDetector(
      onTap: () => onTap(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        decoration: BoxDecoration(
          color: kNotesLinkColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(TraumRadius.chip),
        ),
        child: Text('#$tag',
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: kNotesLinkColor,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

/// Akzentfarbe für Links/Tags im Notiz-Renderer (aus dem Gradient-System).
const Color kNotesLinkColor = TraumColors.cyanBlue;

/// Farb-Mapping der Callout-Typen auf bestehende Theme-Tokens.
({Color color, IconData icon}) calloutStyle(String type) {
  switch (type) {
    case 'tip':
    case 'success':
    case 'done':
      return (color: TraumColors.mintGreen, icon: Icons.check_circle_outline_rounded);
    case 'warning':
    case 'caution':
    case 'attention':
      return (color: TraumColors.amberGold, icon: Icons.warning_amber_rounded);
    case 'danger':
    case 'error':
    case 'bug':
      return (color: TraumColors.roseRed, icon: Icons.dangerous_outlined);
    case 'question':
    case 'help':
    case 'faq':
      return (color: TraumColors.peachOrange, icon: Icons.help_outline_rounded);
    case 'quote':
    case 'cite':
      return (color: TraumColors.lavender, icon: Icons.format_quote_rounded);
    case 'info':
      return (color: TraumColors.cyanBlue, icon: Icons.info_outline_rounded);
    case 'note':
    default:
      return (color: TraumColors.indigoBlue, icon: Icons.edit_note_rounded);
  }
}
