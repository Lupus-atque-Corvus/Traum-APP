import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/models/substance_record.dart';
import 'package:traum/data/services/substance_reference_db_service.dart';

const _fixturePath = 'test/fixtures/substances_reference_fixture.sqlite3';

void main() {
  late SubstanceReferenceDbService service;

  setUp(() => service = SubstanceReferenceDbService(_fixturePath));
  tearDown(() => service.dispose());

  test('search finds a substance by prefix via FTS5', () async {
    final results = await service.search('ibupro');
    expect(results, isNotEmpty);
    expect(results.first.substance.toLowerCase(), contains('ibuprofen'));
  });

  test('search returns empty list for blank query', () async {
    expect(await service.search('   '), isEmpty);
  });

  test('search respects klasseFilter (positive: medikament)', () async {
    final results = await service.search(
      'e',
      klasseFilter: SubstanceKlasse.medikament,
    );
    expect(results, isNotEmpty);
    expect(
      results.every((r) => r.klasse == SubstanceKlasse.medikament),
      isTrue,
    );
  });

  test(
    'search respects klasseFilter (negative: supplement, none in fixture)',
    () async {
      final results = await service.search(
        'e',
        klasseFilter: SubstanceKlasse.supplement,
      );
      expect(results, isEmpty);
    },
  );

  test(
    'search respects pflanzlichOnly filter (none in fixture, must return empty)',
    () async {
      final results = await service.search('e', pflanzlichOnly: true);
      expect(results, isEmpty);
    },
  );

  test('findById returns the matching record', () async {
    final all = await service.search('ibuprofen');
    final found = await service.findById(all.first.id);
    expect(found, isNotNull);
    expect(found!.folder, 'Ibuprofen');
  });

  test('findById returns null for unknown id', () async {
    expect(await service.findById(-999), isNull);
  });

  test('listCategories returns distinct non-null categories', () async {
    final cats = await service.listCategories();
    expect(cats, isNotEmpty);
    expect(cats.toSet().length, cats.length); // distinct
    expect(cats.any((c) => c.isEmpty), isFalse);
  });

  test('topNebenwirkungen returns rows ordered by meldungen desc', () async {
    final all = await service.search('ibuprofen');
    final nw = await service.topNebenwirkungen(all.first.id);
    if (nw.length > 1) {
      for (var i = 0; i < nw.length - 1; i++) {
        expect(nw[i].meldungen! >= (nw[i + 1].meldungen ?? 0), isTrue);
      }
    }
  });

  test('NULL fields stay null, never fabricated as empty string', () async {
    final all = await service.search('ibuprofen');
    final record = all.first;
    // At least one of the rarely-populated fields should be genuinely null
    // on the fixture data, not coerced to ''.
    expect(record.iupacName == null || record.iupacName!.isNotEmpty, isTrue);
  });
}
