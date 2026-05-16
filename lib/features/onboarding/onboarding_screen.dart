import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/navigation/routes.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/components/components.dart';
import '../../core/utils/water_calculator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Form state
  final _nameController = TextEditingController();
  String _sex = 'male';
  String _unitSystem = 'metric';
  DateTime? _birthDate;
  double _heightCm = 175;
  double _weightKg = 75;
  double _weightGoalKg = 70;
  int _stepsGoal = 10000;
  int _kcalGoal = 2000;
  int _proteinGoal = 120;
  int _avgCycleLength = 28;
  int _avgPeriodLength = 5;
  DateTime? _lastPeriodStart;
  String _currencySymbol = '€';
  double _monthlyBudget = 1500;
  bool _periodTrackingEnabled = false;

  // Consents
  bool _consentPrivacy = false;
  bool _consentHealth = false;
  bool _consentTerms = false;
  bool _consentDisclaimer = false;
  bool _consentAge = false;

  bool get _allConsented =>
      _consentPrivacy &&
      _consentHealth &&
      _consentTerms &&
      _consentDisclaimer &&
      _consentAge;

  List<Widget> get _pages {
    final pages = <Widget>[
      _WelcomePage(onNext: _next),
      _ConsentPage(
        consentPrivacy: _consentPrivacy,
        consentHealth: _consentHealth,
        consentTerms: _consentTerms,
        consentDisclaimer: _consentDisclaimer,
        consentAge: _consentAge,
        onChanged: (p, h, t, d, a) => setState(() {
          _consentPrivacy = p;
          _consentHealth = h;
          _consentTerms = t;
          _consentDisclaimer = d;
          _consentAge = a;
        }),
        canContinue: _allConsented,
        onNext: _next,
      ),
      _ProfilePage(
        nameController: _nameController,
        sex: _sex,
        birthDate: _birthDate,
        unitSystem: _unitSystem,
        onSexChanged: (v) => setState(() => _sex = v),
        onUnitChanged: (v) => setState(() => _unitSystem = v),
        onBirthDateChanged: (v) => setState(() => _birthDate = v),
        onNext: _next,
      ),
      _BodyPage(
        heightCm: _heightCm,
        weightKg: _weightKg,
        weightGoalKg: _weightGoalKg,
        stepsGoal: _stepsGoal,
        unitSystem: _unitSystem,
        sex: _sex,
        birthDate: _birthDate,
        onHeightChanged: (v) => setState(() => _heightCm = v),
        onWeightChanged: (v) => setState(() => _weightKg = v),
        onGoalWeightChanged: (v) => setState(() => _weightGoalKg = v),
        onStepsChanged: (v) => setState(() => _stepsGoal = v),
        onNext: _next,
      ),
      _NutritionPage(
        kcalGoal: _kcalGoal,
        proteinGoal: _proteinGoal,
        onKcalChanged: (v) => setState(() => _kcalGoal = v),
        onProteinChanged: (v) => setState(() => _proteinGoal = v),
        onNext: _next,
      ),
      _SupplementsPage(onNext: _next, onSkip: _next),
      _MedicationPage(onNext: _next, onSkip: _next),
      _BudgetPage(
        currencySymbol: _currencySymbol,
        monthlyBudget: _monthlyBudget,
        onCurrencyChanged: (v) => setState(() => _currencySymbol = v),
        onBudgetChanged: (v) => setState(() => _monthlyBudget = v),
        onNext: _next,
        onSkip: _next,
      ),
      if (_sex == 'female')
        _CyclePage(
          avgCycleLength: _avgCycleLength,
          avgPeriodLength: _avgPeriodLength,
          lastPeriodStart: _lastPeriodStart,
          onCycleLengthChanged: (v) => setState(() => _avgCycleLength = v),
          onPeriodLengthChanged: (v) => setState(() => _avgPeriodLength = v),
          onLastPeriodChanged: (v) => setState(() => _lastPeriodStart = v),
          onNext: _next,
          onSkip: () {
            setState(() => _periodTrackingEnabled = false);
            _next();
          },
        ),
      _NavPage(sex: _sex, onNext: _next),
      _WeatherPage(onNext: _next),
      _NotificationsPage(onNext: _next),
      _HealthPage(onNext: _next),
      _DonePage(
        name: _nameController.text,
        kcalGoal: _kcalGoal,
        waterGoal: _computeWaterGoal(),
        onFinish: _finish,
      ),
    ];
    return pages;
  }

  int _computeWaterGoal() {
    if (_birthDate == null) return 2500;
    final age =
        DateTime.now().difference(_birthDate!).inDays ~/ 365;
    return WaterCalculator.recommendedMl(_weightKg, age, _sex);
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      SystemNavigator.pop();
    }
  }

  Future<void> _finish() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final age = _birthDate != null
        ? DateTime.now().difference(_birthDate!).inDays ~/ 365
        : 25;
    final waterGoal = WaterCalculator.recommendedMl(_weightKg, age, _sex);
    final waterMin = WaterCalculator.minimumMl(_weightKg, _sex);
    final waterMax = WaterCalculator.maximumMl(_weightKg);

    await Future.wait([
      prefs.setUserName(_nameController.text.trim()),
      prefs.setUserBiologicalSex(_sex),
      prefs.setUnitSystem(_unitSystem),
      prefs.setHeightCm(_heightCm),
      prefs.setWeightGoalKg(_weightGoalKg),
      prefs.setStepsGoal(_stepsGoal),
      prefs.setKcalGoal(_kcalGoal),
      prefs.setProteinGoalG(_proteinGoal),
      prefs.setWaterGoalMl(waterGoal),
      prefs.setWaterMinMl(waterMin),
      prefs.setWaterMaxMl(waterMax),
      prefs.setCurrencySymbol(_currencySymbol),
      prefs.setMonthlyBudget(_monthlyBudget),
      prefs.setAvgCycleLength(_avgCycleLength),
      prefs.setAvgPeriodLength(_avgPeriodLength),
      prefs.setPeriodTrackingEnabled(_sex == 'female' && _periodTrackingEnabled),
      prefs.setOnboardingComplete(true),
    ]);
    if (_birthDate != null) {
      await prefs.setUserBirthDate(
        '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
      );
    }

    if (mounted) {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _prev();
      },
      canPop: false,
      child: Scaffold(
        backgroundColor: TraumColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: _pages,
                ),
              ),
              _DotIndicator(
                count: _pages.length,
                current: _currentPage,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

// ── Page helpers ──────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == current
                ? TraumColors.coralOrange
                : TraumColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final Widget content;
  final String? buttonLabel;
  final VoidCallback? onButton;
  final bool buttonEnabled;

  const _OnboardingPage({
    required this.title,
    required this.content,
    this.buttonLabel,
    this.onButton,
    this.buttonEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(child: content),
          ),
          if (buttonLabel != null) ...[
            const SizedBox(height: 12),
            GradientButton(
              label: buttonLabel!,
              onPressed: buttonEnabled ? onButton : null,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// Welcome
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Willkommen bei TRAUM',
      buttonLabel: 'Loslegen',
      onButton: onNext,
      content: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: TraumColors.gradientWarm,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 24),
          const Text(
            'Dein Leben. Deine Daten. Dein System.',
            style: TextStyle(
              fontSize: 18,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'TRAUM bringt alle wichtigen Lebensbereiche in einer App zusammen — '
            'komplett offline, sicher auf deinem Gerät.',
            style: TextStyle(
              fontSize: 14,
              color: TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Consent
class _ConsentPage extends StatelessWidget {
  final bool consentPrivacy, consentHealth, consentTerms, consentDisclaimer, consentAge;
  final void Function(bool, bool, bool, bool, bool) onChanged;
  final bool canContinue;
  final VoidCallback onNext;

  const _ConsentPage({
    required this.consentPrivacy,
    required this.consentHealth,
    required this.consentTerms,
    required this.consentDisclaimer,
    required this.consentAge,
    required this.onChanged,
    required this.canContinue,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Datenschutz & Einwilligung',
      buttonLabel: 'Weiter',
      onButton: onNext,
      buttonEnabled: canContinue,
      content: Column(
        children: [
          _ConsentTile(
            label: 'Ich habe die Datenschutzerklärung gelesen und stimme zu.',
            value: consentPrivacy,
            onChanged: (v) => onChanged(
              v ?? false, consentHealth, consentTerms, consentDisclaimer, consentAge),
          ),
          _ConsentTile(
            label: 'Ich willige in die Verarbeitung von Gesundheitsdaten ein (DSGVO Art. 9).',
            value: consentHealth,
            onChanged: (v) => onChanged(
              consentPrivacy, v ?? false, consentTerms, consentDisclaimer, consentAge),
          ),
          _ConsentTile(
            label: 'Ich akzeptiere die Nutzungsbedingungen.',
            value: consentTerms,
            onChanged: (v) => onChanged(
              consentPrivacy, consentHealth, v ?? false, consentDisclaimer, consentAge),
          ),
          _ConsentTile(
            label: 'Ich bestätige den medizinischen Haftungsausschluss.',
            value: consentDisclaimer,
            onChanged: (v) => onChanged(
              consentPrivacy, consentHealth, consentTerms, v ?? false, consentAge),
          ),
          _ConsentTile(
            label: 'Ich bestätige, dass ich mindestens 16 Jahre alt bin.',
            value: consentAge,
            onChanged: (v) => onChanged(
              consentPrivacy, consentHealth, consentTerms, consentDisclaimer, v ?? false),
          ),
        ],
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _ConsentTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: TraumColors.onBackground,
          fontFamily: 'DMSans',
        ),
      ),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

// Profile
class _ProfilePage extends StatelessWidget {
  final TextEditingController nameController;
  final String sex;
  final DateTime? birthDate;
  final String unitSystem;
  final ValueChanged<String> onSexChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<DateTime> onBirthDateChanged;
  final VoidCallback onNext;

  const _ProfilePage({
    required this.nameController,
    required this.sex,
    required this.birthDate,
    required this.unitSystem,
    required this.onSexChanged,
    required this.onUnitChanged,
    required this.onBirthDateChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Dein Profil',
      buttonLabel: 'Weiter',
      onButton: nameController.text.trim().isNotEmpty ? onNext : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'Dein Name'),
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Geschlecht',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'male', label: Text('Männlich')),
              ButtonSegment(value: 'female', label: Text('Weiblich')),
            ],
            selected: {sex},
            onSelectionChanged: (s) => onSexChanged(s.first),
          ),
          const SizedBox(height: 16),
          const Text(
            'Einheiten',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'metric', label: Text('Metrisch')),
              ButtonSegment(value: 'imperial', label: Text('Imperial')),
            ],
            selected: {unitSystem},
            onSelectionChanged: (s) => onUnitChanged(s.first),
          ),
        ],
      ),
    );
  }
}

// Body
class _BodyPage extends StatelessWidget {
  final double heightCm, weightKg, weightGoalKg;
  final int stepsGoal;
  final String unitSystem, sex;
  final DateTime? birthDate;
  final ValueChanged<double> onHeightChanged, onWeightChanged, onGoalWeightChanged;
  final ValueChanged<int> onStepsChanged;
  final VoidCallback onNext;

  const _BodyPage({
    required this.heightCm,
    required this.weightKg,
    required this.weightGoalKg,
    required this.stepsGoal,
    required this.unitSystem,
    required this.sex,
    required this.birthDate,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onGoalWeightChanged,
    required this.onStepsChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final age = birthDate != null
        ? DateTime.now().difference(birthDate!).inDays ~/ 365
        : 25;
    final waterGoal = WaterCalculator.recommendedMl(weightKg, age, sex);
    final waterMin = WaterCalculator.minimumMl(weightKg, sex);
    final waterMax = WaterCalculator.maximumMl(weightKg);

    return _OnboardingPage(
      title: 'Körper & Fitness',
      buttonLabel: 'Weiter',
      onButton: onNext,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderField(
            label: 'Körpergröße',
            value: heightCm,
            min: 120,
            max: 230,
            unit: 'cm',
            onChanged: onHeightChanged,
          ),
          _SliderField(
            label: 'Körpergewicht',
            value: weightKg,
            min: 30,
            max: 250,
            unit: 'kg',
            onChanged: onWeightChanged,
          ),
          _SliderField(
            label: 'Zielgewicht (optional)',
            value: weightGoalKg,
            min: 30,
            max: 250,
            unit: 'kg',
            onChanged: onGoalWeightChanged,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tägliches Schrittziel',
                style: TextStyle(
                  fontSize: 14,
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                ),
              ),
              Text(
                '$stepsGoal Schritte',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TraumColors.coralOrange,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
          Slider(
            value: stepsGoal.toDouble(),
            min: 2000,
            max: 20000,
            divisions: 18,
            activeColor: TraumColors.coralOrange,
            onChanged: (v) => onStepsChanged(v.toInt()),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TraumColors.cyanDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dein Wasserziel (automatisch berechnet)',
                  style: TextStyle(
                    fontSize: 12,
                    color: TraumColors.cyanBlue,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ziel: $waterGoal ml · Minimum: $waterMin ml · Maximum: $waterMax ml',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min, max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} $unit',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TraumColors.coralOrange,
                fontFamily: 'DMSans',
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: TraumColors.coralOrange,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// Nutrition
class _NutritionPage extends StatelessWidget {
  final int kcalGoal, proteinGoal;
  final ValueChanged<int> onKcalChanged, onProteinChanged;
  final VoidCallback onNext;

  const _NutritionPage({
    required this.kcalGoal,
    required this.proteinGoal,
    required this.onKcalChanged,
    required this.onProteinChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Ernährung',
      buttonLabel: 'Weiter',
      onButton: onNext,
      content: Column(
        children: [
          _SliderField(
            label: 'Kalorienziel',
            value: kcalGoal.toDouble(),
            min: 1000,
            max: 5000,
            unit: 'kcal',
            onChanged: (v) => onKcalChanged(v.toInt()),
          ),
          _SliderField(
            label: 'Proteinziel',
            value: proteinGoal.toDouble(),
            min: 40,
            max: 300,
            unit: 'g',
            onChanged: (v) => onProteinChanged(v.toInt()),
          ),
        ],
      ),
    );
  }
}

// Supplements (simplified)
class _SupplementsPage extends StatelessWidget {
  final VoidCallback onNext, onSkip;
  const _SupplementsPage({required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Supplements',
      content: Column(
        children: [
          const Text(
            'Nimmst du Supplements? Du kannst diese später in der App hinzufügen.',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(label: 'Weiter', onPressed: onNext),
          const SizedBox(height: 8),
          TextButton(onPressed: onSkip, child: const Text('Überspringen')),
        ],
      ),
    );
  }
}

// Medication (simplified)
class _MedicationPage extends StatelessWidget {
  final VoidCallback onNext, onSkip;
  const _MedicationPage({required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Medikamente',
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TraumColors.roseRedDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Diese App ersetzt keine ärztliche Beratung.',
              style: TextStyle(
                color: TraumColors.roseRed,
                fontFamily: 'DMSans',
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Du kannst deine Medikamente später in der App hinzufügen.',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(label: 'Weiter', onPressed: onNext),
          const SizedBox(height: 8),
          TextButton(onPressed: onSkip, child: const Text('Überspringen')),
        ],
      ),
    );
  }
}

// Budget
class _BudgetPage extends StatelessWidget {
  final String currencySymbol;
  final double monthlyBudget;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<double> onBudgetChanged;
  final VoidCallback onNext, onSkip;

  const _BudgetPage({
    required this.currencySymbol,
    required this.monthlyBudget,
    required this.onCurrencyChanged,
    required this.onBudgetChanged,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Budget',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Möchtest du dein Budget im Blick behalten?',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _SliderField(
            label: 'Monatliches Budget',
            value: monthlyBudget,
            min: 100,
            max: 10000,
            unit: currencySymbol,
            onChanged: onBudgetChanged,
          ),
          const SizedBox(height: 24),
          GradientButton(label: 'Weiter', onPressed: onNext),
          const SizedBox(height: 8),
          TextButton(onPressed: onSkip, child: const Text('Überspringen')),
        ],
      ),
    );
  }
}

// Cycle
class _CyclePage extends StatelessWidget {
  final int avgCycleLength, avgPeriodLength;
  final DateTime? lastPeriodStart;
  final ValueChanged<int> onCycleLengthChanged, onPeriodLengthChanged;
  final ValueChanged<DateTime> onLastPeriodChanged;
  final VoidCallback onNext, onSkip;

  const _CyclePage({
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.lastPeriodStart,
    required this.onCycleLengthChanged,
    required this.onPeriodLengthChanged,
    required this.onLastPeriodChanged,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Dein Zyklus',
      content: Column(
        children: [
          _SliderField(
            label: 'Zykluslänge (Tage)',
            value: avgCycleLength.toDouble(),
            min: 21,
            max: 40,
            unit: 'T',
            onChanged: (v) => onCycleLengthChanged(v.toInt()),
          ),
          _SliderField(
            label: 'Periodenlänge (Tage)',
            value: avgPeriodLength.toDouble(),
            min: 2,
            max: 10,
            unit: 'T',
            onChanged: (v) => onPeriodLengthChanged(v.toInt()),
          ),
          const SizedBox(height: 24),
          GradientButton(label: 'Weiter', onPressed: onNext),
          const SizedBox(height: 8),
          TextButton(onPressed: onSkip, child: const Text('Überspringen')),
        ],
      ),
    );
  }
}

// Navigation
class _NavPage extends StatelessWidget {
  final String sex;
  final VoidCallback onNext;

  const _NavPage({required this.sex, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Navigation anpassen',
      buttonLabel: 'Weiter',
      onButton: onNext,
      content: const Text(
        'Home ist immer links fest. Du kannst 1–4 weitere Module in die Navigation legen. '
        'Du kannst die Navigation jederzeit im "Mehr"-Menü anpassen.',
        style: TextStyle(
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}

// Weather
class _WeatherPage extends StatelessWidget {
  final VoidCallback onNext;
  const _WeatherPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Wetter-Standort',
      content: Column(
        children: [
          const Text(
            'TRAUM kann das aktuelle Wetter auf der Startseite anzeigen.',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Standort automatisch',
            onPressed: onNext,
            icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onNext, child: const Text('Überspringen')),
        ],
      ),
    );
  }
}

// Notifications
class _NotificationsPage extends StatelessWidget {
  final VoidCallback onNext;
  const _NotificationsPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Benachrichtigungen',
      content: Column(
        children: [
          const Text(
            'Erlaube Benachrichtigungen um Erinnerungen für Medikamente, Wasser, Workouts und mehr zu erhalten.',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Benachrichtigungen erlauben',
            onPressed: () async {
              await Permission.notification.request();
              onNext();
            },
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onNext, child: const Text('Nicht jetzt')),
        ],
      ),
    );
  }
}

// Health Connect
class _HealthPage extends StatelessWidget {
  final VoidCallback onNext;
  const _HealthPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Fitness-Daten verbinden',
      content: Column(
        children: [
          const Text(
            'Verbinde Health Connect (Android) oder Apple Health (iOS) um Schritte, '
            'Schlaf und Herzfrequenz automatisch zu importieren.',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Zugriff erlauben & importieren',
            gradient: TraumColors.gradientCool,
            onPressed: onNext,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onNext, child: const Text('Überspringen')),
        ],
      ),
    );
  }
}

// Done
class _DonePage extends StatelessWidget {
  final String name;
  final int kcalGoal, waterGoal;
  final VoidCallback onFinish;

  const _DonePage({
    required this.name,
    required this.kcalGoal,
    required this.waterGoal,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      title: 'Alles bereit!',
      buttonLabel: 'Los geht\'s',
      onButton: onFinish,
      content: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: TraumColors.gradientWarm,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          if (name.isNotEmpty)
            Text(
              'Willkommen, $name!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Kalorienziel: $kcalGoal kcal · Wasserziel: $waterGoal ml',
            style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Alle Daten bleiben auf deinem Gerät.',
            style: TextStyle(
              color: TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
