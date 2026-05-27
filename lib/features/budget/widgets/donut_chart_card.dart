import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/components/components.dart';
import '../../../core/theme/colors.dart';
import '../budget_providers.dart';

class DonutChartCard extends StatefulWidget {
  final List<CategoryExpense> expenses;
  final String currency;
  final void Function(String? categoryName)? onSegmentTap;

  const DonutChartCard({
    super.key,
    required this.expenses,
    required this.currency,
    this.onSegmentTap,
  });

  @override
  State<DonutChartCard> createState() => _DonutChartCardState();
}

class _DonutChartCardState extends State<DonutChartCard> {
  int? _touchedIndex;

  static const _segmentColors = [
    TraumColors.amberGold,
    TraumColors.coralOrange,
    TraumColors.lavender,
    TraumColors.mintGreen,
    TraumColors.cyanBlue,
    TraumColors.roseRed,
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.expenses.isEmpty) return const SizedBox.shrink();

    final total =
        widget.expenses.fold(0.0, (s, e) => s + e.amount);

    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ausgaben nach Kategorie',
                style: TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} ${widget.currency}',
                style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 44,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (response?.touchedSection != null &&
                              event.isInterestedForInteractions) {
                            _touchedIndex = response!
                                .touchedSection!.touchedSectionIndex;
                            if (widget.onSegmentTap != null) {
                              widget.onSegmentTap!(widget
                                  .expenses[_touchedIndex!].category.name);
                            }
                          } else {
                            _touchedIndex = null;
                            widget.onSegmentTap?.call(null);
                          }
                        });
                      },
                    ),
                    sections: List.generate(widget.expenses.length, (i) {
                      final exp = widget.expenses[i];
                      final color =
                          _segmentColors[i % _segmentColors.length];
                      final isTouched = i == _touchedIndex;
                      return PieChartSectionData(
                        value: exp.amount,
                        color: color,
                        radius: isTouched ? 38 : 32,
                        title: '',
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    widget.expenses.length.clamp(0, 5),
                    (i) {
                      final exp = widget.expenses[i];
                      final color =
                          _segmentColors[i % _segmentColors.length];
                      final pct = total > 0
                          ? (exp.amount / total * 100)
                              .toStringAsFixed(0)
                          : '0';
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              exp.category.name,
                              style: const TextStyle(
                                color: TraumColors.onBackgroundMuted,
                                fontFamily: 'DMSans',
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${exp.amount.toStringAsFixed(0)} ${widget.currency}',
                            style: const TextStyle(
                              color: TraumColors.onBackground,
                              fontFamily: 'DMSans',
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontSize: 10,
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
