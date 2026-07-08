import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import 'create_collection_screen.dart';
import 'graffiti_map_provider.dart';

/// Lädt die zu bearbeitende Karte und rendert anschließend den
/// (geteilten) CreateCollectionScreen im Bearbeiten-Modus.
class EditCollectionScreen extends ConsumerWidget {
  final int collectionId;
  const EditCollectionScreen({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collectionByIdProvider(collectionId));
    return async.when(
      data: (c) => c == null
          ? Scaffold(
              backgroundColor: TraumColors.background,
              body: Center(
                child: Text(AppLocalizations.of(context)!.mapNotFound,
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted)),
              ),
            )
          : CreateCollectionScreen(collection: c),
      loading: () => const Scaffold(
        backgroundColor: TraumColors.background,
        body: Center(
            child: CircularProgressIndicator(color: TraumColors.cyanBlue)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: TraumColors.background,
        body: Center(
          child: Text(AppLocalizations.of(context)!.errorWithDetail(e.toString()),
              style: const TextStyle(color: TraumColors.onBackgroundMuted)),
        ),
      ),
    );
  }
}
