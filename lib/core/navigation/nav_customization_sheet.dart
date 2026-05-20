import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../providers/preferences_provider.dart';
import '../theme/colors.dart';
import '../theme/radius.dart';
import 'routes.dart';

Future<void> showNavCustomizationSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TraumRadius.card),
      ),
    ),
    builder: (_) => const _NavCustomizationSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavCustomizationSheet extends ConsumerStatefulWidget {
  const _NavCustomizationSheet();

  @override
  ConsumerState<_NavCustomizationSheet> createState() =>
      _NavCustomizationSheetState();
}

class _NavCustomizationSheetState
    extends ConsumerState<_NavCustomizationSheet> {
  late List<String> _slots;

  static const _allModules = [
    'training', 'health', 'nutrition', 'supplements',
    'planning', 'medication', 'abstinence', 'budget',
    'period', 'profile', 'settings',
  ];

  @override
  void initState() {
    super.initState();
    _slots = List<String>.from(ref.read(navSlotsProvider));
  }

  void _onReorder(int oldIndex, int newIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _slots.removeAt(oldIndex);
      _slots.insert(newIndex, item);
    });
  }

  void _remove(String module) {
    setState(() => _slots.remove(module));
  }

  void _add(String module) {
    if (_slots.length >= 4 || _slots.contains(module)) return;
    setState(() => _slots.add(module));
  }

  Future<void> _save() async {
    await ref.read(navSlotsProvider.notifier).setSlots(_slots);
    if (mounted) Navigator.pop(context);
  }

  static IconData _iconFor(String module) {
    switch (module) {
      case 'home':        return Icons.home_rounded;
      case 'training':    return Icons.fitness_center_rounded;
      case 'health':      return Icons.favorite_rounded;
      case 'nutrition':   return Icons.restaurant_rounded;
      case 'supplements': return Icons.science_rounded;
      case 'planning':    return Icons.calendar_today_rounded;
      case 'medication':  return Icons.medication_rounded;
      case 'abstinence':  return Icons.block_rounded;
      case 'budget':      return Icons.account_balance_wallet_rounded;
      case 'period':      return Icons.water_drop_rounded;
      case 'profile':     return Icons.person_rounded;
      case 'settings':    return Icons.settings_rounded;
      default:            return Icons.circle;
    }
  }

  // ── Preview ──────────────────────────────────────────────────────────────

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PreviewIcon(module: 'home', isActive: true),
            ..._slots.map((m) => _PreviewIcon(module: m, icon: _iconFor(m))),
            // fill remaining empty slots as placeholders
            for (int i = _slots.length; i < 4; i++)
              _PreviewSlotEmpty(),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TraumColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active slot list ─────────────────────────────────────────────────────

  Widget _buildSlotItem(String module, int index) {
    final color = TraumColors.moduleColor(module);
    final label = Routes.labelFor(module, AppLocalizations.of(context)!);
    return Container(
      key: ValueKey(module),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: ReorderableDragStartListener(
          index: index,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(
              Icons.drag_handle_rounded,
              color: TraumColors.onBackgroundSubtle,
              size: 22,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(_iconFor(module), color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _remove(module),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: const Icon(
              Icons.close_rounded,
              color: TraumColors.onBackgroundSubtle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  // ── Available modules ────────────────────────────────────────────────────

  Widget _buildAvailableModules(bool periodEnabled) {
    final l10n = AppLocalizations.of(context)!;
    final available = _allModules
        .where((m) => !_slots.contains(m))
        .where((m) => m != 'period' || periodEnabled)
        .toList();

    if (available.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          l10n.allModulesInNav,
          style: const TextStyle(
            color: TraumColors.onBackgroundSubtle,
            fontFamily: 'DMSans',
            fontSize: 13,
          ),
        ),
      );
    }

    final full = _slots.length >= 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: available.map((module) {
          final color = TraumColors.moduleColor(module);
          final label = Routes.labelFor(module, l10n);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: full ? null : () => _add(module),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: full
                    ? TraumColors.surfaceVariant.withValues(alpha: 0.4)
                    : TraumColors.surface,
                borderRadius: BorderRadius.circular(TraumRadius.chip),
                border: Border.all(
                  color: full
                      ? TraumColors.surfaceVariant
                      : color.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(module),
                    color: full
                        ? TraumColors.onBackgroundSubtle
                        : color,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: full
                          ? TraumColors.onBackgroundSubtle
                          : TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final periodEnabled = ref.watch(isPeriodTrackingEnabledProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TraumColors.onBackgroundSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.adjustNav,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  style: TextButton.styleFrom(
                    backgroundColor: TraumColors.indigoBlue.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TraumRadius.chip),
                    ),
                  ),
                  child: Text(
                    l10n.done,
                    style: const TextStyle(
                      color: TraumColors.indigoBlue,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // ── Preview ──────────────────────────────────────────
                _buildPreview(),
                const SizedBox(height: 24),

                // ── Active slots ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        l10n.activeModules,
                        style: const TextStyle(
                          color: TraumColors.onBackgroundSubtle,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_slots.length}/4',
                        style: const TextStyle(
                          color: TraumColors.onBackgroundSubtle,
                          fontFamily: 'DMSans',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      l10n.noModulesYet,
                      style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: _onReorder,
                      children: [
                        for (int i = 0; i < _slots.length; i++)
                          _buildSlotItem(_slots[i], i),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // ── Available modules ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l10n.otherModules,
                    style: const TextStyle(
                      color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildAvailableModules(periodEnabled),
                if (_slots.length >= 4)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 8),
                    child: Text(
                      l10n.maxModulesReached,
                      style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Preview widgets ──────────────────────────────────────────────────────────

class _PreviewIcon extends StatelessWidget {
  final String module;
  final IconData? icon;
  final bool isActive;

  const _PreviewIcon({
    required this.module,
    this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = TraumColors.moduleColor(module);
    final ic = icon ??
        (module == 'home' ? Icons.home_rounded : Icons.circle);

    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.10),
          ]),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(ic, color: color, size: 16),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(ic, color: Colors.white.withValues(alpha: 0.75), size: 18),
    );
  }
}

class _PreviewSlotEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
