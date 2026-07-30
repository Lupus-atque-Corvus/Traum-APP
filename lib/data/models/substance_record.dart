// lib/data/models/substance_record.dart

enum SubstanceKlasse { medikament, supplement }

enum DatenStatus { vollstaendig, teilweise, nurChemie }

String? _resolveBilingual(String? de, String? en, String lang) {
  final primary = lang == 'de' ? de : en;
  final secondary = lang == 'de' ? en : de;
  if (primary != null && primary.trim().isNotEmpty) return primary;
  if (secondary != null && secondary.trim().isNotEmpty) return secondary;
  return null;
}

List<String> _parseQuellenTags(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(RegExp(r'\s+'))
      .map((t) => t.replaceAll('[', '').replaceAll(']', '').trim())
      .where((t) => t.isNotEmpty)
      .toList();
}

SubstanceKlasse _parseKlasse(String raw) =>
    raw == 'Supplemente' ? SubstanceKlasse.supplement : SubstanceKlasse.medikament;

DatenStatus _parseDatenStatus(String? raw) {
  switch (raw) {
    case 'vollständig':
      return DatenStatus.vollstaendig;
    case 'nur_chemie':
      return DatenStatus.nurChemie;
    default:
      return DatenStatus.teilweise;
  }
}

/// Dosierungsempfehlungen nach Altersgruppe, je zweisprachig (DE/EN).
/// Leere Felder bleiben `null` — nie fabriziert.
class DosierungNachAltersgruppe {
  final String? _erwachseneDe, _erwachseneEn;
  final String? _kinderDe, _kinderEn;
  final String? _seniorenDe, _seniorenEn;
  final String? _schwangerschaftDe, _schwangerschaftEn;

  const DosierungNachAltersgruppe({
    String? erwachseneDe,
    String? erwachseneEn,
    String? kinderDe,
    String? kinderEn,
    String? seniorenDe,
    String? seniorenEn,
    String? schwangerschaftDe,
    String? schwangerschaftEn,
  })  : _erwachseneDe = erwachseneDe,
        _erwachseneEn = erwachseneEn,
        _kinderDe = kinderDe,
        _kinderEn = kinderEn,
        _seniorenDe = seniorenDe,
        _seniorenEn = seniorenEn,
        _schwangerschaftDe = schwangerschaftDe,
        _schwangerschaftEn = schwangerschaftEn;

  String? erwachsene(String lang) => _resolveBilingual(_erwachseneDe, _erwachseneEn, lang);
  String? kinder(String lang) => _resolveBilingual(_kinderDe, _kinderEn, lang);
  String? senioren(String lang) => _resolveBilingual(_seniorenDe, _seniorenEn, lang);
  String? schwangerschaft(String lang) =>
      _resolveBilingual(_schwangerschaftDe, _schwangerschaftEn, lang);

  bool get isEmpty =>
      erwachsene('de') == null &&
      kinder('de') == null &&
      senioren('de') == null &&
      schwangerschaft('de') == null;
}

/// Eine Zeile aus der Substanz-Referenzdatenbank (`assets/substances_reference.sqlite3`).
/// Read-only Domain-Model — wird nie in die App-Datenbank geschrieben.
class SubstanceRecord {
  final int id;
  final String substance;
  final String folder;
  final SubstanceKlasse klasse;
  final String? kategorie;
  final bool pflanzlich;
  final DatenStatus datenStatus;
  final List<String> quellenTags;
  final String? atc;
  final String? atcKlasse;
  final int? cid;
  final String? summenformel;
  final String? molekulargewicht;
  final String? iupacName;
  final String? smiles;
  final String? inchikey;
  final double? xlogp;
  final double? tpsa;
  final String? rxcui;
  final String? wikidata;
  final String? productType;
  final String? route;
  final DosierungNachAltersgruppe dosierung;
  final String? maxDosisHinweis;

  final String? _beschreibungDe, _beschreibungEn;
  final String? _effektDe, _effektEn;
  final String? _indikationDe, _indikationEn;
  final String? _wechselwirkungenDe, _wechselwirkungenEn;
  final String? _warnungenDe, _warnungenEn;
  final String? _kontraindikationenDe, _kontraindikationenEn;
  final String? _spezPopDe, _spezPopEn;
  final String? _nebenwirkungenTextDe, _nebenwirkungenTextEn;

  const SubstanceRecord({
    required this.id,
    required this.substance,
    required this.folder,
    required this.klasse,
    this.kategorie,
    required this.pflanzlich,
    required this.datenStatus,
    this.quellenTags = const [],
    this.atc,
    this.atcKlasse,
    this.cid,
    this.summenformel,
    this.molekulargewicht,
    this.iupacName,
    this.smiles,
    this.inchikey,
    this.xlogp,
    this.tpsa,
    this.rxcui,
    this.wikidata,
    this.productType,
    this.route,
    required this.dosierung,
    this.maxDosisHinweis,
    String? beschreibungDe,
    String? beschreibungEn,
    String? effektDe,
    String? effektEn,
    String? indikationDe,
    String? indikationEn,
    String? wechselwirkungenDe,
    String? wechselwirkungenEn,
    String? warnungenDe,
    String? warnungenEn,
    String? kontraindikationenDe,
    String? kontraindikationenEn,
    String? spezPopDe,
    String? spezPopEn,
    String? nebenwirkungenTextDe,
    String? nebenwirkungenTextEn,
  })  : _beschreibungDe = beschreibungDe,
        _beschreibungEn = beschreibungEn,
        _effektDe = effektDe,
        _effektEn = effektEn,
        _indikationDe = indikationDe,
        _indikationEn = indikationEn,
        _wechselwirkungenDe = wechselwirkungenDe,
        _wechselwirkungenEn = wechselwirkungenEn,
        _warnungenDe = warnungenDe,
        _warnungenEn = warnungenEn,
        _kontraindikationenDe = kontraindikationenDe,
        _kontraindikationenEn = kontraindikationenEn,
        _spezPopDe = spezPopDe,
        _spezPopEn = spezPopEn,
        _nebenwirkungenTextDe = nebenwirkungenTextDe,
        _nebenwirkungenTextEn = nebenwirkungenTextEn;

  factory SubstanceRecord.fromRow(Map<String, Object?> row) {
    String? s(String key) => row[key] as String?;
    return SubstanceRecord(
      id: row['id'] as int,
      substance: row['substance'] as String,
      folder: row['folder'] as String,
      klasse: _parseKlasse(row['klasse'] as String),
      kategorie: s('kategorie'),
      pflanzlich: (row['pflanzlich'] as int? ?? 0) != 0,
      datenStatus: _parseDatenStatus(s('daten_status')),
      quellenTags: _parseQuellenTags(s('quellen_tags')),
      atc: s('atc'),
      atcKlasse: s('atc_klasse'),
      cid: row['cid'] as int?,
      summenformel: s('summenformel'),
      molekulargewicht: s('molekulargewicht'),
      iupacName: s('iupac_name'),
      smiles: s('smiles'),
      inchikey: s('inchikey'),
      xlogp: (row['xlogp'] as num?)?.toDouble(),
      tpsa: (row['tpsa'] as num?)?.toDouble(),
      rxcui: s('rxcui'),
      wikidata: s('wikidata'),
      productType: s('product_type'),
      route: s('route'),
      maxDosisHinweis: s('max_dosis_hinweis'),
      dosierung: DosierungNachAltersgruppe(
        erwachseneDe: s('dosis_erwachsene_de'),
        erwachseneEn: s('dosis_erwachsene_en'),
        kinderDe: s('dosis_kinder_de'),
        kinderEn: s('dosis_kinder_en'),
        seniorenDe: s('dosis_senioren_de'),
        seniorenEn: s('dosis_senioren_en'),
        schwangerschaftDe: s('dosis_schwangerschaft_de'),
        schwangerschaftEn: s('dosis_schwangerschaft_en'),
      ),
      beschreibungDe: s('beschreibung_de'),
      beschreibungEn: s('beschreibung_en'),
      effektDe: s('effekt_de'),
      effektEn: s('effekt_en'),
      indikationDe: s('indikation_de'),
      indikationEn: s('indikation_en'),
      wechselwirkungenDe: s('wechselwirkungen_de'),
      wechselwirkungenEn: s('wechselwirkungen_en'),
      warnungenDe: s('warnungen_de'),
      warnungenEn: s('warnungen_en'),
      kontraindikationenDe: s('kontraindikationen_de'),
      kontraindikationenEn: s('kontraindikationen_en'),
      spezPopDe: s('spezielle_populationen_de'),
      spezPopEn: s('spezielle_populationen_en'),
      nebenwirkungenTextDe: s('nebenwirkungen_text_de'),
      nebenwirkungenTextEn: s('nebenwirkungen_text_en'),
    );
  }

  String? beschreibung(String lang) => _resolveBilingual(_beschreibungDe, _beschreibungEn, lang);
  String? effekt(String lang) => _resolveBilingual(_effektDe, _effektEn, lang);
  String? indikation(String lang) => _resolveBilingual(_indikationDe, _indikationEn, lang);
  String? wechselwirkungen(String lang) =>
      _resolveBilingual(_wechselwirkungenDe, _wechselwirkungenEn, lang);
  String? warnungen(String lang) => _resolveBilingual(_warnungenDe, _warnungenEn, lang);
  String? kontraindikationen(String lang) =>
      _resolveBilingual(_kontraindikationenDe, _kontraindikationenEn, lang);
  String? spezellePopulationen(String lang) => _resolveBilingual(_spezPopDe, _spezPopEn, lang);
  String? nebenwirkungenText(String lang) =>
      _resolveBilingual(_nebenwirkungenTextDe, _nebenwirkungenTextEn, lang);
}

/// Eine Top-Nebenwirkung (FDA-Meldungszahl-basiert), 1:n zu [SubstanceRecord].
class TopNebenwirkung {
  final int id;
  final int substanceId;
  final String begriff;
  final String? begriffDe;
  final int? meldungen;

  const TopNebenwirkung({
    required this.id,
    required this.substanceId,
    required this.begriff,
    this.begriffDe,
    this.meldungen,
  });

  factory TopNebenwirkung.fromRow(Map<String, Object?> row) => TopNebenwirkung(
        id: row['id'] as int,
        substanceId: row['substance_id'] as int,
        begriff: row['begriff'] as String,
        begriffDe: row['begriff_de'] as String?,
        meldungen: row['meldungen'] as int?,
      );

  String label(String lang) {
    if (lang == 'de' && begriffDe != null && begriffDe!.trim().isNotEmpty) {
      return begriffDe!;
    }
    return begriff;
  }
}
