import 'package:flutter_test/flutter_test.dart';
import 'package:traum/widget/widget_catalog.dart';
import 'package:traum/widget/widget_snapshot.dart';

void main() {
  test('WidgetTemplate enthält die neuen v2-Templates', () {
    final names = WidgetTemplate.values.map((e) => e.name).toSet();
    expect(names.containsAll(
      {'ring', 'ringTrio', 'barChart', 'sparkline', 'donut', 'dashboard', 'motivation'}),
      isTrue);
  });

  test('encodeSeries verbindet Werte mit Komma, encodeLabels mit Semikolon', () {
    expect(WidgetSnapshot.encodeSeries(<num>[4200, 5100, 0]), '4200,5100,0');
    expect(WidgetSnapshot.encodeSeries(const <num>[]), '');
    expect(WidgetSnapshot.encodeLabels(const ['Apfel', 'Reis']), 'Apfel;Reis');
  });
}
