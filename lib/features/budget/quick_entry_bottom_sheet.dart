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
import 'budget_providers.dart';
import 'receipt_scanner.dart';
import 'widgets/numpad_widget.dart';

class QuickEntryBottomSheet extends ConsumerStatefulWidget {
  final QuickTemplate? initialTemplate;

  const QuickEntryBottomSheet({super.key, this.initialTemplate});

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
  final _noteCtrl = TextEditingController();
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
  }

  @override
  void dispose() {
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
              title: const Text(
                'Kamera',
                style: TextStyle(
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
              title: const Text(
                'Galerie',
                style: TextStyle(
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
    if (_type == 'transfer') {
      if (_accountId == null || _toAccountId == null || _accountId == _toAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Von- und Nach-Konto wählen (verschieden)')));
        return;
      }
    }

    final amount = _parsedAmount;
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte einen gültigen Betrag eingeben'),
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

      final description = _noteCtrl.text.trim().isNotEmpty
          ? _noteCtrl.text.trim()
          : (_categoryName ??
              (_type == 'expense'
                  ? 'Ausgabe'
                  : _type == 'income'
                      ? 'Einnahme'
                      : 'Umbuchung'));

      await ref.read(budgetDaoProvider).insertTransaction(
            TransactionsCompanion.insert(
              amount: amount,
              description: description,
              type: Value(_type),
              date: _date,
              categoryId: Value(_type == 'transfer' ? null : _categoryId),
              note: Value(
                _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
              ),
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
    final categoriesAsync = ref.watch(allBudgetCategoriesStreamProvider);
    final currency = ref.watch(currencySymbolProvider);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBefore = today.subtract(const Duration(days: 2));

    final isToday = isSameDay(_date, today);
    final isYesterday = isSameDay(_date, yesterday);
    final isDayBefore = isSameDay(_date, dayBefore);

    // Step 1: Container — sheetBg, radius 22, border-top white@0.08, max 91%
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.91,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: TraumColors.sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(
              color: TraumColors.onBackground.withValues(alpha: 0.08),
              width: 1,
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
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: TraumColors.dimBar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Step 3: Title row — "Hinzufügen" + close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Hinzufügen',
                      style: TextStyle(
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
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: TraumColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: TraumColors.onBackgroundMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Step 4: Type toggle — segmented, solid fills
                      _SegmentedTypeToggle(
                        selected: _type,
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      const SizedBox(height: 16),

                      // Step 5: Amount display — "Betrag" label + 34/w700 amount
                      Column(
                        children: [
                          const Text(
                            'Betrag',
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 8,
                              color: TraumColors.onBackgroundMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                      const SizedBox(height: 12),

                      // Numpad or scanning indicator
                      if (_scanning)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: TraumColors.amberGold),
                                SizedBox(height: 8),
                                Text(
                                  'Kassenzettel wird analysiert...',
                                  style: TextStyle(
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
                      const SizedBox(height: 14),

                      // Step 6: Template chips — amberGold@0.1 bg, border amberGold@0.35,
                      //           radius 18, padding 5×10, zap icon 11
                      if (_type != 'transfer')
                        Consumer(builder: (ctx, r, _) {
                          final tpls = r.watch(quickTemplatesProvider).value ?? const [];
                          if (tpls.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: TraumColors.amberGold.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                            color: TraumColors.amberGold.withValues(alpha: 0.35)),
                                      ),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.bolt_rounded,
                                            size: 11, color: TraumColors.amberGold),
                                        const SizedBox(width: 4),
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
                                  const SizedBox(width: 8),
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
                              padding: const EdgeInsets.only(bottom: 12),
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
                                      const SizedBox(width: 6),
                                    ],
                                    // "+ Neu" tile
                                    GestureDetector(
                                      onTap: () {
                                        final router = GoRouter.of(context);
                                        Navigator.of(context).pop();
                                        router.push('/budget/categories');
                                      },
                                      child: Container(
                                        width: 50,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 3, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: TraumColors.background,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: TraumColors.amberGold.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_rounded,
                                              color: TraumColors.amberGold,
                                              size: 18,
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Neu',
                                              style: TextStyle(
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
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              _AccountChip(
                                label: 'Kein Konto',
                                selected: selected == null,
                                onTap: () => setState(() => _accountId = null),
                              ),
                              for (final a in accounts) ...[
                                const SizedBox(width: 8),
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
                                  const SizedBox(height: 6),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(children: [
                                      for (final a in accounts) ...[
                                        _AccountChip(label: a.name, selected: sel == a.id,
                                            onTap: () => onSel(a.id)),
                                        const SizedBox(width: 8),
                                      ],
                                    ]),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                          return Column(children: [
                            picker('Von', _accountId, (v) => setState(() => _accountId = v)),
                            picker('Nach', _toAccountId, (v) => setState(() => _toAccountId = v)),
                          ]);
                        }),

                      // Step 8: Date chips — 4 equal Expanded, radius 9, padding 6
                      Row(
                        children: [
                          Expanded(
                            child: _DateChip(
                              label: 'Heute',
                              isSelected: isToday,
                              onTap: () => _setDateChip(today),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _DateChip(
                              label: 'Gestern',
                              isSelected: isYesterday,
                              onTap: () => _setDateChip(yesterday),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _DateChip(
                              label: 'Vorgestern',
                              isSelected: isDayBefore,
                              onTap: () => _setDateChip(dayBefore),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _DateChip(
                              label: (!isToday && !isYesterday && !isDayBefore)
                                  ? '${_date.day}.${_date.month}.${_date.year}'
                                  : 'Anderes ▼',
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
                      const SizedBox(height: 12),

                      // Step 9: Note field — bg background, radius 10, pencil icon + camera
                      Container(
                        decoration: BoxDecoration(
                          color: TraumColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: TraumColors.onBackground.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 13,
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
                                      ? 'Kassenbon angehängt'
                                      : 'Notiz hinzufügen...',
                                  hintStyle: const TextStyle(
                                    color: TraumColors.onBackgroundSubtle,
                                    fontFamily: 'DMSans',
                                    fontSize: 11,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _showReceiptSourceDialog,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  _receiptImagePath != null
                                      ? Icons.receipt_long_rounded
                                      : Icons.camera_alt_outlined,
                                  size: 13,
                                  color: _receiptImagePath != null
                                      ? TraumColors.amberGold
                                      : TraumColors.onBackgroundSubtle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Step 10: Save-as-template toggle — custom 34×18 switch
                      _ToggleRow(
                        icon: Icons.bookmark_add_rounded,
                        label: 'Als Vorlage speichern',
                        value: _saveAsTemplate,
                        onChanged: (v) => setState(() => _saveAsTemplate = v),
                      ),
                      if (_saveAsTemplate) ...[
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: TraumColors.background,
                            borderRadius: BorderRadius.circular(8),
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
                            decoration: const InputDecoration(
                              hintText: 'Vorlagen-Name...',
                              hintStyle: TextStyle(
                                color: TraumColors.onBackgroundSubtle,
                                fontFamily: 'DMSans',
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Step 10: Recurring toggle (income/expense only)
                      if (_type != 'transfer') ...[
                        const SizedBox(height: 6),
                        _ToggleRow(
                          icon: Icons.repeat_rounded,
                          label: 'Monatlich wiederkehrend',
                          value: _recurring,
                          onChanged: (v) => setState(() => _recurring = v),
                        ),
                        if (_recurring) ...[
                          const SizedBox(height: 6),
                          Row(children: [
                            const Text('Am Tag des Monats:',
                                style: TextStyle(
                                    fontFamily: 'DMSans',
                                    color: TraumColors.onBackgroundMuted,
                                    fontSize: 13)),
                            const SizedBox(width: 8),
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
                      const SizedBox(height: 70),
                    ],
                  ),
                ),
              ),

              // Step 11: Pinned Speichern footer — 44px, radius 12, amberGold
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Builder(builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx)!;
                  return GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _saving
                            ? TraumColors.amberGold.withValues(alpha: 0.5)
                            : TraumColors.amberGold,
                        borderRadius: BorderRadius.circular(12),
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
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

// Step 4: Segmented type toggle
class _SegmentedTypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedTypeToggle({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: TraumColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Ausgabe',
            isSelected: selected == 'expense',
            activeColor: TraumColors.roseRed,
            activeTextColor: TraumColors.onBackground,
            onTap: () => onChanged('expense'),
          ),
          _Segment(
            label: 'Einnahme',
            isSelected: selected == 'income',
            activeColor: TraumColors.mintGreen,
            activeTextColor: TraumColors.background,
            onTap: () => onChanged('income'),
          ),
          _Segment(
            label: 'Umbuchen',
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
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
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
        width: 50,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? TraumColors.amberGold.withValues(alpha: 0.16)
              : TraumColors.background,
          borderRadius: BorderRadius.circular(10),
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
              size: 18,
            ),
            const SizedBox(height: 2),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: TraumColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: TraumColors.onBackground.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: TraumColors.onBackgroundMuted),
            const SizedBox(width: 8),
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
        width: 34,
        height: 18,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? TraumColors.amberGold : TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(9),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: TraumColors.onBackground,
              borderRadius: BorderRadius.circular(7),
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? TraumColors.amberGold : TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(9),
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
      decoration: const BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: TraumColors.onBackgroundMuted,
              borderRadius: BorderRadius.circular(2),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? TraumColors.amberGoldDim : TraumColors.surface,
            borderRadius: BorderRadius.circular(20),
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
