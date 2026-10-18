import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bottom_nav_hidden_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../application/explore_dock_collapse_provider.dart';
import '../application/explore_providers.dart';

/// Folds Explore's dock while the list scrolls down and tucks the tab bar
/// away with it (and while searching), so the dock drops to take its place.
///
/// Direction changes are discrete, so only rebuild when the scroll direction
/// flips, not for every scroll notification.
mixin ExploreDockCollapse<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool get dockCollapsed => ref.read(exploreDockCollapsedProvider);

  @override
  void initState() {
    super.initState();
    ref.read(exploreDockCollapsedProvider.notifier).set(false);
    ref.read(bottomNavHiddenProvider.notifier).set(hidden: false);
  }

  void handleScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.idle) return;
    final collapsed = notification.direction == ScrollDirection.reverse;
    if (collapsed == dockCollapsed || !mounted) return;
    ref.read(exploreDockCollapsedProvider.notifier).set(collapsed);
    syncNav();
  }

  bool get navHidden =>
      dockCollapsed || ref.read(exploreSearchQueryProvider).trim().isNotEmpty;

  void syncNav() =>
      ref.read(bottomNavHiddenProvider.notifier).set(hidden: navHidden);
}

/// Where the dock sits: above the tab bar, or dropped into its place while
/// [collapsed] or [searching]. Only this widget follows [collapsed], so the
/// dock moves without the rest of the screen rebuilding.
class ExploreDockSlot extends ConsumerWidget {
  const ExploreDockSlot({
    super.key,
    required this.searching,
    required this.child,
  });

  final bool searching;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(exploreDockCollapsedProvider);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: 16,
      right: 16,
      bottom: collapsed || searching
          ? AppBottomNav.bottomGap(context)
          : AppBottomNav.clearance(context) + 4,
      child: child,
    );
  }
}
