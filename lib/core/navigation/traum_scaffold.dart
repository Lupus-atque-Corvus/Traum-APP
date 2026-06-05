import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/app_launcher/app_picker_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../providers/preferences_provider.dart';
import '../services/app_launcher_service.dart';
import '../theme/colors.dart';
import '../theme/radius.dart';
import 'nav_customization_sheet.dart';
import 'routes.dart';

Future<bool> _showExitDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: TraumColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.exitDialogTitle,
        style: const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackground,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: Text(
        l10n.exitDialogContent,
        style: const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackgroundMuted,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            l10n.cancel,
            style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackgroundMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.exit,
            style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.coralOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

class TraumScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const TraumScaffold({super.key, required this.child});

  @override
  ConsumerState<TraumScaffold> createState() => _TraumScaffoldState();
}

class _TraumScaffoldState extends ConsumerState<TraumScaffold> {
  static const double _navBarHeight = 64.0;

  String _currentRoute(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (final route in Routes.moduleRoutes.entries) {
      if (loc.startsWith(route.value) && route.value != Routes.home) {
        return route.key;
      }
    }
    if (loc == Routes.home || loc == '/') return 'home';
    return 'home';
  }

  void _navigate(BuildContext context, String module) {
    HapticFeedback.selectionClick();
    final route = Routes.moduleRoutes[module] ?? Routes.home;
    context.go(route);
  }

  void _showMoreMenu(BuildContext context, List<String> navSlots) {
    final allModules = Routes.moduleRoutes.keys.toList();
    final isPeriodEnabled = ref.read(isPeriodTrackingEnabledProvider);
    final inNav = {'home', ...navSlots};
    final moreModules = allModules
        .where((m) => !inNav.contains(m))
        .where((m) => m != 'period' || isPeriodEnabled)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TraumRadius.card),
        ),
      ),
      builder: (ctx) => _MoreMenuSheet(
        moreModules: moreModules,
        appLauncherEnabled:
            Platform.isAndroid && ref.read(appLauncherEnabledProvider),
        onNavigate: (module) {
          Navigator.pop(ctx);
          _navigate(context, module);
        },
        onCustomize: () {
          Navigator.pop(ctx);
          showNavCustomizationSheet(context, ref);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final navSlots = ref.watch(navSlotsProvider);
    final isPeriodEnabled = ref.watch(isPeriodTrackingEnabledProvider);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final currentModule = _currentRoute(context);

    final filteredSlots = navSlots
        .where((m) => m != 'period' || isPeriodEnabled)
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (currentModule != 'home') {
          context.go(Routes.home);
        } else {
          final shouldExit = await _showExitDialog(context);
          if (shouldExit) SystemNavigator.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                bottom: keyboardOpen ? 0 : _navBarHeight + 12 + safeBottom,
              ),
              child: widget.child,
            ),
            if (!keyboardOpen)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: _TraumNavBar(
                  navSlots: filteredSlots,
                  currentModule: currentModule,
                  safeBottom: safeBottom,
                  onTap: (module) => _navigate(context, module),
                  onMoreTap: () => _showMoreMenu(context, filteredSlots),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TraumNavBar extends StatelessWidget {
  final List<String> navSlots;
  final String currentModule;
  final double safeBottom;
  final void Function(String) onTap;
  final VoidCallback onMoreTap;

  const _TraumNavBar({
    required this.navSlots,
    required this.currentModule,
    required this.safeBottom,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Home (fixed left)
          _NavItem(
            module: 'home',
            isActive: currentModule == 'home',
            onTap: () => onTap('home'),
          ),
          // Free slots
          ...navSlots.map((module) => _NavItem(
                module: module,
                isActive: currentModule == module,
                onTap: () => onTap(module),
              )),
          // More (fixed right)
          _MoreButton(onTap: onMoreTap),
        ],
      ),
    );
  }
}

/// Modul-Icon für Navigationsleiste, „Mehr"-Menü und Tab-Switcher (geteilt).
IconData moduleIcon(String module) {
  switch (module) {
    case 'home':
      return Icons.home_rounded;
    case 'training':
      return Icons.fitness_center_rounded;
    case 'health':
      return Icons.favorite_rounded;
    case 'nutrition':
      return Icons.restaurant_rounded;
    case 'substances':
      return Icons.medication_liquid_rounded;
    case 'planning':
      return Icons.calendar_today_rounded;
    case 'diary':
      return Icons.auto_stories_rounded;
    case 'notes':
      return Icons.notes_rounded;
    case 'abstinence':
      return Icons.trending_up_rounded;
    case 'budget':
      return Icons.account_balance_wallet_rounded;
    case 'period':
      return Icons.water_drop_rounded;
    case 'profile':
      return Icons.person_rounded;
    case 'settings':
      return Icons.settings_rounded;
    default:
      return Icons.circle;
  }
}

class _NavItem extends StatelessWidget {
  final String module;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.module,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = TraumColors.moduleColor(module);
    final label = Routes.labelFor(module, AppLocalizations.of(context)!);

    if (isActive) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.20),
                color.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.30),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                moduleIcon(module),
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Icon(
          moduleIcon(module),
          color: Colors.white.withValues(alpha: 0.85),
          size: 22,
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: TraumColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _MoreMenuSheet extends StatelessWidget {
  final List<String> moreModules;
  final bool appLauncherEnabled;
  final void Function(String) onNavigate;
  final VoidCallback onCustomize;

  const _MoreMenuSheet({
    required this.moreModules,
    required this.appLauncherEnabled,
    required this.onNavigate,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Row(
              children: [
                Text(
                  l10n.more,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCustomize,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TraumColors.surface,
                      borderRadius: BorderRadius.circular(TraumRadius.chip),
                      border: Border.all(color: TraumColors.surfaceVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, color: TraumColors.onBackgroundMuted, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          l10n.customize,
                          style: const TextStyle(
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (moreModules.isEmpty && !appLauncherEnabled)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.allModulesInNav,
                      style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (moreModules.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: moreModules.length,
                    itemBuilder: (_, i) {
                      final module = moreModules[i];
                      final color = TraumColors.moduleColor(module);
                      final label = Routes.labelFor(module, l10n);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onNavigate(module),
                        child: Container(
                          decoration: BoxDecoration(
                            color: TraumColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(moduleIcon(module), color: color, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                if (appLauncherEnabled) const _AppLauncherSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App-Launcher (experimentell) ─────────────────────────────────────────────

class _AppLauncherSection extends ConsumerWidget {
  const _AppLauncherSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favorites = ref.watch(appLauncherFavoritesProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.appsSectionTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans',
                letterSpacing: 0.8,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favorites.length + 1,
            itemBuilder: (_, i) {
              if (i == favorites.length) {
                return _AddAppTile(onTap: () => showAppPickerSheet(context));
              }
              return _AppLauncherTile(packageName: favorites[i]);
            },
          ),
        ],
      ),
    );
  }
}

class _AppLauncherTile extends ConsumerStatefulWidget {
  final String packageName;
  const _AppLauncherTile({required this.packageName});

  @override
  ConsumerState<_AppLauncherTile> createState() => _AppLauncherTileState();
}

class _AppLauncherTileState extends ConsumerState<_AppLauncherTile> {
  LauncherApp? _app;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app =
        await ref.read(appLauncherServiceProvider).getApp(widget.packageName);
    if (mounted) {
      setState(() {
        _app = app;
        _loaded = true;
      });
    }
  }

  Future<void> _open() async {
    final ok =
        await ref.read(appLauncherServiceProvider).launch(widget.packageName);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).maybePop();
    } else {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.appNotFound),
          action: SnackBarAction(
            label: l10n.removeFromLauncher,
            onPressed: () => ref
                .read(appLauncherFavoritesProvider.notifier)
                .remove(widget.packageName),
          ),
        ),
      );
    }
  }

  Future<void> _confirmRemove() async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.selectionClick();
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(
          _app?.name ?? widget.packageName,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          l10n.removeFromLauncher,
          style: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.removeFromLauncher,
                style: const TextStyle(color: TraumColors.coralOrange)),
          ),
        ],
      ),
    );
    if (remove == true) {
      await ref
          .read(appLauncherFavoritesProvider.notifier)
          .remove(widget.packageName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _app?.name ??
        (_loaded ? widget.packageName.split('.').last : '…');
    final Uint8List? icon = _app?.icon;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _open,
      onLongPress: _confirmRemove,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: icon != null
                ? Image.memory(icon, width: 48, height: 48, fit: BoxFit.cover)
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: TraumColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.apps_rounded,
                        color: TraumColors.onBackgroundMuted, size: 24),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAppTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAppTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(Icons.add_rounded,
                color: TraumColors.onBackgroundMuted, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.addApp,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}
