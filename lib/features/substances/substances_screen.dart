import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'my_substances_tab.dart';
import 'database_tab.dart';

class SubstancesScreen extends StatelessWidget {
  const SubstancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: TraumColors.background,
        appBar: AppBar(
          backgroundColor: TraumColors.background,
          title: Text(AppLocalizations.of(context)!.moduleSubstances,
              style: const TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
          elevation: 0,
          bottom: TabBar(
            labelColor: TraumColors.coralOrange,
            unselectedLabelColor: TraumColors.onBackgroundMuted,
            indicatorColor: TraumColors.coralOrange,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontFamily: 'DMSans'),
            tabs: const [
              Tab(text: 'Meine Mittel'),
              Tab(text: 'Datenbank'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MySubstancesTab(),
            DatabaseTab(),
          ],
        ),
      ),
    );
  }
}
