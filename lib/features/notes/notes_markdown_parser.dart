/// Reine Parsing-Logik für die Obsidian-artige Markdown-Syntax.
///
/// Wird sowohl beim Speichern (Link-/Tag-Index, Wortzahl) als auch beim
/// Rendern verwendet. Keine Drift- oder Flutter-Abhängigkeiten, damit die
/// Logik isoliert testbar bleibt.
library;

/// Ein im Text gefundener Wikilink bzw. Embed.
class ParsedLink {
  /// Der Seitenname (Teil vor `#` und `|`), wie er zur Auflösung verwendet wird.
  final String target;

  /// Optionaler Anker: Überschrift (`#…`) oder Block (`#^…`).
  final String? anchor;

  /// Optionaler Anzeigetext (`|…`).
  final String? alias;

  /// true = Embed/Transklusion (`![[…]]`), false = normaler Link (`[[…]]`).
  final bool isEmbed;

  const ParsedLink({
    required this.target,
    this.anchor,
    this.alias,
    required this.isEmbed,
  });

  String get linkType => isEmbed ? 'embed' : 'link';
}

class NotesMarkdownParser {
  NotesMarkdownParser._();

  /// `[[Ziel]]`, `[[Ziel|Alias]]`, `[[Ziel#Überschrift]]`, `[[Ziel#^block]]`,
  /// optional mit führendem `!` für Embeds.
  static final RegExp wikilinkPattern =
      RegExp(r'(!?)\[\[([^\]\[]+?)\]\]');

  /// Inline-Tags `#tag` und verschachtelt `#eltern/kind`.
  /// Muss am Zeilenanfang oder nach Whitespace stehen (sonst greift es in
  /// URLs/Headings). Tag-Zeichen: Buchstaben, Ziffern, `_`, `-`, `/`.
  static final RegExp tagPattern = RegExp(
    r'(?<=^|\s)#([\p{L}][\p{L}\p{N}_/-]*)',
    unicode: true,
    multiLine: true,
  );

  /// Block-Anker am Absatzende, z. B. `^abc-123`.
  static final RegExp blockIdPattern =
      RegExp(r'(?<=\s|^)\^([\w-]+)\s*$', multiLine: true);

  /// Entfernt Codeblöcke und Inline-Code, damit Links/Tags darin nicht als
  /// Syntax gewertet werden.
  static String stripCode(String text) {
    var out = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    out = out.replaceAll(RegExp(r'`[^`\n]*`'), '');
    return out;
  }

  /// Entfernt `%% … %%`-Kommentare.
  static String stripComments(String text) =>
      text.replaceAll(RegExp(r'%%[\s\S]*?%%'), '');

  /// Extrahiert alle Wikilinks/Embeds aus [content] (ohne Frontmatter & Code).
  static List<ParsedLink> extractLinks(String content) {
    final body = stripComments(stripCode(stripFrontmatter(content)));
    final result = <ParsedLink>[];
    for (final m in wikilinkPattern.allMatches(body)) {
      final isEmbed = m.group(1) == '!';
      var inner = m.group(2)!.trim();
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
      result.add(ParsedLink(
        target: inner,
        anchor: anchor?.isEmpty == true ? null : anchor,
        alias: alias?.isEmpty == true ? null : alias,
        isEmbed: isEmbed,
      ));
    }
    return result;
  }

  /// Extrahiert alle eindeutigen Tag-Namen (ohne `#`).
  static List<String> extractTags(String content) {
    final body = stripComments(stripCode(stripFrontmatter(content)));
    final tags = <String>{};
    for (final m in tagPattern.allMatches(body)) {
      final tag = m.group(1)!;
      // Rein numerische "Tags" (z. B. #123) ignorieren – das sind meist
      // keine echten Tags. Das führende Zeichen ist per Pattern ein Buchstabe.
      tags.add(tag);
    }
    return tags.toList();
  }

  /// Trennt den `---`-Frontmatter-Block vom Rest und gibt den Rumpf zurück.
  static String stripFrontmatter(String content) {
    final fm = _frontmatterMatch(content);
    if (fm == null) return content;
    return content.substring(fm.end);
  }

  /// Liefert den rohen YAML-Frontmatter-Text (ohne die `---`-Zeilen) oder null.
  static String? extractFrontmatterRaw(String content) {
    final fm = _frontmatterMatch(content);
    if (fm == null) return null;
    return fm.group(1);
  }

  static RegExpMatch? _frontmatterMatch(String content) {
    // Frontmatter muss ganz am Anfang stehen.
    final pattern = RegExp(r'^---\r?\n([\s\S]*?)\r?\n---\r?\n?');
    return pattern.firstMatch(content);
  }

  /// Zählt Wörter im sichtbaren Text (ohne Frontmatter, Code, Kommentare,
  /// Wikilink-/Tag-Syntaxzeichen).
  static int wordCount(String content) {
    var body = stripComments(stripCode(stripFrontmatter(content)));
    body = body.replaceAll(wikilinkPattern, ' ');
    body = body.replaceAll(RegExp(r'[#*_>`~\-\[\]()!]'), ' ');
    final words = body
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .length;
    return words;
  }

  /// Outline = alle ATX-Überschriften mit Ebene und Text.
  static List<({int level, String text})> extractOutline(String content) {
    final body = stripFrontmatter(content);
    final result = <({int level, String text})>[];
    final heading = RegExp(r'^(#{1,6})\s+(.*)$', multiLine: true);
    var inFence = false;
    for (final line in body.split('\n')) {
      if (line.trimLeft().startsWith('```')) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;
      final m = heading.firstMatch(line);
      if (m != null) {
        result.add((level: m.group(1)!.length, text: m.group(2)!.trim()));
      }
    }
    return result;
  }
}
