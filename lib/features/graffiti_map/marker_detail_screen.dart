import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:drift/drift.dart' show Value;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'field_system/map_field.dart';
import 'graffiti_map_provider.dart';
import 'map_visuals.dart';
import 'map_widgets.dart';
import 'megapixel_helper.dart';
import 'photo_metadata_service.dart';

class MarkerDetailScreen extends ConsumerWidget {
  final int markerId;
  const MarkerDetailScreen({super.key, required this.markerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markerAsync = ref.watch(markerByIdProvider(markerId));
    return Scaffold(
      backgroundColor: TraumColors.background,
      body: markerAsync.when(
        data: (data) {
          if (data == null) {
            return const Center(
              child: Text('Eintrag nicht gefunden',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted)),
            );
          }
          return _MarkerDetailBody(data: data);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: TraumColors.cyanBlue)),
        error: (e, _) => Center(
          child: Text('Fehler: $e',
              style: const TextStyle(color: TraumColors.onBackgroundMuted)),
        ),
      ),
    );
  }
}

class _MarkerDetailBody extends ConsumerStatefulWidget {
  final MarkerWithPhotos data;
  const _MarkerDetailBody({required this.data});

  @override
  ConsumerState<_MarkerDetailBody> createState() => _MarkerDetailBodyState();
}

class _MarkerDetailBodyState extends ConsumerState<_MarkerDetailBody> {
  double? _distanceMeters;

  MapMarker get marker => widget.data.marker;

  @override
  void initState() {
    super.initState();
    _loadDistance();
  }

  Future<void> _loadDistance() async {
    if (marker.latitude == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition();
      final d = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, marker.latitude!, marker.longitude!);
      if (mounted) setState(() => _distanceMeters = d);
    } catch (_) {}
  }

  void _navigate() {
    if (marker.latitude == null) return;
    launchUrl(
      Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${marker.latitude},${marker.longitude}'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _setRating(double r) async {
    final db = ref.read(databaseProvider);
    await db.mapMarkersDao
        .updateMarker(marker.copyWith(rating: Value(r)));
    ref.invalidate(markerByIdProvider(marker.id));
    ref.invalidate(activeMarkersProvider);
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: TraumColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: TraumColors.cyanBlue),
              title: const Text('Kamera',
                  style: TextStyle(
                      fontFamily: 'DMSans', color: TraumColors.onBackground)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: TraumColors.cyanBlue),
              title: const Text('Galerie',
                  style: TextStyle(
                      fontFamily: 'DMSans', color: TraumColors.onBackground)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final result = await PhotoMetadataService.captureWithMetadata(source);
    if (result == null) return;
    final dims = await readImageDimensions(result.photoPath);
    final db = ref.read(databaseProvider);
    await db.markerPhotosDao.insert(MarkerPhotosCompanion.insert(
      markerId: marker.id,
      photoPath: result.photoPath,
      widthPx: Value(dims?.width),
      heightPx: Value(dims?.height),
      latitude: Value(result.latitude),
      longitude: Value(result.longitude),
      takenAt: result.takenAt,
      createdAt: DateTime.now(),
    ));
    ref.invalidate(markerByIdProvider(marker.id));
    ref.invalidate(activeMarkersProvider);
  }

  Future<void> _share() async {
    final photo = widget.data.firstPhoto;
    final text = [
      if (marker.title.isNotEmpty) marker.title,
      if (marker.note.isNotEmpty) marker.note,
      if (marker.locationName != null) marker.locationName!,
    ].join('\n');
    if (photo != null) {
      await Share.shareXFiles([XFile(photo.photoPath)], text: text);
    } else {
      await Share.share(text.isEmpty ? 'TRAUM Marker' : text);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surface,
        title: const Text('Löschen?',
            style: TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700)),
        content: const Text('Diesen Eintrag mit allen Fotos löschen?',
            style: TextStyle(
                fontFamily: 'DMSans', color: TraumColors.onBackgroundMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: TraumColors.onBackgroundMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Löschen',
                  style: TextStyle(color: TraumColors.roseRed))),
        ],
      ),
    );
    if (confirm != true) return;
    final db = ref.read(databaseProvider);
    for (final p in widget.data.photos) {
      await db.markerPhotosDao.deletePhoto(p.id);
      try {
        await File(p.photoPath).delete();
      } catch (_) {}
    }
    await db.mapMarkersDao.deleteMarker(marker.id);
    ref.invalidate(activeMarkersProvider);
    ref.invalidate(allHashtagsProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync =
        ref.watch(collectionByIdProvider(marker.collectionId));
    final collection = collectionAsync.valueOrNull;
    final config = collection != null
        ? jsonDecode(collection.fieldConfig) as Map<String, dynamic>
        : const <String, dynamic>{};
    final hasRating = config['rating'] == true;
    final fields = (config['fields'] as List? ?? [])
        .map((f) => MapField.fromJson(f as Map<String, dynamic>))
        .toList();
    final values =
        jsonDecode(marker.customFields) as Map<String, dynamic>;
    final photos = widget.data.photos;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: TraumColors.background,
          pinned: true,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back, color: TraumColors.onBackground),
            onPressed: () => context.pop(),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: TraumColors.onBackground),
              color: TraumColors.surfaceVariant,
              onSelected: (v) {
                if (v == 'addphoto') _addPhoto();
                if (v == 'share') _share();
                if (v == 'location') {
                  context.push('/graffitimap/marker/${marker.id}/location');
                }
                if (v == 'delete') _delete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'addphoto',
                    child: Text('Foto hinzufügen',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackground))),
                const PopupMenuItem(
                    value: 'share',
                    child: Text('Teilen',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackground))),
                PopupMenuItem(
                    value: 'location',
                    child: Text('Standort anpassen',
                        style: TextStyle(
                            fontFamily: 'DMSans', color: TraumColors.onBackground))),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Löschen',
                        style: TextStyle(
                            fontFamily: 'DMSans', color: TraumColors.roseRed))),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto-Galerie
                if (photos.isEmpty)
                  GestureDetector(
                    onTap: _addPhoto,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: TraumColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: TraumColors.cyanBlue, size: 40),
                            SizedBox(height: 8),
                            Text('Foto hinzufügen',
                                style: TextStyle(
                                    fontFamily: 'DMSans',
                                    color: TraumColors.cyanBlue,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  _PhotoGallery(photos: photos, onAddPhoto: _addPhoto),
                const SizedBox(height: 16),

                // Titel
                if (marker.title.isNotEmpty)
                  Text(
                    marker.title,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (marker.title.isNotEmpty) const SizedBox(height: 8),

                // Sterne (editierbar)
                if (hasRating) ...[
                  StarRatingInput(
                    rating: marker.rating ?? 0,
                    onChanged: _setRating,
                  ),
                  const SizedBox(height: 12),
                ],

                // Gefahren-Hinweis
                if ((values['danger'] ?? '').toString().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TraumColors.roseRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: TraumColors.roseRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: TraumColors.roseRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            values['danger'].toString(),
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: TraumColors.onBackground,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Dynamische Felder
                ..._buildFieldChips(fields, values),

                // Notiz
                if (marker.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    marker.note,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],

                // Hashtags
                if (marker.hashtags.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: marker.hashtags
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: TraumColors.cyanDim,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text('#$t',
                                  style: const TextStyle(
                                      fontFamily: 'DMSans',
                                      color: TraumColors.cyanBlue,
                                      fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ],

                // Ort + Entfernung
                if (marker.locationName != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 18, color: TraumColors.cyanBlue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          marker.locationName!,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: TraumColors.onBackgroundMuted,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_distanceMeters != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${_formatDistance(_distanceMeters!)} von dir',
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted,
                        fontSize: 13),
                  ),
                ],

                // Mini-Karte + Navigation
                if (marker.latitude != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 160,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter:
                              LatLng(marker.latitude!, marker.longitude!),
                          initialZoom: 14,
                          interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.traum.app',
                          ),
                          MarkerLayer(markers: [
                            Marker(
                              point: LatLng(
                                  marker.latitude!, marker.longitude!),
                              child: const Icon(Icons.location_on,
                                  color: TraumColors.cyanBlue, size: 36),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: TraumColors.gradientCool,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextButton.icon(
                        onPressed: _navigate,
                        style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.navigation_rounded,
                            color: Colors.white, size: 20),
                        label: const Text('Navigation starten',
                            style: TextStyle(
                                fontFamily: 'DMSans',
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFieldChips(
      List<MapField> fields, Map<String, dynamic> values) {
    final widgets = <Widget>[];
    for (final f in fields) {
      if (f.key == 'danger') continue; // separate Warn-Card
      final v = values[f.key];
      if (v == null || (v is String && v.isEmpty)) continue;
      switch (f.type) {
        case MapFieldType.select:
          final opt = f.options.firstWhere(
            (o) => o.value == v,
            orElse: () => f.options.isNotEmpty
                ? f.options.first
                : const MapFieldOption(value: ''),
          );
          final color = colorFromHex(opt.colorHex);
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(mapFieldIcon(f.iconName), size: 16, color: color),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('$v',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ));
          break;
        case MapFieldType.toggle:
          if (v == true) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(mapFieldIcon(f.iconName),
                      size: 16, color: TraumColors.cyanBlue),
                  const SizedBox(width: 8),
                  Text(f.label,
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackground,
                          fontSize: 13)),
                ],
              ),
            ));
          }
          break;
        case MapFieldType.text:
        case MapFieldType.number:
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(mapFieldIcon(f.iconName),
                    size: 16, color: TraumColors.onBackgroundMuted),
                const SizedBox(width: 8),
                Text('${f.label}: ',
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted,
                        fontSize: 13)),
                Expanded(
                  child: Text('$v',
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackground,
                          fontSize: 13)),
                ),
              ],
            ),
          ));
          break;
      }
    }
    return widgets;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}

/// Wisch-Galerie mit Seiten-Zähler, Dots, Thumbnail-Leiste und „+ Foto".
class _PhotoGallery extends StatefulWidget {
  final List<MarkerPhoto> photos;
  final VoidCallback onAddPhoto;
  const _PhotoGallery({required this.photos, required this.onAddPhoto});

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen(int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: PageView.builder(
          controller: PageController(initialPage: index),
          itemCount: widget.photos.length,
          itemBuilder: (_, i) => InteractiveViewer(
            child: Center(child: Image.file(File(widget.photos[i].photoPath))),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 320,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _openFullscreen(i),
                    child: Image.file(
                      File(photos[i].photoPath),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${_page + 1} / ${photos.length}',
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: MegapixelBadge(formatMegapixels(
                      photos[_page].widthPx, photos[_page].heightPx)),
                ),
              ],
            ),
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              photos.length,
              (i) => Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page
                      ? TraumColors.cyanBlue
                      : TraumColors.onBackgroundSubtle,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == photos.length) {
                return GestureDetector(
                  onTap: widget.onAddPhoto,
                  child: Container(
                    width: 64,
                    decoration: BoxDecoration(
                      color: TraumColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: TraumColors.cyanBlue.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined,
                        color: TraumColors.cyanBlue, size: 22),
                  ),
                );
              }
              final selected = i == _page;
              return GestureDetector(
                onTap: () => _controller.jumpToPage(i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 64,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            selected ? TraumColors.cyanBlue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Image.file(
                      File(photos[i].thumbnailPath ?? photos[i].photoPath),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
