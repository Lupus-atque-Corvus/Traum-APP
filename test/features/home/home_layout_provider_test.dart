import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/features/home/home_layout_provider.dart';
import 'package:traum/features/home/home_tile.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('seeds default layout when empty', () async {
    final prefs = await SharedPreferences.getInstance();
    final n = HomeLayoutNotifier(prefs);
    expect(n.state, isNotEmpty);
    expect(n.state.first.type, HomeWidgetType.clockDate);
  });

  test('add / removeAt / reorder persist and mutate', () async {
    final prefs = await SharedPreferences.getInstance();
    final n = HomeLayoutNotifier(prefs);
    final len0 = n.state.length;
    n.add(HomeWidgetType.notesCount);
    expect(n.state.length, len0 + 1);
    expect(n.state.last.type, HomeWidgetType.notesCount);
    n.reorder(n.state.length - 1, 0);
    expect(n.state.first.type, HomeWidgetType.notesCount);
    n.removeAt(0);
    expect(n.state.length, len0);

    final n2 = HomeLayoutNotifier(prefs);
    expect(n2.state.length, len0);
  });
}
