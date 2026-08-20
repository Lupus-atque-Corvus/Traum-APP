import 'package:flutter/widgets.dart';

/// Resolves a legal document's asset path for the current app language —
/// the single source both onboarding and Settings use, so they can never
/// diverge on which file they show for a given base name (e.g.
/// `'privacy_policy'` -> `assets/legal/privacy_policy_de.md`). Same
/// two-locale fallback pattern already used by the Substances tab's
/// disclaimer gate (`substances_screen.dart`).
String legalAssetPath(BuildContext context, String baseName) {
  final lang = Localizations.localeOf(context).languageCode;
  return 'assets/legal/${baseName}_${lang == 'de' ? 'de' : 'en'}.md';
}
