import 'dart:io';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'dynamic_marker_sheet.dart';
import 'graffiti_map_provider.dart';
import 'map_config.dart';
import 'map_tile_config.dart';
import 'map_visuals.dart';
import 'megapixel_helper.dart';
import 'photo_metadata_service.dart';

class GraffitiMapScreen extends ConsumerStatefulWidget {
  const GraffitiMapScreen({super.key});

  @override
  ConsumerState<GraffitiMapScreen> createState() => _GraffitiMapScreenState();
}

class _GraffitiMapScreenState extends ConsumerState<GraffitiMapScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  double _rotation = 0;
  CacheStore? _tileStore;

  static const _fallbackCenter = LatLng(51.1657, 10.4515); // Deutschland

  // Echte Weltgrenzen — verhindert das mehrfache Kacheln der Welt beim
  // Rauszoomen und hält die Karte im gültigen Bereich.
  static final _worldBounds = LatLngBounds(
    const LatLng(-85.0, -180.0),
    const LatLng(85.0, 180.0),
  );

  @override
  void initState() {
    super.initState();
    _initTileCache();
  }

  Future<void> _initTileCache() async {
    final dir = await getApplicationCacheDirectory();
    if (mounted) {
      setState(() => _tileStore = FileCacheStore('${dir.path}/maptiles'));
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(mapViewModeProvider);
    final collectionInfo = ref.watch(activeCollectionInfoProvider);
    final hashtagFilter = ref.watch(activeHashtagFilterProvider);
    final markersAsync = _query.isEmpty
        ? ref.watch(activeMarkersProvider)
        : ref.watch(markerSearchProvider(_query));
    final hasRating = collectionInfo.valueOrNull?.hasRating ?? false;

    final all = markersAsync.valueOrNull ?? const [];
    final filtered = hashtagFilter == null
        ? all
        : all.where((d) {
            final tags = d.marker.hashtags
                .split(',')
                .map((t) => t.trim().toLowerCase());
            return tags.contains(hashtagFilter.toLowerCase());
          }).toList();

    final withCoords = filtered
        .where((d) => d.marker.latitude != null)
        .toList();
    final initialCenter = withCoords.isNotEmpty
        ? LatLng(
            withCoords.first.marker.latitude!,
            withCoords.first.marker.longitude!,
          )
        : _fallbackCenter;

    return Scaffold(
      backgroundColor: TraumColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: withCoords.isNotEmpty ? 12 : 5,
              minZoom: 3.0,
              maxZoom: 18,
              cameraConstraint: CameraConstraint.contain(bounds: _worldBounds),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
                // Zoom und Drehung schließen sich pro Geste gegenseitig aus:
                // Wer zuerst die Schwelle überschreitet, gewinnt. Höhere
                // Dreh-Schwelle + niedrigere Zoom-Schwelle = Zoom gewinnt
                // leichter, Übergänge wirken weicher.
                enableMultiFingerGestureRace: true,
                rotationThreshold: 35.0,
                pinchZoomThreshold: 0.3,
              ),
              onPositionChanged: (camera, hasGesture) {
                if (camera.rotation != _rotation) {
                  setState(() => _rotation = camera.rotation);
                }
              },
              onLongPress: (_, latlng) => _createPointAt(latlng),
            ),
            children: [
              ...tileUrlTemplatesFor(viewMode).map(
                (url) => TileLayer(
                  urlTemplate: url,
                  userAgentPackageName: 'com.traum.app',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  retinaMode: RetinaMode.isHighDensity(context),
                  tileBounds: _worldBounds,
                  tileProvider: _tileStore == null
                      ? null
                      : CachedTileProvider(
                          store: _tileStore!,
                          maxStale: const Duration(days: 30),
                        ),
                ),
              ),
              CurrentLocationLayer(
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: TraumColors.cyanBlue,
                  ),
                  markerSize: Size(20, 20),
                  accuracyCircleColor: Color(0x2600D4D4), // cyanBlue ~15%
                  headingSectorColor: Color(0x8000D4D4), // cyanBlue ~50%
                ),
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 50,
                  size: const Size(44, 44),
                  markers: withCoords
                      .map(
                        (data) => Marker(
                          point: LatLng(
                            data.marker.latitude!,
                            data.marker.longitude!,
                          ),
                          width: 56,
                          height: 56,
                          child: GestureDetector(
                            onTap: () => context.go(
                              '/graffitimap/marker/${data.marker.id}',
                            ),
                            child: _MapMarkerWidget(
                              data: data,
                              showRating: hasRating,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  builder: (context, markers) => Container(
                    decoration: BoxDecoration(
                      color: TraumColors.cyanBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TraumColors.background,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${markers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _Attribution(viewMode),
            ],
          ),

          // Suchleiste + Karten-Menü
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _searchBar()),
                    const SizedBox(width: 8),
                    _circleButton(
                      icon: Icons.layers_outlined,
                      onTap: () => _showMapSwitcher(context),
                    ),
                    const SizedBox(width: 8),
                    _circleButton(
                      icon: switch (viewMode) {
                        MapViewMode.standard => Icons.map_outlined,
                        MapViewMode.satellite => Icons.satellite_alt_outlined,
                        MapViewMode.hybrid => Icons.public,
                      },
                      onTap: _cycleViewMode,
                    ),
                  ],
                ),
                if (hashtagFilter != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      label: Text('#$hashtagFilter'),
                      labelStyle: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.cyanBlue,
                        fontSize: 12,
                      ),
                      backgroundColor: TraumColors.surface,
                      side: const BorderSide(color: TraumColors.cyanBlue),
                      deleteIconColor: TraumColors.cyanBlue,
                      onDeleted: () =>
                          ref.read(activeHashtagFilterProvider.notifier).state =
                              null,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Aktions-Buttons unten (nah an der Navbar; der Screen ist bereits
          // durch TraumScaffold über der Navbar eingerückt)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _actionButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'Foto',
                  primary: true,
                  onTap: () => _capturePhoto(ImageSource.camera),
                ),
                _actionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Galerie',
                  onTap: () => context.go('/graffitimap/gallery'),
                ),
                _actionButton(
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'Import',
                  onTap: () => _capturePhoto(ImageSource.gallery),
                ),
                _actionButton(
                  icon: Icons.add_location_alt_outlined,
                  label: 'Ort',
                  onTap: () => _createPointAt(_mapController.camera.center),
                ),
              ],
            ),
          ),

          // Kompass (nur bei gedrehter Karte) + Standort-Button
          Positioned(
            right: 16,
            bottom: 82,
            child: Column(
              children: [
                if (_rotation != 0) ...[
                  _circleButton(
                    icon: Icons.explore_outlined,
                    onTap: () => _mapController.rotate(0),
                  ),
                  const SizedBox(height: 10),
                ],
                _circleButton(
                  icon: Icons.my_location,
                  onTap: _goToMyLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cycleViewMode() {
    final notifier = ref.read(mapViewModeProvider.notifier);
    notifier.state = switch (notifier.state) {
      MapViewMode.standard => MapViewMode.satellite,
      MapViewMode.satellite => MapViewMode.hybrid,
      MapViewMode.hybrid => MapViewMode.standard,
    };
  }

  Future<void> _goToMyLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Standortberechtigung fehlt')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Standort nicht verfügbar')),
        );
      }
    }
  }

  Widget _searchBar() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _searchFocus.requestFocus(),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: TraumColors.onBackgroundMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackground,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Nach #Hashtag suchen…',
                  hintStyle: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundSubtle,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                child: const Icon(
                  Icons.close,
                  color: TraumColors.onBackgroundMuted,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: TraumColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: TraumColors.cyanBlue, size: 22),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: primary ? TraumColors.gradientCool : null,
              color: primary ? null : TraumColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: primary ? Colors.white : TraumColors.cyanBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackground,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto(ImageSource source) async {
    final id = ref.read(activeCollectionProvider);
    final collections = await ref.read(mapCollectionsDaoProvider).getAll();
    if (collections.isEmpty) return;
    final collection = collections.firstWhere(
      (c) => c.id == id,
      orElse: () => collections.first,
    );
    final result = await PhotoMetadataService.captureWithMetadata(source);
    if (result == null || !mounted) return;
    // Auto-Gruppieren: Foto im Radius eines vorhandenen Punktes direkt anhängen.
    if (autoGroupFromConfig(collection.fieldConfig) &&
        result.latitude != null) {
      final markers = await ref.read(mapMarkersDaoProvider).getByCollection(id);
      final pts = markers
          .where((m) => m.latitude != null)
          .map((m) => (m.id, m.latitude!, m.longitude!))
          .toList();
      final attachId = nearestMarkerWithin(pts, result.latitude!,
          result.longitude!, groupRadiusFromConfig(collection.fieldConfig));
      if (attachId != null) {
        final db = ref.read(databaseProvider);
        final dims = await readImageDimensions(result.photoPath);
        final photoId =
            await db.markerPhotosDao.insert(MarkerPhotosCompanion.insert(
          markerId: attachId,
          photoPath: result.photoPath,
          widthPx: Value(dims?.width),
          heightPx: Value(dims?.height),
          latitude: Value(result.latitude),
          longitude: Value(result.longitude),
          takenAt: result.takenAt,
          createdAt: DateTime.now(),
        ));
        ref.invalidate(activeMarkersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Zu vorhandenem Ort hinzugefügt'),
              action: SnackBarAction(
                label: 'Rückgängig',
                onPressed: () async {
                  await db.markerPhotosDao.deletePhoto(photoId);
                  try {
                    await File(result.photoPath).delete();
                  } catch (_) {}
                  ref.invalidate(activeMarkersProvider);
                },
              ),
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DynamicMarkerSheet(
          captureResult: result, collection: collection),
    );
    ref.invalidate(activeMarkersProvider);
    ref.invalidate(allHashtagsProvider);
  }

  /// Erstellt einen Punkt ohne Foto am gegebenen Ort. Fotos können später
  /// im Detail-Screen hinzugefügt werden.
  Future<void> _createPointAt(LatLng point) async {
    final id = ref.read(activeCollectionProvider);
    final collections = await ref.read(mapCollectionsDaoProvider).getAll();
    if (collections.isEmpty) return;
    final collection = collections.firstWhere(
      (c) => c.id == id,
      orElse: () => collections.first,
    );
    String? locationName;
    try {
      final p =
          await placemarkFromCoordinates(point.latitude, point.longitude);
      if (p.isNotEmpty) {
        locationName = [p.first.locality, p.first.country]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
      }
    } catch (_) {}
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DynamicMarkerSheet(
        collection: collection,
        latitude: point.latitude,
        longitude: point.longitude,
        locationName: locationName,
      ),
    );
    ref.invalidate(activeMarkersProvider);
    ref.invalidate(allHashtagsProvider);
  }

  void _showMapSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Consumer(
        builder: (ctx, ref, _) {
          final collections = ref.watch(mapCollectionsProvider);
          final active = ref.watch(activeCollectionProvider);
          return collections.when(
            data: (list) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TraumColors.onBackgroundSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Karte wählen',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: TraumColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...list.map(
                    (c) => ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: mapCollectionColor(c).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          mapCollectionIcon(c.iconName),
                          color: mapCollectionColor(c),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        c.hasRating
                            ? 'Mit Bewertung · mehrere Fotos'
                            : 'Einzelfotos',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackgroundMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (active == c.id)
                            const Icon(Icons.check_circle,
                                color: TraumColors.cyanBlue),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: TraumColors.onBackgroundMuted),
                            tooltip: 'Karte bearbeiten',
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.go('/graffitimap/edit/${c.id}');
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        ref.read(activeCollectionProvider.notifier).state =
                            c.id;
                        ref.read(activeHashtagFilterProvider.notifier).state =
                            null;
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: TraumColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: TraumColors.onBackgroundMuted,
                      ),
                    ),
                    title: const Text(
                      'Neue Karte erstellen',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/graffitimap/create');
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: TraumColors.cyanBlue),
            ),
            error: (_, _) => const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  final MapViewMode mode;
  const _Attribution(this.mode);
  @override
  Widget build(BuildContext context) => RichAttributionWidget(
    attributions: [TextSourceAttribution(mapModeAttribution(mode))],
  );
}

class _MapMarkerWidget extends StatelessWidget {
  final MarkerWithPhotos data;
  final bool showRating;
  const _MapMarkerWidget({required this.data, required this.showRating});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: TraumColors.cyanBlue, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipOval(
            child: data.firstPhoto != null
                ? Image.file(
                    File(
                      data.firstPhoto!.thumbnailPath ??
                          data.firstPhoto!.photoPath,
                    ),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: TraumColors.surfaceVariant,
                    child: const Icon(
                      Icons.image,
                      color: TraumColors.cyanBlue,
                      size: 20,
                    ),
                  ),
          ),
        ),
        if (showRating && data.marker.rating != null)
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: TraumColors.amberGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 9),
                  const SizedBox(width: 1),
                  Text(
                    data.marker.rating!.toStringAsFixed(1),
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
        if (data.photos.length > 1)
          Positioned(
            top: -4,
            right: -4,
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
    );
  }
}
