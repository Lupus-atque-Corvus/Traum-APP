import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/period_tracking/widgets/cycle_ring.dart';

void main() {
  testWidgets('CycleRing shows cycle day and phase label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CycleRing(cycleDay: 14, phaseLabel: 'Fruchtbare Phase', progress: 0.5),
      ),
    ));
    expect(find.text('14'), findsOneWidget);
    expect(find.text('Fruchtbare Phase'), findsOneWidget);
  });
}
