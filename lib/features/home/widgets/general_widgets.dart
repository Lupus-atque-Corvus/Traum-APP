import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart' show WaterLogsCompanion;
import '../../health/health_score_provider.dart';
import '../../health/health_score_result.dart';
import '../home_tile.dart';
import '../home_widget_frame.dart';
import '../home_widget_registry.dart';

final Map<HomeWidgetType, HomeWidgetDescriptor> generalHomeWidgets = {
  HomeWidgetType.clockDate: HomeWidgetDescriptor(
    title: 'Uhr',
    group: HomeWidgetGroup.general,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide, HomeTileSize.large},
    route: null,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Uhr',
      accent: TraumColors.amberGold,
      size: size,
      route: null,
      child: const _ClockDateContent(),
    ),
  ),
  HomeWidgetType.weatherNow: HomeWidgetDescriptor(
    title: 'Wetter',
    group: HomeWidgetGroup.general,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small, HomeTileSize.wide},
    route: null,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Wetter',
      accent: TraumColors.amberGold,
      size: size,
      route: null,
      child: const _WeatherContent(showCondition: false),
    ),
  ),
  HomeWidgetType.weatherForecast: HomeWidgetDescriptor(
    title: 'Wetter',
    group: HomeWidgetGroup.general,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide, HomeTileSize.large},
    route: null,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Wetter',
      accent: TraumColors.amberGold,
      size: size,
      route: null,
      child: const _WeatherContent(showCondition: true),
    ),
  ),
  HomeWidgetType.appFavorites: HomeWidgetDescriptor(
    title: 'Apps',
    group: HomeWidgetGroup.general,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: null,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Apps',
      accent: TraumColors.cyanBlue,
      size: size,
      route: null,
      child: const _AppFavoritesContent(),
    ),
  ),
  HomeWidgetType.quickActions: HomeWidgetDescriptor(
    title: 'Schnellzugriff',
    group: HomeWidgetGroup.general,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: null,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Schnellzugriff',
      accent: TraumColors.mintGreen,
      size: size,
      route: null,
      showTitle: true,
      child: const _QuickActionsContent(),
    ),
  ),
  HomeWidgetType.dailyScore: HomeWidgetDescriptor(
    title: 'Tagesübersicht',
    group: HomeWidgetGroup.general,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Tagesübersicht',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.health,
      child: const _DailyScoreContent(),
    ),
  ),
  HomeWidgetType.miniCalendar: HomeWidgetDescriptor(
    title: 'Kalender',
    group: HomeWidgetGroup.general,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.planning,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Kalender',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.planning,
      child: const _MiniCalendarContent(),
    ),
  ),
};

// ─── Clock + Date ──────────────────────────────────────────────────────────
class _ClockDateContent extends StatefulWidget {
  const _ClockDateContent();

  @override
  State<_ClockDateContent> createState() => _ClockDateContentState();
}

class _ClockDateContentState extends State<_ClockDateContent> {
  late final Stream<void> _ticker =
      Stream<void>.periodic(const Duration(seconds: 1));

  static const _weekdays = [
    'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'
  ];
  static const _months = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _ticker,
      builder: (_, __) {
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final dateStr =
            '${_weekdays[now.weekday - 1]}, ${now.day}. ${_months[now.month - 1]}';
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Weather (now / forecast) ───────────────────────────────────────────────
class _WeatherContent extends ConsumerWidget {
  final bool showCondition;
  const _WeatherContent({required this.showCondition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final cache = prefs.getString('weather_cache');
    num? temp;
    int code = 0;
    if (cache != null) {
      try {
        final data = jsonDecode(cache) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;
        if (current != null) {
          temp = current['temperature_2m'] as num?;
          code = (current['weathercode'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}
    }

    if (temp == null) {
      return const Text(
        '—',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
        ),
      );
    }

    final tempStr = '${temp.toStringAsFixed(0)}°C';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_iconForCode(code), color: TraumColors.amberGold, size: 30),
        const SizedBox(height: 6),
        Text(
          tempStr,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
        if (showCondition) ...[
          const SizedBox(height: 2),
          Text(
            _conditionForCode(code),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ],
    );
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
}

// ─── App favorites ──────────────────────────────────────────────────────────
class _AppFavoritesContent extends ConsumerWidget {
  const _AppFavoritesContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(appLauncherFavoritesProvider);
    if (favorites.isEmpty) {
      return const Text(
        'Keine Favoriten',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${favorites.length} ${favorites.length == 1 ? 'App' : 'Apps'}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          favorites.take(3).map(_shortName).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }

  String _shortName(String packageName) {
    final parts = packageName.split('.');
    return parts.isEmpty ? packageName : parts.last;
  }
}

// ─── Quick actions ──────────────────────────────────────────────────────────
class _QuickActionsContent extends ConsumerWidget {
  const _QuickActionsContent();

  Future<void> _addWater(WidgetRef ref, int ml) async {
    try {
      await ref.read(nutritionRepositoryProvider).addWaterLog(
            WaterLogsCompanion(
              logDate: Value(DateTime.now()),
              amountMl: Value(ml),
            ),
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionButton(
          icon: Icons.water_drop_rounded,
          label: '+250 ml',
          color: TraumColors.cyanBlue,
          onTap: () => _addWater(ref, 250),
        ),
        _QuickActionButton(
          icon: Icons.note_add_rounded,
          label: 'Notiz',
          color: TraumColors.mintGreen,
          onTap: () => context.go(Routes.notes),
        ),
        _QuickActionButton(
          icon: Icons.photo_camera_rounded,
          label: 'Foto',
          color: TraumColors.amberGold,
          onTap: () => context.go(Routes.graffitiMap),
        ),
        _QuickActionButton(
          icon: Icons.payments_rounded,
          label: 'Ausgabe',
          color: TraumColors.coralOrange,
          onTap: () => context.go(Routes.budget),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily score ────────────────────────────────────────────────────────────
class _DailyScoreContent extends ConsumerWidget {
  const _DailyScoreContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(healthScoreProvider).value?.gesamtScore;
    if (score == null) {
      return const Text(
        '—',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
        ),
      );
    }
    final color = scoreLabelColor(score);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: TraumColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          scoreLabel(score),
          style: const TextStyle(
            fontSize: 13,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Mini calendar ──────────────────────────────────────────────────────────
class _MiniCalendarContent extends StatelessWidget {
  const _MiniCalendarContent();

  static const _weekdayHeaders = ['M', 'D', 'M', 'D', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Monday = 1 ... Sunday = 7 → leading blanks before day 1.
    final leadingBlanks = firstOfMonth.weekday - 1;

    final cells = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = day == now.day;
      cells.add(Center(
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: isToday
              ? const BoxDecoration(
                  color: TraumColors.cyanBlue,
                  shape: BoxShape.circle,
                )
              : null,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              color:
                  isToday ? TraumColors.surface : TraumColors.onBackground,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      ));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: _weekdayHeaders
              .map((h) => Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: cells,
          ),
        ),
      ],
    );
  }
}
