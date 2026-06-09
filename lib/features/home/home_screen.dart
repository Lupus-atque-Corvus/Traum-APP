import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/date_utils.dart' as traum_dates;
import '../../core/utils/update_service.dart';
import '../../l10n/app_localizations.dart';
import 'home_edit_overlay.dart';
import 'home_layout_provider.dart';
import 'home_tile.dart';
import 'home_widget_catalog_sheet.dart';
import 'home_widget_registry.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static bool _permissionCheckDone = false;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndPrompt(context);
      if (!_permissionCheckDone) {
        _permissionCheckDone = true;
        _checkPermissions();
      }
    });
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final missing = <String>[];

    final notif = await Permission.notification.status;
    if (!notif.isGranted) missing.add(l10n.permissionNotifications);

    final loc = await Permission.locationWhenInUse.status;
    if (!loc.isGranted) missing.add(l10n.permissionLocation);

    if (missing.isEmpty || !mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.missingPermissions,
          style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.permissionsContent(missing.join('\n• ')),
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.later,
                style: const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(l10n.openSettings,
                style: const TextStyle(color: TraumColors.coralOrange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userName = ref.watch(userNameProvider);
    final tiles = ref.watch(homeLayoutProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: TraumColors.background,
            expandedHeight: 0,
            title: Text(
              traum_dates.greeting(userName, l10n),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: TraumColors.onBackground),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                    _editMode ? Icons.check_rounded : Icons.edit_outlined,
                    color: TraumColors.onBackground),
                onPressed: () => setState(() => _editMode = !_editMode),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(
              child: StaggeredGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (var i = 0; i < tiles.length; i++)
                    StaggeredGridTile.count(
                      crossAxisCellCount:
                          tiles[i].size == HomeTileSize.small ? 1 : 2,
                      mainAxisCellCount:
                          tiles[i].size == HomeTileSize.large ? 2 : 1,
                      child: Builder(
                        builder: (ctx) {
                          final d = descriptorFor(tiles[i].type);
                          if (d == null) return const SizedBox.shrink();
                          final tile = d.builder(ctx, ref, tiles[i].size);
                          if (!_editMode) return tile;
                          final index = i;
                          return HomeEditTile(
                            index: index,
                            onRemove: () => ref
                                .read(homeLayoutProvider.notifier)
                                .removeAt(index),
                            onResize: () => ref
                                .read(homeLayoutProvider.notifier)
                                .cycleSize(index),
                            onReorder: (from, to) => ref
                                .read(homeLayoutProvider.notifier)
                                .reorder(from, to),
                            child: tile,
                          );
                        },
                      ),
                    ),
                  if (_editMode)
                    StaggeredGridTile.count(
                      crossAxisCellCount: 2,
                      mainAxisCellCount: 1,
                      child: _AddWidgetTile(
                        onTap: () => showHomeWidgetCatalog(context, ref),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gestrichelte „+ Widget"-Kachel, die im Edit-Modus den Katalog öffnet.
class _AddWidgetTile extends StatelessWidget {
  const _AddWidgetTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: TraumColors.onBackgroundSubtle,
            radius: 20,
          ),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: TraumColors.onBackgroundMuted),
                SizedBox(width: 8),
                Text(
                  'Widget',
                  style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
