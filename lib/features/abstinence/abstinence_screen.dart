import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

class AbstinenceScreen extends ConsumerWidget {
  const AbstinenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(abstinenceTrackersStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text('Abstinenz',
            style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.roseRed,
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: trackersAsync.when(
        data: (trackers) {
          if (trackers.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trackers.length,
            itemBuilder: (ctx, i) => _TrackerCard(
              tracker: trackers[i],
              onDelete: () => ref.read(abstinenceDaoProvider).deleteTracker(trackers[i].id),
              onRelapse: () => _showRelapseDialog(context, ref, trackers[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.roseRed)),
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
      builder: (ctx) => _AddTrackerSheet(
        onAdd: (c) => ref.read(abstinenceDaoProvider).insertTracker(c),
      ),
    );
  }

  void _showRelapseDialog(BuildContext context, WidgetRef ref, AbstinenceTracker tracker) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text('Rückfall bei "${tracker.name}"?',
            style: const TextStyle(color: TraumColors.roseRed, fontFamily: 'DMSans')),
        content: const Text(
          'Das Startdatum wird auf jetzt zurückgesetzt. Der Rückfall wird gespeichert.',
          style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final now = DateTime.now();
              await ref.read(abstinenceDaoProvider).insertEvent(
                AbstinenceEventsCompanion.insert(
                  trackerId: tracker.id,
                  type: 'relapse',
                  eventDate: now,
                ),
              );
              await ref.read(abstinenceDaoProvider).updateTracker(
                AbstinenceTrackersCompanion(
                  id: Value(tracker.id),
                  name: Value(tracker.name),
                  startDate: Value(now),
                  isActive: Value(tracker.isActive),
                  createdAt: Value(tracker.createdAt),
                ),
              );
            },
            child: const Text('Rückfall bestätigen',
                style: TextStyle(color: TraumColors.roseRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _TrackerCard extends StatefulWidget {
  final AbstinenceTracker tracker;
  final VoidCallback onDelete;
  final VoidCallback onRelapse;

  const _TrackerCard({required this.tracker, required this.onDelete, required this.onRelapse});

  @override
  State<_TrackerCard> createState() => _TrackerCardState();
}

class _TrackerCardState extends State<_TrackerCard> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    if (mounted) setState(() => _elapsed = DateTime.now().difference(widget.tracker.startDate));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _elapsed.inDays;
    final hours = _elapsed.inHours % 24;
    final minutes = _elapsed.inMinutes % 60;
    final seconds = _elapsed.inSeconds % 60;

    return Dismissible(
      key: ValueKey(widget.tracker.id),
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
      onDismissed: (_) => widget.onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: TraumColors.roseRed.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (widget.tracker.emoji != null)
                  Text(widget.tracker.emoji!, style: const TextStyle(fontSize: 24)),
                if (widget.tracker.emoji != null) const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.tracker.name,
                      style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700, fontSize: 18)),
                ),
                TextButton(
                  onPressed: widget.onRelapse,
                  style: TextButton.styleFrom(foregroundColor: TraumColors.roseRed),
                  child: const Text('Rückfall', style: TextStyle(fontFamily: 'DMSans', fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TimeUnit(value: days, label: 'Tage'),
                  const Text(':', style: TextStyle(color: TraumColors.roseRed, fontWeight: FontWeight.w700, fontSize: 28)),
                  _TimeUnit(value: hours, label: 'Std'),
                  const Text(':', style: TextStyle(color: TraumColors.roseRed, fontWeight: FontWeight.w700, fontSize: 28)),
                  _TimeUnit(value: minutes, label: 'Min'),
                  const Text(':', style: TextStyle(color: TraumColors.roseRed, fontWeight: FontWeight.w700, fontSize: 28)),
                  _TimeUnit(value: seconds, label: 'Sek'),
                ],
              ),
              if (widget.tracker.note != null) ...[
                const SizedBox(height: 8),
                Text(widget.tracker.note!,
                    style: const TextStyle(color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans', fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  const _TimeUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value.toString().padLeft(2, '0'),
          style: const TextStyle(color: TraumColors.roseRed, fontFamily: 'DMSans',
              fontWeight: FontWeight.w700, fontSize: 28)),
      Text(label, style: const TextStyle(color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans', fontSize: 11)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.block_rounded, size: 64,
            color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        const Text('Noch kein Abstinenz-Tracker',
            style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans',
                fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Tippe auf + um einen Tracker zu starten',
            style: TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 13),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _AddTrackerSheet extends StatefulWidget {
  final Future<void> Function(AbstinenceTrackersCompanion) onAdd;
  const _AddTrackerSheet({required this.onAdd});

  @override
  State<_AddTrackerSheet> createState() => _AddTrackerSheetState();
}

class _AddTrackerSheetState extends State<_AddTrackerSheet> {
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _emoji = '🚫';
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  static const _emojis = ['🚫', '🍺', '🚬', '🎰', '📱', '🍰', '💊', '☕', '🎮', '🛒'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
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
            const Text('Tracker starten',
                style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                labelText: 'Was willst du vermeiden?',
                labelStyle: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                filled: true, fillColor: TraumColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Emoji', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _emojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected ? TraumColors.roseRedDim : TraumColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? TraumColors.roseRed : Colors.transparent),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Startdatum', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
              trailing: Text(
                '${_startDate.day.toString().padLeft(2, '0')}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.year}',
                style: const TextStyle(color: TraumColors.coralOrange, fontFamily: 'DMSans', fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _startDate,
                  firstDate: DateTime(2000), lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: TraumColors.roseRed)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Motivation / Notiz (optional)',
                labelStyle: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                filled: true, fillColor: TraumColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(label: _saving ? 'Starten…' : 'Tracker starten', onPressed: _saving ? null : _save),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name ist ein Pflichtfeld')));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(AbstinenceTrackersCompanion.insert(
      name: _nameCtrl.text.trim(),
      emoji: Value(_emoji),
      startDate: _startDate,
      note: Value(_noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
    ));
    if (mounted) Navigator.pop(context);
  }
}
