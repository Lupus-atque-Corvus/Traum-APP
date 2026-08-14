import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/components/components.dart';
import '../../core/navigation/routes.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

class _CenterData {
  final List<Medication> dueMeds;
  final int medsTaken;
  final List<Todo> openTodos;
  final Appointment? nextAppointment;
  const _CenterData({
    required this.dueMeds,
    required this.medsTaken,
    required this.openTodos,
    required this.nextAppointment,
  });

  bool get isEmpty =>
      dueMeds.isEmpty && openTodos.isEmpty && nextAppointment == null;
}

final _centerProvider = FutureProvider.autoDispose<_CenterData>((ref) async {
  final medDao = ref.watch(medicationDaoProvider);
  final planDao = ref.watch(planningDaoProvider);
  final meds = await medDao.getActiveMedications();
  final dueMeds = meds
      .where((m) => m.timings.trim().isNotEmpty && m.timings.trim() != '[]')
      .toList();
  final medsTaken = await medDao.getTakenCountToday();
  final todos = await planDao.getAllTodos();
  final openTodos = todos.where((t) => !t.done).toList();
  final nextAppointment = await planDao.getNextAppointment();
  return _CenterData(
    dueMeds: dueMeds,
    medsTaken: medsTaken,
    openTodos: openTodos,
    nextAppointment: nextAppointment,
  );
});

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dataAsync = ref.watch(_centerProvider);
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        title: Text(
          l10n.notificationsSection,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: dataAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TraumColors.coralOrange),
        ),
        error: (e, _) => Center(
          child: Text(
            '$e',
            style: const TextStyle(color: TraumColors.onBackgroundMuted),
          ),
        ),
        data: (data) {
          if (data.isEmpty) {
            return Center(
              child: Text(
                l10n.notificationCenterEmpty,
                style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.dueMeds.isNotEmpty)
                _Section(
                  title: l10n.notificationCenterMedsToday,
                  subtitle: l10n.notificationCenterMedsStatus(
                    data.medsTaken,
                    data.dueMeds.length,
                  ),
                  icon: Icons.medication_rounded,
                  color: TraumColors.roseRed,
                  onTap: () => context.push(Routes.substances),
                ),
              if (data.nextAppointment != null)
                _Section(
                  title: l10n.notificationCenterNextAppointment,
                  subtitle: data.nextAppointment!.title,
                  icon: Icons.event_rounded,
                  color: TraumColors.indigoBlue,
                  onTap: () => context.push(Routes.planning),
                ),
              if (data.openTodos.isNotEmpty)
                _Section(
                  title: l10n.notificationCenterOpenTodos,
                  subtitle: l10n.notificationCenterTodosStatus(
                    data.openTodos.length,
                    data.openTodos.first.title,
                  ),
                  icon: Icons.check_circle_outline_rounded,
                  color: TraumColors.coralOrange,
                  onTap: () => context.push(Routes.planning),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Section({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TraumCard(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: TraumColors.onBackgroundSubtle,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TraumRadius.card),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
