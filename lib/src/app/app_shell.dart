import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_bottom_nav.dart';
import '../design/app_colors.dart';
import '../features/detection/presentation/detection_lifecycle.dart';
import '../features/onboarding/application/startup_flow.dart';
import 'app_routes.dart';
import 'detail_routes.dart';

/// The root tab shell once onboarding is done (v1 `AppShell` parity): one
/// [AppBottomNav] floating over the live tabs. The tabs are go_router
/// branches ([StatefulShellRoute.indexedStack]), so each keeps its own
/// navigation stack, scroll position and state, and is built lazily on
/// first visit. Detection runs around the whole shell.
///
/// Tabs without a branch aren't ported yet; picking one shows a short
/// "coming next" note instead of switching.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(BuildContext context, AppNavTab tab) {
    final index = AppRoutes.tabs.indexOf(tab);
    if (index < 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('This tab is coming next.')),
        );
      return;
    }
    if (index == navigationShell.currentIndex) return;
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeCounty = ref.watch(
      startupFlowProvider.select((s) => s.homeCounty),
    );
    return DetectionLifecycle(
      homeCountyCode: homeCounty?.code,
      onOpenCounty: DetailRoutes.openCounty,
      onOpenPlace: DetailRoutes.openPlace,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        // A Stack, not a Column: the glass nav needs the active tab's
        // content underneath it to float over and blur.
        body: Stack(
          children: [
            Positioned.fill(child: navigationShell),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(
                selected: AppRoutes.tabs[navigationShell.currentIndex],
                onSelect: (tab) => _select(context, tab),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
