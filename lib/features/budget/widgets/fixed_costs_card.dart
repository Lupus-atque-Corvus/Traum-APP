import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/components.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../budget_providers.dart';

class FixedCostsCard extends ConsumerWidget {
  final String currency;

  const FixedCostsCard({super.key, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringTransactionsProvider);

    return recurringAsync.when(
      data: (recurring) {
        if (recurring.isEmpty) return const SizedBox.shrink();
        final now = DateTime.now();
        return TraumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.budgetFixedCosts,
                    style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Bearbeiten ›',
                      style: TextStyle(
                        color: TraumColors.amberGold,
                        fontFamily: 'DMSans',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...recurring.map((t) {
                final day = t.recurringDay ?? 1;
                final daysUntil = day - now.day;
                final _RecurringStatus status;
                if (daysUntil < 0) {
                  status = _RecurringStatus.paid;
                } else if (daysUntil <= 3) {
                  status = _RecurringStatus.upcoming;
                } else {
                  status = _RecurringStatus.pending;
                }

                final (icon, color, label) = switch (status) {
                  _RecurringStatus.paid => (
                      Icons.check_circle_rounded,
                      TraumColors.mintGreen,
                      'bezahlt'
                    ),
                  _RecurringStatus.upcoming => (
                      Icons.hourglass_bottom_rounded,
                      TraumColors.amberGold,
                      'in $daysUntil Tagen'
                    ),
                  _RecurringStatus.pending => (
                      Icons.radio_button_unchecked_rounded,
                      TraumColors.onBackgroundSubtle,
                      'ausstehend'
                    ),
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.description,
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '−${t.amount.toStringAsFixed(0)} $currency',
                      style: const TextStyle(
                        color: TraumColors.roseRed,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontFamily: 'DMSans',
                        fontSize: 11,
                      ),
                    ),
                  ]),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

enum _RecurringStatus { paid, upcoming, pending }
