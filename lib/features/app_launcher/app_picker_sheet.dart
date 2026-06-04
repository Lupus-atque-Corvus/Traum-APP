import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/preferences_provider.dart';
import '../../core/services/app_launcher_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../l10n/app_localizations.dart';

/// Bottom-Sheet zur Auswahl von Launcher-Favoriten aus allen installierten Apps.
Future<void> showAppPickerSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
    ),
    builder: (_) => const _AppPickerSheet(),
  );
}

class _AppPickerSheet extends ConsumerStatefulWidget {
  const _AppPickerSheet();

  @override
  ConsumerState<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends ConsumerState<_AppPickerSheet> {
  List<LauncherApp>? _apps;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await ref.read(appLauncherServiceProvider).listInstalledApps();
    if (mounted) setState(() => _apps = apps);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final favorites = ref.watch(appLauncherFavoritesProvider);
    final apps = _apps;

    final filtered = apps == null
        ? const <LauncherApp>[]
        : apps
            .where((a) => a.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.selectApps,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(
                  color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                hintText: l10n.searchApps,
                hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: TraumColors.onBackgroundMuted),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.chip),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: apps == null
                ? const Center(
                    child: CircularProgressIndicator(
                        color: TraumColors.coralOrange))
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noAppsInstalled,
                          style: const TextStyle(
                            color: TraumColors.onBackgroundSubtle,
                            fontFamily: 'DMSans',
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final app = filtered[i];
                          final selected =
                              favorites.contains(app.packageName);
                          return ListTile(
                            leading: _AppIcon(icon: app.icon, size: 36),
                            title: Text(
                              app.name,
                              style: const TextStyle(
                                color: TraumColors.onBackground,
                                fontFamily: 'DMSans',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              color: selected
                                  ? TraumColors.coralOrange
                                  : TraumColors.onBackgroundSubtle,
                            ),
                            onTap: () => ref
                                .read(appLauncherFavoritesProvider.notifier)
                                .toggle(app.packageName),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Zeigt ein App-Icon aus Bytes oder ein Fallback-Symbol.
class _AppIcon extends StatelessWidget {
  final dynamic icon; // Uint8List?
  final double size;
  const _AppIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(icon, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: TraumColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.apps_rounded,
          color: TraumColors.onBackgroundMuted, size: 20),
    );
  }
}
