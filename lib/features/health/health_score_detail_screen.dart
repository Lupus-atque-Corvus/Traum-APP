import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'health_score_provider.dart';
import 'health_score_result.dart';
import 'widgets/circular_score_ring.dart';
import 'widgets/radar_chart_widget.dart';

class HealthScoreDetailScreen extends ConsumerStatefulWidget {
  const HealthScoreDetailScreen({super.key});

  @override
  ConsumerState<HealthScoreDetailScreen> createState() =>
      _HealthScoreDetailScreenState();
}

class _HealthScoreDetailScreenState
    extends ConsumerState<HealthScoreDetailScreen> {
  int _periodIndex = 1; // 0=Tag 1=Woche 2=Monat 3=Jahr

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scoreAsync = ref.watch(healthScoreProvider);
    final historyAsync = ref.watch(healthScoreHistoryProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(
          l10n.healthScoreTitle,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: scoreAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: TraumColors.coralOrange)),
        error: (e, _) => Center(
            child: Text('$e',
                style: const TextStyle(color: TraumColors.roseRed))),
        data: (result) {
          final history = historyAsync.value ?? [];
          final yesterday =
              history.length >= 2 ? history[history.length - 2] : null;
          final diff =
              yesterday != null ? result.gesamtScore - yesterday : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── 1. Big score ring ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CircularScoreRing(score: result.gesamtScore, size: 200),
                        Column(
                          children: [
                            Text(
                              '${result.gesamtScore}',
                              style: const TextStyle(
                                color: TraumColors.onBackground,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 52,
                              ),
                            ),
                            const Text(
                              '/100',
                              style: TextStyle(
                                color: TraumColors.onBackgroundMuted,
                                fontFamily: 'DMSans',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scoreLabel(result.gesamtScore),
                      style: TextStyle(
                        color: scoreLabelColor(result.gesamtScore),
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    if (diff != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (diff >= 0
                                  ? TraumColors.mintGreen
                                  : TraumColors.roseRed)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          diff >= 0
                              ? '↑ +$diff Punkte · Letzte 7 Tage'
                              : '↓ $diff Punkte · Letzte 7 Tage',
                          style: TextStyle(
                            color: diff >= 0
                                ? TraumColors.mintGreen
                                : TraumColors.roseRed,
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 2. Radar chart ─────────────────────────────────────────────
              TraumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Was beeinflusst deinen Score?',
                      style: TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Dein Score wird aus 6 Hauptbereichen berechnet.',
                      style: TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ScoreRadarChart(faktoren: result.faktoren),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── 3. Period tabs + bar chart ─────────────────────────────────
              TraumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PeriodTabs(
                      selected: _periodIndex,
                      onChanged: (i) => setState(() => _periodIndex = i),
                    ),
                    const SizedBox(height: 16),
                    _periodIndex == 1
                        ? _ScoreBarChart(history: history)
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Daten werden gesammelt…',
                                style: const TextStyle(
                                  color: TraumColors.onBackgroundMuted,
                                  fontFamily: 'DMSans',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 8),
                    Text(
                      motivationstext(result.gesamtScore, l10n),
                      style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  final int selected;
  final void Function(int) onChanged;

  const _PeriodTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Tag', 'Woche', 'Monat', 'Jahr'];
    return Row(
      children: labels.asMap().entries.map((e) {
        final isActive = e.key == selected;
        return GestureDetector(
          onTap: () => onChanged(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? TraumColors.coralOrange
                  : TraumColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ScoreBarChart extends StatelessWidget {
  final List<int> history;

  const _ScoreBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Noch keine Verlaufsdaten',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final now = DateTime.now();
    final labels = List.generate(history.length, (i) {
      final day = now.subtract(Duration(days: history.length - 1 - i));
      return weekdays[day.weekday - 1];
    });

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: 100,
          minY: 0,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    labels[i],
                    style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 20,
              ),
            ),
          ),
          barGroups: history.asMap().entries.map((e) {
            final isLast = e.key == history.length - 1;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  color: isLast
                      ? TraumColors.coralOrange
                      : TraumColors.surfaceVariant,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  rodStackItems: [],
                ),
              ],
              showingTooltipIndicators: isLast ? [0] : [],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()}',
                  const TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
