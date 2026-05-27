import 'package:flutter/material.dart';
import '../../core/components/components.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/models/substance_info.dart';

void showSubstanceDetailSheet(
  BuildContext context,
  SubstanceInfo substance, {
  VoidCallback? onAddPressed,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SubstanceDetailSheet(
      substance: substance,
      onAddPressed: onAddPressed,
    ),
  );
}

class _SubstanceDetailSheet extends StatelessWidget {
  final SubstanceInfo substance;
  final VoidCallback? onAddPressed;

  const _SubstanceDetailSheet({required this.substance, this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: TraumColors.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: substance.type == 'medication'
                      ? TraumColors.roseRedDim
                      : TraumColors.indigoBlueDim,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  substance.type == 'medication'
                      ? Icons.medication_rounded
                      : Icons.science_rounded,
                  color: substance.type == 'medication'
                      ? TraumColors.roseRed
                      : TraumColors.indigoBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(substance.name,
                      style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  Row(children: [
                    _TypeBadge(type: substance.type),
                    if (substance.evidenceGrade != null) ...[
                      const SizedBox(width: 6),
                      _EvidenceBadge(grade: substance.evidenceGrade!),
                    ],
                    if (!substance.isLocal) ...[
                      const SizedBox(width: 6),
                      _SourceBadge(),
                    ],
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            if (substance.category != null)
              _InfoRow(label: 'Kategorie', value: substance.category!),
            if (substance.atcCode != null)
              _InfoRow(label: 'ATC-Code', value: substance.atcCode!),
            if (substance.halfLife != null)
              _InfoRow(label: 'Halbwertszeit', value: substance.halfLife!),
            if (substance.mechanism != null) ...[
              const SizedBox(height: 12),
              _Section(title: 'Wirkung / Mechanismus'),
              Text(substance.mechanism!,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      height: 1.5)),
            ],
            if (substance.commonDosage != null) ...[
              const SizedBox(height: 16),
              _Section(title: 'Dosierung'),
              Text(substance.commonDosage!,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      height: 1.5)),
            ],
            if (substance.adverseEvents.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(title: 'Häufige Nebenwirkungen'),
              ...substance.adverseEvents.take(8).map((ae) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: TraumColors.coralOrange,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ae.frequencyPercent != null
                              ? '${ae.name} (${ae.frequencyPercent!.toStringAsFixed(0)}%)'
                              : ae.name,
                          style: const TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontSize: 13),
                        ),
                      ),
                    ]),
                  )),
            ],
            if (substance.interactions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(title: 'Bekannte Interaktionen'),
              ...substance.interactions.map((ix) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _severityColor(ix.severity).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(TraumRadius.chip),
                      border: Border.all(
                          color: _severityColor(ix.severity).withValues(alpha: 0.3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.warning_rounded,
                            size: 14, color: _severityColor(ix.severity)),
                        const SizedBox(width: 6),
                        Text(ix.withName,
                            style: TextStyle(
                                color: _severityColor(ix.severity),
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const Spacer(),
                        Text(ix.severity.toUpperCase(),
                            style: TextStyle(
                                color: _severityColor(ix.severity),
                                fontFamily: 'DMSans',
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 4),
                      Text(ix.description,
                          style: const TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              height: 1.4)),
                    ]),
                  )),
            ],
            const SizedBox(height: 20),
            if (onAddPressed != null)
              GradientButton(
                label: 'Zu meinen Mitteln hinzufügen',
                onPressed: onAddPressed,
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'major': return TraumColors.roseRed;
      case 'moderate': return TraumColors.coralOrange;
      default: return TraumColors.onBackgroundMuted;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isMed = type == 'medication';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isMed ? TraumColors.roseRedDim : TraumColors.indigoBlueDim,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isMed ? 'Medikament' : 'Supplement',
        style: TextStyle(
          color: isMed ? TraumColors.roseRed : TraumColors.indigoBlue,
          fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EvidenceBadge extends StatelessWidget {
  final String grade;
  const _EvidenceBadge({required this.grade});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: TraumColors.mintGreenDim,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Evidenz $grade',
            style: const TextStyle(
                color: TraumColors.mintGreen,
                fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('API',
            style: TextStyle(
                color: TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans', fontSize: 11)),
      );
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: TraumColors.onBackgroundSubtle,
                    fontFamily: 'DMSans', fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans', fontSize: 13)),
          ),
        ]),
      );
}
