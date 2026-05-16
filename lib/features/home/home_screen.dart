import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/components/components.dart';
import '../../core/navigation/routes.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/date_utils.dart' as traum_dates;
import '../../core/utils/update_service.dart';
import '../../data/database/traum_database.dart' show WaterLogsCompanion;

final waterTodayProvider = StreamProvider.autoDispose<int>((ref) {
  final today = DateTime.now();
  return ref
      .watch(nutritionDaoProvider)
      .watchWaterForDate(today)
      .map((logs) => logs.fold<int>(0, (sum, l) => sum + l.amountMl));
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static bool _permissionCheckDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndPrompt(context);
      if (!_permissionCheckDone) {
        _permissionCheckDone = true;
        _checkPermissions();
      }
    });
  }

  Future<void> _checkPermissions() async {
    final missing = <String>[];

    final notif = await Permission.notification.status;
    if (!notif.isGranted) missing.add('Benachrichtigungen');

    final loc = await Permission.locationWhenInUse.status;
    if (!loc.isGranted) missing.add('Standort (Wetter)');

    if (missing.isEmpty || !mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Fehlende Berechtigungen',
          style: TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Folgende Berechtigungen wurden noch nicht erteilt:\n\n'
          '• ${missing.join('\n• ')}\n\n'
          'Gehe zu Einstellungen › TRAUM, um sie zu aktivieren.',
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Später',
                style: TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Einstellungen öffnen',
                style: TextStyle(color: TraumColors.coralOrange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final stepsGoal = ref.watch(stepsGoalProvider);
    final kcalGoal = ref.watch(kcalGoalProvider);
    final waterGoal = ref.watch(waterGoalMlProvider);
    final waterMin = ref.watch(waterMinMlProvider);
    final waterMax = ref.watch(waterMaxMlProvider);
    final isPeriodEnabled = ref.watch(isPeriodTrackingEnabledProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: TraumColors.background,
            expandedHeight: 0,
            title: Text(
              traum_dates.greeting(userName),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: TraumColors.onBackground),
                onPressed: () {},
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Clock + Weather Card
                _ClockWeatherCard(),
                const SizedBox(height: 12),

                // Aktivitäts-Grid
                _ActivityGrid(
                  stepsGoal: stepsGoal,
                  kcalGoal: kcalGoal,
                ),
                const SizedBox(height: 12),

                // Wasser-Card
                _WaterCard(
                  waterGoal: waterGoal,
                  waterMin: waterMin,
                  waterMax: waterMax,
                ),
                const SizedBox(height: 12),

                // Todos & Medikamente
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TodoCard(
                        onViewAll: () => context.go(Routes.planning),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MedicationCard(
                        onAdd: () => context.go(Routes.medication),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Gewohnheiten
                _HabitsCard(onTap: () => context.go(Routes.planning)),
                const SizedBox(height: 12),

                // Budget
                _BudgetCard(onTap: () => context.go(Routes.budget)),
                const SizedBox(height: 12),

                // Periode (bedingt)
                if (isPeriodEnabled) ...[
                  _PeriodCard(onTap: () => context.go(Routes.period)),
                  const SizedBox(height: 12),
                ],

                // Gesundheits-Snapshot
                _HealthSnapshotCard(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockWeatherCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ClockWeatherCard> createState() => _ClockWeatherCardState();
}

class _ClockWeatherCardState extends ConsumerState<_ClockWeatherCard> {
  late final _ticker = Stream.periodic(const Duration(seconds: 1));
  String? _tempStr;
  String? _condition;
  IconData _weatherIcon = Icons.wb_sunny_rounded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWeather());
  }

  Future<void> _loadWeather() async {
    final prefs = ref.read(sharedPreferencesProvider);
    _parseCachedWeather(prefs);
    final repo = ref.read(weatherRepositoryProvider);
    if (mounted) {
      await repo.refreshOnStart(prefs, context);
      if (mounted) _parseCachedWeather(prefs);
    }
  }

  void _parseCachedWeather(dynamic prefs) {
    final cache = prefs.getString('weather_cache') as String?;
    if (cache == null) return;
    try {
      final data = jsonDecode(cache) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return;
      final temp = current['temperature_2m'] as num?;
      final code = (current['weathercode'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() {
          _tempStr = temp != null ? '${temp.toStringAsFixed(0)}°C' : null;
          _weatherIcon = _iconForCode(code);
          _condition = _conditionForCode(code);
        });
      }
    } catch (_) {}
  }

  IconData _iconForCode(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.wb_cloudy_rounded;
    if (code <= 48) return Icons.cloud_rounded;
    if (code <= 67) return Icons.grain_rounded;
    if (code <= 77) return Icons.ac_unit_rounded;
    if (code <= 82) return Icons.grain_rounded;
    return Icons.thunderstorm_rounded;
  }

  String _conditionForCode(int code) {
    if (code == 0) return 'Klar';
    if (code <= 3) return 'Bewölkt';
    if (code <= 48) return 'Neblig';
    if (code <= 67) return 'Regen';
    if (code <= 77) return 'Schnee';
    if (code <= 82) return 'Schauer';
    return 'Gewitter';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _ticker,
      builder: (_, __) {
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final dateStr = traum_dates.formatDate(now, format: 'EEEE, d. MMMM');

        return TraumCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ],
                ),
              ),
              if (_tempStr != null)
                Column(
                  children: [
                    Icon(_weatherIcon, color: TraumColors.amberGold, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      _tempStr!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                      ),
                    ),
                    Text(
                      _condition!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityGrid extends StatelessWidget {
  final int stepsGoal, kcalGoal;
  const _ActivityGrid({required this.stepsGoal, required this.kcalGoal});

  @override
  Widget build(BuildContext context) {
    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Heute'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircularProgressRing(
                      value: 0,
                      size: 70,
                      color: TraumColors.cyanBlue,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '0',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TraumColors.onBackground,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          const Text(
                            'Ziel',
                            style: TextStyle(
                              fontSize: 9,
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '0 / $stepsGoal',
                      style: const TextStyle(
                        fontSize: 11,
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                      ),
                    ),
                    const Text(
                      'Schritte',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _MacroRow(
                      label: 'Kalorien',
                      value: 0,
                      goal: kcalGoal,
                      unit: 'kcal',
                      gradient: TraumColors.gradientWarm,
                    ),
                    const SizedBox(height: 8),
                    _MacroRow(
                      label: 'Protein',
                      value: 0,
                      goal: 150,
                      unit: 'g',
                      gradient: TraumColors.gradientSupplements,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double value;
  final int goal;
  final String unit;
  final LinearGradient gradient;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} / $goal $unit',
              style: const TextStyle(
                fontSize: 11,
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GradientProgressBar(
          value: goal > 0 ? value / goal : 0,
          gradient: gradient,
          height: 6,
        ),
      ],
    );
  }
}

class _WaterCard extends ConsumerWidget {
  final int waterGoal, waterMin, waterMax;
  const _WaterCard({
    required this.waterGoal,
    required this.waterMin,
    required this.waterMax,
  });

  Future<void> _addWater(BuildContext context, WidgetRef ref, int ml, int currentTotal) async {
    final newTotal = currentTotal + ml;
    if (newTotal > waterMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tageslimit erreicht')),
      );
      return;
    }
    await ref.read(nutritionRepositoryProvider).addWaterLog(
      WaterLogsCompanion(
        logDate: Value(DateTime.now()),
        amountMl: Value(ml),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMl = ref.watch(waterTodayProvider).value ?? 0;
    final ratio = waterGoal > 0 ? totalMl / waterGoal : 0.0;
    final underMin = totalMl < waterMin;
    final atMax = totalMl >= waterMax;

    return TraumCard(
      borderColor: TraumColors.cyanBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Wasser'),
          const SizedBox(height: 10),
          Text(
            'Minimum: $waterMin ml',
            style: const TextStyle(
              fontSize: 11,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 4),
          GradientProgressBar(
            value: ratio.clamp(0.0, 1.0),
            gradient: underMin
                ? const LinearGradient(
                    colors: [TraumColors.warning, TraumColors.coralOrange])
                : TraumColors.gradientNutrition,
            height: 8,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalMl ml',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.cyanBlue,
                  fontFamily: 'DMSans',
                ),
              ),
              Text(
                'Ziel: $waterGoal ml · Max: $waterMax ml',
                style: const TextStyle(
                  fontSize: 11,
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _WaterButton(ml: 200, enabled: !atMax, onTap: () => _addWater(context, ref, 200, totalMl)),
              const SizedBox(width: 8),
              _WaterButton(ml: 300, enabled: !atMax, onTap: () => _addWater(context, ref, 300, totalMl)),
              const SizedBox(width: 8),
              _WaterButton(ml: 500, enabled: !atMax, onTap: () => _addWater(context, ref, 500, totalMl)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  final int ml;
  final bool enabled;
  final VoidCallback onTap;

  const _WaterButton({required this.ml, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: enabled ? TraumColors.cyanDim : TraumColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '+$ml ml',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: enabled ? TraumColors.cyanBlue : TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final VoidCallback onViewAll;
  const _TodoCard({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Todos',
            actionLabel: 'Alle ›',
            onAction: onViewAll,
          ),
          const SizedBox(height: 8),
          const Text(
            'Keine offenen Todos',
            style: TextStyle(
              fontSize: 12,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _MedicationCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Medikamente',
            actionLabel: '+',
            onAction: onAdd,
          ),
          const SizedBox(height: 8),
          const Text(
            'Keine Medikamente',
            style: TextStyle(
              fontSize: 12,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HabitsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TraumCard(
      onTap: onTap,
      borderColor: TraumColors.mintGreen,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Gewohnheiten'),
          SizedBox(height: 8),
          Text(
            'Noch keine Gewohnheiten. Tippe um welche anzulegen.',
            style: TextStyle(
              fontSize: 12,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BudgetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TraumCard(
      onTap: onTap,
      borderColor: TraumColors.amberGold,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Budget'),
          SizedBox(height: 8),
          Text(
            'Keine Transaktionen diesen Monat.',
            style: TextStyle(
              fontSize: 12,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PeriodCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TraumCard(
      onTap: onTap,
      borderColor: TraumColors.periodRose,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Zyklus'),
          SizedBox(height: 8),
          Text(
            'Tippe für Zyklusinfos.',
            style: TextStyle(
              fontSize: 12,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthSnapshotCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TraumCard(
      borderColor: TraumColors.cyanBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Gesundheit'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HealthMetric(
                icon: Icons.bedtime_rounded,
                label: 'Schlaf',
                value: '—',
                unit: 'h',
                color: TraumColors.lavender,
              ),
              _HealthMetric(
                icon: Icons.favorite_rounded,
                label: 'Herzrate',
                value: '—',
                unit: 'bpm',
                color: TraumColors.roseRed,
              ),
              _HealthMetric(
                icon: Icons.mood_rounded,
                label: 'Stimmung',
                value: '—',
                unit: '/5',
                color: TraumColors.amberGold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  final Color color;

  const _HealthMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'DMSans',
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontSize: 11,
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
        ),
        Text(
          label,
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
