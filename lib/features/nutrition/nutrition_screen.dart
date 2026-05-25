import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  DateTime _selectedDate = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  Widget build(BuildContext context) {
    final kcalGoal = ref.watch(kcalGoalNotifierProvider);
    final proteinGoal = ref.watch(proteinGoalNotifierProvider);

    final logsAsync = ref.watch(nutritionLogsForDateProvider(_selectedDate));
    final waterAsync = ref.watch(waterForDateProvider(_selectedDate));

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.nutrition,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: TraumColors.mintGreen),
            tooltip: AppLocalizations.of(context)!.searchFood,
            onPressed: () => context.go('/nutrition/search'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded, color: TraumColors.amberGold),
            tooltip: AppLocalizations.of(context)!.shoppingListTooltip,
            onPressed: () => context.go('/nutrition/shopping'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.mintGreen,
        onPressed: () => context.go('/nutrition/log'),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Date navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: TraumColors.onBackgroundMuted),
                  onPressed: () => setState(() => _selectedDate =
                      _selectedDate.subtract(const Duration(days: 1))),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                                primary: TraumColors.mintGreen)),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Text(
                    _isToday(_selectedDate)
                        ? AppLocalizations.of(context)!.today
                        : '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                    style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: TraumColors.onBackgroundMuted),
                  onPressed: _selectedDate.isBefore(DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day))
                      ? () => setState(() => _selectedDate =
                          _selectedDate.add(const Duration(days: 1)))
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                final totalKcal = logs.fold(0.0, (s, l) => s + l.kcal);
                final totalProtein = logs.fold(0.0, (s, l) => s + l.proteinG);
                final totalCarbs = logs.fold(0.0, (s, l) => s + l.carbsG);
                final totalFat = logs.fold(0.0, (s, l) => s + l.fatG);

                return waterAsync.when(
                  data: (waterLogs) {
                    final totalWater = waterLogs.fold(0, (s, w) => s + w.amountMl);
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      children: [
                        _MacroSummaryCard(
                          kcal: totalKcal,
                          kcalGoal: kcalGoal.toDouble(),
                          protein: totalProtein,
                          proteinGoal: proteinGoal.toDouble(),
                          carbs: totalCarbs,
                          fat: totalFat,
                        ),
                        const SizedBox(height: 12),
                        _WaterCard(
                          totalMl: totalWater,
                          onAdd: () => _addWater(context, ref),
                        ),
                        const SizedBox(height: 12),
                        ...['breakfast', 'lunch', 'dinner', 'snack'].map((mealType) {
                          final mealLogs =
                              logs.where((l) => l.mealType == mealType).toList();
                          return _MealSection(
                            mealType: mealType,
                            logs: mealLogs,
                            onDelete: (id) =>
                                ref.read(nutritionDaoProvider).deleteLog(id),
                          );
                        }),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: TraumColors.mintGreen)),
              error: (e, _) => Center(
                  child: Text('${AppLocalizations.of(context)!.error}: $e',
                      style: const TextStyle(color: TraumColors.roseRed))),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  void _addWater(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        int amount = 250;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: TraumColors.surfaceElevated,
            title: Text(AppLocalizations.of(ctx)!.addWater,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$amount ml',
                  style: const TextStyle(
                      color: TraumColors.cyanBlue,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 28)),
              Slider(
                value: amount.toDouble(),
                min: 100, max: 1000,
                divisions: 18,
                activeColor: TraumColors.cyanBlue,
                label: '$amount ml',
                onChanged: (v) => setState(() => amount = v.round()),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(ctx)!.cancel,
                    style: const TextStyle(color: TraumColors.onBackgroundMuted)),
              ),
              TextButton(
                onPressed: () async {
                  if (amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                          content: Text(AppLocalizations.of(ctx)!.positiveAmountRequired)));
                    return;
                  }
                  Navigator.pop(ctx);
                  await ref.read(nutritionDaoProvider).insertWaterLog(
                        WaterLogsCompanion.insert(
                            logDate: DateTime.now(), amountMl: amount),
                      );
                },
                child: Text(AppLocalizations.of(ctx)!.add,
                    style: const TextStyle(
                        color: TraumColors.cyanBlue, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MacroSummaryCard extends StatelessWidget {
  final double kcal;
  final double kcalGoal;
  final double protein;
  final double proteinGoal;
  final double carbs;
  final double fat;

  const _MacroSummaryCard({
    required this.kcal,
    required this.kcalGoal,
    required this.protein,
    required this.proteinGoal,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final kcalRatio = kcalGoal > 0 ? (kcal / kcalGoal).clamp(0.0, 1.0) : 0.0;
    final proteinRatio =
        proteinGoal > 0 ? (protein / proteinGoal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${kcal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                      color: TraumColors.mintGreen,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 24)),
              Text('${AppLocalizations.of(context)!.goal}: ${kcalGoal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 12)),
            ]),
            Row(children: [
              _MacroBadge(label: 'K', value: carbs, color: TraumColors.amberGold, unit: 'g'),
              const SizedBox(width: 8),
              _MacroBadge(label: 'P', value: protein, color: TraumColors.indigoBlue, unit: 'g'),
              const SizedBox(width: 8),
              _MacroBadge(label: 'F', value: fat, color: TraumColors.coralOrange, unit: 'g'),
            ]),
          ],
        ),
        const SizedBox(height: 12),
        GradientProgressBar(
          value: kcalRatio,
          gradient: const LinearGradient(
              colors: [TraumColors.mintGreen, TraumColors.cyanBlue]),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(AppLocalizations.of(context)!.protein,
              style: const TextStyle(
                  color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
          Text('${protein.toStringAsFixed(0)} / ${proteinGoal.toStringAsFixed(0)} g',
              style: const TextStyle(
                  color: TraumColors.indigoBlue, fontFamily: 'DMSans', fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        GradientProgressBar(
          value: proteinRatio,
          gradient: const LinearGradient(
              colors: [TraumColors.indigoBlue, TraumColors.lavender]),
        ),
      ]),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String unit;

  const _MacroBadge(
      {required this.label, required this.value, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('${value.toStringAsFixed(0)}$unit',
          style: TextStyle(
              color: color, fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 13)),
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 10)),
    ]);
  }
}

class _WaterCard extends StatelessWidget {
  final int totalMl;
  final VoidCallback onAdd;

  const _WaterCard({required this.totalMl, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final ratio = (totalMl / 2000).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Row(children: [
        const Icon(Icons.water_drop_rounded, color: TraumColors.cyanBlue, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$totalMl ml',
                  style: const TextStyle(
                      color: TraumColors.cyanBlue,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600)),
              Text(AppLocalizations.of(context)!.waterGoal2000,
                  style: TextStyle(
                      color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans',
                      fontSize: 11)),
            ]),
            const SizedBox(height: 6),
            GradientProgressBar(
              value: ratio,
              height: 6,
              gradient: const LinearGradient(
                  colors: [TraumColors.cyanBlue, TraumColors.indigoBlue]),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.add_rounded, color: TraumColors.cyanBlue),
          onPressed: onAdd,
        ),
      ]),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String mealType;
  final List<NutritionLog> logs;
  final void Function(int) onDelete;

  const _MealSection({
    required this.mealType,
    required this.logs,
    required this.onDelete,
  });

  static String _mealLabel(String mealType, AppLocalizations l10n) {
    switch (mealType) {
      case 'breakfast': return l10n.breakfast;
      case 'lunch': return l10n.lunch;
      case 'dinner': return l10n.dinner;
      default: return l10n.snack;
    }
  }

  static const _mealIcons = {
    'breakfast': Icons.free_breakfast_rounded,
    'lunch': Icons.lunch_dining_rounded,
    'dinner': Icons.dinner_dining_rounded,
    'snack': Icons.cookie_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final totalKcal = logs.fold(0.0, (s, l) => s + l.kcal);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(children: [
              Icon(_mealIcons[mealType]!, color: TraumColors.mintGreen, size: 18),
              const SizedBox(width: 8),
              Text(_mealLabel(mealType, AppLocalizations.of(context)!),
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const Spacer(),
              Text('${totalKcal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                      color: TraumColors.mintGreen,
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          if (logs.isNotEmpty) ...[
            const Divider(height: 1, color: TraumColors.surfaceVariant),
            ...logs.map((l) => Dismissible(
                  key: ValueKey(l.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: TraumColors.roseRed.withValues(alpha: 0.2),
                    child: const Icon(Icons.delete_rounded,
                        color: TraumColors.roseRed),
                  ),
                  onDismissed: (_) => onDelete(l.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.foodName,
                                  style: const TextStyle(
                                      color: TraumColors.onBackground,
                                      fontFamily: 'DMSans',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13)),
                              Text('${l.amountGrams.toStringAsFixed(0)} g',
                                  style: const TextStyle(
                                      color: TraumColors.onBackgroundMuted,
                                      fontFamily: 'DMSans',
                                      fontSize: 11)),
                            ]),
                      ),
                      Text('${l.kcal.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontSize: 12)),
                    ]),
                  ),
                )),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              child: Text(AppLocalizations.of(context)!.nothingLogged,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans',
                      fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
