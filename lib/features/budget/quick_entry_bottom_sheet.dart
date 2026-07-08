import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../data/services/recurring_poster.dart';
import '../../l10n/app_localizations.dart';
import 'budget_category_icons.dart';
import 'budget_helpers.dart';
import 'budget_providers.dart';
import 'budget_scale.dart';
import 'receipt_scanner.dart';
import 'widgets/numpad_widget.dart';

class QuickEntryBottomSheet extends ConsumerStatefulWidget {
  final QuickTemplate? initialTemplate;
  final Transaction? editTransaction;

  const QuickEntryBottomSheet({
    super.key,
    this.initialTemplate,
    this.editTransaction,
  });

  @override
  ConsumerState<QuickEntryBottomSheet> createState() =>
      _QuickEntryBottomSheetState();
}

class _QuickEntryBottomSheetState extends ConsumerState<QuickEntryBottomSheet> {
  String _type = 'expense';
  String _numpadValue = '';
  DateTime _date = DateTime.now();
  int? _categoryId;
  String? _categoryName;
  final _descCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool get _isEditing => widget.editTransaction != null;
  String? _receiptImagePath;
  bool _saveAsTemplate = false;
  final _templateNameCtrl = TextEditingController();
  int? _accountId;
  int? _toAccountId;
  bool _saving = false;
  bool _scanning = false;
  bool _recurring = false;
  int _recurringDay = 1;
  QuickTemplate? _appliedTemplate;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTemplate;
    if (t != null) {
      _type = t.type;
      _categoryId = t.categoryId;
      _templateNameCtrl.text = t.name;
      if (t.defaultAmount != null) {
        _numpadValue = t.defaultAmount!
            .toStringAsFixed(2)
            .replaceAll('.', ',');
      }
    }

    final e = widget.editTransaction;
    if (e != null) {
      _type = e.type;
      _numpadValue = e.amount.toStringAsFixed(2).replaceAll('.', ',');
      _categoryId = e.categoryId;
      _date = e.date;
      _descCtrl.text = e.description;
      _noteCtrl.text = e.note ?? '';
      _receiptImagePath = e.receiptImagePath;
      _accountId = e.accountId;
      _toAccountId = e.toAccountId;
      _recurring = e.isRecurring;
      _recurringDay = e.recurringDay ?? 1;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _noteCtrl.dispose();
    _templateNameCtrl.dispose();
    super.dispose();
  }

  double? get _parsedAmount {
    if (_numpadValue.isEmpty) return null;
    return double.tryParse(_numpadValue.replaceAll(',', '.'));
  }

  String _formatDisplay(String raw) {
    if (raw.isEmpty) return '0,00';
    if (raw.endsWith(',')) return '$raw—'; // Komma gerade eingegeben
    if (raw.contains(',')) {
      final parts = raw.split(',');
      final euros = parts[0].replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]}.');
      final cents = parts[1].padRight(2, '0');
      return '$euros,$cents';
    }
    return raw.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  void _setDateChip(DateTime date) => setState(() => _date = date);

  Future<void> _scanReceipt(ImageSource source) async {
    setState(() => _scanning = true);
    try {
      final result = source == ImageSource.camera
          ? await ReceiptScanner.scanFromCamera()
          : await ReceiptScanner.scanFromGallery();
      if (result != null) {
        setState(() {
          _receiptImagePath = result.imagePath;
          if (result.detectedAmount != null) {
            _numpadValue = result.detectedAmount!
                .toStringAsFixed(2)
                .replaceAll('.', ',');
          }
          if (result.detectedDate != null) {
            _date = result.detectedDate!;
          }
          if (result.detectedMerchant != null && _noteCtrl.text.isEmpty) {
            _noteCtrl.text = result.detectedMerchant!;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _showReceiptSourceDialog() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TraumRadius.card),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: TraumColors.amberGold),
              title: Text(
                l10n.budgetCamera,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _scanReceipt(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: TraumColors.amberGold),
              title: Text(
                l10n.budgetGallery,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _scanReceipt(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_type == 'transfer') {
      if (_accountId == null || _toAccountId == null || _accountId == _toAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.budgetTransferAccountsRequired)));
        return;
      }
    }

    final amount = _parsedAmount;
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.budgetInvalidAmount),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final isDef = _recurring && _type != 'transfer';
    try {
      final accounts = ref.read(accountsStreamProvider).value ?? const [];
      final effectiveAccount = _type == 'transfer'
          ? _accountId
          : (_accountId ??
              (accounts.where((a) => a.isPrimary).isNotEmpty
                  ? accounts.firstWhere((a) => a.isPrimary).id
                  : null));

      final description = _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : (_categoryName ??
              (_type == 'expense'
                  ? l10n.budgetDefaultDescriptionExpense
                  : _type == 'income'
                      ? l10n.budgetDefaultDescriptionIncome
                      : l10n.budgetTransferLabel));
      final note =
          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

      if (_isEditing) {
        await ref.read(budgetDaoProvider).updateTransaction(
              fullTransactionCompanion(widget.editTransaction!).copyWith(
                amount: Value(amount),
                description: Value(description),
                type: Value(_type),
                date: Value(_date),
                categoryId: Value(_type == 'transfer' ? null : _categoryId),
                note: Value(note),
                receiptImagePath: Value(_receiptImagePath),
                accountId: Value(effectiveAccount),
                toAccountId: Value(_type == 'transfer' ? _toAccountId : null),
                isRecurring: Value(isDef),
                recurringDay: Value(isDef ? _recurringDay : null),
              ),
            );
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      await ref.read(budgetDaoProvider).insertTransaction(
            TransactionsCompanion.insert(
              amount: amount,
              description: description,
              type: Value(_type),
              date: _date,
              categoryId: Value(_type == 'transfer' ? null : _categoryId),
              note: Value(note),
              receiptImagePath: Value(_receiptImagePath),
              accountId: Value(effectiveAccount),
              toAccountId: Value(_type == 'transfer' ? _toAccountId : null),
              isRecurring: Value(isDef),
              recurringDay: Value(isDef ? _recurringDay : null),
              lastPostedMonth: const Value(null),
            ),
          );

      if (_saveAsTemplate && _templateNameCtrl.text.trim().isNotEmpty) {
        await ref.read(budgetDaoProvider).insertTemplate(
              QuickTemplatesCompanion.insert(
                name: _templateNameCtrl.text.trim(),
                defaultAmount: Value(amount),
                categoryId: Value(_categoryId),
                type: _type,
              ),
            );
      }

      if (widget.initialTemplate != null) {
        await ref
            .read(budgetDaoProvider)
            .incrementTemplateUsage(widget.initialTemplate!.id, amount);
      }

      if (_appliedTemplate != null) {
        await ref.read(budgetDaoProvider)
            .incrementTemplateUsage(_appliedTemplate!.id, amount);
      }

      if (isDef) {
        await RecurringPoster.runIfNeeded(ref.read(databaseProvider));
      }

      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(allBudgetCategoriesStreamProvider);
    final currency = ref.watch(currencySymbolProvider);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBefore = today.subtract(const Duration(days: 2));

    final isToday = isSameDay(_date, today);
    final isYesterday = isSameDay(_date, yesterday);
    final isDayBefore = isSameDay(_date, dayBefore);

    // Step 1: Container — sheetBg, radius 22, border-top white@0.08, max 91%
    return BudgetTextScale(
      child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.91,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: TraumColors.sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(bs(22))),
          border: Border(
            top: BorderSide(
              color: TraumColors.onBackground.withValues(alpha: 0.08),
              width: bs(1),
            ),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Step 2: Grabber — 32×3, dimBar, margin bottom 10
              Padding(
                padding: EdgeInsets.only(top: bs(10), bottom: bs(10)),
                child: Center(
                  child: Container(
                    width: bs(32),
                    height: bs(3),
                    decoration: BoxDecoration(
                      color: TraumColors.dimBar,
                      borderRadius: BorderRadius.circular(bs(2)),
                    ),
                  ),
                ),
              ),

              // Step 3: Title row — "Hinzufügen" + close button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: bs(16)),
                child: Row(
                  children: [
                    Text(
                      _isEditing ? l10n.edit : l10n.add,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: TraumColors.onBackground,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: bs(26),
                        height: bs(26),
                        decoration: BoxDecoration(
                          color: TraumColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(bs(13)),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close,
                            size: bs(12),
                            color: TraumColors.onBackgroundMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: bs(10)),

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: bs(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Step 4: Type toggle — segmented, solid fills
                      _SegmentedTypeToggle(
                        selected: _type,
                        onChanged: (v) => setState(() => _type = v),
                        labels: (
                          expense: l10n.budgetTypeExpense,
                          income: l10n.budgetTypeIncome,
                          transfer: l10n.budgetTypeTransfer,
                        ),
                      ),
                      SizedBox(height: bs(16)),

                      // Step 5: Amount display — "Betrag" label + 34/w700 amount
                      Column(
                        children: [
                          Text(
                            l10n.budgetAmountLabel,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 8,
                              color: TraumColors.onBackgroundMuted,
                            ),
                          ),
                          SizedBox(height: bs(2)),
                          Text(
                            '${_formatDisplay(_numpadValue)} $currency',
                            style: TextStyle(
                              color: _type == 'income'
                                  ? TraumColors.mintGreen
                                  : _type == 'transfer'
                                      ? TraumColors.indigoBlue
                                      : TraumColors.onBackground,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 34,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: bs(12)),

                      // Numpad or scanning indicator
                      if (_scanning)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: bs(16)),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                    color: TraumColors.amberGold),
                                SizedBox(height: bs(8)),
                                Text(
                                  l10n.budgetScanningReceipt,
                                  style: const TextStyle(
                                    color: TraumColors.onBackgroundMuted,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        NumpadWidget(
                          displayValue: _numpadValue,
                          onChanged: (v) => setState(() => _numpadValue = v),
                        ),
                      SizedBox(height: bs(14)),

                      // Step 6: Template chips — amberGold@0.1 bg, border amberGold@0.35,
                      //           radius 18, padding 5×10, zap icon 11
                      if (_type != 'transfer')
                        Consumer(builder: (ctx, r, _) {
                          final tpls = r.watch(quickTemplatesProvider).value ?? const [];
                          if (tpls.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(bottom: bs(12)),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: [
                                for (final t in tpls) ...[
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _appliedTemplate = t;
                                      _type = t.type;
                                      _categoryId = t.categoryId;
                                      if (t.defaultAmount != null) {
                                        _numpadValue = t.defaultAmount!
                                            .toStringAsFixed(2)
                                            .replaceAll('.', ',');
                                      }
                                    }),
                                    onLongPress: () =>
                                        ref.read(budgetDaoProvider).deleteTemplate(t.id),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: bs(10), vertical: bs(5)),
                                      decoration: BoxDecoration(
                                        color: TraumColors.amberGold.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(bs(18)),
                                        border: Border.all(
                                            color: TraumColors.amberGold.withValues(alpha: 0.35)),
                                      ),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.bolt_rounded,
                                            size: bs(11), color: TraumColors.amberGold),
                                        SizedBox(width: bs(4)),
                                        Text(
                                          t.name,
                                          style: const TextStyle(
                                            fontFamily: 'DMSans',
                                            color: TraumColors.amberGold,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ),
                                  SizedBox(width: bs(8)),
                                ],
                              ]),
                            ),
                          );
                        }),

                      // Step 7: Category chips — horizontal scroll row, 50px wide column-chips
                      if (_type != 'transfer')
                        categoriesAsync.when(
                          data: (cats) {
                            final filtered = cats
                                .where((c) => c.isExpense == (_type == 'expense'))
                                .toList();
                            if (filtered.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: EdgeInsets.only(bottom: bs(12)),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (int i = 0; i < filtered.length; i++) ...[
                                      _CategoryColumnChip(
                                        cat: filtered[i],
                                        isSelected: _categoryId == filtered[i].id,
                                        onTap: () => setState(() {
                                          final isSelected = _categoryId == filtered[i].id;
                                          _categoryId = isSelected ? null : filtered[i].id;
                                          _categoryName = isSelected ? null : filtered[i].name;
                                        }),
                                      ),
                                      SizedBox(width: bs(6)),
                                    ],
                                    // "+ Neu" tile
                                    GestureDetector(
                                      onTap: () {
                                        final router = GoRouter.of(context);
                                        Navigator.of(context).pop();
                                        router.push('/budget/categories');
                                      },
                                      child: Container(
                                        width: bs(50),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: bs(3), vertical: bs(7)),
                                        decoration: BoxDecoration(
                                          color: TraumColors.background,
                                          borderRadius: BorderRadius.circular(bs(10)),
                                          border: Border.all(
                                            color: TraumColors.amberGold.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_rounded,
                                              color: TraumColors.amberGold,
                                              size: bs(18),
                                            ),
                                            SizedBox(height: bs(2)),
                                            Text(
                                              l10n.budgetNewCategoryTile,
                                              style: const TextStyle(
                                                color: TraumColors.amberGold,
                                                fontFamily: 'DMSans',
                                                fontSize: 8,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),

                      // Account picker (income/expense only)
                      Consumer(builder: (ctx, r, _) {
                        final accounts = r.watch(accountsStreamProvider).value ?? const [];
                        if (accounts.isEmpty || _type == 'transfer') return const SizedBox.shrink();
                        final selected = _accountId ??
                            (accounts.where((a) => a.isPrimary).isNotEmpty
                                ? accounts.firstWhere((a) => a.isPrimary).id
                                : null);
                        return Padding(
                          padding: EdgeInsets.only(bottom: bs(12)),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              _AccountChip(
                                label: l10n.budgetNoAccount,
                                selected: selected == null,
                                onTap: () => setState(() => _accountId = null),
                              ),
                              for (final a in accounts) ...[
                                SizedBox(width: bs(8)),
                                _AccountChip(
                                  label: a.name,
                                  selected: selected == a.id,
                                  onTap: () => setState(() => _accountId = a.id),
                                ),
                              ],
                            ]),
                          ),
                        );
                      }),

                      // Von/Nach pickers for transfer
                      if (_type == 'transfer')
                        Consumer(builder: (ctx, r, _) {
                          final accounts = r.watch(accountsStreamProvider).value ?? const [];
                          Widget picker(String title, int? sel, ValueChanged<int?> onSel) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(
                                      fontFamily: 'DMSans',
                                      color: TraumColors.onBackgroundMuted,
                                      fontSize: 12)),
                                  SizedBox(height: bs(6)),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(children: [
                                      for (final a in accounts) ...[
                                        _AccountChip(label: a.name, selected: sel == a.id,
                                            onTap: () => onSel(a.id)),
                                        SizedBox(width: bs(8)),
                                      ],
                                    ]),
                                  ),
                                  SizedBox(height: bs(12)),
                                ],
                              );
                          return Column(children: [
                            picker(l10n.budgetFromAccount, _accountId, (v) => setState(() => _accountId = v)),
                            picker(l10n.budgetToAccount, _toAccountId, (v) => setState(() => _toAccountId = v)),
                          ]);
                        }),

                      // Step 8: Date chips — 4 equal Expanded, radius 9, padding 6
                      Row(
                        children: [
                          Expanded(
                            child: _DateChip(
                              label: l10n.today,
                              isSelected: isToday,
                              onTap: () => _setDateChip(today),
                            ),
                          ),
                          SizedBox(width: bs(6)),
                          Expanded(
                            child: _DateChip(
                              label: l10n.yesterday,
                              isSelected: isYesterday,
                              onTap: () => _setDateChip(yesterday),
                            ),
                          ),
                          SizedBox(width: bs(6)),
                          Expanded(
                            child: _DateChip(
                              label: l10n.budgetDayBeforeYesterday,
                              isSelected: isDayBefore,
                              onTap: () => _setDateChip(dayBefore),
                            ),
                          ),
                          SizedBox(width: bs(6)),
                          Expanded(
                            child: _DateChip(
                              label: (!isToday && !isYesterday && !isDayBefore)
                                  ? '${_date.day}.${_date.month}.${_date.year}'
                                  : l10n.budgetOtherDate,
                              isSelected: !isToday && !isYesterday && !isDayBefore,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (_) => _CalendarSheet(
                                    initialDate: _date,
                                    onDaySelected: (picked) {
                                      _setDateChip(picked);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: bs(12)),

                      // Beschreibung (Titel der Transaktion)
                      Container(
                        decoration: BoxDecoration(
                          color: TraumColors.background,
                          borderRadius: BorderRadius.circular(bs(10)),
                          border: Border.all(
                            color: TraumColors.onBackground.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: bs(10)),
                              child: Icon(
                                Icons.title_rounded,
                                size: bs(13),
                                color: TraumColors.onBackgroundSubtle,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _descCtrl,
                                style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontSize: 11,
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.budgetDescriptionHint,
                                  hintStyle: const TextStyle(
                                    color: TraumColors.onBackgroundSubtle,
                                    fontFamily: 'DMSans',
                                    fontSize: 11,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: bs(8)),

                      // Step 9: Note field — bg background, radius 10, pencil icon + camera
                      Container(
                        decoration: BoxDecoration(
                          color: TraumColors.background,
                          borderRadius: BorderRadius.circular(bs(10)),
                          border: Border.all(
                            color: TraumColors.onBackground.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: bs(10)),
                              child: Icon(
                                Icons.edit_outlined,
                                size: bs(13),
                                color: TraumColors.onBackgroundSubtle,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _noteCtrl,
                                style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontSize: 11,
                                ),
                                decoration: InputDecoration(
                                  hintText: _receiptImagePath != null
                                      ? l10n.budgetReceiptAttachedHint
                                      : l10n.budgetNoteOptionalHint,
                                  hintStyle: const TextStyle(
                                    color: TraumColors.onBackgroundSubtle,
                                    fontFamily: 'DMSans',
                                    fontSize: 11,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: bs(10),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _showReceiptSourceDialog,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: bs(10)),
                                child: Icon(
                                  _receiptImagePath != null
                                      ? Icons.receipt_long_rounded
                                      : Icons.camera_alt_outlined,
                                  size: bs(13),
                                  color: _receiptImagePath != null
                                      ? TraumColors.amberGold
                                      : TraumColors.onBackgroundSubtle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: bs(10)),

                      // Step 10: Save-as-template toggle — custom 34×18 switch
                      // (nur beim Anlegen, nicht beim Bearbeiten)
                      if (!_isEditing) ...[
                        _ToggleRow(
                          icon: Icons.bookmark_add_rounded,
                          label: l10n.budgetSaveAsTemplate,
                          value: _saveAsTemplate,
                          onChanged: (v) => setState(() => _saveAsTemplate = v),
                        ),
                        if (_saveAsTemplate) ...[
                          SizedBox(height: bs(6)),
                          Container(
                            decoration: BoxDecoration(
                              color: TraumColors.background,
                              borderRadius: BorderRadius.circular(bs(8)),
                              border: Border.all(
                                color: TraumColors.onBackground.withValues(alpha: 0.06),
                              ),
                            ),
                            child: TextField(
                              controller: _templateNameCtrl,
                              style: const TextStyle(
                                color: TraumColors.onBackground,
                                fontFamily: 'DMSans',
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.budgetTemplateNameFieldHint,
                                hintStyle: const TextStyle(
                                  color: TraumColors.onBackgroundSubtle,
                                  fontFamily: 'DMSans',
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: bs(10),
                                  vertical: bs(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],

                      // Step 10: Recurring toggle (income/expense only)
                      if (_type != 'transfer') ...[
                        SizedBox(height: bs(6)),
                        _ToggleRow(
                          icon: Icons.repeat_rounded,
                          label: l10n.budgetMonthlyRecurring,
                          value: _recurring,
                          onChanged: (v) => setState(() => _recurring = v),
                        ),
                        if (_recurring) ...[
                          SizedBox(height: bs(6)),
                          Row(children: [
                            Text(l10n.budgetRecurringDayLabel,
                                style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    color: TraumColors.onBackgroundMuted,
                                    fontSize: 13)),
                            SizedBox(width: bs(8)),
                            DropdownButton<int>(
                              value: _recurringDay,
                              dropdownColor: TraumColors.surfaceVariant,
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  color: TraumColors.onBackground),
                              items: [
                                for (var d = 1; d <= 28; d++)
                                  DropdownMenuItem(value: d, child: Text('$d.'))
                              ],
                              onChanged: (v) =>
                                  setState(() => _recurringDay = v ?? 1),
                            ),
                          ]),
                        ],
                      ],
                      // Bottom padding so content isn't hidden behind footer
                      SizedBox(height: bs(70)),
                    ],
                  ),
                ),
              ),

              // Step 11: Pinned Speichern footer — 44px, radius 12, amberGold
              Padding(
                padding: EdgeInsets.fromLTRB(bs(16), bs(8), bs(16), bs(8)),
                child: Builder(builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx)!;
                  return GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      height: bs(44),
                      decoration: BoxDecoration(
                        color: _saving
                            ? TraumColors.amberGold.withValues(alpha: 0.5)
                            : TraumColors.amberGold,
                        borderRadius: BorderRadius.circular(bs(12)),
                      ),
                      child: Center(
                        child: Text(
                          _saving ? l10n.saving : l10n.save,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TraumColors.background,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

// Step 4: Segmented type toggle
class _SegmentedTypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final ({String expense, String income, String transfer}) labels;

  const _SegmentedTypeToggle({
    required this.selected,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(bs(3)),
      decoration: BoxDecoration(
        color: TraumColors.background,
        borderRadius: BorderRadius.circular(bs(10)),
      ),
      child: Row(
        children: [
          _Segment(
            label: labels.expense,
            isSelected: selected == 'expense',
            activeColor: TraumColors.roseRed,
            activeTextColor: TraumColors.onBackground,
            onTap: () => onChanged('expense'),
          ),
          _Segment(
            label: labels.income,
            isSelected: selected == 'income',
            activeColor: TraumColors.mintGreen,
            activeTextColor: TraumColors.background,
            onTap: () => onChanged('income'),
          ),
          _Segment(
            label: labels.transfer,
            isSelected: selected == 'transfer',
            activeColor: TraumColors.indigoBlue,
            activeTextColor: TraumColors.onBackground,
            onTap: () => onChanged('transfer'),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color activeTextColor;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.activeTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: bs(7)),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(bs(7)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? activeTextColor : TraumColors.onBackgroundMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Step 7: Category column chip (50px wide, icon + label stacked)
class _CategoryColumnChip extends StatelessWidget {
  final dynamic cat;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryColumnChip({
    required this.cat,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: bs(50),
        padding: EdgeInsets.symmetric(horizontal: bs(3), vertical: bs(7)),
        decoration: BoxDecoration(
          color: isSelected
              ? TraumColors.amberGold.withValues(alpha: 0.16)
              : TraumColors.background,
          borderRadius: BorderRadius.circular(bs(10)),
          border: Border.all(
            color: isSelected
                ? TraumColors.amberGold
                : TraumColors.onBackground.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            budgetCategoryGlyph(
              cat.emoji,
              color: isSelected ? TraumColors.amberGold : TraumColors.onBackgroundSubtle,
              size: bs(18),
            ),
            SizedBox(height: bs(2)),
            Text(
              cat.name,
              style: TextStyle(
                color: isSelected ? TraumColors.onBackground : TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Step 10: Custom toggle row with 34×18 switch
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: bs(10), vertical: bs(9)),
        decoration: BoxDecoration(
          color: TraumColors.background,
          borderRadius: BorderRadius.circular(bs(10)),
          border: Border.all(
            color: TraumColors.onBackground.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: bs(14), color: TraumColors.onBackgroundMuted),
            SizedBox(width: bs(8)),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: TraumColors.onBackground,
                ),
              ),
            ),
            _MiniSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MiniSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: bs(34),
        height: bs(18),
        padding: EdgeInsets.all(bs(2)),
        decoration: BoxDecoration(
          color: value ? TraumColors.amberGold : TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(bs(9)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: bs(14),
            height: bs(14),
            decoration: BoxDecoration(
              color: TraumColors.onBackground,
              borderRadius: BorderRadius.circular(bs(7)),
            ),
          ),
        ),
      ),
    );
  }
}

// Step 8: Date chip — Expanded, radius 9, padding 6
class _DateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(bs(6)),
        decoration: BoxDecoration(
          color: isSelected ? TraumColors.amberGold : TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(bs(9)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? TraumColors.background
                  : TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _CalendarSheet extends StatefulWidget {
  final DateTime initialDate;
  final void Function(DateTime) onDaySelected;

  const _CalendarSheet(
      {required this.initialDate, required this.onDaySelected});

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late DateTime _focused;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _focused = widget.initialDate;
    _selected = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(bs(20))),
      ),
      padding: EdgeInsets.fromLTRB(bs(16), bs(12), bs(16), bs(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: bs(40),
            height: bs(4),
            margin: EdgeInsets.only(bottom: bs(16)),
            decoration: BoxDecoration(
              color: TraumColors.onBackgroundMuted,
              borderRadius: BorderRadius.circular(bs(2)),
            ),
          ),
          TableCalendar(
            locale: 'de_DE',
            focusedDay: _focused,
            firstDay: DateTime(2000),
            lastDay: DateTime.now().add(const Duration(days: 1)),
            selectedDayPredicate: (day) => isSameDay(day, _selected),
            onDaySelected: (selected, focused) {
              setState(() {
                _selected = selected;
                _focused = focused;
              });
              widget.onDaySelected(selected);
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: TraumColors.amberGold,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: TraumColors.amberGoldDim,
                shape: BoxShape.circle,
              ),
              todayTextStyle:
                  TextStyle(color: TraumColors.amberGold, fontFamily: 'DMSans'),
              defaultTextStyle:
                  TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              weekendTextStyle:
                  TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              outsideTextStyle: TextStyle(
                  color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700),
              leftChevronIcon: Icon(Icons.chevron_left,
                  color: TraumColors.onBackgroundMuted),
              rightChevronIcon: Icon(Icons.chevron_right,
                  color: TraumColors.onBackgroundMuted),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                  color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
              weekendStyle: TextStyle(
                  color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AccountChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: bs(14), vertical: bs(8)),
          decoration: BoxDecoration(
            color: selected ? TraumColors.amberGoldDim : TraumColors.surface,
            borderRadius: BorderRadius.circular(bs(20)),
            border: selected ? Border.all(color: TraumColors.amberGold) : null,
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? TraumColors.amberGold : TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans', fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ),
      );
}
