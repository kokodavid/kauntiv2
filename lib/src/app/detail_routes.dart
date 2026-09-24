import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/app_tab_shell.dart';
import '../features/discover/application/discover_detail_actions.dart';
import '../features/discover/application/explore_providers.dart';
import '../features/discover/data/directions_launcher.dart';
import '../features/discover/data/supabase_discover_detail_repository.dart';
import '../features/discover/domain/explore_board.dart';
import '../features/discover/presentation/county_detail_screen.dart';
import '../features/discover/presentation/place_detail_screen.dart';
import '../services/app_supabase.dart';

/// Cross-feature navigation to County / Place Detail (architecture §2:
/// features link through `app/`). Returns null callbacks when Supabase
/// isn't configured, so Home keeps its peek sheets instead.
abstract final class DetailRoutes {
  static DiscoverDetailActions? get _actions => AppSupabase.isInitialized
      ? DiscoverDetailActions(
          repository: SupabaseDiscoverDetailRepository(AppSupabase.client),
        )
      : null;

  static void Function(BuildContext, int)? get openCounty {
    final actions = _actions;
    if (actions == null) return null;
    return (context, countyCode) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CountyDetailScreen(countyCode: countyCode, actions: actions),
      ),
    );
  }

  static void Function(BuildContext, String)? get openPlace {
    final actions = _actions;
    if (actions == null) return null;
    return (context, placeId) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailScreen(placeId: placeId, actions: actions),
      ),
    );
  }

  /// Home's "All N left": Explore's UNCLAIMED list, in the tab shell.
  static void openAllUnclaimed(BuildContext context) {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(exploreTabSelectionProvider.notifier).select(ExploreTab.unclaimed);
    AppTabShell.select(context, AppNavTab.explore);
  }

  /// Driving directions to a text destination in the phone's maps app.
  static Future<bool> openDirections(String destination) =>
      const DirectionsLauncher().open(query: destination);
}
