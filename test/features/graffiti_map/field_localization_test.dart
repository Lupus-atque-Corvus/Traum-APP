import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/graffiti_map/field_system/field_localization.dart';
import 'package:traum/features/graffiti_map/field_system/map_templates.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap(Locale locale, Widget Function(BuildContext) builder) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: (ctx) => builder(ctx))),
    );

MapCollection _collection({required String iconName, required String name}) =>
    MapCollection(
      id: 1,
      name: name,
      iconName: iconName,
      colorHex: null,
      hasRating: false,
      multiPhoto: false,
      fieldConfig: '{}',
      sortOrder: 0,
      createdAt: DateTime(2026),
    );

void main() {
  testWidgets(
    'localizedFieldLabel resolves known keys per locale, unknown falls back',
    (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _wrap(const Locale('de'), (c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      );
      expect(localizedFieldLabel(ctx, 'condition', 'irrelevant'), 'Zustand');
      expect(localizedFieldLabel(ctx, 'towerType', 'irrelevant'), 'Turmtyp');
      expect(
        localizedFieldLabel(ctx, 'custom_foo', 'Meine Bezeichnung'),
        'Meine Bezeichnung',
      );

      await tester.pumpWidget(
        _wrap(const Locale('en'), (c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      );
      expect(localizedFieldLabel(ctx, 'condition', 'irrelevant'), 'Condition');
      expect(localizedFieldLabel(ctx, 'towerType', 'irrelevant'), 'Tower type');
      expect(
        localizedFieldLabel(ctx, 'custom_foo', 'Meine Bezeichnung'),
        'Meine Bezeichnung',
      );
    },
  );

  testWidgets(
    'localizedOptionValue resolves known raw values per locale, unknown passes through',
    (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _wrap(const Locale('de'), (c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      );
      expect(localizedOptionValue(ctx, 'Funkmast'), 'Funkmast');
      expect(localizedOptionValue(ctx, 'Verfallen'), 'Verfallen');
      expect(
        localizedOptionValue(ctx, 'Meine eigene Option'),
        'Meine eigene Option',
      );

      await tester.pumpWidget(
        _wrap(const Locale('en'), (c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      );
      expect(localizedOptionValue(ctx, 'Funkmast'), 'Radio mast');
      expect(localizedOptionValue(ctx, 'Verfallen'), 'Decayed');
      expect(
        localizedOptionValue(ctx, 'Meine eigene Option'),
        'Meine eigene Option',
      );
    },
  );

  testWidgets(
    'localizedCollectionName only translates exact icon+name match of a built-in collection',
    (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _wrap(const Locale('en'), (c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      );
      expect(
        localizedCollectionName(
          ctx,
          _collection(iconName: 'tower', name: 'Türme'),
        ),
        'Towers',
      );
      expect(
        localizedCollectionName(
          ctx,
          _collection(iconName: 'home_broken', name: 'Lost Places'),
        ),
        'Lost Places',
      );
      // Same icon as a built-in, but user-chosen name -> must NOT be overridden.
      expect(
        localizedCollectionName(
          ctx,
          _collection(iconName: 'tower', name: 'My Running Log'),
        ),
        'My Running Log',
      );
      // Renamed built-in collection -> respects the user's rename.
      expect(
        localizedCollectionName(
          ctx,
          _collection(iconName: 'spray', name: 'Streetart'),
        ),
        'Streetart',
      );
    },
  );

  testWidgets('localizedTemplateDisplayName resolves all 4 fixed templates', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _wrap(const Locale('en'), (c) {
        ctx = c;
        return const SizedBox.shrink();
      }),
    );
    expect(
      localizedTemplateDisplayName(ctx, MapTemplates.graffiti),
      'Graffiti',
    );
    expect(localizedTemplateDisplayName(ctx, MapTemplates.tuerme), 'Towers');
    expect(
      localizedTemplateDisplayName(ctx, MapTemplates.lostPlaces),
      'Lost Places',
    );
    expect(localizedTemplateDisplayName(ctx, MapTemplates.leer), 'Custom map');
  });
}
