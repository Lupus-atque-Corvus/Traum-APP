import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radius.dart';

class TraumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Color? color;

  const TraumCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Unlike the other Semantics fixes in this sweep, `child` is opaque and
    // varies per call site — there's no single label to derive here, so this
    // only adds the "button" trait and leaves the child's own text/icon
    // semantics to merge in naturally (no ExcludeSemantics, no label
    // override, which would otherwise silently swallow richer per-call-site
    // content like amounts or dates).
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? TraumColors.surface,
            borderRadius: BorderRadius.circular(TraumRadius.card),
            border: borderColor != null
                ? Border.all(
                    color: borderColor!.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          // `Material(type: transparency)` paints nothing itself but gives
          // any Material descendant placed inside (e.g. a ListTile, as used
          // by NotificationCenterScreen) a proper ancestor to paint ink
          // splashes on — without it those splashes are silently invisible
          // since this Container's own decoration intercepts the paint
          // layer instead.
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}
