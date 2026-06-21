import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../budget_providers.dart';

/// Wrappt eine Betragsanzeige und legt — solange [budgetBalanceVisibleProvider]
/// `false` ist — einen weichen Blur darüber (entspricht dem `filter:blur`-Effekt
/// aus dem Design-Prototyp). Der Übergang wird über 250 ms animiert.
///
/// [enabled] erlaubt es, einzelne Vorkommen vom Verbergen auszunehmen.
class HiddenAmount extends ConsumerWidget {
  final Widget child;
  final bool enabled;

  const HiddenAmount({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(budgetBalanceVisibleProvider);
    final blurOn = enabled && !visible;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: blurOn ? 6.0 : 0.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, sigma, child) {
        if (sigma < 0.05) return child!;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
        );
      },
      child: child,
    );
  }
}
