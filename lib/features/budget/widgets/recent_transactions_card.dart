import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/traum_card.dart';
import '../../../core/theme/colors.dart';
import '../budget_helpers.dart';
import '../budget_providers.dart';

class RecentTransactionsCard extends ConsumerWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(recentTransactionItemsProvider(5));

    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text(
              'Letzte Transaktionen',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                color: TraumColors.onBackground,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/budget/transactions'),
              child: const Text(
                'Mehr ›',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.amberGold,
                  fontSize: 13,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          itemsAsync.when(
            data: (items) => Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _TransactionRow(
                    item: items[i],
                    onTap: () =>
                        context.go('/budget/transaction/${items[i].tx.id}'),
                  ),
                  if (i < items.length - 1)
                    Divider(
                        color: Colors.white.withValues(alpha: 0.06),
                        height: 1),
                ],
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: TraumColors.amberGold),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final RecentTransactionItem item;
  final VoidCallback? onTap;

  const _TransactionRow({required this.item, this.onTap});

  static const _fallbackColors = [
    TraumColors.coralOrange,
    TraumColors.mintGreen,
    TraumColors.cyanBlue,
    TraumColors.lavender,
    TraumColors.amberGold,
  ];

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == 'income';
    final amountColor =
        isIncome ? TraumColors.mintGreen : TraumColors.onBackground;
    final amountPrefix = isIncome ? '+' : '−';

    final catColor = item.category?.color != null
        ? Color(item.category!.color!)
        : _fallbackColors[
            (item.tx.categoryId ?? 0) % _fallbackColors.length];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.category?.emoji ?? '💰',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    color: TraumColors.onBackground,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.categoryName,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix€${fmtAmount(item.amount.abs())}',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                  fontSize: 14,
                ),
              ),
              Text(
                fmtTransactionDate(item.date),
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackgroundMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
