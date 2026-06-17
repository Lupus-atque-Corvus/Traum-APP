import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  Transaction? _transaction;
  List<BudgetCategory> _categories = [];
  bool _loading = true;
  bool _editingNote = false;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dao = ref.read(budgetDaoProvider);
    final tx = await dao.getTransaction(widget.transactionId);
    final cats = await dao.getAllCategories();
    if (mounted) {
      setState(() {
        _transaction = tx;
        _categories = cats;
        _noteCtrl.text = tx?.note ?? '';
        _loading = false;
      });
    }
  }

  BudgetCategory? get _category => _transaction?.categoryId != null
      ? _categories.cast<BudgetCategory?>().firstWhere(
          (c) => c?.id == _transaction!.categoryId,
          orElse: () => null)
      : null;

  /// Build a full companion from the current transaction, overriding only
  /// the specified fields. Drift's replace() sets absent fields to table
  /// defaults, so we must supply every non-default column explicitly.
  TransactionsCompanion _fullCompanion({
    String? noteOverride,
    bool clearNote = false,
    String? templateNameOverride,
  }) {
    final tx = _transaction!;
    return TransactionsCompanion(
      id: Value(tx.id),
      amount: Value(tx.amount),
      description: Value(tx.description),
      categoryId: Value(tx.categoryId),
      type: Value(tx.type),
      date: Value(tx.date),
      note: clearNote
          ? const Value(null)
          : noteOverride != null
              ? Value(noteOverride)
              : Value(tx.note),
      receiptImagePath: Value(tx.receiptImagePath),
      isRecurring: Value(tx.isRecurring),
      recurringDay: Value(tx.recurringDay),
      templateName: templateNameOverride != null
          ? Value(templateNameOverride)
          : Value(tx.templateName),
      splitFromId: Value(tx.splitFromId),
    );
  }

  Future<void> _saveAsTemplateDialog() async {
    if (_transaction == null) return;
    final nameCtrl = TextEditingController(text: _transaction!.description);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surface,
        title: const Text('Als Vorlage speichern',
            style: TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(
              color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: InputDecoration(
            hintText: 'Vorlagenname',
            hintStyle: const TextStyle(
                color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
            filled: true,
            fillColor: TraumColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen',
                style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Speichern',
                style: TextStyle(
                    color: TraumColors.amberGold, fontFamily: 'DMSans')),
          ),
        ],
      ),
    );
    if (saved == true && nameCtrl.text.trim().isNotEmpty && mounted) {
      final tx = _transaction!;
      await ref.read(budgetDaoProvider).insertTemplate(
            QuickTemplatesCompanion.insert(
              name: nameCtrl.text.trim(),
              defaultAmount: Value(tx.amount),
              categoryId: Value(tx.categoryId),
              type: tx.type,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Als Vorlage gespeichert')),
        );
      }
    }
    nameCtrl.dispose();
  }

  Future<void> _saveNote() async {
    if (_transaction == null) return;
    final dao = ref.read(budgetDaoProvider);
    final trimmed = _noteCtrl.text.trim();
    await dao.updateTransaction(
      trimmed.isEmpty
          ? _fullCompanion(clearNote: true)
          : _fullCompanion(noteOverride: trimmed),
    );
    await _load();
    setState(() => _editingNote = false);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TraumColors.surface,
        title: const Text('Transaktion löschen?',
            style: TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: const Text(
            'Diese Aktion kann nicht rückgängig gemacht werden.',
            style: TextStyle(
                color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen',
                style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen',
                style:
                    TextStyle(color: TraumColors.roseRed, fontFamily: 'DMSans')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(budgetDaoProvider).deleteTransaction(widget.transactionId);
      if (mounted) context.go('/budget');
    }
  }

  Future<void> _showSplitDialog() async {
    if (_transaction == null) return;
    final cats = _categories.where((c) => c.isExpense).toList();
    final total = _transaction!.amount;

    // Controllers for each split part (start with 2 parts)
    final parts = <_SplitPart>[
      _SplitPart(
          amountCtrl: TextEditingController(),
          categoryId: _transaction?.categoryId),
      _SplitPart(amountCtrl: TextEditingController(), categoryId: null),
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          double sumParts = 0;
          for (final p in parts) {
            sumParts +=
                double.tryParse(p.amountCtrl.text.replaceAll(',', '.')) ?? 0;
          }
          final remaining = total - sumParts;

          return AlertDialog(
            backgroundColor: TraumColors.surface,
            title: const Text('Betrag aufteilen',
                style: TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Originalbetrag: ${total.toStringAsFixed(2)} €',
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ...parts.asMap().entries.map((e) {
                    final p = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        // Category dropdown
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int?>(
                            initialValue: p.categoryId,
                            dropdownColor: TraumColors.surface,
                            style: const TextStyle(
                                color: TraumColors.onBackground,
                                fontFamily: 'DMSans',
                                fontSize: 12),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: TraumColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('—')),
                              ...cats.map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                        '${c.emoji ?? ''} ${c.name}'.trim()),
                                  )),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => p.categoryId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Amount field
                        Expanded(
                          child: TextField(
                            controller: p.amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(
                                color: TraumColors.onBackground,
                                fontFamily: 'DMSans',
                                fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: const TextStyle(
                                  color: TraumColors.onBackgroundSubtle,
                                  fontFamily: 'DMSans'),
                              filled: true,
                              fillColor: TraumColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ]),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setDialogState(() {
                      parts.add(_SplitPart(
                          amountCtrl: TextEditingController(),
                          categoryId: null));
                    }),
                    icon: const Icon(Icons.add,
                        color: TraumColors.amberGold, size: 16),
                    label: const Text('Weiteren Teil hinzufügen',
                        style: TextStyle(
                            color: TraumColors.amberGold,
                            fontFamily: 'DMSans',
                            fontSize: 12)),
                  ),
                  const Divider(color: TraumColors.surfaceVariant),
                  Text(
                    'Verbleibend: ${remaining.toStringAsFixed(2)} €',
                    style: TextStyle(
                      color: remaining.abs() < 0.01
                          ? TraumColors.mintGreen
                          : TraumColors.roseRed,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen',
                    style: TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans')),
              ),
              TextButton(
                onPressed: remaining.abs() < 0.01
                    ? () async {
                        Navigator.pop(ctx);
                        await _applySplit(parts);
                      }
                    : null,
                child: Text(
                  'Aufteilen',
                  style: TextStyle(
                    color: remaining.abs() < 0.01
                        ? TraumColors.amberGold
                        : TraumColors.onBackgroundSubtle,
                    fontFamily: 'DMSans',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Dispose controllers
    for (final p in parts) {
      p.amountCtrl.dispose();
    }
  }

  Future<void> _applySplit(List<_SplitPart> parts) async {
    if (_transaction == null) return;
    final dao = ref.read(budgetDaoProvider);

    // Mark original as split parent (full companion to avoid data loss)
    await dao.updateTransaction(
      _fullCompanion(templateNameOverride: 'SPLIT_PARENT'),
    );

    // Insert split children
    for (final part in parts) {
      final amount =
          double.tryParse(part.amountCtrl.text.replaceAll(',', '.'));
      if (amount == null || amount <= 0) continue;
      await dao.insertTransaction(TransactionsCompanion.insert(
        amount: amount,
        description: _transaction!.description,
        type: Value(_transaction!.type),
        date: _transaction!.date,
        categoryId: Value(part.categoryId),
        splitFromId: Value(_transaction!.id),
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaktion aufgeteilt')),
      );
      context.go('/budget');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);

    if (_loading) {
      return const Scaffold(
        backgroundColor: TraumColors.background,
        body: Center(
            child: CircularProgressIndicator(color: TraumColors.amberGold)),
      );
    }

    if (_transaction == null) {
      return Scaffold(
        backgroundColor: TraumColors.background,
        appBar: AppBar(
          backgroundColor: TraumColors.background,
          iconTheme: const IconThemeData(color: TraumColors.onBackground),
          elevation: 0,
        ),
        body: const Center(
          child: Text('Transaktion nicht gefunden',
              style: TextStyle(
                  color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
        ),
      );
    }

    final tx = _transaction!;
    final isIncome = tx.type == 'income';
    final cat = _category;
    final amountColor =
        isIncome ? TraumColors.mintGreen : TraumColors.roseRed;
    final amountPrefix = isIncome ? '+' : '−';

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        title: const Text(
          'Details',
          style: TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount
            Center(
              child: Text(
                '$amountPrefix${tx.amount.toStringAsFixed(2)} $currency',
                style: TextStyle(
                  color: amountColor,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Category
            if (cat != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: TraumColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${cat.emoji ?? ''} ${cat.name}'.trim(),
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 13),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Details card
            TraumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    label: 'Beschreibung',
                    value: tx.description,
                  ),
                  const Divider(
                      color: TraumColors.surfaceVariant, height: 20),
                  _DetailRow(
                    label: 'Datum',
                    value:
                        '${tx.date.day.toString().padLeft(2, '0')}.${tx.date.month.toString().padLeft(2, '0')}.${tx.date.year}'
                        ' ${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}',
                  ),
                  const Divider(
                      color: TraumColors.surfaceVariant, height: 20),
                  // Note (editable)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Notiz',
                                style: TextStyle(
                                    color: TraumColors.onBackgroundMuted,
                                    fontFamily: 'DMSans',
                                    fontSize: 12)),
                            const SizedBox(height: 4),
                            _editingNote
                                ? TextField(
                                    controller: _noteCtrl,
                                    autofocus: true,
                                    style: const TextStyle(
                                        color: TraumColors.onBackground,
                                        fontFamily: 'DMSans'),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onSubmitted: (_) => _saveNote(),
                                  )
                                : GestureDetector(
                                    onTap: () =>
                                        setState(() => _editingNote = true),
                                    child: Text(
                                      tx.note?.isNotEmpty == true
                                          ? tx.note!
                                          : 'Tippe zum Bearbeiten...',
                                      style: TextStyle(
                                        color: tx.note?.isNotEmpty == true
                                            ? TraumColors.onBackground
                                            : TraumColors.onBackgroundSubtle,
                                        fontFamily: 'DMSans',
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      if (_editingNote)
                        IconButton(
                          icon: const Icon(Icons.check_rounded,
                              color: TraumColors.mintGreen),
                          onPressed: _saveNote,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Receipt photo
            if (tx.receiptImagePath != null) ...[
              TraumCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(TraumRadius.card),
                  child: GestureDetector(
                    onTap: () => _showFullscreenPhoto(
                        context, tx.receiptImagePath!),
                    child: Image.file(
                      File(tx.receiptImagePath!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Foto nicht verfügbar',
                            style: TextStyle(
                                color: TraumColors.onBackgroundMuted,
                                fontFamily: 'DMSans')),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Split button — only for non-split-parent, non-split-child
            if (tx.templateName != 'SPLIT_PARENT' && tx.splitFromId == null)
              OutlinedButton.icon(
                onPressed: _showSplitDialog,
                icon: const Icon(Icons.call_split_rounded,
                    color: TraumColors.amberGold),
                label: const Text('Betrag aufteilen',
                    style: TextStyle(
                        color: TraumColors.amberGold,
                        fontFamily: 'DMSans')),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: TraumColors.amberGold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(TraumRadius.card),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Save as template
            OutlinedButton.icon(
              onPressed: _saveAsTemplateDialog,
              icon: const Icon(Icons.bookmark_add_outlined,
                  color: TraumColors.amberGold),
              label: const Text('Als Vorlage speichern',
                  style: TextStyle(
                      color: TraumColors.amberGold, fontFamily: 'DMSans')),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TraumColors.amberGold),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Delete button
            OutlinedButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_rounded,
                  color: TraumColors.roseRed),
              label: const Text('Löschen',
                  style: TextStyle(
                      color: TraumColors.roseRed,
                      fontFamily: 'DMSans')),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TraumColors.roseRed),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenPhoto(BuildContext context, String path) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.file(File(path)),
          ),
        ),
      ),
    ));
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SplitPart {
  final TextEditingController amountCtrl;
  int? categoryId;

  _SplitPart({required this.amountCtrl, this.categoryId});
}
