import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';
import 'feedback_type.dart';

class FeedbackBottomSheet extends ConsumerStatefulWidget {
  const FeedbackBottomSheet({super.key});

  @override
  ConsumerState<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends ConsumerState<FeedbackBottomSheet> {
  FeedbackType _type = FeedbackType.bug;
  final _controller = TextEditingController();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
            const SizedBox(height: 20),
            const Text(
              'Feedback senden',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TraumColors.onBackground,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dein Feedback hilft TRAUM besser zu machen.',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                color: TraumColors.onBackgroundMuted,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TYP',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TraumColors.onBackgroundMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: FeedbackType.values.map((type) {
                final isSelected = _type == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? type.color.withValues(alpha: 0.15)
                            : TraumColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? type.color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type.icon,
                            color: isSelected ? type.color : TraumColors.onBackgroundMuted,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? type.color : TraumColors.onBackgroundMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'KURZTITEL',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TraumColors.onBackgroundMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackground),
              decoration: InputDecoration(
                hintText: _type == FeedbackType.bug
                    ? 'z.B. "Wasser-Tracking aktualisiert nicht"'
                    : _type == FeedbackType.feature
                        ? 'z.B. "Darkmode für Widgets"'
                        : 'z.B. "Tipp-Fehler im Onboarding"',
                hintStyle: const TextStyle(
                    color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
                filled: true,
                fillColor: TraumColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: TraumColors.coralOrange, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'BESCHREIBUNG',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TraumColors.onBackgroundMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 4,
              style: const TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackground),
              decoration: InputDecoration(
                hintText: _type == FeedbackType.bug
                    ? 'Beschreibe was passiert ist und wie man es reproduzieren kann...'
                    : 'Beschreibe deine Idee oder den gewünschten Verbesserungsvorschlag...',
                hintStyle: const TextStyle(
                    color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
                filled: true,
                fillColor: TraumColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: TraumColors.coralOrange, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.info_outline, size: 14, color: TraumColors.onBackgroundSubtle),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Systemdaten (App-Version, Android-Version, Gerät) werden automatisch angehängt.',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: TraumColors.onBackgroundSubtle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [TraumColors.coralOrange, TraumColors.peachOrange],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  color: _titleController.text.trim().isEmpty
                      ? TraumColors.surfaceVariant
                      : null,
                ),
                child: TextButton.icon(
                  onPressed: _titleController.text.trim().isEmpty
                      ? null
                      : () => _submit(context),
                  icon: const Icon(Icons.open_in_browser, color: Colors.white, size: 18),
                  label: const Text(
                    'GitHub öffnen & absenden',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Öffnet GitHub im Browser. Ein GitHub-Account ist zum Absenden nötig.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 10,
                  color: TraumColors.onBackgroundSubtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final systemInfo = await _buildSystemInfo();
    final issueUrl = _buildGitHubUrl(systemInfo);
    if (!context.mounted) return;
    Navigator.pop(context);
    await launchUrl(Uri.parse(issueUrl), mode: LaunchMode.externalApplication);
  }

  Future<String> _buildSystemInfo() async {
    final pkg = await PackageInfo.fromPlatform();
    String deviceInfo = '';
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      deviceInfo = '- **Gerät:** ${info.manufacturer} ${info.model}\n'
          '- **Android:** ${info.version.release} (API ${info.version.sdkInt})\n';
    } else if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      deviceInfo = '- **Gerät:** ${info.model}\n'
          '- **iOS:** ${info.systemVersion}\n';
    }

    final prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString('app_locale') ?? 'de';

    return '''
---
**Systeminfo (automatisch)**
- **App-Version:** ${pkg.version}+${pkg.buildNumber}
$deviceInfo- **Sprache:** $locale
- **Datum:** ${DateTime.now().toString().substring(0, 16)}
''';
  }

  String _buildGitHubUrl(String systemInfo) {
    final title = '[${_type.githubLabel}] ${_titleController.text.trim()}';
    final body = _buildBody(systemInfo);

    return 'https://github.com/Lupus-atque-Corvus/Android-app-/issues/new'
        '?title=${Uri.encodeComponent(title)}'
        '&body=${Uri.encodeComponent(body)}'
        '&labels=${Uri.encodeComponent(_type.githubLabel)}';
  }

  String _buildBody(String systemInfo) {
    switch (_type) {
      case FeedbackType.bug:
        return '''## Fehlerbeschreibung

${_controller.text.trim().isEmpty ? '_Keine Beschreibung angegeben._' : _controller.text.trim()}

## Schritte zum Reproduzieren

1.
2.
3.

## Erwartetes Verhalten

_Was sollte passieren?_

## Tatsächliches Verhalten

_Was ist stattdessen passiert?_

$systemInfo''';

      case FeedbackType.feature:
        return '''## Feature-Idee

${_controller.text.trim().isEmpty ? '_Keine Beschreibung angegeben._' : _controller.text.trim()}

## Warum ist das nützlich?

_Für wen und in welcher Situation hilft dieses Feature?_

## Mögliche Umsetzung

_Optional: Ideen wie es umgesetzt werden könnte._

$systemInfo''';

      case FeedbackType.improvement:
        return '''## Verbesserungsvorschlag

${_controller.text.trim().isEmpty ? '_Keine Beschreibung angegeben._' : _controller.text.trim()}

## Aktuelles Verhalten

_Wie funktioniert es jetzt?_

## Gewünschtes Verhalten

_Wie sollte es funktionieren?_

$systemInfo''';
    }
  }
}
