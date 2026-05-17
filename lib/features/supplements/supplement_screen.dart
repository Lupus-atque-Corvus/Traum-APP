import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

class SupplementScreen extends ConsumerWidget {
  const SupplementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppsAsync = ref.watch(supplementsStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text('Supplements',
            style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.indigoBlue,
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: suppsAsync.when(
        data: (supps) {
          if (supps.isEmpty) return const _EmptyState();
          // Group by category
          final grouped = <String, List<Supplement>>{};
          for (final s in supps) {
            final cat = s.category ?? 'Sonstige';
            grouped.putIfAbsent(cat, () => []).add(s);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(e.key, style: const TextStyle(
                      color: TraumColors.indigoBlue, fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                ...e.value.map((s) => _SupplementCard(
                  supplement: s,
                  onDelete: () => ref.read(supplementDaoProvider).deleteSupplement(s.id),
                  onToggle: (active) => ref.read(supplementDaoProvider).updateSupplement(
                    SupplementsCompanion(
                      id: Value(s.id),
                      name: Value(s.name),
                      isActive: Value(active),
                    ),
                  ),
                )),
              ],
            )).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.indigoBlue)),
        error: (e, _) => Center(child: Text('Fehler: $e',
            style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddSupplementSheet(
        onAdd: (c) => ref.read(supplementDaoProvider).insertSupplement(c),
      ),
    );
  }
}

class _SupplementCard extends StatelessWidget {
  final Supplement supplement;
  final VoidCallback onDelete;
  final void Function(bool) onToggle;

  const _SupplementCard({required this.supplement, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(supplement.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: supplement.isActive
                ? TraumColors.indigoBlue.withValues(alpha: 0.3)
                : TraumColors.surfaceVariant,
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: TraumColors.indigoBlueDim, shape: BoxShape.circle),
            child: const Icon(Icons.science_rounded, color: TraumColors.indigoBlue, size: 20),
          ),
          title: Text(supplement.name,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${supplement.dosageAmount ?? '?'} ${supplement.dosageUnit ?? ''}'.trim(),
            style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
          ),
          trailing: Switch(
            value: supplement.isActive,
            activeThumbColor: TraumColors.indigoBlue,
            onChanged: onToggle,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.science_rounded, size: 64,
            color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        const Text('Noch keine Supplements',
            style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans',
                fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Tippe auf + um ein Supplement hinzuzufügen',
            style: TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 13),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _AddSupplementSheet extends StatefulWidget {
  final Future<void> Function(SupplementsCompanion) onAdd;
  const _AddSupplementSheet({required this.onAdd});

  @override
  State<_AddSupplementSheet> createState() => _AddSupplementSheetState();
}

class _AddSupplementSheetState extends State<_AddSupplementSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = 'Vitamine';
  String _unit = 'mg';
  bool _saving = false;

  static const _categories = [
    'Vitamine', 'Mineralien', 'Aminosäuren', 'Protein', 'Omega-3',
    'Adaptogene', 'Pre-Workout', 'Darmgesundheit', 'Kreatin', 'Sonstige'
  ];
  static const _units = ['mg', 'g', 'µg', 'IU', 'ml', 'Kapsel(n)', 'Tablette(n)', 'Messbecher'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
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
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Supplement hinzufügen',
                style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            _buildTextField('Name', _nameCtrl, hint: 'z.B. Vitamin D3'),
            const SizedBox(height: 12),
            const Text('Kategorie', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _category,
              dropdownColor: TraumColors.surfaceElevated,
              isExpanded: true,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              underline: Container(height: 1, color: TraumColors.surfaceVariant),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildTextField('Menge', _amountCtrl, hint: '1000', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Einheit', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: _unit,
                    dropdownColor: TraumColors.surfaceElevated,
                    style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
                    underline: Container(height: 1, color: TraumColors.surfaceVariant),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 20),
            GradientButton(label: _saving ? 'Speichern…' : 'Speichern', onPressed: _saving ? null : _save),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
            filled: true, fillColor: TraumColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name ist ein Pflichtfeld')));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(SupplementsCompanion.insert(
      name: _nameCtrl.text.trim(),
      category: Value(_category),
      dosageAmount: Value(_amountCtrl.text.trim().isEmpty ? null : _amountCtrl.text.trim()),
      dosageUnit: Value(_unit),
    ));
    if (mounted) Navigator.pop(context);
  }
}
