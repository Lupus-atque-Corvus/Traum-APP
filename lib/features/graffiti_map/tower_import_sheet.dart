import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import '../../data/repositories/overpass_tower_repository.dart';
import 'graffiti_map_provider.dart';
import 'tower_import_controller.dart';

enum _ImportMode { viewport, region }

/// Bottom Sheet zum Import von Türmen/Funkmasten aus OpenStreetMap (Overpass)
/// in die aktuelle Türme-Collection. Modus-Wahl (aktueller Kartenausschnitt
/// vs. Region/Land per Namen), Live-Fortschritt, Ergebnis-/Fehler-Anzeige.
class TowerImportSheet extends ConsumerStatefulWidget {
  final int collectionId;
  final LatLngBounds viewportBounds;
  const TowerImportSheet({
    super.key,
    required this.collectionId,
    required this.viewportBounds,
  });

  @override
  ConsumerState<TowerImportSheet> createState() => _TowerImportSheetState();
}

class _TowerImportSheetState extends ConsumerState<TowerImportSheet> {
  _ImportMode _mode = _ImportMode.viewport;
  final _regionController = TextEditingController();

  @override
  void dispose() {
    _regionController.dispose();
    super.dispose();
  }

  void _start() {
    final query = _mode == _ImportMode.viewport
        ? OverpassBboxQuery(
            south: widget.viewportBounds.south,
            west: widget.viewportBounds.west,
            north: widget.viewportBounds.north,
            east: widget.viewportBounds.east,
          )
        : OverpassRegionQuery(_regionController.text.trim());
    ref.read(towerImportControllerProvider.notifier).start(
          collectionId: widget.collectionId,
          query: query,
        );
  }

  String? _errorMessage(AppLocalizations l10n, String key) => switch (key) {
        'mapImportErrorNetwork' => l10n.mapImportErrorNetwork,
        'mapImportErrorHttp' => l10n.mapImportErrorHttp,
        'mapImportErrorRegionNotFound' => l10n.mapImportErrorRegionNotFound,
        _ => l10n.mapImportErrorUnknown,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(towerImportControllerProvider, (prev, next) {
      if (next.done && next.errorKey == null && prev?.done != true) {
        ref.invalidate(activeMarkersProvider);
      }
    });
    final state = ref.watch(towerImportControllerProvider);
    final canStart = !state.running &&
        (_mode == _ImportMode.viewport || _regionController.text.trim().isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: TraumColors.onBackgroundSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            l10n.mapImportTowersTitle,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TraumColors.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          if (!state.done) ...[
            RadioGroup<_ImportMode>(
              groupValue: _mode,
              onChanged: (v) {
                if (state.running) return;
                setState(() => _mode = v!);
              },
              child: Column(
                children: [
                  RadioListTile<_ImportMode>(
                    contentPadding: EdgeInsets.zero,
                    value: _ImportMode.viewport,
                    activeColor: TraumColors.cyanBlue,
                    title: Text(
                      l10n.mapImportAreaViewport,
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackground),
                    ),
                  ),
                  RadioListTile<_ImportMode>(
                    contentPadding: EdgeInsets.zero,
                    value: _ImportMode.region,
                    activeColor: TraumColors.cyanBlue,
                    title: Text(
                      l10n.mapImportAreaRegion,
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackground),
                    ),
                  ),
                ],
              ),
            ),
            if (_mode == _ImportMode.region) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _regionController,
                enabled: !state.running,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackground),
                decoration: InputDecoration(
                  hintText: l10n.mapImportRegionHint,
                  hintStyle: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundSubtle),
                  filled: true,
                  fillColor: TraumColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
          if (state.running) ...[
            LinearProgressIndicator(
              color: TraumColors.cyanBlue,
              backgroundColor: TraumColors.surfaceVariant,
              value: state.progress == null || state.progress!.total == 0
                  ? null
                  : (state.progress!.imported +
                          state.progress!.skipped +
                          state.progress!.errors) /
                      state.progress!.total,
            ),
            const SizedBox(height: 12),
            Text(
              state.progress == null
                  ? '…'
                  : l10n.mapImportProgress(
                      state.progress!.imported,
                      state.progress!.skipped,
                      state.progress!.errors,
                      state.progress!.total,
                    ),
              style: const TextStyle(
                  fontFamily: 'DMSans', color: TraumColors.onBackgroundMuted),
            ),
            const SizedBox(height: 20),
          ],
          if (state.done) ...[
            Text(
              state.errorKey != null
                  ? _errorMessage(l10n, state.errorKey!)!
                  : l10n.mapImportDone,
              style: TextStyle(
                fontFamily: 'DMSans',
                color: state.errorKey != null
                    ? TraumColors.roseRed
                    : TraumColors.onBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (state.errorKey == null && state.progress != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.mapImportProgress(
                  state.progress!.imported,
                  state.progress!.skipped,
                  state.progress!.errors,
                  state.progress!.total,
                ),
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted),
              ),
            ],
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.done
                  ? () => Navigator.pop(context)
                  : (canStart ? _start : null),
              style: FilledButton.styleFrom(
                backgroundColor: TraumColors.cyanBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                state.done ? l10n.mapImportCloseButton : l10n.mapImportStartButton,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
