import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../graffiti_map/graffiti_map_provider.dart'
    show mapMarkersDaoProvider, markerPhotosDaoProvider;
import '../../../data/database/traum_database.dart'
    show AbstinenceTracker, MapMarker, MarkerPhoto, Note, PeriodEntry;
import '../home_tile.dart';
import '../home_widget_frame.dart';
import '../home_widget_registry.dart';

// ─── One-shot snapshot providers ────────────────────────────────────────────
// Plain `.get()` reads (not drift `.watch()` streams) so no query-stream close
// timer lingers in widget tests.

final _abstinenceTrackersProvider =
    FutureProvider.autoDispose<List<AbstinenceTracker>>((ref) {
  return ref.watch(abstinenceDaoProvider).getAllTrackers();
});

final _latestPeriodEntryProvider =
    FutureProvider.autoDispose<PeriodEntry?>((ref) {
  return ref.watch(periodDaoProvider).getLatestPeriodEntry();
});

/// Predicted next-period date for the latest period entry, if computed.
final _nextPeriodPredictedProvider =
    FutureProvider.autoDispose<DateTime?>((ref) async {
  final dao = ref.watch(periodDaoProvider);
  final latest = await dao.getLatestPeriodEntry();
  if (latest == null) return null;
  final calc = await dao.getCalculationForEntry(latest.id);
  return calc?.nextPeriodPredicted;
});

final _recentNotesProvider = FutureProvider.autoDispose<List<Note>>((ref) {
  return ref.watch(notesDaoProvider).getRecentNotes(5);
});

final _notesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return (await ref.watch(notesDaoProvider).getActiveNotes()).length;
});

final _pinnedNotesProvider = FutureProvider.autoDispose<List<Note>>((ref) {
  return ref.watch(notesDaoProvider).getPinnedNotes();
});

final _mapMarkersProvider = FutureProvider.autoDispose<List<MapMarker>>((ref) {
  return ref.watch(mapMarkersDaoProvider).getAll();
});

final _mapPhotosProvider =
    FutureProvider.autoDispose<List<MarkerPhoto>>((ref) {
  return ref.watch(markerPhotosDaoProvider).getAll();
});

// ─── Registry ────────────────────────────────────────────────────────────────

final Map<HomeWidgetType, HomeWidgetDescriptor> miscHomeWidgets = {
  // ─── Abstinenz ──────────────────────────────────────────────────────────
  HomeWidgetType.currentStreak: HomeWidgetDescriptor(
    title: 'Aktueller Streak',
    group: HomeWidgetGroup.abstinence,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.abstinence,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Aktueller Streak',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.abstinence,
      child: const _CurrentStreakContent(),
    ),
  ),
  HomeWidgetType.longestStreak: HomeWidgetDescriptor(
    title: 'Längster Streak',
    group: HomeWidgetGroup.abstinence,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.abstinence,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Längster Streak',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.abstinence,
      child: const _LongestStreakContent(),
    ),
  ),
  HomeWidgetType.moneySaved: HomeWidgetDescriptor(
    title: 'Gespart',
    group: HomeWidgetGroup.abstinence,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.abstinence,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Gespart',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.abstinence,
      // No money/cost field is tracked → permanent empty state.
      child: const _MetricValue(
        value: '—',
        unit: '€',
        color: TraumColors.mintGreen,
      ),
    ),
  ),
  HomeWidgetType.allCounters: HomeWidgetDescriptor(
    title: 'Alle Counter',
    group: HomeWidgetGroup.abstinence,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.abstinence,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Alle Counter',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.abstinence,
      child: const _AllCountersContent(),
    ),
  ),

  // ─── Substanzen ─────────────────────────────────────────────────────────
  HomeWidgetType.lastIntake: HomeWidgetDescriptor(
    title: 'Letzte Einnahme',
    group: HomeWidgetGroup.substances,
    accent: TraumColors.lavender,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.substances,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Letzte Einnahme',
      accent: TraumColors.lavender,
      size: size,
      route: Routes.substances,
      // No intake log is persisted (only a substance reference cache) → empty.
      child: const _EmptyDash(),
    ),
  ),
  HomeWidgetType.takenToday: HomeWidgetDescriptor(
    title: 'Heute',
    group: HomeWidgetGroup.substances,
    accent: TraumColors.lavender,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.substances,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Heute',
      accent: TraumColors.lavender,
      size: size,
      route: Routes.substances,
      // No intake log is persisted → always 0.
      child: const _MetricValue(
        value: '0',
        unit: 'Einnahmen',
        color: TraumColors.lavender,
      ),
    ),
  ),

  // ─── Periode ────────────────────────────────────────────────────────────
  HomeWidgetType.cycleDay: HomeWidgetDescriptor(
    title: 'Zyklustag',
    group: HomeWidgetGroup.period,
    accent: TraumColors.periodRose,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.period,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Zyklustag',
      accent: TraumColors.periodRose,
      size: size,
      route: Routes.period,
      child: const _CycleDayContent(),
    ),
  ),
  HomeWidgetType.nextPeriod: HomeWidgetDescriptor(
    title: 'Nächste Periode',
    group: HomeWidgetGroup.period,
    accent: TraumColors.periodRose,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.period,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Nächste Periode',
      accent: TraumColors.periodRose,
      size: size,
      route: Routes.period,
      child: const _NextPeriodContent(),
    ),
  ),

  // ─── Notizen ────────────────────────────────────────────────────────────
  HomeWidgetType.notesCount: HomeWidgetDescriptor(
    title: 'Notizen',
    group: HomeWidgetGroup.notes,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.notes,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Notizen',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.notes,
      child: const _NotesCountContent(),
    ),
  ),
  HomeWidgetType.lastNote: HomeWidgetDescriptor(
    title: 'Letzte Notiz',
    group: HomeWidgetGroup.notes,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: Routes.notes,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Letzte Notiz',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.notes,
      child: const _LastNoteContent(),
    ),
  ),
  HomeWidgetType.pinnedNote: HomeWidgetDescriptor(
    title: 'Angepinnt',
    group: HomeWidgetGroup.notes,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: Routes.notes,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Angepinnt',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.notes,
      child: const _PinnedNoteContent(),
    ),
  ),

  // ─── Map ────────────────────────────────────────────────────────────────
  HomeWidgetType.placesCount: HomeWidgetDescriptor(
    title: 'Orte',
    group: HomeWidgetGroup.map,
    accent: TraumColors.coralOrange,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.graffitiMap,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Orte',
      accent: TraumColors.coralOrange,
      size: size,
      route: Routes.graffitiMap,
      child: const _PlacesCountContent(),
    ),
  ),
  HomeWidgetType.lastPhoto: HomeWidgetDescriptor(
    title: 'Letztes Foto',
    group: HomeWidgetGroup.map,
    accent: TraumColors.coralOrange,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.graffitiMap,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Letztes Foto',
      accent: TraumColors.coralOrange,
      size: size,
      route: Routes.graffitiMap,
      child: const _LastPhotoContent(),
    ),
  ),
  HomeWidgetType.mapPreview: HomeWidgetDescriptor(
    title: 'Karte',
    group: HomeWidgetGroup.map,
    accent: TraumColors.coralOrange,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.graffitiMap,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Karte',
      accent: TraumColors.coralOrange,
      size: size,
      route: Routes.graffitiMap,
      child: const _MapPreviewContent(),
    ),
  ),
};

// ─── Shared display helpers ──────────────────────────────────────────────────
class _EmptyDash extends StatelessWidget {
  const _EmptyDash();

  @override
  Widget build(BuildContext context) {
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
}

class _MetricValue extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  const _MetricValue({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '—';
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
              color: isEmpty ? TraumColors.onBackgroundMuted : color,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
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

int _daysSince(DateTime d) {
  final now = DateTime.now();
  final start = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(start).inDays;
  return diff < 0 ? 0 : diff;
}

// ─── Abstinenz ────────────────────────────────────────────────────────────────
class _CurrentStreakContent extends ConsumerWidget {
  const _CurrentStreakContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackers = ref.watch(_abstinenceTrackersProvider).value;
    final active = trackers?.where((t) => t.isActive).toList() ?? const [];
    if (active.isEmpty) return const _EmptyDash();
    // Longest currently-running streak = earliest start among active.
    final best = active
        .map((t) => _daysSince(t.startDate))
        .reduce((a, b) => a > b ? a : b);
    return _MetricValue(
      value: '$best',
      unit: best == 1 ? 'Tag' : 'Tage',
      color: TraumColors.mintGreen,
    );
  }
}

class _LongestStreakContent extends ConsumerWidget {
  const _LongestStreakContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackers = ref.watch(_abstinenceTrackersProvider).value;
    if (trackers == null || trackers.isEmpty) return const _EmptyDash();
    final best = trackers
        .map((t) => _daysSince(t.startDate))
        .reduce((a, b) => a > b ? a : b);
    return _MetricValue(
      value: '$best',
      unit: best == 1 ? 'Tag' : 'Tage',
      color: TraumColors.mintGreen,
    );
  }
}

class _AllCountersContent extends ConsumerWidget {
  const _AllCountersContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackers = ref.watch(_abstinenceTrackersProvider).value;
    if (trackers == null || trackers.isEmpty) return const _EmptyDash();
    final sorted = [...trackers]
      ..sort((a, b) => _daysSince(b.startDate).compareTo(_daysSince(a.startDate)));
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final t = sorted[i];
        final days = _daysSince(t.startDate);
        return Row(
          children: [
            if (t.emoji != null && t.emoji!.isNotEmpty) ...[
              Text(t.emoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                t.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$days ${days == 1 ? 'Tag' : 'Tage'}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TraumColors.mintGreen,
                fontFamily: 'DMSans',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Periode ──────────────────────────────────────────────────────────────────
class _CycleDayContent extends ConsumerWidget {
  const _CycleDayContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(_latestPeriodEntryProvider).value;
    if (latest == null) return const _EmptyDash();
    final day = _daysSince(latest.startDate) + 1;
    return _MetricValue(
      value: '$day',
      unit: 'Tag',
      color: TraumColors.periodRose,
    );
  }
}

class _NextPeriodContent extends ConsumerWidget {
  const _NextPeriodContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predicted = ref.watch(_nextPeriodPredictedProvider).value;
    if (predicted == null) return const _EmptyDash();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(predicted.year, predicted.month, predicted.day);
    final days = target.difference(today).inDays;
    if (days < 0) return const _EmptyDash();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'in',
          style: TextStyle(
            fontSize: 12,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
        Text(
          '$days',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: TraumColors.periodRose,
            fontFamily: 'DMSans',
          ),
        ),
        Text(
          days == 1 ? 'Tag' : 'Tagen',
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

// ─── Notizen ────────────────────────────────────────────────────────────────
class _NotesCountContent extends ConsumerWidget {
  const _NotesCountContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_notesCountProvider).value ?? 0;
    return _MetricValue(
      value: '$count',
      unit: count == 1 ? 'Notiz' : 'Notizen',
      color: TraumColors.cyanBlue,
    );
  }
}

class _LastNoteContent extends ConsumerWidget {
  const _LastNoteContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(_recentNotesProvider).value;
    if (notes == null || notes.isEmpty) return const _EmptyDash();
    return _NotePreview(note: notes.first);
  }
}

class _PinnedNoteContent extends ConsumerWidget {
  const _PinnedNoteContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(_pinnedNotesProvider).value;
    if (pinned == null || pinned.isEmpty) return const _EmptyDash();
    return _NotePreview(note: pinned.first, icon: Icons.push_pin_rounded);
  }
}

class _NotePreview extends StatelessWidget {
  final Note note;
  final IconData? icon;
  const _NotePreview({required this.note, this.icon});

  @override
  Widget build(BuildContext context) {
    final title = note.title.trim().isEmpty ? 'Ohne Titel' : note.title.trim();
    final snippet = note.content.trim().replaceAll('\n', ' ');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: TraumColors.cyanBlue),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          ],
        ),
        if (snippet.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            snippet,
            maxLines: 2,
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
}

// ─── Map ────────────────────────────────────────────────────────────────────
class _PlacesCountContent extends ConsumerWidget {
  const _PlacesCountContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(_mapMarkersProvider).value;
    final count = markers?.length ?? 0;
    return _MetricValue(
      value: '$count',
      unit: count == 1 ? 'Ort' : 'Orte',
      color: TraumColors.coralOrange,
    );
  }
}

class _LastPhotoContent extends ConsumerWidget {
  const _LastPhotoContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(_mapPhotosProvider).value;
    if (photos == null || photos.isEmpty) return const _EmptyDash();
    final latest = photos.first;
    final d = latest.takenAt;
    final label =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.photo_camera_rounded,
            size: 30, color: TraumColors.coralOrange),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

class _MapPreviewContent extends ConsumerWidget {
  const _MapPreviewContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(_mapMarkersProvider).value;
    final count = markers?.length ?? 0;
    // Intentionally NOT a live FlutterMap (avoids tile/network in tests):
    // a simple count + hint stands in for the map.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.map_rounded, size: 36, color: TraumColors.coralOrange),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: TraumColors.coralOrange,
            fontFamily: 'DMSans',
          ),
        ),
        Text(
          count == 1 ? 'Ort auf der Karte' : 'Orte auf der Karte',
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
