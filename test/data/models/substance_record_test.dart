// test/data/models/substance_record_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/models/substance_record.dart';

Map<String, Object?> _row(Map<String, Object?> overrides) => {
  'id': 1,
  'substance': 'Ibuprofen',
  'folder': 'ibuprofen',
  'klasse': 'Medikamente',
  'kategorie': 'Schmerzmittel',
  'pflanzlich': 0,
  'daten_status': 'vollständig',
  'quellen_tags': '[dailymed] [wikipedia:ww]',
  'atc': 'M01AE01',
  'atc_klasse': null,
  'cid': 3672,
  'summenformel': 'C13H18O2',
  'molekulargewicht': '206.28',
  'iupac_name': null,
  'smiles': null,
  'inchikey': null,
  'xlogp': 3.5,
  'tpsa': 37.3,
  'rxcui': null,
  'wikidata': null,
  'product_type': null,
  'route': null,
  'beschreibung_de': null,
  'beschreibung_en': 'A nonsteroidal anti-inflammatory drug.',
  'effekt_de': 'Schmerzlinderung',
  'effekt_en': 'Pain relief',
  'indikation_de': null,
  'indikation_en': null,
  'wechselwirkungen_de': 'Erhöhtes Blutungsrisiko mit Warfarin.',
  'wechselwirkungen_en': null,
  'warnungen_de': null,
  'warnungen_en': null,
  'kontraindikationen_de': null,
  'kontraindikationen_en': null,
  'spezielle_populationen_de': null,
  'spezielle_populationen_en': null,
  'nebenwirkungen_text_de': null,
  'nebenwirkungen_text_en': null,
  'dosis_erwachsene_de': '200-400 mg alle 6-8h',
  'dosis_erwachsene_en': null,
  'dosis_kinder_de': null,
  'dosis_kinder_en': null,
  'dosis_senioren_de': null,
  'dosis_senioren_en': null,
  'dosis_schwangerschaft_de': null,
  'dosis_schwangerschaft_en': null,
  'max_dosis_hinweis': 'Max. 2400 mg/Tag',
  'todo': null,
  ...overrides,
};

void main() {
  group('SubstanceRecord.fromRow', () {
    test('parses klasse, datenStatus and quellenTags correctly', () {
      final r = SubstanceRecord.fromRow(_row({}));
      expect(r.klasse, SubstanceKlasse.medikament);
      expect(r.datenStatus, DatenStatus.vollstaendig);
      expect(r.quellenTags, ['dailymed', 'wikipedia:ww']);
      expect(r.pflanzlich, isFalse);
    });

    test('parses Supplemente klasse and pflanzlich=1', () {
      final r = SubstanceRecord.fromRow(
        _row({'klasse': 'Supplemente', 'pflanzlich': 1}),
      );
      expect(r.klasse, SubstanceKlasse.supplement);
      expect(r.pflanzlich, isTrue);
    });

    test('bilingual getter falls back EN->DE when DE is null', () {
      final r = SubstanceRecord.fromRow(_row({}));
      expect(r.beschreibung('de'), 'A nonsteroidal anti-inflammatory drug.');
    });

    test('bilingual getter falls back DE->EN when EN is null', () {
      final r = SubstanceRecord.fromRow(_row({'effekt_en': null}));
      expect(
        r.effekt('en'),
        'Schmerzlinderung',
      ); // EN is null, falls back to DE
    });

    test('bilingual getter returns null when both languages are empty', () {
      final r = SubstanceRecord.fromRow(_row({}));
      expect(r.indikation('de'), isNull);
      expect(r.indikation('en'), isNull);
    });

    test(
      'bilingual getter returns the requested language when both are present',
      () {
        final r = SubstanceRecord.fromRow(
          _row({}),
        ); // both effekt_de and effekt_en set in the base fixture
        expect(
          r.effekt('en'),
          'Pain relief',
        ); // requesting EN returns EN, not DE
        expect(r.effekt('de'), 'Schmerzlinderung'); // requesting DE returns DE
      },
    );

    test('never fabricates a value — null stays null, not empty string', () {
      final r = SubstanceRecord.fromRow(_row({}));
      expect(r.warnungen('de'), isNull);
    });

    test('dosierung getters resolve per age group independently', () {
      final r = SubstanceRecord.fromRow(_row({}));
      expect(r.dosierung.erwachsene('de'), '200-400 mg alle 6-8h');
      expect(r.dosierung.kinder('de'), isNull);
      expect(r.maxDosisHinweis, 'Max. 2400 mg/Tag');
    });
  });

  group('TopNebenwirkung.fromRow', () {
    test('label prefers begriffDe when present', () {
      final t = TopNebenwirkung.fromRow({
        'id': 1,
        'substance_id': 1,
        'begriff': 'NAUSEA',
        'begriff_de': 'Übelkeit',
        'meldungen': 42,
      });
      expect(t.label('de'), 'Übelkeit');
      expect(t.label('en'), 'NAUSEA');
    });

    test('label falls back to begriff (EN) when begriffDe is null', () {
      final t = TopNebenwirkung.fromRow({
        'id': 1,
        'substance_id': 1,
        'begriff': 'NAUSEA',
        'begriff_de': null,
        'meldungen': null,
      });
      expect(t.label('de'), 'NAUSEA');
    });
  });
}
