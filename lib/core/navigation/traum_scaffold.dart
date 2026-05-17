import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/preferences_provider.dart';
import '../theme/colors.dart';
import '../theme/radius.dart';
import 'routes.dart';

Future<bool> _showExitDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: TraumColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'App beenden?',
        style: TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackground,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: const Text(
        'Möchtest du TRAUM wirklich beenden?',
        style: TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackgroundMuted,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(
            'Abbrechen',
            style: TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackgroundMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Beenden',
            style: TextStyle(
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
        navSlots: navSlots,
        onNavigate: (module) {
          Navigator.pop(ctx);
          _navigate(context, module);
        },
        onSlotsChanged: (newSlots) {
          ref.read(navSlotsProvider.notifier).setSlots(newSlots);
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

class _NavItem extends StatelessWidget {
  final String module;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.module,
    required this.isActive,
    required this.onTap,
  });

  IconData _iconFor(String module) {
    switch (module) {
      case 'home':
        return Icons.home_rounded;
      case 'training':
        return Icons.fitness_center_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'nutrition':
        return Icons.restaurant_rounded;
      case 'supplements':
        return Icons.science_rounded;
      case 'planning':
        return Icons.calendar_today_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'abstinence':
        return Icons.block_rounded;
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

  @override
  Widget build(BuildContext context) {
    final color = TraumColors.moduleColor(module);
    final label = Routes.moduleLabels[module] ?? module;

    if (isActive) {
      return GestureDetector(
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
                _iconFor(module),
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
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Icon(
          _iconFor(module),
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

class _MoreMenuSheet extends ConsumerStatefulWidget {
  final List<String> moreModules;
  final List<String> navSlots;
  final void Function(String) onNavigate;
  final void Function(List<String>) onSlotsChanged;

  const _MoreMenuSheet({
    required this.moreModules,
    required this.navSlots,
    required this.onNavigate,
    required this.onSlotsChanged,
  });

  @override
  ConsumerState<_MoreMenuSheet> createState() => _MoreMenuSheetState();
}

class _MoreMenuSheetState extends ConsumerState<_MoreMenuSheet> {
  static const _allModules = [
    'training', 'health', 'nutrition', 'supplements', 'planning',
    'medication', 'abstinence', 'budget', 'period', 'profile', 'settings',
  ];

  IconData _iconFor(String module) {
    switch (module) {
      case 'training':
        return Icons.fitness_center_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'nutrition':
        return Icons.restaurant_rounded;
      case 'supplements':
        return Icons.science_rounded;
      case 'planning':
        return Icons.calendar_today_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'abstinence':
        return Icons.block_rounded;
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

  @override
  Widget build(BuildContext context) {
    final activeSlots = widget.navSlots;
    final inNav = {'home', ...activeSlots};
    final isPeriodEnabled = ref.watch(isPeriodTrackingEnabledProvider);
    final availableToAdd = _allModules
        .where((m) => !inNav.contains(m))
        .where((m) => m != 'period' || isPeriodEnabled)
        .toList();

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
          // Sektion: Leiste anpassen
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text(
              'LEISTE ANPASSEN',
              style: TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            height: 72,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: activeSlots.length,
              onReorder: (oldIdx, newIdx) {
                HapticFeedback.mediumImpact();
                ref.read(navSlotsProvider.notifier).reorder(oldIdx, newIdx);
              },
              itemBuilder: (_, i) {
                final module = activeSlots[i];
                final color = TraumColors.moduleColor(module);
                final label = Routes.moduleLabels[module] ?? module;
                return Container(
                  key: ValueKey(module),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(TraumRadius.chip),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconFor(module), color: color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => ref
                            .read(navSlotsProvider.notifier)
                            .remove(module),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (activeSlots.length < 4 && availableToAdd.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text(
                'HINZUFÜGEN',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackgroundMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableToAdd.map((m) {
                  final color = TraumColors.moduleColor(m);
                  final label = Routes.moduleLabels[m] ?? m;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(navSlotsProvider.notifier).add(m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: TraumColors.surface,
                        borderRadius:
                            BorderRadius.circular(TraumRadius.chip),
                        border: Border.all(
                            color: color.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontFamily: 'DMSans',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const Divider(color: Colors.white12, height: 24),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              'MEHR',
              style: TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: widget.moreModules.length,
              itemBuilder: (_, i) {
                final module = widget.moreModules[i];
                final color = TraumColors.moduleColor(module);
                final label = Routes.moduleLabels[module] ?? module;
                return GestureDetector(
                  onTap: () => widget.onNavigate(module),
                  child: Container(
                    decoration: BoxDecoration(
                      color: TraumColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_iconFor(module), color: color, size: 28),
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
          ),
        ],
      ),
    );
  }
}
