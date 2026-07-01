import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'budget_helpers.dart';
import 'budget_providers.dart';
import 'budget_scale.dart';
import 'widgets/budget_sub_header.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final debts = ref.watch(allDebtsStreamProvider);
    return Scaffold(
      backgroundColor: TraumColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.roseRed,
        onPressed: () => _showAddSheet(context, ref),
        child: Icon(Icons.add_rounded, color: Colors.white, size: bs(20)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BudgetSubHeader(title: 'Schulden'),
            Expanded(
              child: debts.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        'Keine Schulden erfasst',
                        style: TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    );
                  }
                  final totalDebt = list
                      .where((d) => !d.isPaidOff)
                      .fold(0.0, (s, d) => s + d.remainingAmount);
                  final openCount = list.where((d) => !d.isPaidOff).length;
                  final paidCount = list.where((d) => d.isPaidOff).length;
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(bs(12), 0, bs(12), bs(80)),
                    itemCount: list.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _DebtsHero(
                          totalDebt: totalDebt,
                          openCount: openCount,
                          paidCount: paidCount,
                          currency: currency,
                        );
                      }
                      final debt = list[i - 1];
                      return _DebtCard(
                        debt: debt,
                        currency: currency,
                        onPay: (amt) => ref
                            .read(budgetRepositoryProvider)
                            .payDebtRate(debt.id, amt),
                        onDelete: () => ref
                            .read(budgetRepositoryProvider)
                            .deleteDebt(debt.id),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: TraumColors.roseRed),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final creditor = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          decoration: const BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schuld hinzufügen',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              debtField(creditor, 'Gläubiger *', 'z.B. Bank'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TraumColors.roseRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () {
                    final c = creditor.text.trim();
                    if (c.isEmpty) return;
                    ref.read(budgetRepositoryProvider).addDebt(
                          DebtsCompanion.insert(
                            creditor: c,
                            originalAmount: 0,
                            remainingAmount: 0,
                          ),
                        );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text(
                    'Speichern',
                    style: TextStyle(
                        fontFamily: 'DMSans', fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget debtField(
    TextEditingController c,
    String label,
    String hint, {
    bool number = false,
  }) =>
      TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackground,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: TraumColors.surfaceVariant,
          labelStyle: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundMuted,
            fontSize: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

// ---------------------------------------------------------------------------
// Hero summary
// ---------------------------------------------------------------------------

class _DebtsHero extends StatelessWidget {
  final double totalDebt;
  final int openCount;
  final int paidCount;
  final String currency;

  const _DebtsHero({
    required this.totalDebt,
    required this.openCount,
    required this.paidCount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: bs(10)),
        padding: EdgeInsets.all(bs(12)),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(bs(13)),
          border: Border.all(
            color: TraumColors.roseRed.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offene Schulden gesamt',
              style: TextStyle(
                fontSize: 9,
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
              ),
            ),
            SizedBox(height: bs(2)),
            Text(
              '${fmtAmount(totalDebt)} $currency',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: TraumColors.roseRed,
                fontFamily: 'DMSans',
              ),
            ),
            SizedBox(height: bs(2)),
            Text(
              '$openCount offen · $paidCount beglichen',
              style: const TextStyle(
                fontSize: 9,
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Debt card
// ---------------------------------------------------------------------------

class _DebtCard extends ConsumerStatefulWidget {
  final Debt debt;
  final String currency;
  final void Function(double) onPay;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.currency,
    required this.onPay,
    required this.onDelete,
  });

  @override
  ConsumerState<_DebtCard> createState() => _DebtCardState();
}

class _DebtCardState extends ConsumerState<_DebtCard> {
  bool _expanded = false;

  static const IconData _defaultIcon = Icons.account_balance_rounded;

  Color get _accentColor =>
      widget.debt.isPaidOff ? TraumColors.mintGreen : TraumColors.roseRed;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(debtItemsStreamProvider(widget.debt.id));
    final items = itemsAsync.value ?? const <DebtItem>[];
    final l10n = AppLocalizations.of(context)!;
    final ratio = widget.debt.originalAmount > 0
        ? (1 - widget.debt.remainingAmount / widget.debt.originalAmount)
            .clamp(0.0, 1.0)
        : 0.0;
    final paidAmount = widget.debt.originalAmount - widget.debt.remainingAmount;
    final paidPct = (ratio * 100).round();

    return Dismissible(
      key: ValueKey(widget.debt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: bs(20)),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(bs(15)),
        ),
        child: Icon(Icons.delete_outline,
            color: TraumColors.roseRed, size: bs(22)),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: Container(
        margin: EdgeInsets.only(bottom: bs(9)),
        padding: EdgeInsets.all(bs(13)),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(bs(15)),
          border: Border.all(
            color: widget.debt.isPaidOff
                ? TraumColors.mintGreen.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ──────────────────────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container 38×38, radius 10
                  Container(
                    width: bs(38),
                    height: bs(38),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(bs(10)),
                    ),
                    child: Icon(
                      _defaultIcon,
                      size: bs(16),
                      color: _accentColor,
                    ),
                  ),
                  SizedBox(width: bs(10)),
                  // Name + item count subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.debt.creditor,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: TraumColors.onBackground,
                          ),
                        ),
                        SizedBox(height: bs(2)),
                        Text(
                          l10n.debtTotalFromItems(items.length),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 9,
                            color: TraumColors.onBackgroundMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: bs(8)),
                  // Right side: remaining amount OR paid badge
                  widget.debt.isPaidOff
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: bs(14), color: TraumColors.mintGreen),
                            SizedBox(width: bs(4)),
                            const Text(
                              'Bezahlt',
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: TraumColors.mintGreen,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${fmtAmount(widget.debt.remainingAmount)} ${widget.currency}',
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: TraumColors.roseRed,
                              ),
                            ),
                            const Text(
                              'offen',
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 9,
                                color: TraumColors.onBackgroundMuted,
                              ),
                            ),
                          ],
                        ),
                  SizedBox(width: bs(6)),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: bs(18),
                    color: TraumColors.onBackgroundMuted,
                  ),
                ],
              ),
            ),
            // ── Progress bar ─────────────────────────────────────────────
            if (!widget.debt.isPaidOff) ...[
              SizedBox(height: bs(10)),
              ClipRRect(
                borderRadius: BorderRadius.circular(bs(3)),
                child: SizedBox(
                  height: bs(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: TraumColors.surfaceVariant,
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.transparent),
                  ),
                ),
              ),
              // Overlay the gradient fill on top of the progress track
              Transform.translate(
                offset: Offset(0, -bs(6)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(bs(3)),
                  child: SizedBox(
                    height: bs(6),
                    child: LayoutBuilder(
                      builder: (ctx, constraints) => Stack(
                        children: [
                          Container(
                            width: constraints.maxWidth,
                            color: TraumColors.surfaceVariant,
                          ),
                          Container(
                            width: constraints.maxWidth * ratio,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  TraumColors.mintGreen,
                                  TraumColors.amberGold,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // ── Footer ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$paidPct% getilgt · ${fmtAmount(paidAmount)} ${widget.currency} bezahlt',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 9,
                      color: TraumColors.mintGreen,
                    ),
                  ),
                  // "Rate zahlen" pill
                  GestureDetector(
                    onTap: () => _payDialog(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: bs(10), vertical: bs(5)),
                      decoration: BoxDecoration(
                        color: TraumColors.roseRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(bs(8)),
                      ),
                      child: const Text(
                        'Rate zahlen',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: TraumColors.roseRed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // ── Expandable items section ──────────────────────────────────
            if (_expanded) ...[
              SizedBox(height: bs(10)),
              Container(
                  height: 1, color: Colors.white.withValues(alpha: 0.06)),
              SizedBox(height: bs(6)),
              ...items.map((item) => _DebtItemRow(
                    item: item,
                    currency: widget.currency,
                    onDelete: () => ref
                        .read(budgetRepositoryProvider)
                        .deleteDebtItem(item.id),
                    onEdit: () => _showItemSheet(context, item: item),
                  )),
              GestureDetector(
                onTap: () => _showItemSheet(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: bs(8)),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded,
                          size: bs(16), color: TraumColors.roseRed),
                      SizedBox(width: bs(6)),
                      Text(
                        l10n.addDebtItem,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TraumColors.roseRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _payDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surface,
        title: const Text(
          'Rate zahlen',
          style: TextStyle(
              fontFamily: 'DMSans', color: TraumColors.onBackground),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(
              fontFamily: 'DMSans', color: TraumColors.onBackground),
          decoration: const InputDecoration(hintText: '0,00'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final a =
                  double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ??
                      0;
              if (a > 0) widget.onPay(a);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showItemSheet(BuildContext context, {DebtItem? item}) {
    final desc = TextEditingController(text: item?.description ?? '');
    final price = TextEditingController(
        text: item == null ? '' : fmtAmount(item.amount));
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          decoration: const BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.addDebtItem,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              DebtsScreen.debtField(desc, l10n.debtItemDescription, ''),
              const SizedBox(height: 8),
              DebtsScreen.debtField(price, l10n.debtItemPrice, '0,00',
                  number: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TraumColors.roseRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () {
                    final d = desc.text.trim();
                    final a = double.tryParse(
                            price.text.trim().replaceAll(',', '.')) ??
                        0;
                    if (d.isEmpty || a <= 0) return;
                    final repo = ref.read(budgetRepositoryProvider);
                    if (item == null) {
                      repo.addDebtItem(DebtItemsCompanion.insert(
                          debtId: widget.debt.id,
                          description: d,
                          amount: a));
                    } else {
                      repo.updateDebtItem(DebtItemsCompanion(
                        id: Value(item.id),
                        debtId: Value(item.debtId),
                        description: Value(d),
                        amount: Value(a),
                        createdAt: Value(item.createdAt),
                      ));
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: const Text(
                    'Speichern',
                    style: TextStyle(
                        fontFamily: 'DMSans', fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debt item row
// ---------------------------------------------------------------------------

class _DebtItemRow extends StatelessWidget {
  final DebtItem item;
  final String currency;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _DebtItemRow({
    required this.item,
    required this.currency,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => Dismissible(
        key: ValueKey('item_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: bs(12)),
          child: Icon(Icons.delete_outline,
              color: TraumColors.roseRed, size: bs(18)),
        ),
        onDismissed: (_) => onDelete(),
        child: GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: bs(6)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: TraumColors.onBackground,
                    ),
                  ),
                ),
                Text(
                  '${fmtAmount(item.amount)} $currency',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TraumColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
