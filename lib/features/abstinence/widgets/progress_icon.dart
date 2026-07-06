import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';

/// Ordered list of all known SVG icon keys for the Fortschritt (progress) tab
/// — trackers/abstinence, habits, goals, and the generic default. Assets live
/// under `assets/icons/progress/<key>.svg`. Keep in sync with the actual
/// files in that folder (asserted by `test/features/abstinence/progress_icon_test.dart`).
const List<String> kProgressIcons = [
  // Trackers / Abstinence
  'no_alcohol',
  'no_smoking',
  'no_sugar',
  'no_drugs',
  'no_phone',
  'no_coffee',
  'no_gambling',
  // Habits
  'meditation',
  'water',
  'running',
  'book',
  'sleep',
  'journal',
  'stretch',
  'healthy_food',
  'music',
  'sunrise',
  'moon',
  // Goals
  'savings',
  'target',
  'weight',
  'trophy',
  'mountain',
  'heart',
  // Default
  'star',
];

/// Fallback icon key used whenever a stored value is missing or unrecognized.
const String kDefaultProgressIcon = 'star';

/// Maps legacy emoji values (from the old emoji-picker UI) that used to be
/// stored directly in the `emoji` text column, onto the closest matching
/// SVG icon key. Anything not covered here — including the raw emoji itself
/// — falls back to [kDefaultProgressIcon]; the emoji character is never
/// rendered directly.
const Map<String, String> kLegacyEmojiToIconKey = {
  // Abstinence-Tracker (alt)
  '🚭': 'no_smoking',
  '🚬': 'no_smoking',
  '🍺': 'no_alcohol',
  '🍷': 'no_alcohol',
  '🍬': 'no_sugar',
  '🍰': 'no_sugar',
  '💊': 'no_drugs',
  '📱': 'no_phone',
  '☕': 'no_coffee',
  '🎰': 'no_gambling',
  // Habits (alt)
  '🧘': 'meditation',
  '💧': 'water',
  '🏃': 'running',
  '📖': 'book',
  '📚': 'book',
  '💪': 'stretch',
  '🍎': 'healthy_food',
  '😴': 'sleep',
  '✍️': 'journal',
  // Goals (alt) / generisch
  '💰': 'savings',
  '🎯': 'target',
  '⭐': 'star',
};

/// Resolves a stored `emoji` column value to a known SVG icon key.
///
/// - `null`/empty → [kDefaultProgressIcon]
/// - already a known key (from the new picker) → returned unchanged
/// - a legacy emoji with a known mapping → the mapped key
/// - anything else (unknown emoji, garbage) → [kDefaultProgressIcon]
///
/// The raw emoji character is never rendered — this always resolves to
/// something [ProgressIcon] can render as SVG.
String resolveIconKey(String? stored) {
  if (stored == null || stored.isEmpty) return kDefaultProgressIcon;
  if (kProgressIcons.contains(stored)) return stored;
  return kLegacyEmojiToIconKey[stored] ?? kDefaultProgressIcon;
}

/// Renders a single-color line-icon SVG for a tracker/habit/goal icon key
/// (or a legacy emoji value — it is resolved internally, never rendered raw).
class ProgressIcon extends StatelessWidget {
  final String? iconKey;
  final double size;
  final Color? color;

  const ProgressIcon(this.iconKey, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final key = resolveIconKey(iconKey);
    final tint = color ?? TraumColors.onBackground;
    return SvgPicture.asset(
      'assets/icons/progress/$key.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}

/// Opens the icon picker as a bottom sheet and returns the chosen icon key,
/// or `null` if dismissed without a selection.
Future<String?> showIconPickerSheet(
  BuildContext context, {
  String? selected,
  Color accentColor = TraumColors.lavender,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
    ),
    builder: (ctx) => IconPickerSheet(
      selected: selected,
      accentColor: accentColor,
    ),
  );
}

/// Bottom-sheet grid of all [kProgressIcons], tap to select. Pops the sheet
/// with the selected icon key.
class IconPickerSheet extends StatelessWidget {
  final String? selected;
  final Color accentColor;

  const IconPickerSheet({
    super.key,
    this.selected,
    this.accentColor = TraumColors.lavender,
  });

  @override
  Widget build(BuildContext context) {
    final currentKey = resolveIconKey(selected);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TraumColors.onBackgroundSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Icon auswählen',
            style: TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: kProgressIcons.length,
            itemBuilder: (ctx, i) {
              final key = kProgressIcons[i];
              final isSelected = key == currentKey;
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.2)
                        : TraumColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? accentColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: ProgressIcon(
                      key,
                      size: 20,
                      color: isSelected
                          ? accentColor
                          : TraumColors.onBackgroundMuted,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
