import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../l10n/app_localizations.dart';
import 'my_substances_tab.dart';
import 'database_tab.dart';

class SubstancesScreen extends ConsumerWidget {
  const SubstancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accepted = ref.watch(substancesDisclaimerAcceptedProvider);
    return accepted ? const _SubstancesTabs() : const _DisclaimerGate();
  }
}

class _SubstancesTabs extends StatelessWidget {
  const _SubstancesTabs();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: TraumColors.background,
        appBar: AppBar(
          backgroundColor: TraumColors.background,
          title: Text(l10n.moduleSubstances,
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
            tabs: [
              Tab(text: l10n.substancesTabMyMeds),
              Tab(text: l10n.substancesTabDatabase),
            ],
          ),
        ),
        body: const TabBarView(
          children: [MySubstancesTab(), DatabaseTab()],
        ),
      ),
    );
  }
}

class _DisclaimerGate extends ConsumerStatefulWidget {
  const _DisclaimerGate();

  @override
  ConsumerState<_DisclaimerGate> createState() => _DisclaimerGateState();
}

class _DisclaimerGateState extends ConsumerState<_DisclaimerGate> {
  String? _body;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Localizations.localeOf(context) requires an established InheritedWidget
    // dependency, which isn't available yet in initState() — didChangeDependencies
    // is the correct lifecycle hook for this. Guarded so the async load only
    // starts once, even though didChangeDependencies can fire multiple times.
    if (!_loadStarted) {
      _loadStarted = true;
      _loadBody();
    }
  }

  Future<void> _loadBody() async {
    final lang = Localizations.localeOf(context).languageCode;
    final path = 'assets/legal/substances_disclaimer_${lang == 'de' ? 'de' : 'en'}.md';
    final text = await rootBundle.loadString(path);
    if (mounted) setState(() => _body = text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: TraumColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 24),
            const Icon(Icons.health_and_safety_rounded,
                size: 40, color: TraumColors.coralOrange),
            const SizedBox(height: 16),
            Text(l10n.substancesDisclaimerTitle,
                style: const TextStyle(color: TraumColors.onBackground,
                    fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_body ?? '',
                    style: const TextStyle(color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans', fontSize: 13, height: 1.6)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('substances_disclaimer_accept'),
                style: FilledButton.styleFrom(
                  backgroundColor: TraumColors.coralOrange,
                  foregroundColor: TraumColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TraumRadius.card)),
                ),
                onPressed: () async {
                  await ref
                      .read(preferencesRepositoryProvider)
                      .setSubstancesDisclaimerAccepted(true);
                  ref.invalidate(substancesDisclaimerAcceptedProvider);
                },
                child: Text(l10n.substancesDisclaimerAccept,
                    style: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
