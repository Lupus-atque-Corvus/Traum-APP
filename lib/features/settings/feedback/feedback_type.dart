import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';

enum FeedbackType {
  bug,
  feature,
  improvement,
}

extension FeedbackTypeExt on FeedbackType {
  String label(AppLocalizations l10n) => switch (this) {
    FeedbackType.bug         => l10n.feedbackTypeBug,
    FeedbackType.feature     => l10n.feedbackTypeFeature,
    FeedbackType.improvement => l10n.feedbackTypeImprovement,
  };

  /// GitHub issue-tracker label slug — a fixed identifier in the repo's
  /// label taxonomy, not user-facing text, so it stays unlocalized.
  String get githubLabel => switch (this) {
    FeedbackType.bug         => 'bug',
    FeedbackType.feature     => 'enhancement',
    FeedbackType.improvement => 'improvement',
  };

  IconData get icon => switch (this) {
    FeedbackType.bug         => Icons.bug_report_outlined,
    FeedbackType.feature     => Icons.lightbulb_outline,
    FeedbackType.improvement => Icons.tune_outlined,
  };

  Color get color => switch (this) {
    FeedbackType.bug         => TraumColors.roseRed,
    FeedbackType.feature     => TraumColors.mintGreen,
    FeedbackType.improvement => TraumColors.amberGold,
  };
}
