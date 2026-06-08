import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/components/components.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/colors.dart';
import '../../nutrition/nutrition_providers.dart';
import '../home_tile.dart';
import '../home_widget_frame.dart';
import '../home_widget_registry.dart';

final Map<HomeWidgetType, HomeWidgetDescriptor> nutritionHomeWidgets = {
  HomeWidgetType.caloriesRing: HomeWidgetDescriptor(
    title: 'Kalorien',
    group: HomeWidgetGroup.nutrition,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small, HomeTileSize.large},
    route: Routes.nutrition,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Kalorien',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.nutrition,
      child: _CaloriesRingContent(size: size),
    ),
  ),
  HomeWidgetType.macros: HomeWidgetDescriptor(
    title: 'Makros',
    group: HomeWidgetGroup.nutrition,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: Routes.nutrition,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Makros',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.nutrition,
      child: const _MacrosContent(),
    ),
  ),
  HomeWidgetType.water: HomeWidgetDescriptor(
    title: 'Wasser',
    group: HomeWidgetGroup.nutrition,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.small, HomeTileSize.wide},
    route: Routes.nutrition,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Wasser',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.nutrition,
      child: _WaterContent(size: size),
    ),
  ),
  HomeWidgetType.lastMeal: HomeWidgetDescriptor(
    title: 'Letzte Mahlzeit',
    group: HomeWidgetGroup.nutrition,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.nutrition,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Letzte Mahlzeit',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.nutrition,
      child: const _LastMealContent(),
    ),
  ),
  HomeWidgetType.remainingCalories: HomeWidgetDescriptor(
    title: 'Rest-kcal',
    group: HomeWidgetGroup.nutrition,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.nutrition,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Rest-kcal',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.nutrition,
      child: const _RemainingCaloriesContent(),
    ),
  ),
  HomeWidgetType.supplementsToday: HomeWidgetDescriptor(
    title: 'Supplements',
    group: HomeWidgetGroup.nutrition,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.nutrition,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Supplements',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.nutrition,
      child: const _SupplementsTodayContent(),
    ),
  ),
  HomeWidgetType.mealsToday: HomeWidgetDescriptor(
    title: 'Mahlzeiten',
    group: HomeWidgetGroup.nutrition,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.nutrition,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Mahlzeiten',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.nutrition,
      child: const _MealsTodayContent(),
    ),
  ),
};

// ─── Shared display helpers ──────────────────────────────────────────────────
class _EmptyDash extends StatelessWidget {
  final double fontSize;
  const _EmptyDash({this.fontSize = 28});

  @override
  Widget build(BuildContext context) {
    return Text(
      '—',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: TraumColors.onBackgroundMuted,
        fontFamily: 'DMSans',
      ),
    );
  }
}

class _ValueUnit extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  const _ValueUnit({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 11,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Calories ring ───────────────────────────────────────────────────────────
class _CaloriesRingContent extends ConsumerWidget {
  final HomeTileSize size;
  const _CaloriesRingContent({required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(todaysTotalsProvider).value;
    final goal = ref.watch(kcalGoalProvider);
    final eaten = totals?.calories ?? 0;
    final ringSize = size == HomeTileSize.small ? 72.0 : 96.0;
    final value = goal > 0 ? (eaten / goal).clamp(0.0, 1.0) : 0.0;

    final center = (totals == null || eaten <= 0)
        ? _EmptyDash(fontSize: size == HomeTileSize.small ? 22 : 28)
        : Text(
            eaten.toStringAsFixed(0),
            style: TextStyle(
              fontSize: size == HomeTileSize.small ? 20 : 26,
              fontWeight: FontWeight.w700,
              color: TraumColors.amberGold,
              fontFamily: 'DMSans',
            ),
          );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressRing(
          value: value,
          size: ringSize,
          color: TraumColors.amberGold,
          center: center,
        ),
        const SizedBox(height: 6),
        Text(
          'Ziel $goal kcal',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Macros ──────────────────────────────────────────────────────────────────
class _MacrosContent extends ConsumerWidget {
  const _MacrosContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(todaysTotalsProvider).value ?? MacroSummary.empty;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MacroRow(
          label: 'Protein',
          grams: totals.protein,
          color: TraumColors.mintGreen,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          label: 'Carbs',
          grams: totals.carbs,
          color: TraumColors.cyanBlue,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          label: 'Fett',
          grams: totals.fat,
          color: TraumColors.amberGold,
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;
  const _MacroRow({
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Reference scale of 200 g for the mini bar fill.
    final value = (grams / 200).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        Expanded(
          child: GradientProgressBar(
            value: value,
            height: 6,
            gradient: LinearGradient(colors: [color, color]),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 38,
          child: Text(
            '${grams.toStringAsFixed(0)} g',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Water ───────────────────────────────────────────────────────────────────
class _WaterContent extends ConsumerWidget {
  final HomeTileSize size;
  const _WaterContent({required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One-shot snapshot (not the live waterTodayProvider stream) so no drift
    // query-stream timer lingers after the widget tree is disposed.
    final totalMl = ref.watch(waterTodaySnapshotProvider).value ?? 0;
    final goal = ref.watch(waterGoalMlProvider);

    if (size == HomeTileSize.small) {
      return _ValueUnit(
        value: '$totalMl',
        unit: 'ml',
        color: TraumColors.cyanBlue,
      );
    }

    final value = goal > 0 ? (totalMl / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$totalMl',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.cyanBlue,
                  fontFamily: 'DMSans',
                ),
              ),
              TextSpan(
                text: ' / $goal ml',
                style: const TextStyle(
                  fontSize: 12,
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GradientProgressBar(
          value: value,
          height: 8,
          gradient: const LinearGradient(
            colors: [TraumColors.cyanBlue, TraumColors.cyanBlue],
          ),
        ),
      ],
    );
  }
}

// ─── Last meal ─────────────────────────────────────────────────────────────
class _LastMealContent extends ConsumerWidget {
  const _LastMealContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meal = ref.watch(lastMealProvider).value;
    if (meal == null) {
      return const Center(child: _EmptyDash());
    }
    final t = meal.loggedAt;
    final timeStr =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meal.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          timeStr,
          style: const TextStyle(
            fontSize: 12,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Remaining calories ──────────────────────────────────────────────────────
class _RemainingCaloriesContent extends ConsumerWidget {
  const _RemainingCaloriesContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(todaysTotalsProvider).value;
    final goal = ref.watch(kcalGoalProvider);
    if (totals == null && goal <= 0) {
      return const _EmptyDash();
    }
    final eaten = totals?.calories ?? 0;
    final remaining = (goal - eaten).round();
    final color =
        remaining < 0 ? TraumColors.roseRed : TraumColors.amberGold;
    return _ValueUnit(
      value: '$remaining',
      unit: 'kcal übrig',
      color: color,
    );
  }
}

// ─── Supplements today ───────────────────────────────────────────────────────
class _SupplementsTodayContent extends ConsumerWidget {
  const _SupplementsTodayContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(supplementsTakenTodayProvider).value ?? 0;
    return _ValueUnit(
      value: '$count',
      unit: 'genommen',
      color: TraumColors.cyanBlue,
    );
  }
}

// ─── Meals today ─────────────────────────────────────────────────────────────
class _MealsTodayContent extends ConsumerWidget {
  const _MealsTodayContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(todaysMealEntriesProvider).value;
    final count = entries?.length ?? 0;
    return _ValueUnit(
      value: '$count',
      unit: count == 1 ? 'Mahlzeit' : 'Mahlzeiten',
      color: TraumColors.mintGreen,
    );
  }
}
