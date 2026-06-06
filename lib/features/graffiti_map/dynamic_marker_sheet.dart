import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'field_system/map_field.dart';
import 'graffiti_map_provider.dart';
import 'map_widgets.dart';
import 'megapixel_helper.dart';
import 'photo_metadata_service.dart';

/// Dynamisches Eintrag-Formular. Liest die Feld-Konfiguration der aktiven
/// Karte und rendert die passenden Felder.
class DynamicMarkerSheet extends ConsumerStatefulWidget {
  final PhotoCaptureResult captureResult;
  final MapCollection collection;
  final int? initialAttachMarkerId;
  const DynamicMarkerSheet({
    super.key,
    required this.captureResult,
    required this.collection,
    this.initialAttachMarkerId,
  });

  @override
  ConsumerState<DynamicMarkerSheet> createState() => _DynamicMarkerSheetState();
}

class _DynamicMarkerSheetState extends ConsumerState<DynamicMarkerSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _hashtagController = TextEditingController();

  late final bool _hasRating;
  late final bool _multiPhoto;
  late final List<MapField> _fields;

  double _rating = 0;
  final Map<String, dynamic> _values = {};
  final List<String> _hashtags = [];

  /// Wenn != null, wird das Foto an einen bestehenden Marker angehängt.
  int? _attachToMarkerId;
  List<MapMarker> _existing = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final config =
        jsonDecode(widget.collection.fieldConfig) as Map<String, dynamic>;
    _hasRating = config['rating'] == true;
    _multiPhoto = config['multiPhoto'] == true;
    _fields = (config['fields'] as List? ?? [])
        .map((f) => MapField.fromJson(f as Map<String, dynamic>))
        .toList();
    if (_multiPhoto) _loadExisting();
    _attachToMarkerId = widget.initialAttachMarkerId;
  }

  Future<void> _loadExisting() async {
    final list =
        await ref.read(mapMarkersDaoProvider).getByCollection(widget.collection.id);
    if (mounted) setState(() => _existing = list);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  void _addHashtag(String raw) {
    var t = raw.trim().replaceAll('#', '');
    if (t.isEmpty) return;
    if (!_hashtags.contains(t)) setState(() => _hashtags.add(t));
    _hashtagController.clear();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final r = widget.captureResult;
    final db = ref.read(databaseProvider);
    final dims = await readImageDimensions(r.photoPath);

    int markerId;
    if (_attachToMarkerId != null) {
      markerId = _attachToMarkerId!;
    } else {
      markerId = await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
        collectionId: widget.collection.id,
        title: Value(_titleController.text.trim()),
        latitude: Value(r.latitude),
        longitude: Value(r.longitude),
        locationName: Value(r.locationName),
        note: Value(_noteController.text.trim()),
        hashtags: Value(_hashtags.join(', ')),
        rating: Value(_hasRating && _rating > 0 ? _rating : null),
        customFields: Value(jsonEncode(_values)),
        isHidden: Value(_values['hidden'] == true),
        createdAt: DateTime.now(),
      ));
    }

    await db.markerPhotosDao.insert(MarkerPhotosCompanion.insert(
      markerId: markerId,
      photoPath: r.photoPath,
      widthPx: Value(dims?.width),
      heightPx: Value(dims?.height),
      takenAt: r.takenAt,
      createdAt: DateTime.now(),
    ));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.captureResult;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TraumColors.onBackgroundSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Foto-Vorschau + Megapixel
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.file(
                      File(r.photoPath),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _MegapixelFromFile(path: r.photoPath),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 16, color: TraumColors.cyanBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.locationName ??
                          (r.latitude != null
                              ? '${r.latitude!.toStringAsFixed(4)}, ${r.longitude!.toStringAsFixed(4)}'
                              : 'Kein Standort'),
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(r.takenAt),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mehrfoto: neuer Eintrag oder zu bestehendem hinzufügen
              if (_multiPhoto && _existing.isNotEmpty) ...[
                _label('Eintrag'),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  initialValue: _attachToMarkerId,
                  dropdownColor: TraumColors.surfaceVariant,
                  decoration: mapInputDecoration(''),
                  style: const TextStyle(
                      fontFamily: 'DMSans', color: TraumColors.onBackground),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Neuer Eintrag'),
                    ),
                    ..._existing.map((m) => DropdownMenuItem<int?>(
                          value: m.id,
                          child: Text(
                            m.title.isNotEmpty
                                ? m.title
                                : (m.locationName ?? 'Punkt #${m.id}'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() => _attachToMarkerId = v),
                ),
                const SizedBox(height: 14),
              ],

              // Titel (nur multiPhoto + neuer Eintrag)
              if (_multiPhoto && _attachToMarkerId == null) ...[
                _label('Name'),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                      fontFamily: 'DMSans', color: TraumColors.onBackground),
                  decoration: mapInputDecoration('Name…'),
                ),
                const SizedBox(height: 14),
              ],

              // Sterne
              if (_hasRating && _attachToMarkerId == null) ...[
                _label('Bewertung'),
                const SizedBox(height: 6),
                StarRatingInput(
                  rating: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: 14),
              ],

              // Dynamische Felder (nur bei neuem Eintrag relevant)
              if (_attachToMarkerId == null)
                ..._fields.map((f) => _buildField(f)),

              // Notiz
              if (_attachToMarkerId == null) ...[
                _label('Notiz'),
                const SizedBox(height: 6),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: const TextStyle(
                      fontFamily: 'DMSans', color: TraumColors.onBackground),
                  decoration: mapInputDecoration('Notiz hinzufügen…'),
                ),
                const SizedBox(height: 14),

                // Hashtags
                _label('Hashtags'),
                const SizedBox(height: 6),
                if (_hashtags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _hashtags
                        .map((t) => Chip(
                              label: Text('#$t',
                                  style: const TextStyle(
                                      fontFamily: 'DMSans',
                                      color: TraumColors.cyanBlue,
                                      fontSize: 12)),
                              backgroundColor: TraumColors.cyanDim,
                              side: BorderSide.none,
                              deleteIconColor: TraumColors.cyanBlue,
                              onDeleted: () =>
                                  setState(() => _hashtags.remove(t)),
                            ))
                        .toList(),
                  ),
                if (_hashtags.isNotEmpty) const SizedBox(height: 8),
                TextField(
                  controller: _hashtagController,
                  style: const TextStyle(
                      fontFamily: 'DMSans', color: TraumColors.onBackground),
                  decoration: mapInputDecoration('Hashtag eingeben'),
                  onSubmitted: _addHashtag,
                ),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: TraumColors.gradientCool,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton(
                    onPressed: _saving ? null : _save,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Speichern',
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: TraumColors.onBackgroundMuted,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildField(MapField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(field.label),
          const SizedBox(height: 6),
          switch (field.type) {
            MapFieldType.select => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: field.options.map((opt) {
                  final sel = _values[field.key] == opt.value;
                  final color = opt.colorHex != null
                      ? Color(int.parse('0xFF${opt.colorHex}'))
                      : TraumColors.cyanBlue;
                  return GestureDetector(
                    onTap: () => setState(() => _values[field.key] = opt.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? color.withValues(alpha: 0.2)
                            : TraumColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? color : Colors.transparent,
                            width: 1.5),
                      ),
                      child: Text(
                        opt.value,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: sel ? color : TraumColors.onBackgroundMuted,
                          fontSize: 13,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            MapFieldType.toggle => Switch(
                value: _values[field.key] == true,
                activeThumbColor: TraumColors.cyanBlue,
                onChanged: (v) => setState(() => _values[field.key] = v),
              ),
            MapFieldType.text => TextField(
                onChanged: (v) => _values[field.key] = v,
                style: const TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackground),
                decoration: mapInputDecoration('Eingeben…'),
              ),
            MapFieldType.number => TextField(
                keyboardType: TextInputType.number,
                onChanged: (v) => _values[field.key] = num.tryParse(v),
                style: const TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackground),
                decoration: mapInputDecoration('0'),
              ),
          },
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

/// Liest die Bildmaße asynchron und zeigt das Megapixel-Badge.
class _MegapixelFromFile extends StatelessWidget {
  final String path;
  const _MegapixelFromFile({required this.path});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({int width, int height})?>(
      future: readImageDimensions(path),
      builder: (context, snap) {
        final dims = snap.data;
        return MegapixelBadge(
            formatMegapixels(dims?.width, dims?.height));
      },
    );
  }
}
