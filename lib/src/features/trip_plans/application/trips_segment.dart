import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/planned_trips.dart';

part 'trips_segment.g.dart';

/// Which half of the Trips tab is showing. Null until the default has been
/// worked out (see [resolveDefault]); after that only the user changes it,
/// so a refresh never flips the tab under them. Not kept between sessions.
@riverpod
class TripsSegmentChoice extends _$TripsSegmentChoice {
  @override
  TripsSegment? build() => null;

  /// Sets the opening segment once, by the rule in [defaultTripsSegment].
  void resolveDefault({
    required bool recording,
    required bool hasUpcomingPlan,
  }) {
    state ??= defaultTripsSegment(
      recording: recording,
      hasUpcomingPlan: hasUpcomingPlan,
    );
  }

  void select(TripsSegment segment) => state = segment;
}
