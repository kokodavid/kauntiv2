import 'package:flutter/material.dart';

import '../features/discover/application/discover_detail_actions.dart';
import '../features/discover/data/supabase_discover_detail_repository.dart';
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
}
