import 'dart:convert';
import 'dart:io';
import 'package:gpx/gpx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/database/traum_database.dart';

class MapExportService {
  static Future<void> exportGpx(TraumDatabase db, MapCollection c) async {
    final markers = await db.mapMarkersDao.getByCollection(c.id);
    final visible = markers.where((m) => !m.isHidden && m.latitude != null);
    final gpx = Gpx()
      ..creator = 'TRAUM App'
      ..wpts = visible
          .map((m) => Wpt(
                lat: m.latitude,
                lon: m.longitude,
                name: m.title.isNotEmpty
                    ? m.title
                    : (m.locationName ?? 'Punkt'),
                desc: m.note,
              ))
          .toList();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safe(c.name)}_export.gpx');
    await file.writeAsString(GpxWriter().asString(gpx, pretty: true));
    await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)], text: '${c.name} — TRAUM Export'));
  }

  static Future<void> exportJson(TraumDatabase db, MapCollection c) async {
    final markers = await db.mapMarkersDao.getByCollection(c.id);
    final visible = markers.where((m) => !m.isHidden);
    final data = {
      'collection': c.name,
      'exported': DateTime.now().toIso8601String(),
      'markers': visible
          .map((m) => {
                'title': m.title,
                'lat': m.latitude,
                'lon': m.longitude,
                'location': m.locationName,
                'note': m.note,
                'hashtags': m.hashtags,
                'rating': m.rating,
                'fields': jsonDecode(m.customFields),
              })
          .toList(),
    };
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safe(c.name)}_export.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)], text: '${c.name} — TRAUM Export'));
  }

  static String _safe(String name) =>
      name.replaceAll(RegExp(r'[^\w\-]+'), '_');
}
