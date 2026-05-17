import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/colors.dart';
import '../theme/radius.dart';

class UpdateService {
  static const _apiUrl =
      'https://api.github.com/repos/Lupus-atque-Corvus/Traum-APP/releases/latest';

  static Future<void> checkAndPrompt(BuildContext context) async {
    if (!Platform.isAndroid) return;
    try {
      final pkg = await PackageInfo.fromPlatform();
      final response = await http
          .get(Uri.parse(_apiUrl), headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
      final releaseNotes = (data['body'] as String?) ?? '';
      final assets = data['assets'] as List<dynamic>? ?? [];
      final apkAsset = assets.firstWhere(
        (a) => (a['name'] as String?)?.endsWith('.apk') == true,
        orElse: () => null,
      );
      if (apkAsset == null) return;
      final apkUrl = apkAsset['browser_download_url'] as String?;
      if (apkUrl == null) return;

      if (!_isNewer(tagName, pkg.version)) return;

      if (context.mounted) {
        await _showUpdateDialog(context, tagName, releaseNotes, apkUrl);
      }
    } catch (_) {
      // No internet or error — silent fail
    }
  }

  static bool _isNewer(String remote, String current) {
    final r = _parse(remote);
    final c = _parse(current);
    for (var i = 0; i < 3; i++) {
      if (r[i] > c[i]) return true;
      if (r[i] < c[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String v) {
    final parts = v.split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    String version,
    String releaseNotes,
    String apkUrl,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialog(
        version: version,
        releaseNotes: releaseNotes,
        apkUrl: apkUrl,
      ),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String version;
  final String releaseNotes;
  final String apkUrl;
  const _UpdateDialog({required this.version, required this.releaseNotes, required this.apkUrl});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress;
  bool _downloading = false;
  String? _errorMsg;

  Future<void> _download() async {
    // On Android 8+, the user must explicitly allow installing from unknown sources.
    // Permission.requestInstallPackages.request() opens that settings screen directly.
    if (Platform.isAndroid) {
      final granted = await Permission.requestInstallPackages.isGranted;
      if (!granted) {
        await Permission.requestInstallPackages.request();
        if (!mounted) return;
        final nowGranted = await Permission.requestInstallPackages.isGranted;
        if (!nowGranted) {
          setState(() => _errorMsg = 'Berechtigung fehlt. Aktiviere "Unbekannte Apps" in den Einstellungen und versuche es erneut.');
          return;
        }
      }
    }

    setState(() { _downloading = true; _errorMsg = null; _progress = null; });
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/traum-update.apk');

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.apkUrl));
      final streamedResponse = await client.send(request);
      final total = streamedResponse.contentLength ?? 0;
      var received = 0;

      final sink = file.openWrite();
      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          setState(() => _progress = received / total);
        }
      }
      await sink.close();
      client.close();

      if (mounted) {
        Navigator.pop(context);
        await OpenFile.open(file.path);
      }
    } catch (e) {
      setState(() { _downloading = false; _errorMsg = 'Download fehlgeschlagen'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TraumColors.surfaceElevated,
      title: Text(
        'Update verfügbar — v${widget.version}',
        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.releaseNotes.isNotEmpty) ...[
              SizedBox(
                height: 160,
                child: SingleChildScrollView(
                  child: Text(
                    widget.releaseNotes,
                    style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_downloading) ...[
              Text(
                _progress != null ? '${(_progress! * 100).toStringAsFixed(0)}%' : 'Wird vorbereitet…',
                style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(TraumRadius.chip),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: TraumColors.surfaceVariant,
                  color: TraumColors.coralOrange,
                  minHeight: 6,
                ),
              ),
            ],
            if (_errorMsg != null)
              Text(_errorMsg!, style: const TextStyle(color: TraumColors.roseRed, fontFamily: 'DMSans', fontSize: 12)),
          ],
        ),
      ),
      actions: _downloading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Später', style: TextStyle(color: TraumColors.onBackgroundMuted)),
              ),
              TextButton(
                onPressed: _download,
                child: const Text('Jetzt aktualisieren', style: TextStyle(color: TraumColors.coralOrange, fontWeight: FontWeight.w700)),
              ),
            ],
    );
  }
}
