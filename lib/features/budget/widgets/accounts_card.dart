import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/traum_card.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/traum_database.dart';
import '../budget_helpers.dart';
import '../budget_providers.dart';

class AccountsCard extends ConsumerWidget {
  const AccountsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final derived = ref.watch(accountDerivedBalancesProvider).value ?? const {};
    final currency = ref.watch(currencySymbolProvider);

    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text(
              'Konten',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                color: TraumColors.onBackground,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(Routes.transactionList),
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
          const SizedBox(height: 12),
          accountsAsync.when(
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      for (int i = 0; i < list.length; i++) ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              _showAccountSheet(context, account: list[i]),
                          child: _AccountRow(
                              account: list[i],
                              balance: derived[list[i].id] ?? list[i].balance,
                              currency: currency),
                        ),
                        if (i < list.length - 1)
                          Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 1,
                          ),
                      ],
                    ],
                  ),
            loading: () => const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: TraumColors.amberGold),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showAccountSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: TraumColors.surfaceVariant,
                borderRadius: BorderRadius.circular(TraumRadius.input),
              ),
              child: const Text(
                '+ Konto hinzufügen',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackgroundMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountSheet(BuildContext context, {Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAccountSheet(account: account),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final Account account;
  final double balance;
  final String currency;

  const _AccountRow(
      {required this.account, required this.balance, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isInvestment = account.type == 'investment';
    final negative = balance < 0;
    final balanceColor =
        negative ? TraumColors.roseRed : TraumColors.onBackground;

    final iconColor = switch (account.type) {
      'checking' => TraumColors.coralOrange,
      'savings' => TraumColors.cyanBlue,
      'credit' => TraumColors.indigoBlue,
      'investment' => TraumColors.lavender,
      _ => TraumColors.amberGold,
    };

    final icon = switch (account.type) {
      'checking' => Icons.account_balance_outlined,
      'savings' => Icons.savings_outlined,
      'credit' => Icons.credit_card_outlined,
      'investment' => Icons.show_chart_outlined,
      _ => Icons.wallet_outlined,
    };

    final subtitle = account.lastFour != null
        ? '${account.institution ?? ''} •••• ${account.lastFour}'
        : account.institution ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  color: TraumColors.onBackground,
                  fontSize: 14,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
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
              '${negative ? '-' : ''}$currency${fmtAmount(balance.abs())}',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                color: balanceColor,
                fontSize: 14,
              ),
            ),
            if (account.isPrimary)
              const Text(
                'Hauptkonto',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.mintGreen,
                    fontSize: 11),
              )
            else if (account.returnRate != null && isInvestment)
              Text(
                '↗ +${account.returnRate!.toStringAsFixed(1)}%',
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.mintGreen,
                    fontSize: 11),
              )
            else if (account.returnRate != null)
              Text(
                'Rendite: ${account.returnRate!.toStringAsFixed(2)}%',
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.mintGreen,
                    fontSize: 11),
              ),
          ],
        ),
      ]),
    );
  }
}

class AddAccountSheet extends ConsumerStatefulWidget {
  final Account? account;
  const AddAccountSheet({super.key, this.account});

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _lastFourCtrl = TextEditingController();
  final _returnRateCtrl = TextEditingController();
  String _type = 'checking';
  bool _isPrimary = false;
  bool _saving = false;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _nameCtrl.text = a.name;
      _institutionCtrl.text = a.institution ?? '';
      _balanceCtrl.text =
          a.balance.toStringAsFixed(2).replaceAll('.', ',');
      _lastFourCtrl.text = a.lastFour ?? '';
      if (a.returnRate != null) {
        _returnRateCtrl.text =
            a.returnRate!.toStringAsFixed(2).replaceAll('.', ',');
      }
      _type = a.type;
      _isPrimary = a.isPrimary;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _institutionCtrl.dispose();
    _balanceCtrl.dispose();
    _lastFourCtrl.dispose();
    _returnRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final balance =
        double.tryParse(_balanceCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final returnRate = _returnRateCtrl.text.trim().isNotEmpty
          ? double.tryParse(_returnRateCtrl.text.trim().replaceAll(',', '.'))
          : null;
      final lastFour =
          _type == 'credit' && _lastFourCtrl.text.trim().isNotEmpty
              ? _lastFourCtrl.text.trim()
              : null;
      final institution = _institutionCtrl.text.trim().isNotEmpty
          ? _institutionCtrl.text.trim()
          : null;
      final existing = widget.account;
      await ref.read(accountsDaoProvider).upsertAccount(
            AccountsCompanion(
              id: existing != null ? Value(existing.id) : const Value.absent(),
              name: Value(name),
              institution: Value(institution),
              type: Value(_type),
              balance: Value(balance),
              lastFour: Value(lastFour),
              returnRate: Value(returnRate),
              isPrimary: Value(_isPrimary),
              sortOrder: Value(existing?.sortOrder ?? 0),
              updatedAt: Value(DateTime.now()),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final account = widget.account;
    if (account == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konto löschen?',
            style: TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        content: Text(
          '„${account.name}" wird entfernt. Bereits erfasste Transaktionen bleiben erhalten.',
          style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackgroundMuted,
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.roseRed,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(accountsDaoProvider).deleteAccount(account.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
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
            _isEditing ? 'Konto bearbeiten' : 'Konto hinzufügen',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              color: TraumColors.onBackground,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TypeChip(
                    label: 'Girokonto',
                    value: 'checking',
                    selected: _type,
                    onTap: (v) => setState(() => _type = v)),
                const SizedBox(width: 8),
                _TypeChip(
                    label: 'Sparkonto',
                    value: 'savings',
                    selected: _type,
                    onTap: (v) => setState(() => _type = v)),
                const SizedBox(width: 8),
                _TypeChip(
                    label: 'Kreditkarte',
                    value: 'credit',
                    selected: _type,
                    onTap: (v) => setState(() => _type = v)),
                const SizedBox(width: 8),
                _TypeChip(
                    label: 'Investment',
                    value: 'investment',
                    selected: _type,
                    onTap: (v) => setState(() => _type = v)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Field(ctrl: _nameCtrl, label: 'Name *', hint: 'z.B. Girokonto'),
          const SizedBox(height: 8),
          _Field(
              ctrl: _institutionCtrl,
              label: 'Bank / Institut',
              hint: 'z.B. Sparkasse'),
          const SizedBox(height: 8),
          _Field(
              ctrl: _balanceCtrl,
              label: 'Kontostand *',
              hint: '0,00',
              keyboardType: TextInputType.number),
          if (_type == 'credit') ...[
            const SizedBox(height: 8),
            _Field(
                ctrl: _lastFourCtrl,
                label: 'Letzte 4 Stellen',
                hint: '1234',
                keyboardType: TextInputType.number),
          ],
          if (_type == 'savings' || _type == 'investment') ...[
            const SizedBox(height: 8),
            _Field(
                ctrl: _returnRateCtrl,
                label: 'Rendite %',
                hint: '3,5',
                keyboardType: TextInputType.number),
          ],
          const SizedBox(height: 8),
          Row(children: [
            const Text(
              'Als Hauptkonto markieren',
              style: TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Switch(
              value: _isPrimary,
              onChanged: (v) => setState(() => _isPrimary = v),
              activeThumbColor: TraumColors.amberGold,
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: TraumColors.amberGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(TraumRadius.button)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Speichern',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline,
                    color: TraumColors.roseRed, size: 18),
                label: const Text(
                  'Konto löschen',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.roseRed,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;

  const _TypeChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? TraumColors.amberGold.withValues(alpha: 0.2)
              : TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: TraumColors.amberGold, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DMSans',
            color: isSelected
                ? TraumColors.amberGold
                : TraumColors.onBackgroundMuted,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackground,
          fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundMuted,
            fontSize: 13),
        hintStyle: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundSubtle,
            fontSize: 13),
        filled: true,
        fillColor: TraumColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TraumRadius.input),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
