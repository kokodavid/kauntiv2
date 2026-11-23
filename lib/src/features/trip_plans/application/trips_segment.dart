import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/planned_trips.dart';

part 'trips_segment.g.dart';

/// Which half of the Trips tab is showing. The tab always opens on
/// Recorded; after that only the user (or a notification that points at
/// plans) changes it. Not kept between sessions.
@riverpod
class TripsSegmentChoice extends _$TripsSegmentChoice {
  @override
  TripsSegment build() => TripsSegment.recorded;

  void select(TripsSegment segment) => state = segment;
}
