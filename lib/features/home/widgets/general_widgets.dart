import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/services/app_launcher_service.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart' show WaterLogsCompanion;
import '../../../l10n/app_localizations.dart';
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
      title: AppLocalizations.of(context)!.homeWidgetClock,
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
      title: AppLocalizations.of(context)!.homeWidgetWeather,
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
      title: AppLocalizations.of(context)!.homeWidgetWeather,
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
      title: AppLocalizations.of(context)!.homeWidgetApps,
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
      title: AppLocalizations.of(context)!.homeWidgetQuickAccess,
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
      title: AppLocalizations.of(context)!.homeWidgetDailyOverview,
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
      title: AppLocalizations.of(context)!.homeWidgetCalendar,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weekdays = l10n.weekdaysShort.split(',');
    final months = [
      l10n.monthShortJan, l10n.monthShortFeb, l10n.monthShortMar,
      l10n.monthShortApr, l10n.monthShortMay, l10n.monthShortJun,
      l10n.monthShortJul, l10n.monthShortAug, l10n.monthShortSep,
      l10n.monthShortOct, l10n.monthShortNov, l10n.monthShortDec,
    ];
    return StreamBuilder<void>(
      stream: _ticker,
      builder: (_, _) {
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final dateStr =
            '${weekdays[now.weekday - 1]}, ${now.day}. ${months[now.month - 1]}';
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
            _conditionForCode(code, AppLocalizations.of(context)!),
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

  String _conditionForCode(int code, AppLocalizations l10n) {
    if (code == 0) return l10n.weatherClear;
    if (code <= 3) return l10n.weatherCloudy;
    if (code <= 48) return l10n.weatherFoggy;
    if (code <= 67) return l10n.weatherRain;
    if (code <= 77) return l10n.weatherSnow;
    if (code <= 82) return l10n.weatherShowers;
    return l10n.weatherThunderstorm;
  }
}

// ─── App favorites ──────────────────────────────────────────────────────────
/// Resolves the real, installed-app display name for up to 3 favorites via
/// [AppLauncherService.getApp] (already cached there) — previously this
/// tile derived a label by splitting the package name on '.' and taking
/// the last segment, which is often meaningless ("com.spotify.music" →
/// "music", "com.facebook.katana" → "katana") instead of the real name.
/// Falls back to that same last-segment heuristic only if an app can no
/// longer be resolved (e.g. uninstalled since being favorited).
final _favoriteAppNamesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final favorites = ref.watch(appLauncherFavoritesProvider).take(3).toList();
  final service = ref.watch(appLauncherServiceProvider);
  return Future.wait(favorites.map((packageName) async {
    final app = await service.getApp(packageName);
    if (app != null) return app.name;
    final parts = packageName.split('.');
    return parts.isEmpty ? packageName : parts.last;
  }));
});

class _AppFavoritesContent extends ConsumerWidget {
  const _AppFavoritesContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(appLauncherFavoritesProvider);
    if (favorites.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.noFavoriteApps,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
        ),
      );
    }
    final namesAsync = ref.watch(_favoriteAppNamesProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${favorites.length} ${favorites.length == 1 ? AppLocalizations.of(context)!.appSingular : AppLocalizations.of(context)!.appPlural}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          namesAsync.maybeWhen(
            data: (names) => names.join(' · '),
            orElse: () => '',
          ),
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
}

// ─── Quick actions ──────────────────────────────────────────────────────────
class _QuickActionsContent extends ConsumerWidget {
  const _QuickActionsContent();

  Future<void> _addWater(BuildContext context, WidgetRef ref, int ml) async {
    try {
      await ref.read(nutritionRepositoryProvider).addWaterLog(
            WaterLogsCompanion(
              logDate: Value(DateTime.now()),
              amountMl: Value(ml),
            ),
          );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.waterLogFailed)));
      }
    }
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
          onTap: () => _addWater(context, ref, 250),
        ),
        _QuickActionButton(
          icon: Icons.note_add_rounded,
          label: AppLocalizations.of(context)!.quickActionNote,
          color: TraumColors.mintGreen,
          onTap: () => context.go(Routes.notes),
        ),
        _QuickActionButton(
          icon: Icons.photo_camera_rounded,
          label: AppLocalizations.of(context)!.quickActionPhoto,
          color: TraumColors.amberGold,
          onTap: () => context.go(Routes.graffitiMap),
        ),
        _QuickActionButton(
          icon: Icons.payments_rounded,
          label: AppLocalizations.of(context)!.quickActionExpense,
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
