import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'wings_skill_tree_screen.dart';
import 'wings_tutorials_screen.dart';
import 'wings_training_screen.dart';

class WingsScreen extends StatelessWidget {
  const WingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: TraumColors.background,
        appBar: AppBar(
          backgroundColor: TraumColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'WINGS',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: TraumColors.onBackground,
              letterSpacing: 6,
            ),
          ),
          bottom: TabBar(
            labelColor: TraumColors.cyanBlue,
            unselectedLabelColor: TraumColors.onBackgroundMuted,
            indicatorColor: TraumColors.cyanBlue,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: l10n.wingsSkillTree),
              Tab(text: l10n.wingsExercises),
              Tab(text: l10n.wingsTraining),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WingsSkillTreeScreen(),
            WingsTutorialsScreen(),
            WingsTrainingScreen(),
          ],
        ),
      ),
    );
  }
}
