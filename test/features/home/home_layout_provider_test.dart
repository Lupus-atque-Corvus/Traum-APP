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

  test('reorder forward (oldIndex < newIndex) drops the tile at the target '
      'position instead of one slot past it (regression: previously off '
      'by one because removing the dragged tile first shifts every later '
      'index — including the drop target — one earlier)', () async {
    final prefs = await SharedPreferences.getInstance();
    final n = HomeLayoutNotifier(prefs);
    n.resetToDefault();
    n.add(HomeWidgetType.notesCount);
    n.add(HomeWidgetType.bestHabitStreak);
    n.add(HomeWidgetType.budgetProgress);
    final before = n.state.map((t) => t.type).toList();
    final aType = before[0];
    final targetType = before[2];

    n.reorder(0, 2); // drag the first tile onto the third tile

    final after = n.state.map((t) => t.type).toList();
    // The dragged tile must land exactly where the target was, pushing the
    // target one slot later — not one slot past the target.
    expect(after[1], aType,
        reason: 'dragged tile should take the target\'s old slot');
    expect(after[2], targetType,
        reason: 'target should be pushed one slot later, not skipped past');
  });
}
