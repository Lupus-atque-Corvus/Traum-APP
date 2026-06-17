import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import 'graffiti_map_provider.dart';
import 'map_widgets.dart';
import 'megapixel_helper.dart';

class MapGalleryScreen extends ConsumerStatefulWidget {
  const MapGalleryScreen({super.key});

  @override
  ConsumerState<MapGalleryScreen> createState() => _MapGalleryScreenState();
}

class _MapGalleryScreenState extends ConsumerState<MapGalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionInfo = ref.watch(activeCollectionInfoProvider);
    final hashtagFilter = ref.watch(activeHashtagFilterProvider);
    final hashtags = ref.watch(allHashtagsProvider).value ?? const [];
    final markersAsync = _query.isEmpty
        ? ref.watch(activeMarkersProvider)
        : ref.watch(markerSearchProvider(_query));
    final collection = collectionInfo.value;

    final all = markersAsync.value ?? const [];
    final filtered = hashtagFilter == null
        ? all
        : all.where((d) {
            final tags = d.marker.hashtags
                .split(',')
                .map((t) => t.trim().toLowerCase());
            return tags.contains(hashtagFilter.toLowerCase());
          }).toList();

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TraumColors.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          collection?.name ?? 'Übersicht',
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(
                  fontFamily: 'DMSans', color: TraumColors.onBackground),
              decoration: mapInputDecoration('Suchen…').copyWith(
                prefixIcon: const Icon(Icons.search,
                    color: TraumColors.onBackgroundMuted, size: 20),
              ),
            ),
          ),
          if (hashtags.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: hashtags.map((t) {
                  final sel = hashtagFilter?.toLowerCase() == t.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('#$t'),
                      selected: sel,
                      labelStyle: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        color: sel
                            ? TraumColors.cyanBlue
                            : TraumColors.onBackgroundMuted,
                      ),
                      backgroundColor: TraumColors.surface,
                      selectedColor: TraumColors.cyanDim,
                      side: BorderSide(
                          color: sel
                              ? TraumColors.cyanBlue
                              : Colors.transparent),
                      onSelected: (v) => ref
                          .read(activeHashtagFilterProvider.notifier)
                          .state = v ? t : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Noch keine Einträge',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackgroundMuted),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final data = filtered[i];
                      final photo = data.firstPhoto;
                      return GestureDetector(
                        onTap: () => context
                            .go('/graffitimap/marker/${data.marker.id}'),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (photo != null)
                                Image.file(
                                  File(photo.thumbnailPath ?? photo.photoPath),
                                  fit: BoxFit.cover,
                                )
                              else
                                Container(
                                  color: TraumColors.surfaceVariant,
                                  child: const Icon(Icons.image,
                                      color: TraumColors.cyanBlue),
                                ),
                              // Megapixel-Label
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: MegapixelBadge(formatMegapixels(
                                    photo?.widthPx, photo?.heightPx)),
                              ),
                              // Sterne-Badge
                              if ((collection?.hasRating ?? false) &&
                                  data.marker.rating != null)
                                Positioned(
                                  left: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: TraumColors.amberGold,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.white, size: 9),
                                        const SizedBox(width: 1),
                                        Text(
                                          data.marker.rating!
                                              .toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'DMSans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Fotoanzahl-Badge
                              if (data.photos.length > 1)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: TraumColors.cyanBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${data.photos.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'DMSans',
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
