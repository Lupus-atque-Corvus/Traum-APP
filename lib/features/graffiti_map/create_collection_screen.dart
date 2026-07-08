import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'field_system/map_field.dart';
import 'field_system/map_templates.dart';
import 'field_system/predefined_fields.dart';
import 'graffiti_map_provider.dart';
import 'map_config.dart';
import 'map_visuals.dart';
import 'map_widgets.dart';
import 'photo_grouping.dart';
import 'photo_grouping_service.dart';

class CreateCollectionScreen extends ConsumerStatefulWidget {
  /// Wenn gesetzt, arbeitet der Screen im Bearbeiten-Modus.
  final MapCollection? collection;
  const CreateCollectionScreen({super.key, this.collection});

  @override
  ConsumerState<CreateCollectionScreen> createState() =>
      _CreateCollectionScreenState();
}

class _CreateCollectionScreenState
    extends ConsumerState<CreateCollectionScreen> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'map';
  String _selectedColor = '3DD68C';
  bool _hasRating = false;
  bool _multiPhoto = false;
  int _groupRadius = 50;
  bool _autoGroup = false;
  List<PhotoPoint> _points = const []; // vorhandene Fotos (nur Bearbeiten-Modus)
  final List<MapField> _selectedFields = [];

  bool get _isEditing => widget.collection != null;

  @override
  void initState() {
    super.initState();
    final c = widget.collection;
    if (c != null) {
      _nameController.text = c.name;
      _selectedIcon = c.iconName;
      _selectedColor = c.colorHex ?? '3DD68C';
      _hasRating = c.hasRating;
      _multiPhoto = c.multiPhoto;
      try {
        final cfg = jsonDecode(c.fieldConfig) as Map<String, dynamic>;
        final gr = cfg['groupRadius'];
        if (gr is num) _groupRadius = gr.toInt();
        _selectedFields.addAll((cfg['fields'] as List? ?? [])
            .map((f) => MapField.fromJson(f as Map<String, dynamic>)));
      } catch (_) {}
      _autoGroup = autoGroupFromConfig(c.fieldConfig);
    }
    if (widget.collection != null) _loadPoints(widget.collection!.id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPoints(int collectionId) async {
    final db = ref.read(databaseProvider);
    final markers = await db.mapMarkersDao.getByCollection(collectionId);
    final photos = await db.markerPhotosDao.getByCollection(collectionId);
    final byId = {for (final m in markers) m.id: m};
    final pts = <PhotoPoint>[];
    for (final p in photos) {
      final lat = p.latitude ?? byId[p.markerId]?.latitude;
      final lon = p.longitude ?? byId[p.markerId]?.longitude;
      if (lat == null || lon == null) continue;
      pts.add(PhotoPoint(
          id: p.id,
          markerId: p.markerId,
          lat: lat,
          lon: lon,
          createdAt: p.createdAt));
    }
    if (mounted) setState(() => _points = pts);
  }

  void _applyTemplate(MapTemplate t) {
    setState(() {
      _nameController.text = t.name;
      _selectedIcon = t.iconName;
      _selectedColor = t.colorHex;
      _hasRating = t.hasRating;
      _multiPhoto = t.multiPhoto;
      _groupRadius = t.groupRadius;
      _selectedFields
        ..clear()
        ..addAll(t.fields);
    });
  }

  void _toggleField(MapField f) {
    setState(() {
      final existing = _selectedFields.indexWhere((e) => e.key == f.key);
      if (existing >= 0) {
        _selectedFields.removeAt(existing);
      } else {
        _selectedFields.add(f);
      }
    });
  }

  Future<void> _addCustomField() async {
    final field = await showDialog<MapField>(
      context: context,
      builder: (_) => const _CustomFieldDialog(),
    );
    if (field != null) setState(() => _selectedFields.add(field));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.mapEnterName)),
      );
      return;
    }
    final multiPhoto = _multiPhoto || _autoGroup;
    final config = jsonEncode({
      'rating': _hasRating,
      'multiPhoto': multiPhoto,
      'autoGroup': _autoGroup,
      'groupRadius': _groupRadius,
      'fields': _selectedFields.map((f) => f.toJson()).toList(),
    });
    final dao = ref.read(mapCollectionsDaoProvider);
    final existing = widget.collection;
    if (existing != null) {
      await dao.updateCollection(existing.copyWith(
        name: name,
        iconName: _selectedIcon,
        colorHex: Value(_selectedColor),
        hasRating: _hasRating,
        multiPhoto: multiPhoto,
        fieldConfig: config,
      ));
      ref.invalidate(collectionByIdProvider(existing.id));
      ref.invalidate(activeCollectionInfoProvider);
      ref.invalidate(activeMarkersProvider);
      if (_autoGroup) {
        await regroupCollection(
            ref.read(databaseProvider), existing.id, _groupRadius.toDouble());
        ref.invalidate(activeMarkersProvider);
      }
    } else {
      await dao.insert(MapCollectionsCompanion.insert(
        name: name,
        iconName: _selectedIcon,
        colorHex: Value(_selectedColor),
        hasRating: Value(_hasRating),
        multiPhoto: Value(multiPhoto),
        fieldConfig: Value(config),
        sortOrder: Value(await dao.nextSortOrder()),
        createdAt: DateTime.now(),
      ));
    }
    ref.invalidate(mapCollectionsProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = colorFromHex(_selectedColor);
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TraumColors.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Karte bearbeiten' : 'Neue Karte erstellen',
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          if (!_isEditing) ...[
            _sectionLabel('Vorlage wählen'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: MapTemplates.all.map((t) {
                final c = colorFromHex(t.colorHex);
                return GestureDetector(
                  onTap: () => _applyTemplate(t),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TraumColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: c.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(mapCollectionIcon(t.iconName),
                              color: c, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(t.name,
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  color: TraumColors.onBackground,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          _sectionLabel('Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(
                fontFamily: 'DMSans', color: TraumColors.onBackground),
            decoration: mapInputDecoration('Kartenname…'),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Icon'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kSelectableMapIcons.map((ic) {
              final sel = _selectedIcon == ic;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = ic),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sel
                        ? accent.withValues(alpha: 0.18)
                        : TraumColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? accent : Colors.transparent, width: 1.5),
                  ),
                  child: Icon(mapCollectionIcon(ic),
                      color: sel ? accent : TraumColors.onBackgroundMuted,
                      size: 22),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Farbe'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kSelectableMapColors.map((hex) {
              final c = colorFromHex(hex);
              final sel = _selectedColor == hex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: sel ? Colors.white : Colors.transparent,
                        width: 2.5),
                  ),
                  child: sel
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Funktionen'),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: accent,
            value: _hasRating,
            onChanged: (v) => setState(() => _hasRating = v),
            title: Text(AppLocalizations.of(context)!.mapStarRating,
                style: TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackground)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: accent,
            value: _multiPhoto,
            onChanged: (v) => setState(() => _multiPhoto = v),
            title: Text(AppLocalizations.of(context)!.mapMultiplePhotos,
                style: TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackground)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: accent,
            value: _autoGroup,
            onChanged: (v) => setState(() => _autoGroup = v),
            title: Text(AppLocalizations.of(context)!.mapAutoGroupPhotos,
                style: TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackground)),
            subtitle: const Text(
                'Fotos im Umkreis werden zu einem Ort zusammengefasst',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted,
                    fontSize: 12)),
          ),
          if (_autoGroup) ...[
            const SizedBox(height: 8),
            _sectionLabel('Gruppierungs-Radius'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _groupRadius.toDouble().clamp(10, 200).toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 38,
                    label: '$_groupRadius m',
                    activeColor: accent,
                    onChanged: (v) =>
                        setState(() => _groupRadius = v.round()),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '$_groupRadius m',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackground,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            if (_points.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_points.length} Fotos → '
                  '${groupPhotos(_points, _groupRadius.toDouble()).length} Orte',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.cyanBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
          const SizedBox(height: 12),

          _sectionLabel('Felder'),
          const SizedBox(height: 4),
          ...PredefinedFields.all.map((f) {
            final sel = _selectedFields.any((e) => e.key == f.key);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: accent,
              value: sel,
              onChanged: (_) => _toggleField(f),
              title: Text(f.label,
                  style: const TextStyle(
                      fontFamily: 'DMSans', color: TraumColors.onBackground)),
              secondary: Icon(mapFieldIcon(f.iconName),
                  color: TraumColors.onBackgroundMuted, size: 20),
            );
          }),
          // Eigene Felder, die nicht zu den vordefinierten gehören
          ..._selectedFields
              .where((f) => !PredefinedFields.all.any((p) => p.key == f.key))
              .map((f) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: accent,
                    value: true,
                    onChanged: (_) => _toggleField(f),
                    title: Text(f.label,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackground)),
                    secondary: const Icon(Icons.label_outline,
                        color: TraumColors.onBackgroundMuted, size: 20),
                  )),
          TextButton.icon(
            onPressed: _addCustomField,
            icon: const Icon(Icons.add, color: TraumColors.cyanBlue, size: 18),
            label: Text(AppLocalizations.of(context)!.mapAddCustomField,
                style: TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.cyanBlue)),
          ),
        ],
      ),
      bottomSheet: Container(
        color: TraumColors.background,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: TraumColors.gradientCool,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(_isEditing ? 'Speichern' : 'Karte erstellen',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: TraumColors.onBackgroundMuted,
          letterSpacing: 0.8,
        ),
      );
}

/// Dialog zum Erstellen eines eigenen Feldes.
class _CustomFieldDialog extends StatefulWidget {
  const _CustomFieldDialog();

  @override
  State<_CustomFieldDialog> createState() => _CustomFieldDialogState();
}

class _CustomFieldDialogState extends State<_CustomFieldDialog> {
  final _labelController = TextEditingController();
  final _optionsController = TextEditingController();
  MapFieldType _type = MapFieldType.text;

  @override
  void dispose() {
    _labelController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;
    final key = 'custom_${label.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    List<MapFieldOption> options = const [];
    if (_type == MapFieldType.select) {
      options = _optionsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => MapFieldOption(value: s))
          .toList();
    }
    Navigator.pop(
      context,
      MapField(key: key, label: label, type: _type, options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TraumColors.surface,
      title: Text(AppLocalizations.of(context)!.mapCustomField,
          style: TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackground,
              fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            style: const TextStyle(
                fontFamily: 'DMSans', color: TraumColors.onBackground),
            decoration: mapInputDecoration('Bezeichnung'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MapFieldType>(
            initialValue: _type,
            dropdownColor: TraumColors.surfaceVariant,
            decoration: mapInputDecoration(''),
            style: const TextStyle(
                fontFamily: 'DMSans', color: TraumColors.onBackground),
            items: [
              DropdownMenuItem(
                  value: MapFieldType.text, child: Text(AppLocalizations.of(context)!.fieldTypeText)),
              DropdownMenuItem(
                  value: MapFieldType.select, child: Text(AppLocalizations.of(context)!.fieldTypeSelect)),
              DropdownMenuItem(
                  value: MapFieldType.toggle, child: Text(AppLocalizations.of(context)!.fieldTypeToggle)),
              DropdownMenuItem(
                  value: MapFieldType.number, child: Text(AppLocalizations.of(context)!.fieldTypeNumber)),
            ],
            onChanged: (v) =>
                setState(() => _type = v ?? MapFieldType.text),
          ),
          if (_type == MapFieldType.select) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _optionsController,
              style: const TextStyle(
                  fontFamily: 'DMSans', color: TraumColors.onBackground),
              decoration:
                  mapInputDecoration('Optionen, mit Komma getrennt'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: TraumColors.onBackgroundMuted)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(AppLocalizations.of(context)!.add,
              style: TextStyle(color: TraumColors.cyanBlue)),
        ),
      ],
    );
  }
}
