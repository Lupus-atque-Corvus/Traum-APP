import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

/// A named target duration since a tracker's start (e.g. "1 Woche" = 7 days).
class Milestone {
  final String label;
  final Duration duration;

  const Milestone(this.label, this.duration);
}

/// Commonly used abstinence milestones: 24h, 1 week, 1 month, 3 months,
/// 6 months, 1 year. Callers may pass a different set to [computeMilestones] —
/// this is only a convenience default.
const List<Milestone> kAbstinenceMilestones = [
  Milestone('24 Stunden', Duration(hours: 24)),
  Milestone('1 Woche', Duration(days: 7)),
  Milestone('1 Monat', Duration(days: 30)),
  Milestone('3 Monate', Duration(days: 90)),
  Milestone('6 Monate', Duration(days: 180)),
  Milestone('1 Jahr', Duration(days: 365)),
];

/// Computed status of a single milestone relative to `now`.
class MilestoneStatus {
  final Milestone milestone;
  final bool reached;
  final bool isCurrent;
  final Duration? remaining;

  const MilestoneStatus({
    required this.milestone,
    required this.reached,
    required this.isCurrent,
    this.remaining,
  });
}

/// Pure function: given a tracker `start` date, a list of target [milestones]
/// (unordered), and the current time `now`, returns one [MilestoneStatus]
/// per milestone — sorted ascending by duration.
///
/// - `reached` is true once the elapsed time is >= the milestone duration
///   (i.e. reached exactly on the boundary, not only strictly after it).
/// - `isCurrent` marks the single nearest not-yet-reached milestone (the
///   "next" target the user is working towards). At most one milestone is
///   current.
/// - `remaining` is the time left to reach a not-yet-reached milestone, and
///   `null` for already-reached ones.
List<MilestoneStatus> computeMilestones(
  DateTime start,
  List<Milestone> milestones,
  DateTime now,
) {
  final elapsed = now.difference(start);
  final sorted = [...milestones]..sort(
      (a, b) => a.duration.compareTo(b.duration),
    );
  final firstNotReachedIndex = sorted.indexWhere(
    (m) => elapsed < m.duration,
  );

  return List.generate(sorted.length, (i) {
    final m = sorted[i];
    final reached = elapsed >= m.duration;
    final isCurrent = !reached && i == firstNotReachedIndex;
    final remaining = reached ? null : m.duration - elapsed;
    return MilestoneStatus(
      milestone: m,
      reached: reached,
      isCurrent: isCurrent,
      remaining: remaining,
    );
  });
}

/// Formats a remaining [Duration] as a short "when" label, e.g. "in 3 T"
/// (days) or "in 5 Std." (hours) when less than a day remains.
String formatMilestoneRemaining(Duration remaining) {
  if (remaining.inDays >= 1) return 'in ${remaining.inDays} T';
  if (remaining.inHours >= 1) return 'in ${remaining.inHours} Std.';
  return 'bald';
}

/// Vertical timeline of milestones: a pip per milestone (done / current /
/// future) connected by a line, the label, and a trailing "when" indicator.
/// Pure presentation — renders exactly what [statuses] describes.
class MilestoneTimeline extends StatelessWidget {
  final List<MilestoneStatus> statuses;
  final Color accentColor;

  const MilestoneTimeline({
    super.key,
    required this.statuses,
    this.accentColor = TraumColors.roseRed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < statuses.length; i++)
          _MilestoneRow(
            status: statuses[i],
            accentColor: accentColor,
            isLast: i == statuses.length - 1,
          ),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final MilestoneStatus status;
  final Color accentColor;
  final bool isLast;

  const _MilestoneRow({
    required this.status,
    required this.accentColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final pipColor = status.reached
        ? accentColor
        : status.isCurrent
            ? accentColor
            : TraumColors.surfaceVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: status.reached
                      ? pipColor
                      : pipColor.withValues(alpha: status.isCurrent ? 0.25 : 1),
                  shape: BoxShape.circle,
                  border: status.isCurrent
                      ? Border.all(color: accentColor, width: 2)
                      : null,
                ),
                child: status.reached
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: status.reached
                        ? accentColor.withValues(alpha: 0.4)
                        : TraumColors.surfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    status.milestone.label,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      fontWeight: status.isCurrent
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: status.reached || status.isCurrent
                          ? TraumColors.onBackground
                          : TraumColors.onBackgroundMuted,
                    ),
                  ),
                  Text(
                    status.reached
                        ? 'erreicht'
                        : status.remaining != null
                            ? formatMilestoneRemaining(status.remaining!)
                            : '—',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status.reached
                          ? accentColor
                          : TraumColors.onBackgroundMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
