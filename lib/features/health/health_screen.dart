import 'package:drift/drift.dart' show Value;
import 'package:fl_chart/fl_chart.dart';
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
import 'health_score_provider.dart';
import 'health_score_result.dart';
import 'widgets/circular_score_ring.dart';
import 'widgets/faktor_detail_card.dart';
import 'widgets/faktor_row.dart';
import 'widgets/insight_card.dart';
import 'widgets/score_sparkline.dart';

final _todayNutritionProvider = StreamProvider.autoDispose<List<NutritionLog>>((ref) {
  final today = DateTime.now();
  return ref
      .watch(nutritionDaoProvider)
      .watchLogsForDate(today);
});

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(l10n.health,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TraumColors.cyanBlue,
          labelColor: TraumColors.cyanBlue,
          unselectedLabelColor: TraumColors.onBackgroundMuted,
          labelStyle: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: l10n.score),
            Tab(text: l10n.overview),
            Tab(text: l10n.sleepTab),
            Tab(text: l10n.weightTab),
            Tab(text: l10n.measurementsTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ScoreTab(),
          _OverviewTab(),
          _SleepTab(),
          _WeightTab(),
          _MeasurementsTab(),
        ],
      ),
    );
  }
}

// ─── Score tab ────────────────────────────────────────────────────────────────

class _ScoreTab extends ConsumerStatefulWidget {
  const _ScoreTab();

  @override
  ConsumerState<_ScoreTab> createState() => _ScoreTabState();
}

class _ScoreTabState extends ConsumerState<_ScoreTab> {
  int _selectedDayOffset = 0; // 0 = today

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scoreAsync = ref.watch(healthScoreProvider);
    final historyAsync = ref.watch(healthScoreHistoryProvider);

    return scoreAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: TraumColors.coralOrange)),
      error: (e, _) => Center(
          child:
              Text('$e', style: const TextStyle(color: TraumColors.roseRed))),
      data: (result) {
        final history = historyAsync.valueOrNull ?? [];
        final yesterday =
            history.length >= 2 ? history[history.length - 2] : null;
        final diff =
            yesterday != null ? result.gesamtScore - yesterday : null;

        final weakest = result.weakestFactor;
        final strongest = result.strongestFactor;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Wochentag-Leiste ──────────────────────────────────
                  _DaySelector(
                    selectedOffset: _selectedDayOffset,
                    onSelect: (offset) =>
                        setState(() => _selectedDayOffset = offset),
                  ),
                  const SizedBox(height: 12),

                  // ── 2. Score-Karte ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TraumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.healthScoreTitle,
                                style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    context.push('/health/score-detail'),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  color: TraumColors.onBackgroundMuted,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                CircularScoreRing(
                                    score: result.gesamtScore, size: 160),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '/100',
                                          style: TextStyle(
                                            color: TraumColors.onBackgroundMuted,
                                            fontFamily: 'DMSans',
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (diff != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (diff >= 0
                                                      ? TraumColors.mintGreen
                                                      : TraumColors.roseRed)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              diff >= 0
                                                  ? '↑ +$diff'
                                                  : '↓ $diff',
                                              style: TextStyle(
                                                color: diff >= 0
                                                    ? TraumColors.mintGreen
                                                    : TraumColors.roseRed,
                                                fontFamily: 'DMSans',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              scoreLabel(result.gesamtScore),
                              style: TextStyle(
                                color: scoreLabelColor(result.gesamtScore),
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              motivationstext(result.gesamtScore, l10n),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: TraumColors.onBackgroundMuted,
                                fontFamily: 'DMSans',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (history.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ScoreSparkline(
                              scores: history,
                              currentScore: result.gesamtScore,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 3. Einflussfaktoren ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TraumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.healthScoreInfluenceFactors,
                                style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    context.push('/health/score-detail'),
                                child: Text(
                                  '${l10n.moreLabel} ›',
                                  style: const TextStyle(
                                    color: TraumColors.coralOrange,
                                    fontFamily: 'DMSans',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...result.faktoren.asMap().entries.map((e) {
                            final isLast =
                                e.key == result.faktoren.length - 1;
                            return Column(
                              children: [
                                FaktorRow(faktor: e.value),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    color: Colors.white
                                        .withValues(alpha: 0.06),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 4. Heute im Fokus ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TraumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.healthScoreTodayFocus,
                            style: const TextStyle(
                              color: TraumColors.onBackground,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.flash_on_rounded,
                                  color: TraumColors.amberGold, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      weakest.name,
                                      style: const TextStyle(
                                        color: TraumColors.onBackground,
                                        fontFamily: 'DMSans',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      faktorHinweis(weakest.name, l10n),
                                      style: const TextStyle(
                                        color: TraumColors.onBackgroundMuted,
                                        fontFamily: 'DMSans',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: TraumColors.onBackgroundSubtle,
                                  size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 5. Tageszusammenfassung ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DailySummaryCard(),
                  ),
                  const SizedBox(height: 12),

                  // ── 6. Einflussfaktor-Detail-Karten (horizontal) ─────────
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.healthScoreFactorDetails,
                          style: const TextStyle(
                            color: TraumColors.onBackground,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.tapOnArea,
                          style: const TextStyle(
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: result.faktoren.length,
                            itemBuilder: (ctx, i) => FaktorDetailCard(
                              faktor: result.faktoren[i],
                              history: history,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 7. Insights & Empfehlungen ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.healthScoreInsights,
                          style: const TextStyle(
                            color: TraumColors.onBackground,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          children: [
                            InsightCard(
                              icon: Icons.star_rounded,
                              color: TraumColors.mintGreen,
                              title: l10n.strength,
                              text:
                                  '${strongest.name}: ${faktorBewertung(strongest.score)} (${strongest.score}/100)',
                              buttonLabel: l10n.details,
                              onTap: () =>
                                  context.push('/health/score-detail'),
                            ),
                            InsightCard(
                              icon: Icons.trending_up_rounded,
                              color: TraumColors.amberGold,
                              title: l10n.healthScorePotential,
                              text:
                                  '${weakest.name}: ${faktorBewertung(weakest.score, l10n)} (${weakest.score}/100). ${faktorHinweis(weakest.name, l10n)}',
                              buttonLabel: l10n.improve,
                              onTap: () =>
                                  context.push('/health/score-detail'),
                            ),
                            InsightCard(
                              icon: Icons.show_chart_rounded,
                              color: TraumColors.cyanBlue,
                              title: l10n.trendLabel,
                              text: diff == null
                                  ? l10n.noTrendData
                                  : diff >= 0
                                      ? l10n.trendBetter(diff)
                                      : l10n.trendWorse(diff.abs()),
                              buttonLabel: l10n.trendLabel,
                              onTap: () =>
                                  context.push('/health/score-detail'),
                            ),
                            InsightCard(
                              icon: Icons.balance_rounded,
                              color: TraumColors.lavender,
                              title: l10n.healthScoreBalance,
                              text: l10n.balanceDiff(
                                  strongest.score - weakest.score,
                                  strongest.name,
                                  weakest.name),
                              buttonLabel: l10n.analyze,
                              onTap: () =>
                                  context.push('/health/score-detail'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Day selector ──────────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  final int selectedOffset;
  final void Function(int) onSelect;

  const _DaySelector({required this.selectedOffset, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final weekdays = AppLocalizations.of(context)!.weekdaysShort.split(',');
    final now = DateTime.now();

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (ctx, i) {
          final offset = 6 - i;
          final day = now.subtract(Duration(days: offset));
          final isSelected = selectedOffset == offset;
          final isToday = offset == 0;

          return GestureDetector(
            onTap: () => onSelect(offset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? TraumColors.coralOrange
                    : TraumColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdays[day.weekday - 1],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? TraumColors.coralOrange
                              : TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Daily summary card ────────────────────────────────────────────────────────

class _DailySummaryCard extends ConsumerWidget {
  const _DailySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nutritionAsync = ref.watch(_todayNutritionProvider);
    final kcalGoal = ref.watch(kcalGoalNotifierProvider);
    final stepsToday = ref.watch(stepsTodayProvider);

    final totalKcal = nutritionAsync.valueOrNull?.fold<double>(
          0,
          (sum, l) => sum + l.kcal,
        ) ??
        0;

    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.healthScoreDailySummary,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryMetric(
                icon: Icons.local_fire_department_rounded,
                color: TraumColors.coralOrange,
                value: '${totalKcal.toInt()}',
                sub: '/$kcalGoal kcal',
              ),
              const SizedBox(width: 8),
              _SummaryMetric(
                icon: Icons.directions_walk_rounded,
                color: TraumColors.mintGreen,
                value: stepsToday > 0 ? '$stepsToday' : '—',
                sub: l10n.steps,
              ),
              const SizedBox(width: 8),
              _SummaryMetric(
                icon: Icons.bedtime_rounded,
                color: TraumColors.cyanBlue,
                value: '—',
                sub: l10n.sleep,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String sub;

  const _SummaryMetric({
    required this.icon,
    required this.color,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(TraumRadius.chip),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sleepAsync = ref.watch(recentSleepLogsProvider(7));
    final moodAsync = ref.watch(latestMoodProvider);
    final weightAsync = ref.watch(latestWeightProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sleep summary
        sleepAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return TraumCard(
                child: _EmptyCardContent(icon: Icons.bedtime_rounded, label: l10n.noSleepData),
              );
            }
            final avgHours = logs.map((l) => l.wakeTime.difference(l.bedtime).inMinutes / 60.0).reduce((a, b) => a + b) / logs.length;
            return TraumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.bedtime_rounded, color: TraumColors.cyanBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.sleepLast7Nights,
                        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                  const SizedBox(height: 12),
                  Text(l10n.avgHours(avgHours.toStringAsFixed(1)),
                      style: const TextStyle(color: TraumColors.cyanBlue, fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700, fontSize: 28)),
                  Text(l10n.entriesRecorded(logs.length),
                      style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
                  const SizedBox(height: 8),
                  TraumLineChart(
                    spots: logs.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(),
                            e.value.wakeTime.difference(e.value.bedtime).inMinutes / 60.0)).toList(),
                    xLabels: logs.map((l) => '${l.bedtime.day}.${l.bedtime.month}').toList(),
                    color: TraumColors.cyanBlue,
                    height: 80,
                  ),
                ],
              ),
            );
          },
          loading: () => const ShimmerLoader(width: double.infinity, height: 120),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        // Latest weight
        weightAsync.when(
          data: (w) => TraumCard(
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: TraumColors.cyanDim, shape: BoxShape.circle),
                child: const Icon(Icons.monitor_weight_rounded, color: TraumColors.cyanBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.currentWeight,
                    style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
                Text(
                  w != null ? '${w.weightKg.toStringAsFixed(1)} kg' : l10n.noEntry,
                  style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700, fontSize: 20),
                ),
              ]),
            ]),
          ),
          loading: () => const ShimmerLoader(width: double.infinity, height: 80),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        // Latest mood
        moodAsync.when(
          data: (m) => TraumCard(
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: TraumColors.mintGreenDim, shape: BoxShape.circle),
                child: Text(m != null ? _moodEmoji(m.moodScore) : '😐',
                    style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.moodLastEntry,
                    style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
                Text(
                  m != null ? _moodLabel(l10n, m.moodScore) : l10n.noEntry,
                  style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ]),
            ]),
          ),
          loading: () => const ShimmerLoader(width: double.infinity, height: 80),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _moodEmoji(int score) {
    switch (score) {
      case 1: return '😢';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '😊';
      case 5: return '😄';
      default: return '😐';
    }
  }

  String _moodLabel(AppLocalizations l10n, int score) {
    switch (score) {
      case 1: return l10n.moodVeryBad;
      case 2: return l10n.moodBad;
      case 3: return l10n.moodNeutral;
      case 4: return l10n.moodGood;
      case 5: return l10n.moodExcellent;
      default: return l10n.moodNeutral;
    }
  }
}

// ─── Sleep tab ────────────────────────────────────────────────────────────────

class _SleepTab extends ConsumerWidget {
  const _SleepTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final logsAsync = ref.watch(allSleepLogsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.cyanBlue,
        onPressed: () => _showAddSleepDialog(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: _EmptyCardContent(icon: Icons.bedtime_rounded, label: l10n.noSleepData),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (ctx, i) {
              final log = logs[i];
              final duration = log.wakeTime.difference(log.bedtime);
              final hours = duration.inHours;
              final mins = duration.inMinutes % 60;
              return Dismissible(
                key: ValueKey(log.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: TraumColors.roseRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                  ),
                  child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
                ),
                onDismissed: (_) => ref.read(healthDaoProvider).deleteSleepLog(log.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: TraumColors.surface,
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: TraumColors.cyanDim, shape: BoxShape.circle),
                      child: const Icon(Icons.bedtime_rounded, color: TraumColors.cyanBlue, size: 20),
                    ),
                    title: Text('$hours h $mins min',
                        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${log.bedtime.day}.${log.bedtime.month} — ${_fmt(log.bedtime)} bis ${_fmt(log.wakeTime)}',
                      style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
                    ),
                    trailing: log.qualityStars != null
                        ? Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) =>
                            Icon(i < log.qualityStars! ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: TraumColors.amberGold, size: 14)))
                        : null,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.cyanBlue)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  String _fmt(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _showAddSleepDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddSleepSheet(
        onAdd: (c) => ref.read(healthDaoProvider).insertSleepLog(c),
      ),
    );
  }
}

class _AddSleepSheet extends StatefulWidget {
  final Future<void> Function(SleepLogsCompanion) onAdd;
  const _AddSleepSheet({required this.onAdd});

  @override
  State<_AddSleepSheet> createState() => _AddSleepSheetState();
}

class _AddSleepSheetState extends State<_AddSleepSheet> {
  DateTime _bedtime = DateTime.now().subtract(const Duration(hours: 8));
  DateTime _wakeTime = DateTime.now();
  int _quality = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(l10n.logSleep, style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
              fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _TimePickerTile(
            label: l10n.fallingAsleep,
            time: TimeOfDay.fromDateTime(_bedtime),
            onChanged: (t) => setState(() => _bedtime = DateTime(_bedtime.year, _bedtime.month, _bedtime.day, t.hour, t.minute)),
          ),
          _TimePickerTile(
            label: l10n.wakingUp,
            time: TimeOfDay.fromDateTime(_wakeTime),
            onChanged: (t) => setState(() => _wakeTime = DateTime(_wakeTime.year, _wakeTime.month, _wakeTime.day, t.hour, t.minute)),
          ),
          const SizedBox(height: 8),
          Text(l10n.sleepQuality, style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _quality = i + 1),
              child: Icon(i < _quality ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: TraumColors.amberGold, size: 32),
            )),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: l10n.save,
            onPressed: () async {
              await widget.onAdd(SleepLogsCompanion.insert(bedtime: _bedtime, wakeTime: _wakeTime, qualityStars: Value(_quality)));
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final void Function(TimeOfDay) onChanged;

  const _TimePickerTile({required this.label, required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
      trailing: GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context, initialTime: time,
            builder: (ctx, child) => Theme(
              data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: TraumColors.cyanBlue)),
              child: child!,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(TraumRadius.chip),
            border: Border.all(color: TraumColors.cyanBlue.withValues(alpha: 0.3)),
          ),
          child: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: TraumColors.cyanBlue, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ─── Weight tab ───────────────────────────────────────────────────────────────

class _WeightTab extends ConsumerWidget {
  const _WeightTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(allWeightLogsStreamProvider);
    final unitSystem = ref.watch(unitSystemProvider);

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.cyanBlue,
        onPressed: () => _showAddWeightDialog(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: logsAsync.when(
        data: (logs) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (logs.length >= 2)
              TraumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.weightHistory,
                        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 8),
                    TraumLineChart(
                      spots: logs.reversed.toList().asMap().entries.map((e) =>
                          FlSpot(e.key.toDouble(), unitSystem == 'imperial'
                              ? e.value.weightKg * 2.20462
                              : e.value.weightKg)).toList(),
                      xLabels: logs.reversed.map((l) => '${l.logDate.day}.${l.logDate.month}').toList(),
                      color: TraumColors.cyanBlue,
                      height: 100,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SectionHeader(title: l10n.entries),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              _EmptyCardContent(icon: Icons.monitor_weight_rounded, label: l10n.noWeightEntries),
            ...logs.map((log) => Dismissible(
              key: ValueKey(log.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: TraumColors.roseRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                ),
                child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
              ),
              onDismissed: (_) => ref.read(healthDaoProvider).deleteWeightLog(log.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: TraumColors.surface, borderRadius: BorderRadius.circular(TraumRadius.card)),
                child: ListTile(
                  title: Text(
                    unitSystem == 'imperial'
                        ? '${(log.weightKg * 2.20462).toStringAsFixed(1)} lb'
                        : '${log.weightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w600),
                  ),
                  trailing: Text('${log.logDate.day}.${log.logDate.month}.${log.logDate.year}',
                      style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
                ),
              ),
            )),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.cyanBlue)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(AppLocalizations.of(ctx)!.logWeight,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: TraumColors.onBackground),
          decoration: const InputDecoration(suffixText: 'kg', suffixStyle: TextStyle(color: TraumColors.onBackgroundMuted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx)!.cancel, style: const TextStyle(color: TraumColors.onBackgroundMuted))),
          TextButton(
            onPressed: () async {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (v != null && v > 0) {
                await ref.read(healthDaoProvider).insertWeightLog(
                  WeightLogsCompanion.insert(weightKg: v, logDate: DateTime.now()),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(ctx)!.save, style: const TextStyle(color: TraumColors.coralOrange)),
          ),
        ],
      ),
    );
  }
}

// ─── Measurements tab ─────────────────────────────────────────────────────────

class _MeasurementsTab extends ConsumerWidget {
  const _MeasurementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final latestAsync = ref.watch(allMeasurementsStreamProvider);

    return latestAsync.when(
      data: (entries) {
        final latest = entries.isNotEmpty ? entries.first : null;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            backgroundColor: TraumColors.cyanBlue,
            onPressed: () => _showAddDialog(context, ref, latest),
            child: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (latest == null)
                _EmptyCardContent(icon: Icons.straighten_rounded, label: l10n.noBodyMeasurements),
              if (latest != null) ...[
                TraumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.currentMeasurements,
                          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 12),
                      _MeasurementRow(l10n.chest, latest.chestCm),
                      _MeasurementRow(l10n.waist, latest.waistCm),
                      _MeasurementRow(l10n.hips, latest.hipsCm),
                      _MeasurementRow(l10n.thigh, latest.thighCm),
                      _MeasurementRow(l10n.bicep, latest.bicepCm),
                      _MeasurementRow(l10n.shoulders, latest.shoulderCm),
                      _MeasurementRow(l10n.calf, latest.calfCm),
                      _MeasurementRow(l10n.neck, latest.neckCm),
                      if (latest.bodyFatPct != null)
                        _MeasurementRow(l10n.bodyFat, latest.bodyFatPct, suffix: '%'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.cyanBlue)),
      error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: TraumColors.roseRed))),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, BodyMeasurement? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddMeasurementSheet(
        existing: existing,
        onSave: (c) => ref.read(healthDaoProvider).insertMeasurement(c),
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  final String label;
  final double? value;
  final String suffix;

  const _MeasurementRow(this.label, this.value, {this.suffix = 'cm'});

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13))),
        Text('${value!.toStringAsFixed(1)} $suffix',
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _AddMeasurementSheet extends StatefulWidget {
  final BodyMeasurement? existing;
  final Future<void> Function(BodyMeasurementsCompanion) onSave;
  const _AddMeasurementSheet({this.existing, required this.onSave});

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _controllers = {
      'chest': TextEditingController(text: e?.chestCm?.toStringAsFixed(1) ?? ''),
      'waist': TextEditingController(text: e?.waistCm?.toStringAsFixed(1) ?? ''),
      'hips': TextEditingController(text: e?.hipsCm?.toStringAsFixed(1) ?? ''),
      'thigh': TextEditingController(text: e?.thighCm?.toStringAsFixed(1) ?? ''),
      'bicep': TextEditingController(text: e?.bicepCm?.toStringAsFixed(1) ?? ''),
      'shoulder': TextEditingController(text: e?.shoulderCm?.toStringAsFixed(1) ?? ''),
      'calf': TextEditingController(text: e?.calfCm?.toStringAsFixed(1) ?? ''),
      'neck': TextEditingController(text: e?.neckCm?.toStringAsFixed(1) ?? ''),
      'bodyfat': TextEditingController(text: e?.bodyFatPct?.toStringAsFixed(1) ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  double? _parse(String key) => double.tryParse(_controllers[key]!.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.logBodyMeasurements, style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            for (final entry in () {
              final l10n = AppLocalizations.of(context)!;
              return [
                ('${l10n.chest} (cm)', 'chest'), ('${l10n.waist} (cm)', 'waist'), ('${l10n.hips} (cm)', 'hips'),
                ('${l10n.thigh} (cm)', 'thigh'), ('${l10n.bicep} (cm)', 'bicep'), ('${l10n.shoulders} (cm)', 'shoulder'),
                ('${l10n.calf} (cm)', 'calf'), ('${l10n.neck} (cm)', 'neck'), ('${l10n.bodyFat} (%)', 'bodyfat'),
              ];
            }())
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _controllers[entry.$2],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  decoration: InputDecoration(
                    labelText: entry.$1,
                    labelStyle: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                    filled: true, fillColor: TraumColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            GradientButton(
              label: AppLocalizations.of(context)!.save,
              onPressed: () async {
                await widget.onSave(BodyMeasurementsCompanion.insert(
                  logDate: DateTime.now(),
                  chestCm: Value(_parse('chest')),
                  waistCm: Value(_parse('waist')),
                  hipsCm: Value(_parse('hips')),
                  thighCm: Value(_parse('thigh')),
                  bicepCm: Value(_parse('bicep')),
                  shoulderCm: Value(_parse('shoulder')),
                  calfCm: Value(_parse('calf')),
                  neckCm: Value(_parse('neck')),
                  bodyFatPct: Value(_parse('bodyfat')),
                ));
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _EmptyCardContent extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyCardContent({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans', fontSize: 14), textAlign: TextAlign.center),
      ]),
    );
  }
}
