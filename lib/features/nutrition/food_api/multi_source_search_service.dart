import '../../../data/database/traum_database.dart';
import 'food_source.dart';
import 'multi_source_aggregator.dart';

/// Orchestriert die Volltextsuche über die lokale Produkt-DB und alle
/// registrierten externen [FoodSource]s (OpenFoodFacts, USDA, …),
/// aggregiert/dedupliziert/rankt das Ergebnis (siehe [aggregateAndRank])
/// und liefert eine einzige, sortierte Trefferliste zurück.
///
/// Offline-first: jede externe Quelle läuft einzeln mit Timeout + Try/Catch
/// abgesichert — eine down/langsame/netzlose Quelle liefert `[]` statt die
/// gesamte Suche scheitern zu lassen. Die lokale Suche läuft unabhängig
/// davon immer (SQLite, kein Netz nötig).
class MultiSourceSearchService {
  final List<FoodSource> _sources;
  final FoodProductsDao _localDao;

  MultiSourceSearchService(this._sources, this._localDao);

  Future<List<FoodSearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final local = await _localDao.search(trimmed);
    final remote = await Future.wait(_sources.map((source) async {
      try {
        return await source.search(trimmed).timeout(const Duration(seconds: 8));
      } catch (_) {
        // Quelle down/Timeout/Parse-Fehler → Rest der Suche läuft weiter.
        return <FoodSearchResult>[];
      }
    }));

    return aggregateAndRank(trimmed, [localToResults(local), ...remote]);
  }
}

/// Mappt lokal gespeicherte [FoodProduct]s auf [FoodSearchResult]s (Quelle
/// `'local'`). `sourceId` trägt die lokale Produkt-ID (als String) — so
/// kann die UI bei einem Tap auf einen lokalen Treffer direkt per
/// [FoodProductsDao.getById] zum vollständigen Produkt zurückfinden, ohne
/// einen erneuten Cache-Write auszulösen.
List<FoodSearchResult> localToResults(List<FoodProduct> products) => products
    .map((p) => FoodSearchResult(
          name: p.name,
          brand: p.brand,
          kcalPer100g: p.caloriesPer100g,
          proteinPer100g: p.proteinPer100g,
          carbsPer100g: p.carbsPer100g,
          fatPer100g: p.fatPer100g,
          sugarPer100g: p.sugarPer100g,
          fiberPer100g: p.fiberPer100g,
          saltPer100g: p.saltPer100g,
          source: 'local',
          sourceId: p.id.toString(),
          barcode: p.barcode,
          imageUrl: p.imageUrl,
          localId: p.id,
        ))
    .toList();
