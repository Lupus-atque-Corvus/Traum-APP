import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/home/home_seed.dart';
import 'package:traum/features/home/home_tile.dart';

void main() {
  group('Home-Seeding aus Interessen', () {
    test('Seeding enthält Signatur-Widgets der Auswahl', () {
      final tiles = seededLayoutForModules({'training', 'budget', 'notes'});
      final types = tiles.map((t) => t.type).toSet();
      expect(types, containsAll([
        HomeWidgetType.nextWorkout,
        HomeWidgetType.incomeExpense,
        HomeWidgetType.lastNote,
      ]));
    });

    test('Default-Layout bei leerer Auswahl', () {
      expect(seededLayoutForModules({}), defaultHomeLayout());
    });
  });
}
