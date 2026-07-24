import '../models/substance_record.dart';
import '../services/substance_reference_db_service.dart';

/// Dünne Repository-Schicht über [SubstanceReferenceDbService] — hält die
/// Screens per Repository-Pattern von der Query-Implementierung entkoppelt
/// (non-negotiable #5). Kein Fallback-Chain mehr (API-Fallback entfernt,
/// siehe Task 6): die 6.580-Einträge-DB ist die einzige Datenquelle.
class SubstanceRepository {
  final SubstanceReferenceDbService _service;

  SubstanceRepository(this._service);

  Future<List<SubstanceRecord>> search(
    String query, {
    SubstanceKlasse? klasseFilter,
    String? kategorieFilter,
    bool? pflanzlichOnly,
  }) =>
      _service.search(
        query,
        klasseFilter: klasseFilter,
        kategorieFilter: kategorieFilter,
        pflanzlichOnly: pflanzlichOnly,
      );

  Future<SubstanceRecord?> findById(int id) => _service.findById(id);

  Future<List<String>> listCategories() => _service.listCategories();

  Future<List<TopNebenwirkung>> topNebenwirkungen(int substanceId) =>
      _service.topNebenwirkungen(substanceId);
}
