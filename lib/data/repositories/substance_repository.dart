import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import '../database/traum_database.dart';
import '../models/substance_info.dart';
import '../services/substance_api_service.dart';

class SubstanceRepository {
  final SubstanceDao _dao;
  final SubstanceApiService _api;
  List<SubstanceInfo>? _local;

  SubstanceRepository(this._dao, this._api);

  Future<List<SubstanceInfo>> _loadLocal() async {
    _local ??= await _parseAsset();
    return _local!;
  }

  Future<List<SubstanceInfo>> _parseAsset() async {
    final raw = await rootBundle.loadString('assets/substances.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((j) => SubstanceInfo.fromJson(j)).toList();
  }

  Future<SubstanceInfo?> findById(String id) async {
    final local = await _loadLocal();
    final fromLocal = local.where((s) => s.id == id).firstOrNull;
    if (fromLocal != null) return fromLocal;
    final cached = await _dao.findById(id);
    if (cached != null) {
      return SubstanceInfo.fromJson(
          jsonDecode(cached.dataJson) as Map<String, dynamic>,
          isLocal: false);
    }
    return null;
  }

  Future<List<SubstanceInfo>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final local = await _loadLocal();
    final localResults =
        local.where((s) => s.name.toLowerCase().contains(q)).toList();
    if (localResults.length >= 3) return localResults;

    final cached = await _dao.searchByName(q);
    final cachedInfos = cached
        .map((c) => SubstanceInfo.fromJson(
            jsonDecode(c.dataJson) as Map<String, dynamic>,
            isLocal: false))
        .toList();

    final combined = [...localResults, ...cachedInfos];
    if (combined.length >= 3) return combined;

    final apiResult = await _fetchAndCache(q);
    if (apiResult != null) {
      final alreadyPresent =
          combined.any((s) => s.name.toLowerCase() == apiResult.name.toLowerCase());
      if (!alreadyPresent) combined.add(apiResult);
    }
    return combined;
  }

  Future<SubstanceInfo?> _fetchAndCache(String query) async {
    SubstanceInfo? result;
    result = await _api.fetchMedication(query);
    result ??= await _api.fetchSupplement(query);
    if (result == null) return null;
    await _dao.upsert(SubstanceCachesCompanion(
      substanceId: Value(result.id),
      name: Value(result.name),
      type: Value(result.type),
      dataJson: Value(jsonEncode(result.toJson())),
      source: Value('api'),
    ));
    return result;
  }

  Future<List<SubstanceInfo>> getAll() => _loadLocal();
}
