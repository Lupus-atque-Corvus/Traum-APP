import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import 'home_layout_provider.dart';
import 'home_tile.dart';
import 'home_widget_registry.dart';

/// Öffnet das Katalog-Bottom-Sheet zum Hinzufügen neuer Home-Widgets.
Future<void> showHomeWidgetCatalog(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _HomeWidgetCatalog(ref: ref),
  );
}

class _HomeWidgetCatalog extends StatefulWidget {
  const _HomeWidgetCatalog({required this.ref});

  final WidgetRef ref;

  @override
  State<_HomeWidgetCatalog> createState() => _HomeWidgetCatalogState();
}

class _HomeWidgetCatalogState extends State<_HomeWidgetCatalog> {
  String _query = '';

  String _sizeHint(HomeTileSize size) => switch (size) {
        HomeTileSize.small => '1×1',
        HomeTileSize.tall => '1×2',
        HomeTileSize.wide => '2×1',
        HomeTileSize.large => '2×2',
        HomeTileSize.xlarge => '2×3',
      };

  @override
  Widget build(BuildContext context) {
    final periodEnabled =
        widget.ref.read(isPeriodTrackingEnabledProvider) == true;
    final q = _query.trim().toLowerCase();

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Widget hinzufügen',
                style: TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                autofocus: false,
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Suchen…',
                  hintStyle:
                      const TextStyle(color: TraumColors.onBackgroundMuted),
                  prefixIcon: const Icon(Icons.search,
                      color: TraumColors.onBackgroundMuted),
                  filled: true,
                  fillColor: TraumColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                shrinkWrap: true,
                children: [
                  for (final group in homeWidgetGroupOrder)
                    ..._buildGroup(group, q, periodEnabled),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroup(
      HomeWidgetGroup group, String query, bool periodEnabled) {
    if (group == HomeWidgetGroup.period && !periodEnabled) {
      return const [];
    }

    final entries = homeWidgetRegistry.entries
        .where((e) => e.value.group == group)
        .where((e) =>
            query.isEmpty || e.value.title.toLowerCase().contains(query))
        .toList();

    if (entries.isEmpty) return const [];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Text(
          homeWidgetGroupLabel(group),
          style: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in entries)
            _WidgetChip(
              entry: e,
              sizeHint: _sizeHint,
              onTap: () => _add(e.key),
            ),
        ],
      ),
    ];
  }

  void _add(HomeWidgetType type) {
    widget.ref.read(homeLayoutProvider.notifier).add(type);
    Navigator.pop(context);
  }
}

class _WidgetChip extends StatelessWidget {
  const _WidgetChip({
    required this.entry,
    required this.sizeHint,
    required this.onTap,
  });

  final MapEntry<HomeWidgetType, HomeWidgetDescriptor> entry;
  final String Function(HomeTileSize) sizeHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = entry.value;
    return Material(
      color: TraumColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: d.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                d.title,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sizeHint(d.defaultSize),
                style: const TextStyle(
                  color: TraumColors.onBackgroundSubtle,
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
