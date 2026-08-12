import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/settings/feedback/feedback_type.dart';
import 'package:traum/l10n/app_localizations_de.dart';
import 'package:traum/l10n/app_localizations_en.dart';

void main() {
  final de = AppLocalizationsDe();
  final en = AppLocalizationsEn();

  test('label is localized per type and locale', () {
    expect(FeedbackType.bug.label(de), 'Bug');
    expect(FeedbackType.feature.label(de), 'Feature');
    expect(FeedbackType.improvement.label(de), 'Verbesserung');

    expect(FeedbackType.bug.label(en), isNotEmpty);
    expect(FeedbackType.feature.label(en), isNotEmpty);
    expect(FeedbackType.improvement.label(en), isNotEmpty);
  });

  test('githubLabel is a fixed slug independent of locale', () {
    expect(FeedbackType.bug.githubLabel, 'bug');
    expect(FeedbackType.feature.githubLabel, 'enhancement');
    expect(FeedbackType.improvement.githubLabel, 'improvement');
  });

  test('every type has a distinct icon and color', () {
    final icons = FeedbackType.values.map((t) => t.icon).toSet();
    final colors = FeedbackType.values.map((t) => t.color).toSet();
    expect(icons, hasLength(FeedbackType.values.length));
    expect(colors, hasLength(FeedbackType.values.length));
  });
}
