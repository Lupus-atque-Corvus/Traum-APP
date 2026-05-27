import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/substance_info.dart';

class SubstanceApiService {
  static const _fdaBase = 'https://api.fda.gov/drug/label.json';
  static const _pubchemBase =
      'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name';

  Future<SubstanceInfo?> fetchMedication(String query) async {
    try {
      final encoded = Uri.encodeComponent('"$query"');
      final uri = Uri.parse(
          '$_fdaBase?search=openfda.generic_name:$encoded+openfda.brand_name:$encoded&limit=1');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List?)?.cast<Map<String, dynamic>>();
      if (results == null || results.isEmpty) return null;
      final r = results.first;
      final openfda = r['openfda'] as Map<String, dynamic>? ?? {};
      final name = ((openfda['generic_name'] as List?)?.first as String?) ??
          ((openfda['brand_name'] as List?)?.first as String?) ??
          query;
      final mechanism = _firstString(r['mechanism_of_action']);
      final dosage = _firstString(r['dosage_and_administration']);
      final warningsRaw = _firstString(r['warnings']);
      final interactionsRaw = _firstString(r['drug_interactions']);

      return SubstanceInfo(
        id: 'fda_${query.toLowerCase().replaceAll(' ', '_')}',
        name: name,
        type: 'medication',
        category: 'Medikament',
        mechanism: mechanism != null && mechanism.length > 300
            ? '${mechanism.substring(0, 300)}…'
            : mechanism,
        commonDosage: dosage != null && dosage.length > 200
            ? '${dosage.substring(0, 200)}…'
            : dosage,
        adverseEvents: warningsRaw != null
            ? [AdverseEventInfo(name: warningsRaw.length > 200
                ? '${warningsRaw.substring(0, 200)}…'
                : warningsRaw)]
            : [],
        interactions: interactionsRaw != null
            ? [InteractionInfo(
                withId: 'unknown',
                withName: 'Verschiedene',
                severity: 'moderate',
                description: interactionsRaw.length > 300
                    ? '${interactionsRaw.substring(0, 300)}…'
                    : interactionsRaw,
              )]
            : [],
        isLocal: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<SubstanceInfo?> fetchSupplement(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final uri = Uri.parse('$_pubchemBase/$encoded/JSON');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final compounds =
          (data['PC_Compounds'] as List?)?.cast<Map<String, dynamic>>();
      if (compounds == null || compounds.isEmpty) return null;
      final props = (compounds.first['props'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      String? iupacName;
      for (final prop in props) {
        final urn = prop['urn'] as Map<String, dynamic>?;
        if (urn?['label'] == 'IUPAC Name' && urn?['name'] == 'Preferred') {
          iupacName = (prop['value'] as Map?)?.values.first as String?;
          break;
        }
      }
      return SubstanceInfo(
        id: 'pubchem_${query.toLowerCase().replaceAll(' ', '_')}',
        name: query,
        type: 'supplement',
        category: 'Supplement',
        mechanism: iupacName != null ? 'IUPAC: $iupacName' : null,
        isLocal: false,
      );
    } catch (_) {
      return null;
    }
  }

  String? _firstString(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first as String?;
    if (value is String) return value;
    return null;
  }
}
