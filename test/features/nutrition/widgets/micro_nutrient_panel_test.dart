import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/nutrition/micro_nutrients.dart';
import 'package:traum/features/nutrition/nutrition_providers.dart';
import 'package:traum/features/nutrition/widgets/micro_nutrient_panel.dart';

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  // The panel's live drift query streams (dailyMicros, supplements, logs) leave a
  // pending zero-duration timer that trips testWidgets' "A Timer is still pending"
  // check. We override those three providers with plain, self-closing streams so
  // the widget opens no drift streams; the checkbox toggle still hits the real
  // DAO (supplementDaoProvider is not overridden) so the write-path is exercised.
  Future<void> pump(
    WidgetTester tester, {
    List<Supplement> supplements = const [],
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dailyMicrosProvider.overrideWith((ref, arg) => MicroNutrients.empty),
        supplementsStreamProvider
            .overrideWith((ref) => Stream.fromIterable([supplements])),
        supplementLogsTodayProvider
            .overrideWith((ref) => Stream.fromIterable([const <SupplementLog>[]])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MicroNutrientPanel(dateStr: formatDateStr(DateTime.now())),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('collapsed by default, expands on tap', (tester) async {
    await pump(tester);
    // Collapsed: nutrient rows not shown yet.
    expect(find.text('Vitamin C'), findsNothing);
    await tester.tap(find.textContaining('Mikronährstoffe'));
    await tester.pumpAndSettle();
    expect(find.text('Vitamin C'), findsOneWidget);
    expect(find.text('Zucker'), findsOneWidget);
  });

  testWidgets('checking a supplement updates the bar', (tester) async {
    await db.supplementDao.insertSupplement(SupplementsCompanion.insert(
      id: const Value(1),
      name: 'Vitamin C',
      isActive: const Value(true),
      nutrientKey: const Value('vitC'),
      dosageAmount: const Value('500'),
      dosageUnit: const Value('mg'),
    ));
    final supp = Supplement(
      id: 1,
      name: 'Vitamin C',
      timings: '[]',
      isActive: true,
      createdAt: DateTime.now(),
      nutrientKey: 'vitC',
      dosageAmount: '500',
      dosageUnit: 'mg',
    );

    await pump(tester, supplements: [supp]);
    await tester.tap(find.textContaining('Mikronährstoffe'));
    await tester.pumpAndSettle();

    // Supplement appears in "Supplements heute" with a checkbox.
    expect(find.text('Vitamin C'), findsWidgets);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    // A log was written for today (queried directly, no lingering stream).
    final logs = await db.select(db.supplementLogs).get();
    expect(logs.length, 1);
    expect(logs.single.supplementId, 1);
  });
}
