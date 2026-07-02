import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/navigation/routes.dart';

void main() {
  group('Routes.isModuleRoot', () {
    test('module roots return true', () {
      expect(Routes.isModuleRoot('/home'), isTrue);
      expect(Routes.isModuleRoot('/budget'), isTrue);
      expect(Routes.isModuleRoot('/training'), isTrue);
      expect(Routes.isModuleRoot('/settings'), isTrue);
    });

    test('sub routes return false', () {
      expect(Routes.isModuleRoot('/budget/stats'), isFalse);
      expect(Routes.isModuleRoot('/training/heatmap'), isFalse);
      expect(Routes.isModuleRoot('/notes/note/5'), isFalse);
      expect(Routes.isModuleRoot('/notifications'), isFalse);
    });
  });
}
