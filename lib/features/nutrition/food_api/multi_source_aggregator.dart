import 'food_source.dart';

/// Aggregation/Dedupe/Ranking über mehrere [FoodSearchResult]-Quellen hinweg.
///
/// Reine, Flutter-/HTTP-/DB-freie Logik (siehe Task 6.3). Wird von der
/// Such-UI aufgerufen, nachdem lokale + externe Quellen (OFF, USDA, …)
/// jeweils ihre eigene Trefferliste geliefert haben.

/// Priorität der Quellen für "erste Nicht-Null-Quelle gewinnt" beim Merge
/// sowie als Ranking-Bonus. Höherer Wert = höhere Priorität.
const _sourcePriority = {'local': 3, 'off': 2, 'usda': 1};

/// Ranking-Bonus je Quelle (Regel 4). Für gemergte Ergebnisse wird der Bonus
/// der höchstpriorisierten beitragenden Quelle übernommen (siehe
/// [_mergeCluster]) — ein gemergtes Ergebnis ist mindestens so vertrauens-
/// würdig wie sein bester Beitrag, weil auch die Identitätsfelder (Name,
/// Marke, …) bereits von dieser Quelle bevorzugt übernommen werden.
const _sourceRankBonus = {'local': 0.3, 'off': 0.2, 'usda': 0.1};

/// Normalisiert einen String für Dedupe-Vergleich und Namens-Matching:
/// lowercase, deutsche Umlaute/ß transliteriert (ä→a, ö→o, ü→u, ß→ss),
/// mehrfache Whitespaces zu einem einzelnen Space kollabiert, getrimmt.
String normalize(String s) {
  var result = s.toLowerCase();
  result = result
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss');
  result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
  return result;
}

/// Dedupe-Schlüssel: normalisierter Name + normalisierte Marke.
String _dedupeKey(FoodSearchResult r) =>
    '${normalize(r.name)}|${normalize(r.brand ?? '')}';

/// Prüft, ob zwei kcal-Werte "nah genug" sind, um als Duplikat gemergt zu
/// werden (Regel 2/3: Abweichung < 10 %).
///
/// Basis der relativen Abweichung ist der MITTELWERT der beiden Werte
/// (symmetrisch, unabhängig von der Vergleichsreihenfolge). Sonderfall:
/// sind beide Werte gleich (inkl. beide 0), gilt das als Übereinstimmung
/// (verhindert Division durch 0, da der Mittelwert dann ebenfalls 0 wäre).
bool _kcalWithinMergeThreshold(double a, double b) {
  if (a == b) return true;
  final base = (a + b) / 2;
  if (base == 0) return false;
  return (a - b).abs() / base < 0.10;
}

/// Gruppiert Ergebnisse mit demselben Dedupe-Schlüssel in Cluster, deren
/// kcal-Werte paarweise innerhalb der 10%-Schwelle liegen.
///
/// Greedy-Clustering: Ergebnisse werden nach Quellen-Priorität absteigend
/// sortiert (deterministisch), dann wird jedes Ergebnis dem ersten
/// bestehenden Cluster zugeordnet, dessen aktueller kcal-Mittelwert
/// innerhalb der Schwelle liegt; sonst startet es ein neues Cluster. Für
/// die in der Praxis erwarteten Gruppengrößen (2-3 Quellen) verhält sich
/// das wie das paarweise Merge/Conflict aus der Aufgabenstellung.
List<List<FoodSearchResult>> _clusterByKcal(List<FoodSearchResult> items) {
  final sorted = [...items]..sort((a, b) =>
      (_sourcePriority[b.source] ?? 0).compareTo(_sourcePriority[a.source] ?? 0));

  final clusters = <List<FoodSearchResult>>[];
  for (final item in sorted) {
    List<FoodSearchResult>? target;
    for (final cluster in clusters) {
      final avgKcal =
          cluster.map((e) => e.kcalPer100g).reduce((a, b) => a + b) /
              cluster.length;
      if (_kcalWithinMergeThreshold(avgKcal, item.kcalPer100g)) {
        target = cluster;
        break;
      }
    }
    if (target != null) {
      target.add(item);
    } else {
      clusters.add([item]);
    }
  }
  return clusters;
}

/// Ein Zwischenergebnis nach Merge/Dedupe, zusammen mit seinem
/// Quellen-Prioritäts-Bonus fürs Ranking (Regel 4).
typedef _Resolved = ({FoodSearchResult result, double sourceBonus});

/// Merged ein Cluster von >= 2 Duplikaten zu einem einzigen Ergebnis
/// (Regel 2): kcal + die 4 Makro-/Pflichtfelder werden gemittelt; optionale
/// Nährwertfelder (Zucker/Ballaststoffe/Salz) werden über die vorhandenen
/// Nicht-Null-Werte gemittelt (null, wenn keine Quelle einen Wert liefert);
/// Identitätsfelder (Marke, Barcode, Bild-URL, sourceId) nehmen den ersten
/// Nicht-Null-Wert in Prioritätsreihenfolge local > off > usda. Name ist bei
/// [FoodSearchResult] ein Pflichtfeld — hier ebenfalls der Wert der
/// höchstpriorisierten Quelle.
_Resolved _mergeCluster(List<FoodSearchResult> cluster) {
  final byPriority = [...cluster]..sort((a, b) =>
      (_sourcePriority[b.source] ?? 0).compareTo(_sourcePriority[a.source] ?? 0));

  String? firstNonNullString(String? Function(FoodSearchResult) f) {
    for (final r in byPriority) {
      final v = f(r);
      if (v != null) return v;
    }
    return null;
  }

  double avg(Iterable<double> vals) => vals.reduce((a, b) => a + b) / vals.length;

  double? avgOptional(Iterable<double?> vals) {
    final nonNull = vals.whereType<double>().toList();
    if (nonNull.isEmpty) return null;
    return nonNull.reduce((a, b) => a + b) / nonNull.length;
  }

  final merged = FoodSearchResult(
    name: byPriority.first.name,
    brand: firstNonNullString((r) => r.brand),
    kcalPer100g: avg(cluster.map((e) => e.kcalPer100g)),
    proteinPer100g: avg(cluster.map((e) => e.proteinPer100g)),
    carbsPer100g: avg(cluster.map((e) => e.carbsPer100g)),
    fatPer100g: avg(cluster.map((e) => e.fatPer100g)),
    sugarPer100g: avgOptional(cluster.map((e) => e.sugarPer100g)),
    fiberPer100g: avgOptional(cluster.map((e) => e.fiberPer100g)),
    saltPer100g: avgOptional(cluster.map((e) => e.saltPer100g)),
    source: 'merged',
    sourceId: firstNonNullString((r) => r.sourceId),
    barcode: firstNonNullString((r) => r.barcode),
    imageUrl: firstNonNullString((r) => r.imageUrl),
  );

  final topSource = byPriority.first.source;
  return (result: merged, sourceBonus: _sourceRankBonus[topSource] ?? 0);
}

/// Berechnet den Namens-Match-Anteil des Ranking-Scores (Regel 4).
///
/// Die drei Stufen sind exklusiv (nicht additiv): ein exakter Treffer
/// erfüllt zwar auch die Prefix-/Wort-Bedingung, zählt aber nur mit dem
/// höchsten zutreffenden Bonus (+3), nicht mit der Summe aller drei — sonst
/// würde ein exakter Treffer +6 statt +3 bekommen, was die in Regel 4
/// genannten Einzelwerte (+3/+2/+1) sinnlos machen würde.
double _nameMatchScore(String normQuery, String normName) {
  if (normQuery.isEmpty) return 0;
  if (normQuery == normName) return 3;
  if (normName.startsWith(normQuery)) return 2;
  if (normName.split(' ').contains(normQuery)) return 1;
  return 0;
}

/// Aggregiert Suchergebnisse mehrerer Quellen: dedupliziert nahe Duplikate
/// (Regel 1/2), behält echte Konflikte (Regel 3) und sortiert absteigend
/// nach Ranking-Score (Regel 4).
///
/// [perSource] enthält je eine Trefferliste pro Quelle (Reihenfolge der
/// äußeren Liste spielt keine Rolle — die Quellen-Priorität wird über das
/// `source`-Feld jedes [FoodSearchResult] bestimmt, nicht über die Position
/// in [perSource]).
List<FoodSearchResult> aggregateAndRank(
  String query,
  List<List<FoodSearchResult>> perSource,
) {
  final all = perSource.expand((l) => l).toList();
  if (all.isEmpty) return [];

  // Gruppieren nach Dedupe-Schlüssel, Reihenfolge des ersten Auftretens
  // bleibt für deterministisches Verhalten erhalten.
  final groupOrder = <String>[];
  final groups = <String, List<FoodSearchResult>>{};
  for (final r in all) {
    final key = _dedupeKey(r);
    final bucket = groups.putIfAbsent(key, () {
      groupOrder.add(key);
      return [];
    });
    bucket.add(r);
  }

  final resolved = <_Resolved>[];
  for (final key in groupOrder) {
    final items = groups[key]!;
    for (final cluster in _clusterByKcal(items)) {
      if (cluster.length == 1) {
        final r = cluster.single;
        resolved.add((result: r, sourceBonus: _sourceRankBonus[r.source] ?? 0));
      } else {
        resolved.add(_mergeCluster(cluster));
      }
    }
  }

  final normQuery = normalize(query);
  final scored = resolved.map((entry) {
    final normName = normalize(entry.result.name);
    final score = _nameMatchScore(normQuery, normName) +
        entry.result.completeness +
        entry.sourceBonus;
    return (result: entry.result, score: score, normName: normName);
  }).toList();

  scored.sort((a, b) {
    final scoreCmp = b.score.compareTo(a.score);
    if (scoreCmp != 0) return scoreCmp;
    final nameCmp = a.normName.compareTo(b.normName);
    if (nameCmp != 0) return nameCmp;
    // Letzter deterministischer Tiebreak, falls Name+Score identisch sind.
    return a.result.source.compareTo(b.result.source);
  });

  return scored.map((e) => e.result).toList();
}
