import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/core/providers/preferences_provider.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/home/home_tile.dart';
import 'package:traum/features/home/home_widget_registry.dart';

const _group = HomeWidgetGroup.planning;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('all planning widgets registered and build for each size',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final types = HomeWidgetType.values
        .where((t) => homeWidgetRegistry[t]?.group == _group)
        .toList();
    expect(types, isNotEmpty);
    for (final t in types) {
      final d = homeWidgetRegistry[t]!;
      for (final size in d.sizes) {
        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (ctx, ref, _) => SizedBox(
                    width: 180, height: 180, child: d.builder(ctx, ref, size)),
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$t @ $size threw');
      }
    }
  });
}
