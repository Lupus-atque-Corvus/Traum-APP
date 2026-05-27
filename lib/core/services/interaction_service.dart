import '../../data/models/substance_info.dart';
import '../../data/repositories/substance_repository.dart';

class InteractionService {
  final SubstanceRepository _repo;

  InteractionService(this._repo);

  Future<List<InteractionAlert>> checkSubstances(
      List<String> activeSubstanceNames) async {
    if (activeSubstanceNames.length < 2) return [];

    final all = await _repo.getAll();
    final nameToInfo = {
      for (final s in all) s.name.toLowerCase(): s,
    };

    final resolved = activeSubstanceNames
        .map((n) => nameToInfo[n.toLowerCase()])
        .whereType<SubstanceInfo>()
        .toList();

    final alerts = <InteractionAlert>[];
    final seen = <String>{};

    for (var i = 0; i < resolved.length; i++) {
      for (var j = i + 1; j < resolved.length; j++) {
        final a = resolved[i];
        final b = resolved[j];
        final key = '${a.id}|${b.id}';
        if (seen.contains(key)) continue;
        seen.add(key);

        bool alertAdded = false;
        for (final ix in a.interactions) {
          if (ix.withId == b.id || ix.withName.toLowerCase() == b.name.toLowerCase()) {
            final sev = ix.severity.trim().toLowerCase();
            if (sev == 'major' || sev == 'moderate') {
              alerts.add(InteractionAlert(
                substanceAName: a.name,
                substanceBName: b.name,
                severity: ix.severity,
                description: ix.description,
              ));
              alertAdded = true;
            }
            break;
          }
        }
        if (!alertAdded) {
          for (final ix in b.interactions) {
            if (ix.withId == a.id || ix.withName.toLowerCase() == a.name.toLowerCase()) {
              final sev = ix.severity.trim().toLowerCase();
              if (sev == 'major' || sev == 'moderate') {
                alerts.add(InteractionAlert(
                  substanceAName: b.name,
                  substanceBName: a.name,
                  severity: ix.severity,
                  description: ix.description,
                ));
              }
              break;
            }
          }
        }
      }
    }
    return alerts;
  }
}
