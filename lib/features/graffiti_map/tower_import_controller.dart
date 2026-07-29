import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/overpass_tower_repository.dart';
import '../../data/repositories/tower_import_repository.dart';
import 'graffiti_map_provider.dart';

final overpassTowerRepositoryProvider =
    Provider<OverpassTowerRepository>((ref) => OverpassTowerRepository());

final towerImportRepositoryProvider = Provider<TowerImportRepository>(
  (ref) => TowerImportRepository(
    ref.watch(mapMarkersDaoProvider),
    ref.watch(overpassTowerRepositoryProvider),
  ),
);

class TowerImportState {
  final bool running;
  final TowerImportProgress? progress;
  final String? errorKey;
  final bool done;
  const TowerImportState({
    this.running = false,
    this.progress,
    this.errorKey,
    this.done = false,
  });
}

class TowerImportController extends StateNotifier<TowerImportState> {
  final TowerImportRepository _repo;
  TowerImportController(this._repo) : super(const TowerImportState());

  Future<void> start({
    required int collectionId,
    required OverpassAreaQuery query,
  }) async {
    state = const TowerImportState(running: true);
    try {
      await for (final progress
          in _repo.importTowers(collectionId: collectionId, query: query)) {
        state = TowerImportState(running: true, progress: progress);
      }
      state = TowerImportState(
        running: false,
        progress: state.progress,
        done: true,
      );
    } on OverpassImportException catch (e) {
      state = TowerImportState(running: false, errorKey: e.messageKey, done: true);
    } catch (_) {
      state = const TowerImportState(
        running: false,
        errorKey: 'mapImportErrorUnknown',
        done: true,
      );
    }
  }
}

final towerImportControllerProvider = StateNotifierProvider.autoDispose<
    TowerImportController, TowerImportState>(
  (ref) => TowerImportController(ref.watch(towerImportRepositoryProvider)),
);
