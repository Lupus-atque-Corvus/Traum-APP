import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchCtrl = TextEditingController();
  List<MealTemplate> _results = [];
  bool _searched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }

    final results = await ref.read(nutritionDaoProvider).searchTemplates(query.trim());
    if (mounted) {
      setState(() {
        _results = results;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text('Lebensmittel suchen',
            style: TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _showCreateTemplateSheet(context),
            child: const Text('+ Neu',
                style: TextStyle(color: TraumColors.mintGreen, fontFamily: 'DMSans')),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                hintText: 'z.B. Haferflocken, Hühnerbrust…',
                hintStyle: const TextStyle(
                    color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: TraumColors.onBackgroundMuted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: TraumColors.onBackgroundMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: _search,
              onSubmitted: _search,
            ),
          ),
          Expanded(
            child: !_searched
                ? const Center(
                    child: Text('Lebensmittel suchen oder neu erstellen',
                        style: TextStyle(
                            color: TraumColors.onBackgroundSubtle,
                            fontFamily: 'DMSans',
                            fontSize: 13),
                        textAlign: TextAlign.center),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: TraumColors.onBackgroundSubtle),
                          const SizedBox(height: 12),
                          const Text('Keine Ergebnisse',
                              style: TextStyle(
                                  color: TraumColors.onBackgroundMuted,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => _showCreateTemplateSheet(context,
                                initialName: _searchCtrl.text.trim()),
                            child: const Text('Lebensmittel erstellen',
                                style: TextStyle(
                                    color: TraumColors.mintGreen, fontFamily: 'DMSans')),
                          ),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) => _FoodTile(
                          template: _results[i],
                          onTap: () => _showAddToLogDialog(context, _results[i]),
                          onDelete: _results[i].isCustom
                              ? () => ref
                                  .read(nutritionDaoProvider)
                                  .deleteTemplate(_results[i].id)
                              : null,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddToLogDialog(BuildContext context, MealTemplate template) {
    final amountCtrl = TextEditingController(
        text: template.servingSizeG.toStringAsFixed(0));
    String mealType = 'snack';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final amount = double.tryParse(amountCtrl.text) ?? template.servingSizeG;
          final factor = amount / 100;
          final kcal = template.kcalPer100g * factor;
          final protein = template.proteinPer100g * factor;

          return AlertDialog(
            backgroundColor: TraumColors.surfaceElevated,
            title: Text(template.name,
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans')),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _NutriChip(label: '${kcal.toStringAsFixed(0)} kcal',
                      color: TraumColors.mintGreen),
                  _NutriChip(label: '${protein.toStringAsFixed(1)}g P',
                      color: TraumColors.indigoBlue),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  decoration: const InputDecoration(
                    labelText: 'Menge (g)',
                    labelStyle: TextStyle(
                        color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: mealType,
                  dropdownColor: TraumColors.surfaceElevated,
                  isExpanded: true,
                  style: const TextStyle(
                      color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  underline: Container(height: 1, color: TraumColors.surfaceVariant),
                  items: const [
                    DropdownMenuItem(value: 'breakfast', child: Text('Frühstück')),
                    DropdownMenuItem(value: 'lunch', child: Text('Mittagessen')),
                    DropdownMenuItem(value: 'dinner', child: Text('Abendessen')),
                    DropdownMenuItem(value: 'snack', child: Text('Snack')),
                  ],
                  onChanged: (v) => setState(() => mealType = v!),
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen',
                    style: TextStyle(color: TraumColors.onBackgroundMuted)),
              ),
              TextButton(
                onPressed: () async {
                  final a = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ??
                      template.servingSizeG;
                  final f = a / 100;
                  Navigator.pop(ctx);
                  await ref.read(nutritionDaoProvider).insertLog(
                        NutritionLogsCompanion.insert(
                          logDate: DateTime.now(),
                          mealType: Value(mealType),
                          foodName: template.name,
                          amountGrams: a,
                          kcal: template.kcalPer100g * f,
                          proteinG: Value(template.proteinPer100g * f),
                          carbsG: Value(template.carbsPer100g * f),
                          fatG: Value(template.fatPer100g * f),
                          templateId: Value(template.id),
                        ),
                      );
                  if (context.mounted) context.go('/nutrition');
                },
                child: const Text('Eintragen',
                    style: TextStyle(
                        color: TraumColors.mintGreen, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateTemplateSheet(BuildContext context, {String? initialName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _CreateTemplateSheet(
        initialName: initialName,
        onAdd: (c) => ref.read(nutritionDaoProvider).insertTemplate(c),
      ),
    );
  }
}

class _NutriChip extends StatelessWidget {
  final String label;
  final Color color;
  const _NutriChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _FoodTile extends StatelessWidget {
  final MealTemplate template;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _FoodTile({required this.template, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(template.name,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${template.kcalPer100g.toStringAsFixed(0)} kcal/100g  •  ${template.proteinPer100g.toStringAsFixed(1)}g P',
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 11),
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_rounded,
                    color: TraumColors.onBackgroundSubtle, size: 18),
                onPressed: onDelete,
              )
            : const Icon(Icons.add_circle_outline_rounded,
                color: TraumColors.mintGreen, size: 20),
      ),
    );
  }
}

class _CreateTemplateSheet extends StatefulWidget {
  final String? initialName;
  final Future<void> Function(MealTemplatesCompanion) onAdd;

  const _CreateTemplateSheet({this.initialName, required this.onAdd});

  @override
  State<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends State<_CreateTemplateSheet> {
  late final TextEditingController _nameCtrl;
  final _servingCtrl = TextEditingController(text: '100');
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController(text: '0');
  final _carbsCtrl = TextEditingController(text: '0');
  final _fatCtrl = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: TraumColors.onBackgroundSubtle,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Lebensmittel erstellen',
                style: TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 16),
            _buildField('Name', _nameCtrl, hint: 'z.B. Haferflocken'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildField('Portionsgröße (g)', _servingCtrl, hint: '100', numeric: true)),
              const SizedBox(width: 10),
              Expanded(child: _buildField('Kalorien/100g', _kcalCtrl, hint: '370', numeric: true)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildField('Protein/100g', _proteinCtrl, hint: '13', numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildField('Kohlenhydrate/100g', _carbsCtrl, hint: '60', numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildField('Fett/100g', _fatCtrl, hint: '7', numeric: true)),
            ]),
            const SizedBox(height: 20),
            GradientButton(
              label: _saving ? 'Speichern…' : 'Erstellen',
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String? hint, bool numeric = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 11),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
          filled: true,
          fillColor: TraumColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
      ),
    ]);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name ist ein Pflichtfeld')));
      return;
    }
    final kcal = double.tryParse(_kcalCtrl.text.replaceAll(',', '.'));
    if (kcal == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Kalorien eingeben')));
      return;
    }
    final serving = double.tryParse(_servingCtrl.text.replaceAll(',', '.')) ?? 100;
    setState(() => _saving = true);
    await widget.onAdd(MealTemplatesCompanion.insert(
      name: _nameCtrl.text.trim(),
      servingSizeG: serving,
      kcalPer100g: kcal,
      proteinPer100g: Value(double.tryParse(_proteinCtrl.text.replaceAll(',', '.')) ?? 0),
      carbsPer100g: Value(double.tryParse(_carbsCtrl.text.replaceAll(',', '.')) ?? 0),
      fatPer100g: Value(double.tryParse(_fatCtrl.text.replaceAll(',', '.')) ?? 0),
      isCustom: const Value(true),
    ));
    if (mounted) Navigator.pop(context);
  }
}
