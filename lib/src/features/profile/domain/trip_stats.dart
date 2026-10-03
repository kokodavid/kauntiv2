/// Profile's progress-card stats row: how many Trips this account has
/// saved, total distance, and the longest single Trip. From
/// `profile_trip_stats()`.
class TripStats {
  const TripStats({
    required this.tripCount,
    required this.totalDistanceM,
    required this.longestDistanceM,
  });

  final int tripCount;
  final double totalDistanceM;
  final double longestDistanceM;

  static const zero = TripStats(
    tripCount: 0,
    totalDistanceM: 0,
    longestDistanceM: 0,
  );

  /// Rounded to the nearest km, matching the design's "214 km" style.
  int get totalDistanceKm => (totalDistanceM / 1000).round();
  int get longestDistanceKm => (longestDistanceM / 1000).round();
}
