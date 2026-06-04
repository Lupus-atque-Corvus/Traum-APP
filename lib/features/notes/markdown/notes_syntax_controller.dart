import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import 'notes_markdown_syntaxes.dart';

/// `TextEditingController`, der im Edit-Mode Markdown-Syntax hervorhebt.
///
/// Hebt hervor: Überschriften, Fett/Kursiv, Wikilinks, Tags, Inline-Code &
/// Codeblöcke, Callout-Marker, Aufgaben-Checkboxen, Highlights.
class NotesSyntaxController extends TextEditingController {
  NotesSyntaxController({super.text});

  static final List<_Rule> _rules = [
    // Codeblöcke (fenced) – zuerst, damit Inneres nicht weiter gefärbt wird.
    _Rule(
      RegExp(r'```[\s\S]*?```', multiLine: true),
      const TextStyle(
          fontFamily: 'monospace', color: TraumColors.cyanBlue, fontSize: 13.5),
    ),
    // Callout-Marker am Zeilenanfang.
    _Rule(
      RegExp(r'^\s*>\s*\[![\w]+\][+-]?.*$', multiLine: true),
      const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.indigoBlue,
          fontWeight: FontWeight.w600),
    ),
    // Überschriften.
    _Rule(
      RegExp(r'^#{1,6}\s.*$', multiLine: true),
      const TextStyle(
          fontFamily: 'DMSans',
          color: kNotesLinkColor,
          fontWeight: FontWeight.w700),
    ),
    // Aufgaben-Checkboxen.
    _Rule(
      RegExp(r'^\s*[-*+]\s*\[[ xX]\]', multiLine: true),
      const TextStyle(
          fontFamily: 'monospace', color: TraumColors.mintGreen),
    ),
    // Embeds & Wikilinks.
    _Rule(
      RegExp(r'!?\[\[[^\]\[]+?\]\]'),
      const TextStyle(
          fontFamily: 'DMSans',
          color: kNotesLinkColor,
          fontWeight: FontWeight.w500),
    ),
    // Inline-Code.
    _Rule(
      RegExp(r'`[^`\n]+`'),
      const TextStyle(fontFamily: 'monospace', color: TraumColors.cyanBlue),
    ),
    // Highlights.
    _Rule(
      RegExp(r'==[^=\n]+=='),
      const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.amberGold,
          fontWeight: FontWeight.w500),
    ),
    // Fett.
    _Rule(
      RegExp(r'\*\*[^*\n]+\*\*|__[^_\n]+__'),
      const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w700),
    ),
    // Kursiv.
    _Rule(
      RegExp(r'(?<!\*)\*[^*\n]+\*(?!\*)|(?<!_)_[^_\n]+_(?!_)'),
      const TextStyle(
          fontFamily: 'DMSans', fontStyle: FontStyle.italic),
    ),
    // Tags.
    _Rule(
      RegExp(r'(?<=^|\s)#[\p{L}][\p{L}\p{N}_/-]*', unicode: true),
      const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.lavender,
          fontWeight: FontWeight.w500),
    ),
  ];

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = (style ?? const TextStyle()).copyWith(
      fontFamily: 'DMSans',
      color: TraumColors.onBackground,
      height: 1.45,
    );
    final src = text;
    if (src.isEmpty) return TextSpan(text: '', style: base);

    // Höchstpriorisierte, nicht überlappende Intervalle sammeln.
    final taken = List<bool>.filled(src.length, false);
    final spans = <_Span>[];
    for (final rule in _rules) {
      for (final m in rule.pattern.allMatches(src)) {
        var free = true;
        for (var i = m.start; i < m.end; i++) {
          if (taken[i]) {
            free = false;
            break;
          }
        }
        if (!free) continue;
        for (var i = m.start; i < m.end; i++) {
          taken[i] = true;
        }
        spans.add(_Span(m.start, m.end, rule.style));
      }
    }
    spans.sort((a, b) => a.start.compareTo(b.start));

    final children = <TextSpan>[];
    var cursor = 0;
    for (final s in spans) {
      if (s.start > cursor) {
        children.add(TextSpan(text: src.substring(cursor, s.start), style: base));
      }
      children.add(TextSpan(
          text: src.substring(s.start, s.end),
          style: base.merge(s.style)));
      cursor = s.end;
    }
    if (cursor < src.length) {
      children.add(TextSpan(text: src.substring(cursor), style: base));
    }
    return TextSpan(style: base, children: children);
  }
}

class _Rule {
  final RegExp pattern;
  final TextStyle style;
  _Rule(this.pattern, this.style);
}

class _Span {
  final int start;
  final int end;
  final TextStyle style;
  _Span(this.start, this.end, this.style);
}
