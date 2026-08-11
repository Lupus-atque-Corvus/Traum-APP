import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _TraumLintsPlugin();

class _TraumLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        AvoidHardcodedStringsInTextWidget(),
      ];
}

/// Flags `Text('…')` (and `Text("…")`) constructor calls whose literal
/// first argument looks like real, user-facing prose — a capitalized word
/// followed by a space — instead of an `l10n.*` call. Catches the recurring
/// "hardcoded German/English string slips into a new screen" class of bug
/// found repeatedly across the app during the Phase 6 translation sweep,
/// without flagging short technical literals (keys, codes, single words,
/// number-format patterns) that don't need localization.
class AvoidHardcodedStringsInTextWidget extends DartLintRule {
  AvoidHardcodedStringsInTextWidget() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_hardcoded_strings_in_text_widget',
    problemMessage:
        'Hardcoded UI string in Text(...) — route it through AppLocalizations '
        '(l10n.*) instead of a string literal.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName != 'Text') return;

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;
      final first = args.first;
      if (first is! SimpleStringLiteral) return;

      if (!_looksLikeUserFacingProse(first.value)) return;
      reporter.atNode(first, _code);
    });
  }

  static bool _looksLikeUserFacingProse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    // Require at least one space: filters out single-word technical
    // literals (enum-ish values, short labels already covered by other
    // means, format strings like 'dd.MM.yyyy', units like 'kg').
    if (!trimmed.contains(' ')) return false;
    final firstChar = trimmed[0];
    final upper = firstChar.toUpperCase();
    final lower = firstChar.toLowerCase();
    // Only a cased letter can distinguish upper/lower; digits/symbols are
    // equal to themselves under toUpperCase/toLowerCase and are excluded
    // here since they're never how real prose starts anyway.
    if (upper == lower) return false;
    return firstChar == upper;
  }
}
