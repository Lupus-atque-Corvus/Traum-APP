import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String assetPath;
  final String title;

  const LegalDocumentScreen({
    super.key,
    required this.assetPath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.surface,
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackground,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        leading: BackButton(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: TraumColors.coralOrange),
            );
          }
          if (snap.hasError || !snap.hasData) {
            final l10n = AppLocalizations.of(context)!;
            return Center(
              child: Text(
                l10n.documentCouldNotLoad,
                style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                ),
              ),
            );
          }
          return Markdown(
            data: snap.data!,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 14,
                height: 1.6,
              ),
              h1: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
              h2: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              strong: const TextStyle(
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w600,
              ),
              listBullet: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 14,
              ),
              blockquoteDecoration: BoxDecoration(
                color: TraumColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: TraumColors.coralOrange.withValues(alpha: 0.3),
                ),
              ),
            ),
            padding: const EdgeInsets.all(20),
          );
        },
      ),
    );
  }
}
