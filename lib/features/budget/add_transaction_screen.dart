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
import '../../l10n/app_localizations.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'expense';
  DateTime _date = DateTime.now();
  int? _categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final categoriesAsync = ref.watch(allBudgetCategoriesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.addTransaction,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type toggle
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = 'expense'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == 'expense'
                          ? TraumColors.roseRedDim
                          : TraumColors.surfaceVariant,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(TraumRadius.card),
                        bottomLeft: Radius.circular(TraumRadius.card),
                      ),
                      border: Border.all(
                        color: _type == 'expense'
                            ? TraumColors.roseRed
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.expenseLabel,
                          style: TextStyle(
                              color: _type == 'expense'
                                  ? TraumColors.roseRed
                                  : TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = 'income'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == 'income'
                          ? TraumColors.mintGreenDim
                          : TraumColors.surfaceVariant,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(TraumRadius.card),
                        bottomRight: Radius.circular(TraumRadius.card),
                      ),
                      border: Border.all(
                        color: _type == 'income'
                            ? TraumColors.mintGreen
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.incomeLabel,
                          style: TextStyle(
                              color: _type == 'income'
                                  ? TraumColors.mintGreen
                                  : TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _buildLabel(AppLocalizations.of(context)!.amountWithCurrency(currency)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  color: TraumColors.onBackground, fontFamily: 'DMSans', fontSize: 24),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: const TextStyle(
                    color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 24),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel(AppLocalizations.of(context)!.fieldDescription),
            const SizedBox(height: 6),
            _buildTextField(_descCtrl, hint: AppLocalizations.of(context)!.transactionDescriptionHint),
            const SizedBox(height: 16),
            _buildLabel(AppLocalizations.of(context)!.dateLabel),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(primary: TraumColors.amberGold)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: TraumColors.surface,
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: TraumColors.amberGold, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                    style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel(AppLocalizations.of(context)!.categoryOptional),
            const SizedBox(height: 6),
            categoriesAsync.when(
              data: (categories) {
                final filtered =
                    categories.where((c) => c.isExpense == (_type == 'expense')).toList();
                if (filtered.isEmpty) {
                  return Text(AppLocalizations.of(context)!.noCategories,
                      style: const TextStyle(
                          color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'));
                }
                return DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  dropdownColor: TraumColors.surfaceElevated,
                  style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: TraumColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(TraumRadius.card),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.noCategory)),
                    ...filtered.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.emoji ?? ''} ${c.name}'.trim()),
                        )),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            _buildLabel(AppLocalizations.of(context)!.fieldNoteOptional),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.noteHint,
                hintStyle: const TextStyle(
                    color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: _saving ? AppLocalizations.of(context)!.saving : AppLocalizations.of(context)!.save,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13));

  Widget _buildTextField(TextEditingController ctrl, {String? hint}) => TextField(
        controller: ctrl,
        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
          filled: true,
          fillColor: TraumColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TraumRadius.card),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );

  Future<void> _save() async {
    final amountText = _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterValidAmount)));
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.descriptionRequired)));
      return;
    }
    setState(() => _saving = true);
    await ref.read(budgetDaoProvider).insertTransaction(
          TransactionsCompanion.insert(
            amount: amount,
            description: _descCtrl.text.trim(),
            type: Value(_type),
            date: _date,
            categoryId: Value(_categoryId),
            note: Value(_noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
          ),
        );
    if (mounted) context.go('/budget');
  }
}
