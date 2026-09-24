import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import 'app_bottom_nav.dart';

/// The root tab shell once onboarding is done (v1 `AppShell` parity): one
/// [AppBottomNav] floating over the live tabs, swapped with an
/// [IndexedStack] instead of pushed as routes.
///
/// Keeping every visited tab mounted means switching back is an instant
/// swap: no reload, no page transition, and each tab keeps its own
/// scroll position and state. Tabs are built lazily on first visit.
///
/// Tabs missing from [tabs] aren't ported yet; picking one shows a short
/// "coming next" note instead of switching.
class AppTabShell extends StatefulWidget {
  const AppTabShell({super.key, required this.tabs});

  final Map<AppNavTab, WidgetBuilder> tabs;

  /// Switches the nearest shell to [tab], e.g. from a "see all" link.
  static void select(BuildContext context, AppNavTab tab) =>
      context.findAncestorStateOfType<_AppTabShellState>()?._select(tab);

  @override
  State<AppTabShell> createState() => _AppTabShellState();
}

class _AppTabShellState extends State<AppTabShell> {
  AppNavTab _selected = AppNavTab.map;
  final Set<AppNavTab> _visited = {AppNavTab.map};

  List<AppNavTab> get _order => [
    for (final tab in AppNavTab.values)
      if (widget.tabs.containsKey(tab)) tab,
  ];

  void _select(AppNavTab tab) {
    if (tab == _selected) return;
    if (!widget.tabs.containsKey(tab)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('This tab is coming next.')),
        );
      return;
    }
    setState(() {
      _selected = tab;
      _visited.add(tab);
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      // A Stack, not a Column: the glass nav needs the active tab's
      // content underneath it to float over and blur.
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: order.indexOf(_selected),
              children: [
                for (final tab in order)
                  _visited.contains(tab)
                      ? Builder(builder: widget.tabs[tab]!)
                      : const SizedBox.shrink(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(selected: _selected, onSelect: _select),
          ),
        ],
      ),
    );
  }
}
