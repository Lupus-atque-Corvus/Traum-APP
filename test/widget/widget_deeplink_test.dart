import 'package:flutter_test/flutter_test.dart';
import 'package:traum/app.dart' show isKnownWidgetRoute, routeFromWidgetUri;

void main() {
  test('akzeptiert bekannte Widget-Routen', () {
    expect(isKnownWidgetRoute('/budget'), isTrue);
    expect(isKnownWidgetRoute('/graffitimap'), isTrue);
    expect(isKnownWidgetRoute('/unbekannt'), isFalse);
    expect(isKnownWidgetRoute(null), isFalse);
  });

  test('routeFromWidgetUri bildet iOS widgetURL auf bekannte Route ab', () {
    expect(routeFromWidgetUri(Uri.parse('traum:///budget')), '/budget');
    expect(routeFromWidgetUri(Uri.parse('traum:///graffitimap')), '/graffitimap');
    expect(routeFromWidgetUri(Uri.parse('traum://budget')), '/budget');
    expect(routeFromWidgetUri(Uri.parse('traum:///unbekannt')), isNull);
    expect(routeFromWidgetUri(null), isNull);
  });
}
