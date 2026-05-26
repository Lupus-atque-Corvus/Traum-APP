import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/open_food_facts_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final _service = OpenFoodFactsService();
  final MobileScannerController _ctrl = MobileScannerController();

  bool _scanning = true;
  bool _loading = false;
  bool _saving = false;
  FoodProduct? _product;
  String? _error;

  final _amountCtrl = TextEditingController(text: '100');
  String _mealType = 'snack';

  @override
  void dispose() {
    _ctrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _onBarcode(BarcodeCapture capture) async {
    if (!_scanning) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() {
      _scanning = false;
      _loading = true;
      _error = null;
    });
    await _ctrl.stop();

    final product = await _service.lookup(barcode);
    if (!mounted) return;

    if (product == null) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.barcodeProductNotFound;
      });
    } else {
      if (product.servingSizeG != null) {
        _amountCtrl.text = product.servingSizeG!.toStringAsFixed(0);
      }
      setState(() {
        _loading = false;
        _product = product;
      });
    }
  }

  Future<void> _logMeal(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final product = _product;
    if (product == null) return;

    final amountG = double.tryParse(_amountCtrl.text.trim()) ?? 100.0;
    final factor = amountG / 100.0;

    setState(() => _saving = true);
    try {
      await ref.read(nutritionDaoProvider).insertLog(NutritionLogsCompanion.insert(
        logDate: DateTime.now(),
        mealType: Value(_mealType),
        foodName: '${product.name}${product.brand != null ? ' (${product.brand})' : ''}',
        amountGrams: amountG,
        kcal: product.kcalPer100g * factor,
        proteinG: Value(product.proteinPer100g * factor),
        carbsG: Value(product.carbsPer100g * factor),
        fatG: Value(product.fatPer100g * factor),
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mealLogged)),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _rescan() {
    setState(() {
      _scanning = true;
      _loading = false;
      _product = null;
      _error = null;
    });
    _ctrl.start();
  }

  List<(String, String)> _mealTypes(AppLocalizations l10n) => [
    ('breakfast', l10n.breakfast),
    ('lunch', l10n.lunch),
    ('dinner', l10n.dinner),
    ('snack', l10n.snack),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(l10n.barcodeScanner,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: _product != null
          ? _buildProductForm(context, l10n)
          : _buildScanner(context, l10n),
    );
  }

  Widget _buildScanner(BuildContext context, AppLocalizations l10n) {
    return Stack(
      children: [
        MobileScanner(
          controller: _ctrl,
          onDetect: _onBarcode,
        ),
        // Overlay frame
        Center(
          child: Container(
            width: 260,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: TraumColors.mintGreen, width: 2),
              borderRadius: BorderRadius.circular(TraumRadius.card),
            ),
          ),
        ),
        if (_loading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: TraumColors.mintGreen),
            ),
          ),
        if (_error != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TraumColors.surfaceElevated,
                borderRadius: BorderRadius.circular(TraumRadius.card),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!,
                      style: const TextStyle(
                          color: TraumColors.roseRed, fontFamily: 'DMSans'),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TraumColors.mintGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _rescan,
                    child: Text(l10n.barcodeScanAgain,
                        style: const TextStyle(fontFamily: 'DMSans')),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(l10n.barcodeScanHint,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'DMSans',
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
          ),
        ),
      ],
    );
  }

  Widget _buildProductForm(BuildContext context, AppLocalizations l10n) {
    final product = _product!;
    final amount = double.tryParse(_amountCtrl.text) ?? 100.0;
    final factor = amount / 100.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_rounded,
                        color: TraumColors.mintGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(product.name,
                          style: const TextStyle(
                              color: TraumColors.onBackground,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ),
                  ],
                ),
                if (product.brand != null) ...[
                  const SizedBox(height: 4),
                  Text(product.brand!,
                      style: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 13)),
                ],
                const SizedBox(height: 12),
                _MacroRow(
                  label: 'kcal',
                  value: (product.kcalPer100g * factor).toStringAsFixed(0),
                  color: TraumColors.coralOrange,
                ),
                _MacroRow(
                  label: l10n.protein,
                  value: '${(product.proteinPer100g * factor).toStringAsFixed(1)} g',
                  color: TraumColors.indigoBlue,
                ),
                _MacroRow(
                  label: l10n.carbs,
                  value: '${(product.carbsPer100g * factor).toStringAsFixed(1)} g',
                  color: TraumColors.amberGold,
                ),
                _MacroRow(
                  label: l10n.fat,
                  value: '${(product.fatPer100g * factor).toStringAsFixed(1)} g',
                  color: TraumColors.roseRed,
                ),
                const SizedBox(height: 4),
                Text(l10n.barcodePer100g,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount
          Text(l10n.amountGrams,
              style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              suffixText: 'g',
              suffixStyle: const TextStyle(
                  color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
              filled: true,
              fillColor: TraumColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TraumRadius.input),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Meal type
          Text(l10n.mealType,
              style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _mealTypes(l10n).map((t) {
              final selected = _mealType == t.$1;
              return ChoiceChip(
                label: Text(t.$2,
                    style: TextStyle(
                        color: selected
                            ? Colors.white
                            : TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans')),
                selected: selected,
                selectedColor: TraumColors.mintGreen,
                backgroundColor: TraumColors.surface,
                onSelected: (_) => setState(() => _mealType = t.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TraumColors.onBackgroundMuted,
                    side: const BorderSide(color: TraumColors.onBackgroundSubtle),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TraumRadius.button)),
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _rescan,
                  child: Text(l10n.barcodeScanAgain,
                      style: const TextStyle(fontFamily: 'DMSans')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TraumColors.mintGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TraumRadius.button)),
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _saving ? null : () => _logMeal(context),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(l10n.logMeal,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontFamily: 'DMSans', fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
