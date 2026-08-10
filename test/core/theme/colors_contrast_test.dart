import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/theme/colors.dart';

/// WCAG 2.1 relative luminance (§1.4.3 contrast ratio formula).
double _relativeLuminance(Color c) {
  double linearize(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linearize(c.r) + 0.7152 * linearize(c.g) + 0.0722 * linearize(c.b);
}

double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('onBackgroundSubtle meets WCAG AA (4.5:1) against background', () {
    final ratio =
        contrastRatio(TraumColors.onBackgroundSubtle, TraumColors.background);
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  test('onBackgroundMuted and onBackground remain comfortably above AA too',
      () {
    expect(
        contrastRatio(TraumColors.onBackgroundMuted, TraumColors.background),
        greaterThanOrEqualTo(4.5));
    expect(contrastRatio(TraumColors.onBackground, TraumColors.background),
        greaterThanOrEqualTo(4.5));
  });
}
