import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/discover/application/discover_detail_actions.dart';
import '../features/discover/application/explore_providers.dart';
import '../features/discover/data/directions_launcher.dart';
import '../features/discover/data/supabase_discover_detail_repository.dart';
import '../features/discover/domain/explore_board.dart';
import '../services/app_supabase.dart';
import 'app_routes.dart';

/// Cross-feature navigation to County / Place Detail (architecture §2:
/// features link through `app/`). The links are null when Supabase isn't
/// configured, so Home keeps its peek sheets instead.
abstract final class DetailRoutes {
  /// What County / Place Detail load through; null without Supabase.
  static DiscoverDetailActions? get actions => AppSupabase.isInitialized
      ? DiscoverDetailActions(
          repository: SupabaseDiscoverDetailRepository(AppSupabase.client),
        )
      : null;

  static void Function(BuildContext, int)? get openCounty =>
      AppSupabase.isInitialized
      ? (context, countyCode) =>
            context.push(AppRoutes.county(countyCode))
      : null;

  static void Function(BuildContext, String)? get openPlace =>
      AppSupabase.isInitialized
      ? (context, placeId) => context.push(AppRoutes.place(placeId))
      : null;

  /// Home's "All N left": Explore's UNCLAIMED list, in the tab shell.
  static void openAllUnclaimed(BuildContext context) {
    ProviderScope.containerOf(context, listen: false)
        .read(exploreTabSelectionProvider.notifier)
        .select(ExploreTab.unclaimed);
    context.go(AppRoutes.explore);
  }

  /// Driving directions to a text destination in the phone's maps app.
  static Future<bool> openDirections(String destination) =>
      const DirectionsLauncher().open(query: destination);
}
