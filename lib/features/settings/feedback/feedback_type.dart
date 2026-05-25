import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

enum FeedbackType {
  bug,
  feature,
  improvement,
}

extension FeedbackTypeExt on FeedbackType {
  String get label => switch (this) {
    FeedbackType.bug         => 'Bug',
    FeedbackType.feature     => 'Feature',
    FeedbackType.improvement => 'Verbesserung',
  };

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
