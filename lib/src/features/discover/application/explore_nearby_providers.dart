import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/supabase_map_place_reads.dart';
import '../../../core/domain/place_type.dart';
import '../../../core/services/app_current_location.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../map_home/application/real_map_start_focus.dart';
import '../../map_home/domain/map_home_nearby_places.dart';
import '../../profile/application/interests_providers.dart';
import '../domain/explore_board.dart';
import '../domain/explore_entries.dart';
import '../domain/explore_labels.dart';
import 'explore_providers.dart';

part 'explore_nearby_providers.g.dart';

/// The places nearest the traveller, ranked by exactly the function Home's
/// sheet uses ([MapHomeNearbyPlaces.nearest]): every listed place, device
/// location, and the same lean toward the traveller's interests. Empty when
/// there is no fix in Kenya, as on Home.
@riverpod
Future<List<ExploreEntry>> exploreNearby(Ref ref) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const [];
  final board = await ref.watch(exploreBoardProvider.future);
  final picks = ref.watch(myInterestsProvider).value?.interests ?? const [];
  final matcher = ref.watch(interestMatcherProvider);
  final (places, fix) = await (
    SupabaseMapPlaceReads(client).loadMapPlaces(),
    AppCurrentLocation.read(),
  ).wait;
  if (fix == null ||
      !RealMapStartFocus.isInKenya(
        latitude: fix.latitude,
        longitude: fix.longitude,
      )) {
    return const [];
  }
  final claimed = {
    if (board.featuredUnlock case final unlock?) unlock.county.code,
    for (final county in board.mine) county.county.code,
  };
  final saved = {
    for (final group in board.saved)
      for (final place in group.places) place.id,
  };
  final nearest = MapHomeNearbyPlaces.nearest(
    places: places,
    from: fix,
    claimedCountyCodes: claimed,
    interestFor: picks.isEmpty
        ? null
        : (t, county) => matcher.matchFor(t, picks, countyCode: county),
  );
  return [
    for (final near in nearest)
      ExploreEntry(
        place: ExplorePlace(
          id: near.place.id,
          title: near.place.name,
          description: near.place.summary ?? '',
          category: PlaceType.of(near.place.type),
          saved: saved.contains(near.place.id),
          thumbnailUrl: near.place.thumbnailUrl,
          distanceLabel: ExploreLabels.distance(near.distanceMeters),
          distanceMeters: near.distanceMeters,
        ),
        countyCode: near.county.code,
        countyName: near.county.name,
        claimed: near.countyClaimed,
      ),
  ];
}
