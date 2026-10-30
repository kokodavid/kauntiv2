import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_config_provider.dart';
import '../data/geoapify_plan_place_search.dart';
import '../data/plan_place_search_client.dart';
import '../domain/plan_place_suggestion.dart';
import 'create_plan_controller.dart';

part 'plan_place_search.g.dart';

/// The start-point search: Geoapify when its key is set (it finds businesses
/// and landmarks), else Mapbox's address search, else none.
@Riverpod(keepAlive: true)
PlanPlaceSearchClient? planPlaceSearchClient(Ref ref) {
  final config = ref.watch(appConfigProvider);
  if (config.geoapifyApiKey.isNotEmpty) {
    return GeoapifyPlanPlaceSearch(apiKey: config.geoapifyApiKey);
  }
  final token = config.mapboxAccessToken;
  return token.isEmpty ? null : MapboxPlanPlaceSearch(accessToken: token);
}

/// Shortest text worth searching for.
const planPlaceSearchMinLength = 3;

/// Suggestions for what has been typed. Waits a moment first so a burst of
/// typing asks once, and favours spots near the user. A failure is thrown,
/// so the page can say so and offer Retry.
@riverpod
Future<List<PlanPlaceSuggestion>> planPlaceSuggestions(
  Ref ref,
  String query,
) async {
  final text = query.trim();
  if (text.length < planPlaceSearchMinLength) return const [];
  final client = ref.watch(planPlaceSearchClientProvider);
  if (client == null) {
    throw const PlanPlaceSearchFailure('Search is not available here.');
  }
  await Future<void>.delayed(const Duration(milliseconds: 350));
  if (!ref.mounted) return const [];
  final near = ref.read(planCurrentLocationProvider).value;
  return client.search(
    text,
    nearLat: near?.latitude,
    nearLng: near?.longitude,
  );
}
