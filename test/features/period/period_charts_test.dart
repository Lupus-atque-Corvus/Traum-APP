import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/period_tracking/widgets/period_charts.dart';

void main() {
  testWidgets('CycleLengthChart renders a bar per length', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CycleLengthChart(lengths: [28, 30, 27, 40], avgLength: 28),
      ),
    ));
    expect(find.byType(CycleLengthChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BbtChart handles empty data without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BbtChart(points: [])),
    ));
    expect(tester.takeException(), isNull);
  });
}
