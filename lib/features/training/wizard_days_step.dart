import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/repositories/plan_templates.dart';

class WizardDaysStep extends StatefulWidget {
  final PlanTemplate template;
  final Map<int, String> selectedDays; // dayOfWeek -> name
  final ValueChanged<Map<int, String>> onChanged;

  const WizardDaysStep({
    super.key,
    required this.template,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  State<WizardDaysStep> createState() => _WizardDaysStepState();
}

class _WizardDaysStepState extends State<WizardDaysStep> {
  late Map<int, String> _days;
  final _controllers = <int, TextEditingController>{};

  static const _weekLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  void initState() {
    super.initState();
    _days = Map.from(widget.selectedDays);
    for (final entry in _days.entries) {
      _controllers[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleDay(int dow) {
    setState(() {
      if (_days.containsKey(dow)) {
        _days.remove(dow);
        _controllers.remove(dow)?.dispose();
      } else {
        final defaultName = widget.template.days
            .cast<TemplateDay?>()
            .firstWhere((d) => d?.dayOfWeek == dow, orElse: () => null)
            ?.name ?? 'Training ${_weekLabels[dow - 1]}';
        _days[dow] = defaultName;
        _controllers[dow] = TextEditingController(text: defaultName);
      }
    });
    widget.onChanged(Map.from(_days));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trainingstage',
          style: TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        const SizedBox(height: 6),
        const Text(
          'Waehle die Tage und passe die Namen an.',
          style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14),
        ),
        const SizedBox(height: 20),
        // Weekday chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (i) {
            final dow = i + 1;
            final active = _days.containsKey(dow);
            return GestureDetector(
              onTap: () => _toggleDay(dow),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: active
                      ? TraumColors.coralOrange
                      : TraumColors.surface,
                  borderRadius: BorderRadius.circular(TraumRadius.chip),
                  border: Border.all(
                    color: active
                        ? TraumColors.coralOrange
                        : TraumColors.surfaceVariant,
                  ),
                ),
                child: Center(
                  child: Text(
                    _weekLabels[i],
                    style: TextStyle(
                        color: active ? Colors.white : TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_days.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Einheitennamen',
            style: TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 12,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          ...(_days.keys.toList()..sort()).map((dow) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                    color: TraumColors.coralDim, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    _weekLabels[dow - 1],
                    style: const TextStyle(
                        color: TraumColors.coralOrange,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controllers[dow],
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: TraumColors.surface,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TraumRadius.input),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  onChanged: (v) {
                    _days[dow] = v;
                    widget.onChanged(Map.from(_days));
                  },
                ),
              ),
            ]),
          )),
        ],
      ],
    );
  }
}
