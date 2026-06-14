import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/components/components.dart';
import '../../core/navigation/routes.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

final _allSessionsProvider =
    StreamProvider.autoDispose<List<WorkoutSession>>((ref) {
  return ref.watch(trainingDaoProvider).watchAllSessions();
});

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_allSessionsProvider);
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        title: const Text(
          'Trainings-Verlauf',
          style: TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: sessionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: TraumColors.coralOrange)),
        error: (e, _) => Center(
          child: Text('$e',
              style: const TextStyle(color: TraumColors.onBackgroundMuted)),
        ),
        data: (sessions) {
          final completed =
              sessions.where((s) => s.completedAt != null).toList();
          if (completed.isEmpty) {
            return const Center(
              child: Text(
                'Noch keine abgeschlossenen Workouts',
                style: TextStyle(
                    color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completed.length,
            itemBuilder: (_, i) => _SessionTile(session: completed[i]),
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final WorkoutSession session;
  const _SessionTile({required this.session});

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _duration(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final m = seconds ~/ 60;
    final h = m ~/ 60;
    return h > 0 ? '${h}h ${m % 60}min' : '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final dur = _duration(session.durationSeconds);
    final note = session.notes?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TraumCard(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: const Icon(Icons.fitness_center_rounded,
              color: TraumColors.coralOrange),
          title: Text(
            note.isEmpty ? _date(session.startedAt) : note,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [_date(session.startedAt), if (dur.isNotEmpty) dur].join(' · '),
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: TraumColors.onBackgroundSubtle),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TraumRadius.card)),
          onTap: () =>
              context.push(Routes.workoutDetailPath(session.id)),
        ),
      ),
    );
  }
}
