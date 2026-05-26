import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';

class WingsTrainingScreen extends StatelessWidget {
  const WingsTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final guides = [
      _GuideData(
        icon: Icons.school_outlined,
        title: l10n.wingsBeginnerGuide,
        color: TraumColors.mintGreen,
        sections: [
          _GuideSection(
            heading: 'What is Calisthenics?',
            body:
                'Calisthenics is bodyweight exercise focused on skill development. It includes skills like the Planche, Front Lever, and Handstand. This guide is for those who are completely new to calisthenics or have just started.',
          ),
          _GuideSection(
            heading: 'Where to Start',
            body:
                'Begin with fundamental movements: Pull-ups, Push-ups, Dips, and core work. These build the foundation for all advanced skills. Focus on volume and consistency before skill training.',
          ),
          _GuideSection(
            heading: 'Training Frequency',
            body:
                'As a beginner, train 3× per week with full body workouts. Allow at least one rest day between sessions. Consistency over intensity – showing up regularly matters more than training hard.',
          ),
        ],
      ),
      _GuideData(
        icon: Icons.fitness_center,
        title: l10n.wingsBeginnerWorkout,
        color: TraumColors.cyanBlue,
        sections: [
          _GuideSection(
            heading: '3× per week – Full Body',
            body: 'Train on Monday, Wednesday, Friday (or similar). Rest on alternate days.',
          ),
          _GuideSection(
            heading: 'Pull',
            body: '3 sets of Pull-ups (or Assisted Pull-ups)\n5–8 reps per set\nRest 2–3 minutes between sets',
          ),
          _GuideSection(
            heading: 'Push',
            body: '3 sets of Push-ups or Dips\n8–12 reps per set\nRest 90 seconds between sets',
          ),
          _GuideSection(
            heading: 'Core',
            body: '3 sets of Hollow Body Hold\n20–30 seconds per set\nRest 60 seconds between sets',
          ),
          _GuideSection(
            heading: 'Legs',
            body: '3 sets of Bodyweight Squats\n10–15 reps per set\nRest 90 seconds between sets',
          ),
        ],
      ),
      _GuideData(
        icon: Icons.trending_up,
        title: l10n.wingsIntermediateWorkout,
        color: TraumColors.coralOrange,
        sections: [
          _GuideSection(
            heading: '4× per week – Push/Pull Split',
            body: 'Example: Pull D1, Push D2, Rest, Pull D3, Push D4, Rest, Rest.',
          ),
          _GuideSection(
            heading: 'Exercise Selection',
            body:
                '1st exercise: MOST SPECIFIC to target skill (6 sec holds × 3 sets, or heavy sets)\n2nd exercise: Second most specific (6–9 RPE, 3–4 sets)\n3rd exercise: Hypertrophy/volume focus (3–4 sets)\n4th+: Accessory exercises (2–3 sets, 80% to failure)\nFinisher: Volume (max reps × 2 sets)',
          ),
          _GuideSection(
            heading: 'Front Lever Example',
            body:
                'Straddle FL 6s × 3\nBanded Straddle FL 7s × 2\nBanded Straddle FL Pulls 3 × 4 reps\nWeighted Pull-ups/Pull-ups 3 × 5 reps\nDragon Flag max hold × 2\nPull-ups max × 2',
          ),
          _GuideSection(
            heading: 'Rest Times',
            body:
                'Skill holds (max intensity): 3–5 minutes\nStrength sets: 2–3 minutes\nHypertrophy: 90 seconds\nAccessory/volume: 60–90 seconds',
          ),
        ],
      ),
      _GuideData(
        icon: Icons.show_chart,
        title: l10n.wingsProgressiveOverload,
        color: TraumColors.amberGold,
        sections: [
          _GuideSection(
            heading: 'How to Progress',
            body:
                'Add reps, sets, or difficulty. Advance to a harder progression when your current one feels comfortable for 3 consecutive sessions.',
          ),
          _GuideSection(
            heading: 'Law of Specificity',
            body:
                'Your body adapts to what you specifically train. Train the exact movement pattern you want to improve. Accessory work helps, but the specific skill must be practiced.',
          ),
          _GuideSection(
            heading: 'Breaking Plateaus',
            body:
                'If stuck, change your exercises for 1–2 weeks. Focus training on individual components of the skill. Split your goal into smaller sub-goals.',
          ),
          _GuideSection(
            heading: 'Deload',
            body:
                'Every 4–6 weeks, reduce volume by 40–50% for one week. This allows full recovery and often leads to new PRs afterward.',
          ),
        ],
      ),
      _GuideData(
        icon: Icons.arrow_back,
        title: l10n.wingsFrontLeverGuide,
        color: TraumColors.lavender,
        sections: [
          _GuideSection(
            heading: 'Key Principles',
            body:
                'Maintain scapular retraction and depression at all times. Keep the body as flat and parallel to the ground as possible. Engage the core – treat it like a hollow body hold while hanging.',
          ),
          _GuideSection(
            heading: 'Progression Order',
            body:
                'Tuck FL → Adv. Tuck FL → Super Adv. Tuck FL → Pike FL → Straddle FL → Straddle FL Row → Half Lay FL → Full Front Lever',
          ),
          _GuideSection(
            heading: 'Training Protocol',
            body:
                'Hold each progression for 5–10 seconds × 3 sets before progressing. Train 2× per week. Add FL rows alongside holds for strength.',
          ),
          _GuideSection(
            heading: 'Common Mistakes',
            body:
                'Sagging hips – engage the core more and reduce progression. Bent arms – build more pulling/lat strength first. Rushing progressions – spend at least 4 weeks on each level.',
          ),
        ],
      ),
      _GuideData(
        icon: Icons.arrow_upward,
        title: l10n.wingsHandstandGuide,
        color: TraumColors.peachOrange,
        sections: [
          _GuideSection(
            heading: 'Practice Daily',
            body:
                'Handstand balance improves with daily practice. Even 10–15 minutes per day is enough. Consistency matters more than long sessions.',
          ),
          _GuideSection(
            heading: 'Progression',
            body:
                'Pike Push-up → Crow Pose → Wall Handstand → Assisted Handstand → Freestanding Handstand',
          ),
          _GuideSection(
            heading: 'Body Position',
            body:
                'Maintain a hollow body position – not an arched back. Stack shoulders over wrists, hips over shoulders, legs over hips. Use fingertips and heel of palm to fine-tune balance.',
          ),
          _GuideSection(
            heading: 'Bailing Safely',
            body:
                'Learn to bail before training freestanding. Roll forward or step down to one side. Never fall onto a hyperextended wrist.',
          ),
        ],
      ),
      _GuideData(
        icon: Icons.schedule,
        title: l10n.wingsSkillPriority,
        color: TraumColors.indigoBlue,
        sections: [
          _GuideSection(
            heading: 'Push vs Pull Priority',
            body:
                'The skill you train FIRST benefits more due to fresh CNS. Push D1 → Pull D2 = Push gets priority. Swap if Pull is more important to you.',
          ),
          _GuideSection(
            heading: 'Same Day vs Split',
            body:
                'Training Planche and Front Lever the same day is possible but both compete for CNS resources. A split (push/pull days) generally produces better results for each skill.',
          ),
          _GuideSection(
            heading: 'Overtraining',
            body:
                'Signs: declining performance, persistent soreness, poor sleep. Solution: reduce volume, add a deload week, improve sleep and nutrition.',
          ),
        ],
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: guides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _GuideCard(guide: guides[i]),
    );
  }
}

class _GuideSection {
  final String heading;
  final String body;
  const _GuideSection({required this.heading, required this.body});
}

class _GuideData {
  final IconData icon;
  final String title;
  final Color color;
  final List<_GuideSection> sections;

  const _GuideData({
    required this.icon,
    required this.title,
    required this.color,
    required this.sections,
  });
}

class _GuideCard extends StatefulWidget {
  final _GuideData guide;

  const _GuideCard({required this.guide});

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? widget.guide.color.withAlpha(80)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.guide.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.guide.icon,
                        color: widget.guide.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.guide.title,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackground,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: TraumColors.onBackgroundMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: widget.guide.sections.map((sec) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sec.heading.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            color: widget.guide.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sec.body,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackgroundMuted,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
