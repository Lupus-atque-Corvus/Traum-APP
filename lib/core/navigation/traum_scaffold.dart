import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/preferences_provider.dart';
import '../theme/colors.dart';
import '../theme/radius.dart';
import 'nav_customization_sheet.dart';
import 'routes.dart';

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
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (currentModule == 'home') {
          SystemNavigator.pop();
        } else {
          context.go(Routes.home);
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
      behavior: HitTestBehavior.opaque,
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
  final void Function(String) onNavigate;
  final VoidCallback onCustomize;

  const _MoreMenuSheet({
    required this.moreModules,
    required this.onNavigate,
    required this.onCustomize,
  });

  static IconData _iconFor(String module) {
    switch (module) {
      case 'training':    return Icons.fitness_center_rounded;
      case 'health':      return Icons.favorite_rounded;
      case 'nutrition':   return Icons.restaurant_rounded;
      case 'supplements': return Icons.science_rounded;
      case 'planning':    return Icons.calendar_today_rounded;
      case 'medication':  return Icons.medication_rounded;
      case 'abstinence':  return Icons.block_rounded;
      case 'budget':      return Icons.account_balance_wallet_rounded;
      case 'period':      return Icons.water_drop_rounded;
      case 'profile':     return Icons.person_rounded;
      case 'settings':    return Icons.settings_rounded;
      default:            return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TraumColors.onBackgroundSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Mehr',
                  style: TextStyle(
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, color: TraumColors.onBackgroundMuted, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Anpassen',
                          style: TextStyle(
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
          const SizedBox(height: 12),
          Expanded(
            child: moreModules.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Alle Module sind bereits in deiner Navigation.',
                        style: TextStyle(
                          color: TraumColors.onBackgroundSubtle,
                          fontFamily: 'DMSans',
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : GridView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: moreModules.length,
                    itemBuilder: (_, i) {
                      final module = moreModules[i];
                      final color = TraumColors.moduleColor(module);
                      final label = Routes.moduleLabels[module] ?? module;
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
