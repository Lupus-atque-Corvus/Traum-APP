import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/abstinence/widgets/progress_icon.dart';

void main() {
  group('resolveIconKey', () {
    test('returns known icon keys unchanged', () {
      for (final key in kProgressIcons) {
        expect(resolveIconKey(key), key);
      }
    });

    test('maps legacy emoji to the expected icon key', () {
      expect(resolveIconKey('🚭'), 'no_smoking');
      expect(resolveIconKey('🚬'), 'no_smoking');
      expect(resolveIconKey('🍺'), 'no_alcohol');
      expect(resolveIconKey('🍷'), 'no_alcohol');
      expect(resolveIconKey('🍬'), 'no_sugar');
      expect(resolveIconKey('💊'), 'no_drugs');
      expect(resolveIconKey('📱'), 'no_phone');
      expect(resolveIconKey('☕'), 'no_coffee');
      expect(resolveIconKey('🎰'), 'no_gambling');
      expect(resolveIconKey('🧘'), 'meditation');
      expect(resolveIconKey('💧'), 'water');
      expect(resolveIconKey('🏃'), 'running');
      expect(resolveIconKey('📖'), 'book');
      expect(resolveIconKey('💰'), 'savings');
      expect(resolveIconKey('🎯'), 'target');
      expect(resolveIconKey('⭐'), 'star');
    });

    test('falls back to the default star icon for null/empty/unknown', () {
      expect(resolveIconKey(null), kDefaultProgressIcon);
      expect(resolveIconKey(''), kDefaultProgressIcon);
      expect(resolveIconKey('🚫'), kDefaultProgressIcon);
      expect(resolveIconKey('some-garbage-value'), kDefaultProgressIcon);
    });

    test('never returns a raw emoji character', () {
      for (final emoji in kLegacyEmojiToIconKey.keys) {
        final resolved = resolveIconKey(emoji);
        expect(kProgressIcons.contains(resolved), isTrue,
            reason: '$emoji resolved to "$resolved", which is not a known icon key');
      }
    });
  });

  group('kProgressIcons asset coverage', () {
    test('every icon key has a matching SVG asset file', () {
      for (final key in kProgressIcons) {
        final file = File('assets/icons/progress/$key.svg');
        expect(file.existsSync(), isTrue,
            reason: 'Missing asset for icon key "$key": ${file.path}');
      }
    });

    test('kDefaultProgressIcon is a valid, known icon key', () {
      expect(kProgressIcons.contains(kDefaultProgressIcon), isTrue);
    });
  });
}
