import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
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
              categoryId: Value(_categoryId),
              note: Value(
                _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
              ),
              receiptImagePath: Value(_receiptImagePath),
              accountId: Value(effectiveAccount),
              toAccountId: Value(_type == 'transfer' ? _toAccountId : null),
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

    return Container(
      decoration: const BoxDecoration(
        color: TraumColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TraumColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: '− Ausgabe',
                      isSelected: _type == 'expense',
                      selectedColor: TraumColors.roseRed,
                      isLeft: true,
                      onTap: () => setState(() => _type = 'expense'),
                    ),
                  ),
                  Expanded(
                    child: _TypeButton(
                      label: '+ Einnahme',
                      isSelected: _type == 'income',
                      selectedColor: TraumColors.mintGreen,
                      isLeft: false,
                      onTap: () => setState(() => _type = 'income'),
                    ),
                  ),
                  Expanded(
                    child: _TypeButton(
                      label: '⇄ Umbuchung',
                      isSelected: _type == 'transfer',
                      selectedColor: TraumColors.cyanBlue,
                      isLeft: false,
                      onTap: () => setState(() => _type = 'transfer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount display
              Center(
                child: Text(
                  _numpadValue.isEmpty
                      ? '0,00 $currency'
                      : '$_numpadValue $currency',
                  style: TextStyle(
                    color: _type == 'expense'
                        ? TraumColors.roseRed
                        : _type == 'income'
                            ? TraumColors.mintGreen
                            : TraumColors.cyanBlue,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 36,
                  ),
                ),
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
              const SizedBox(height: 16),

              // Date chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _DateChip(
                      label: 'Heute',
                      isSelected: isToday,
                      onTap: () => _setDateChip(today),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
                      label: 'Gestern',
                      isSelected: isYesterday,
                      onTap: () => _setDateChip(yesterday),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
                      label: 'Vorgestern',
                      isSelected: isDayBefore,
                      onTap: () => _setDateChip(dayBefore),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
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
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                              fontFamily: 'DMSans', color: TraumColors.onBackgroundMuted, fontSize: 12)),
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

              // Category grid
              if (_type != 'transfer')
              categoriesAsync.when(
                data: (cats) {
                  final filtered = cats
                      .where((c) => c.isExpense == (_type == 'expense'))
                      .toList();
                  if (filtered.isEmpty) return const SizedBox.shrink();
                  // +1 for the "+ Neu" tile
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: filtered.length + 1,
                    itemBuilder: (_, i) {
                      if (i == filtered.length) {
                        return GestureDetector(
                          onTap: () {
                            final router = GoRouter.of(context);
                            Navigator.of(context).pop();
                            router.push('/budget/categories');
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: TraumColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: TraumColors.amberGold.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: TraumColors.amberGold,
                                  size: 22,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Neu',
                                  style: TextStyle(
                                    color: TraumColors.amberGold,
                                    fontFamily: 'DMSans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final cat = filtered[i];
                      final isSelected = _categoryId == cat.id;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _categoryId = isSelected ? null : cat.id;
                          _categoryName = isSelected ? null : cat.name;
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? TraumColors.amberGoldDim
                                : TraumColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: TraumColors.amberGold,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cat.emoji ?? '📦',
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cat.name,
                                style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),

              // Note field
              TextField(
                controller: _noteCtrl,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                ),
                decoration: InputDecoration(
                  hintText: 'Notiz hinzufügen...',
                  hintStyle: const TextStyle(
                    color: TraumColors.onBackgroundSubtle,
                    fontFamily: 'DMSans',
                  ),
                  filled: true,
                  fillColor: TraumColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Receipt scan button
              OutlinedButton.icon(
                onPressed: _showReceiptSourceDialog,
                icon: const Icon(
                  Icons.receipt_long_rounded,
                  color: TraumColors.amberGold,
                ),
                label: Text(
                  _receiptImagePath != null
                      ? '🧾 Kassenbon angehängt'
                      : '🧾 Kassenbon scannen / Foto',
                  style: const TextStyle(
                    color: TraumColors.amberGold,
                    fontFamily: 'DMSans',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: TraumColors.amberGold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Save as template
              Row(
                children: [
                  Checkbox(
                    value: _saveAsTemplate,
                    onChanged: (v) =>
                        setState(() => _saveAsTemplate = v ?? false),
                    activeColor: TraumColors.amberGold,
                  ),
                  const Text(
                    'Als Vorlage speichern:',
                    style: TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_saveAsTemplate)
                    Expanded(
                      child: TextField(
                        controller: _templateNameCtrl,
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Name...',
                          hintStyle: const TextStyle(
                            color: TraumColors.onBackgroundSubtle,
                            fontFamily: 'DMSans',
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: TraumColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Save button
              Builder(builder: (ctx) {
                final l10n = AppLocalizations.of(ctx)!;
                return GradientButton(
                  label: _saving
                      ? l10n.saving
                      : _type == 'expense'
                          ? '${l10n.budgetAddExpense}  ${_numpadValue.isNotEmpty ? "−$_numpadValue $currency" : ""}'
                          : _type == 'income'
                              ? '${l10n.budgetAddIncome}  ${_numpadValue.isNotEmpty ? "+$_numpadValue $currency" : ""}'
                              : '⇄ Umbuchung  ${_numpadValue.isNotEmpty ? "$_numpadValue $currency" : ""}',
                  onPressed: _saving ? null : _save,
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final bool isLeft;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.15)
              : TraumColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: isLeft
                ? const Radius.circular(TraumRadius.card)
                : Radius.zero,
            bottomLeft: isLeft
                ? const Radius.circular(TraumRadius.card)
                : Radius.zero,
            topRight: !isLeft
                ? const Radius.circular(TraumRadius.card)
                : Radius.zero,
            bottomRight: !isLeft
                ? const Radius.circular(TraumRadius.card)
                : Radius.zero,
          ),
          border: isSelected ? Border.all(color: selectedColor) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedColor : TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? TraumColors.amberGoldDim : TraumColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: TraumColors.amberGold)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? TraumColors.amberGold
                : TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
