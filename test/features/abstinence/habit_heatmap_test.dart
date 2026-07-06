import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/abstinence/widgets/habit_heatmap.dart';
import 'package:traum/core/theme/colors.dart';

void main() {
  group('heatmapIntensityFor', () {
    test('zero or negative completion maps to none', () {
      expect(heatmapIntensityFor(0), HeatmapIntensity.none);
      expect(heatmapIntensityFor(-0.5), HeatmapIntensity.none);
    });

    test('a fraction strictly between 0 and 1 maps to partial', () {
      expect(heatmapIntensityFor(0.01), HeatmapIntensity.partial);
      expect(heatmapIntensityFor(0.5), HeatmapIntensity.partial);
      expect(heatmapIntensityFor(0.99), HeatmapIntensity.partial);
    });

    test('completion of 1 or more maps to full', () {
      expect(heatmapIntensityFor(1.0), HeatmapIntensity.full);
      expect(heatmapIntensityFor(1.5), HeatmapIntensity.full);
    });
  });

  group('heatmapIntensityColor', () {
    const base = TraumColors.mintGreen;
    const track = TraumColors.surfaceVariant;

    test('none resolves to the track color', () {
      expect(
        heatmapIntensityColor(HeatmapIntensity.none, base: base, track: track),
        track,
      );
    });

    test('full resolves to the fully opaque base color', () {
      final color = heatmapIntensityColor(HeatmapIntensity.full, base: base, track: track);
      expect(color, base);
    });

    test('partial resolves to a dimmed version of the base color, distinct from full and none', () {
      final color = heatmapIntensityColor(HeatmapIntensity.partial, base: base, track: track);
      expect(color, isNot(base));
      expect(color, isNot(track));
      expect(color.a, lessThan(base.a));
    });
  });

  group('HabitHeatmapRow', () {
    test('asserts exactly 7 day values', () {
      expect(
        () => HabitHeatmapRow(name: 'x', dayValues: const [1, 0, 1]),
        throwsA(isA<AssertionError>()),
      );
      // does not throw with exactly 7 values
      expect(
        HabitHeatmapRow(name: 'x', dayValues: const [1, 0, 1, 0, 1, 0, 1]).dayValues.length,
        7,
      );
    });
  });
}
