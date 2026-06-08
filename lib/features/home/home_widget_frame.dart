import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import 'home_tile.dart';

/// Einheitlicher Rahmen für ein Home-Widget. Füllt die ihm vom Raster
/// zugewiesene Kachel, zeigt optional einen Titel und navigiert bei Tap.
class HomeWidgetFrame extends StatelessWidget {
  final String title;
  final Color accent;
  final String? route;
  final HomeTileSize size;
  final Widget child;
  final bool showTitle;

  const HomeWidgetFrame({
    super.key,
    required this.title,
    required this.accent,
    required this.size,
    required this.child,
    this.route,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route == null ? null : () => context.go(route!),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showTitle)
              Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: accent,
                ),
              ),
            Expanded(child: Center(child: child)),
          ],
        ),
      ),
    );
  }
}
