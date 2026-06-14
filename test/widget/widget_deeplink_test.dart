import 'package:flutter_test/flutter_test.dart';
import 'package:traum/app.dart' show isKnownWidgetRoute;

void main() {
  test('akzeptiert bekannte Widget-Routen', () {
    expect(isKnownWidgetRoute('/budget'), isTrue);
    expect(isKnownWidgetRoute('/graffitimap'), isTrue);
    expect(isKnownWidgetRoute('/unbekannt'), isFalse);
    expect(isKnownWidgetRoute(null), isFalse);
  });
}
