import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../providers/preferences_provider.dart';
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
      backgroundColor: Colors.transparent,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
        ),
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

  bool _isCyan(String module) =>
      module == 'health' ||
      module == 'nutrition' ||
      module == 'supplements' ||
      module == 'abstinence';

  @override
  Widget build(BuildContext context) {
    final label = Routes.labelFor(module, AppLocalizations.of(context)!);
    final cyan = _isCyan(module);

    // Pill gradient colours matching the original concept
    final pillGradient = cyan
        ? const LinearGradient(
            colors: [Color(0x331A5F66), Color(0x1A0D3F46)])
        : const LinearGradient(
            colors: [Color(0x33FF9A5A), Color(0x1AFFB07A)]);

    final textColor =
        cyan ? const Color(0xFF7EE7F0) : const Color(0xFFFFB07A);
    final glowColor =
        cyan ? const Color(0x297EE7F0) : const Color(0x2EFF9A5A);
    final borderAccent =
        cyan ? const Color(0xFF7EE7F0) : const Color(0xFFFF9A5A);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 11,
          vertical: 9,
        ),
        decoration: isActive
            ? BoxDecoration(
                gradient: pillGradient,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: borderAccent.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(color: glowColor, blurRadius: 14)
                ],
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(module),
              size: 22,
              color: isActive
                  ? textColor
                  : Colors.white.withValues(alpha: 0.85),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 22,
          color: Colors.white.withValues(alpha: 0.85),
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
        return Icons.self_improvement_rounded;
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

  bool _isCyan(String module) =>
      module == 'health' ||
      module == 'nutrition' ||
      module == 'supplements' ||
      module == 'abstinence';

  Color _accentFor(String module) {
    if (_isCyan(module)) return TraumColors.cyanBlue;
    if (module == 'settings') return Colors.white70;
    return TraumColors.coralOrange;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header row
          Row(
            children: [
              Text(
                l10n.more,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'DMSans',
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCustomize,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TraumColors.coralOrange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(TraumRadius.chip),
                    border: Border.all(
                        color: TraumColors.coralOrange.withValues(alpha: 0.30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded,
                          color:
                              TraumColors.coralOrange.withValues(alpha: 0.80),
                          size: 15),
                      const SizedBox(width: 6),
                      Text(
                        l10n.customize,
                        style: TextStyle(
                          color:
                              TraumColors.coralOrange.withValues(alpha: 0.80),
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
          const SizedBox(height: 16),

          if (moreModules.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'WEITERE MODULE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.8,
              ),
              itemCount: moreModules.length,
              itemBuilder: (_, i) {
                final module = moreModules[i];
                final label = Routes.labelFor(module, l10n);
                final ac = _accentFor(module);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onNavigate(module);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(_iconFor(module),
                            size: 20,
                            color: ac.withValues(alpha: 0.85)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontSize: 13,
                              fontFamily: 'DMSans',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ] else
            Center(
              child: Padding(
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
            ),
        ],
      ),
    );
  }
}
