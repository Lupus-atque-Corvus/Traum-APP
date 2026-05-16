import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heightCm = ref.watch(heightCmNotifierProvider);
    final weightGoal = ref.watch(weightGoalNotifierProvider);
    final kcalGoal = ref.watch(kcalGoalNotifierProvider);
    final proteinGoal = ref.watch(proteinGoalNotifierProvider);
    final stepsGoal = ref.watch(stepsGoalNotifierProvider);
    final unitSystem = ref.watch(unitSystemProvider);

    final weightAsync = ref.watch(
      FutureProvider((ref) => ref.watch(healthDaoProvider).getLatestWeight()),
    );
    final sleepAsync = ref.watch(
      FutureProvider((ref) => ref.watch(healthDaoProvider).getRecentSleepLogs(30)),
    );
    final moodAsync = ref.watch(
      FutureProvider((ref) => ref.watch(healthDaoProvider).getLatestMood()),
    );
    final trainingSetsAsync = ref.watch(
      FutureProvider((ref) =>
          ref.watch(trainingDaoProvider).getRecentSets(const Duration(days: 30))),
    );
    final trainingSessionsAsync = ref.watch(
      FutureProvider((ref) =>
          ref.watch(trainingDaoProvider).getSessionsThisWeek()),
    );
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text('Mein Profil',
            style: TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar and identity
          Center(
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  gradient: TraumColors.gradientCool,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 12),
              const Text('Mein Dashboard',
                  style: TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 20)),
            ]),
          ),
          const SizedBox(height: 24),

          // Body stats
          SectionHeader(title: 'Körper'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
            ),
            child: Column(children: [
              weightAsync.when(
                data: (weight) {
                  if (weight == null) return const SizedBox.shrink();
                  final weightKg = weight.weightKg;
                  // BMI calculation
                  double? bmi;
                  if (heightCm > 0) {
                    final heightM = heightCm / 100;
                    bmi = weightKg / (heightM * heightM);
                  }
                  return Column(children: [
                    Row(children: [
                      Expanded(child: _StatCard(
                        label: 'Aktuelles Gewicht',
                        value: unitSystem == 'metric'
                            ? '${weightKg.toStringAsFixed(1)} kg'
                            : '${(weightKg * 2.20462).toStringAsFixed(1)} lbs',
                        color: TraumColors.lavender,
                      )),
                      if (heightCm > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          label: 'Größe',
                          value: unitSystem == 'metric'
                              ? '${heightCm.toStringAsFixed(0)} cm'
                              : "${(heightCm / 30.48).floor()}' ${((heightCm / 2.54) % 12).round()}\"",
                          color: TraumColors.cyanBlue,
                        )),
                      ],
                    ]),
                    if (bmi != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _StatCard(
                          label: 'BMI',
                          value: bmi.toStringAsFixed(1),
                          color: _bmiColor(bmi),
                          subtitle: _bmiCategory(bmi),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          label: 'Gewichtsziel',
                          value: '${weightGoal.toStringAsFixed(1)} kg',
                          color: TraumColors.mintGreen,
                          subtitle: '${(weightKg - weightGoal).abs().toStringAsFixed(1)} kg ${weightKg > weightGoal ? 'abnehmen' : 'zunehmen'}',
                        )),
                      ]),
                    ],
                  ]);
                },
                loading: () => ShimmerLoader(width: double.infinity, height: 60),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Sleep stats
          SectionHeader(title: 'Schlaf (30 Tage)'),
          const SizedBox(height: 8),
          sleepAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return _EmptyCard(message: 'Keine Schlafdaten');
              }
              final avgMinutes = logs.map((l) => l.wakeTime.difference(l.bedtime).inMinutes)
                  .fold(0, (s, m) => s + m) ~/ logs.length;
              final avgHours = avgMinutes ~/ 60;
              final avgMins = avgMinutes % 60;
              final avgQuality = logs.isEmpty
                  ? 0.0
                  : logs.fold(0, (s, l) => s + (l.qualityStars ?? 0)) / logs.length;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TraumColors.surface,
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                ),
                child: Row(children: [
                  Expanded(child: _StatCard(
                    label: 'Ø Schlafdauer',
                    value: '${avgHours}h ${avgMins}m',
                    color: TraumColors.indigoBlue,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    label: 'Ø Qualität',
                    value: '⭐' * avgQuality.round(),
                    color: TraumColors.amberGold,
                    subtitle: '${avgQuality.toStringAsFixed(1)}/5',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    label: 'Einträge',
                    value: '${logs.length}',
                    color: TraumColors.lavender,
                  )),
                ]),
              );
            },
            loading: () => ShimmerLoader(width: double.infinity, height: 60),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Training stats
          SectionHeader(title: 'Training (diese Woche)'),
          const SizedBox(height: 8),
          trainingSessionsAsync.when(
            data: (sessions) {
              return trainingSetsAsync.when(
                data: (sets) {
                  final volume = sets.fold(
                      0.0, (v, s) => v + ((s.weightKg ?? 0) * (s.reps ?? 1)));
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TraumColors.surface,
                      borderRadius: BorderRadius.circular(TraumRadius.card),
                    ),
                    child: Row(children: [
                      Expanded(child: _StatCard(
                        label: 'Workouts',
                        value: '${sessions.length}',
                        color: TraumColors.coralOrange,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        label: 'Sätze',
                        value: '${sets.length}',
                        color: TraumColors.peachOrange,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        label: 'Volumen',
                        value: '${volume.toStringAsFixed(0)} kg',
                        color: TraumColors.amberGold,
                      )),
                    ]),
                  );
                },
                loading: () => ShimmerLoader(width: double.infinity, height: 60),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
            loading: () => ShimmerLoader(width: double.infinity, height: 60),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Nutrition goals
          SectionHeader(title: 'Ernährungsziele'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
            ),
            child: Row(children: [
              Expanded(child: _StatCard(
                label: 'Kcal-Ziel',
                value: '$kcalGoal kcal',
                color: TraumColors.mintGreen,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Protein-Ziel',
                value: '${proteinGoal}g',
                color: TraumColors.indigoBlue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Schritte-Ziel',
                value: '$stepsGoal',
                color: TraumColors.amberGold,
              )),
            ]),
          ),
          const SizedBox(height: 16),

          // Mood
          SectionHeader(title: 'Stimmung'),
          const SizedBox(height: 8),
          moodAsync.when(
            data: (mood) {
              if (mood == null) return _EmptyCard(message: 'Keine Stimmungsdaten');
              const moodEmojis = ['', '😢', '😕', '😐', '😊', '😄'];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TraumColors.surface,
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                ),
                child: Row(children: [
                  Text(
                    mood.moodScore <= 5 ? moodEmojis[mood.moodScore.clamp(1, 5)] : '😐',
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Letzte Stimmung: ${mood.moodScore}/5',
                        style: const TextStyle(
                            color: TraumColors.onBackground,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w600)),
                    Text(
                      '${mood.logDate.day}.${mood.logDate.month}.${mood.logDate.year}',
                      style: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 12),
                    ),
                  ]),
                ]),
              );
            },
            loading: () => ShimmerLoader(width: double.infinity, height: 60),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return TraumColors.cyanBlue;
    if (bmi < 25) return TraumColors.mintGreen;
    if (bmi < 30) return TraumColors.amberGold;
    return TraumColors.roseRed;
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Untergewicht';
    if (bmi < 25) return 'Normalgewicht';
    if (bmi < 30) return 'Übergewicht';
    return 'Adipositas';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 16),
          textAlign: TextAlign.center),
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 11),
          textAlign: TextAlign.center),
      if (subtitle != null)
        Text(subtitle!,
            style: const TextStyle(
                color: TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans',
                fontSize: 10),
            textAlign: TextAlign.center),
    ]);
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Text(message,
          style: const TextStyle(
              color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 13)),
    );
  }
}
