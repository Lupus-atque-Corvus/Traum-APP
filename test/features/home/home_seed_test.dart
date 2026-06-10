import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/home/home_tile.dart';
import 'package:traum/features/home/home_seed.dart';

void main() {
  group('seededLayoutForModules', () {
    test('leere Auswahl liefert Default-Layout', () {
      expect(seededLayoutForModules({}), defaultHomeLayout());
    });

    test('enthält immer die Basis-Widgets', () {
      final tiles = seededLayoutForModules({'budget'});
      final types = tiles.map((t) => t.type).toList();
      expect(types, contains(HomeWidgetType.clockDate));
      expect(types, contains(HomeWidgetType.dailyScore));
    });

    test('fügt Signatur-Widget je gewähltem Modul hinzu', () {
      final tiles = seededLayoutForModules({'budget', 'diary'});
      final types = tiles.map((t) => t.type).toSet();
      expect(types, contains(HomeWidgetType.incomeExpense));
      expect(types, contains(HomeWidgetType.lastEntry));
    });

    test('nutrition fügt zwei Signatur-Widgets hinzu', () {
      final tiles = seededLayoutForModules({'nutrition'});
      final types = tiles.map((t) => t.type).toSet();
      expect(types, contains(HomeWidgetType.caloriesRing));
      expect(types, contains(HomeWidgetType.water));
    });

    test('ignoriert unbekannte Module ohne Fehler', () {
      expect(() => seededLayoutForModules({'unknown'}), returnsNormally);
    });
  });
}
