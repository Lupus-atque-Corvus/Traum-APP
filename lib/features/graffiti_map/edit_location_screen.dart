import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/colors.dart';
import 'graffiti_map_provider.dart';

class EditLocationScreen extends ConsumerStatefulWidget {
  final int markerId;
  const EditLocationScreen({super.key, required this.markerId});

  @override
  ConsumerState<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends ConsumerState<EditLocationScreen> {
  final _mapController = MapController();
  LatLng _center = const LatLng(51.1657, 10.4515);
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await ref.read(mapMarkersDaoProvider).getById(widget.markerId);
    if (m?.latitude != null) {
      _center = LatLng(m!.latitude!, m.longitude!);
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final c = _mapController.camera.center;
    String? locationName;
    try {
      final p = await placemarkFromCoordinates(c.latitude, c.longitude);
      if (p.isNotEmpty) {
        locationName = [p.first.locality, p.first.country]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
      }
    } catch (_) {}
    final dao = ref.read(mapMarkersDaoProvider);
    final m = await dao.getById(widget.markerId);
    if (m != null) {
      await dao.updateMarker(m.copyWith(
        latitude: Value(c.latitude),
        longitude: Value(c.longitude),
        locationName: Value(locationName ?? m.locationName),
      ));
    }
    ref.invalidate(markerByIdProvider(widget.markerId));
    ref.invalidate(activeMarkersProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TraumColors.onBackground),
          onPressed: () => context.pop(),
        ),
        title: const Text('Standort anpassen',
            style: TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700)),
      ),
      body: !_ready
          ? const Center(
              child: CircularProgressIndicator(color: TraumColors.cyanBlue))
          : Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 15,
                    interactionOptions:
                        const InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.traum.app',
                    ),
                  ],
                ),
                const IgnorePointer(
                  child: Icon(Icons.add_location,
                      color: TraumColors.cyanBlue, size: 44),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: TraumColors.gradientCool,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton(
                      onPressed: _saving ? null : _save,
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Hier setzen',
                              style: TextStyle(
                                  fontFamily: 'DMSans',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
