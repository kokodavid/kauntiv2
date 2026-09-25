import 'journey_point.dart';
import 'journey_route.dart';

/// What happened at a key moment of a Journey.
enum JourneyMomentKind { recordingBreak, longStop, countyCrossing, savedPlace }

/// A key moment the replay pauses at: where along the route ([index], a
/// point in recording order) and what happened there.
class JourneyMoment {
  const JourneyMoment({
    required this.kind,
    required this.index,
    this.name,
    this.duration,
  });

  final JourneyMomentKind kind;
  final int index;

  /// The county entered or the saved place passed (null when unknown).
  final String? name;

  /// How long the recording was paused, or the stop lasted.
  final Duration? duration;
}

/// A place the user saved, as the replay looks for it along the route.
class JourneyPlaceMark {
  const JourneyPlaceMark({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

/// Finds a Journey's key moments: recording breaks, long stops, county
/// crossings and saved places passed, in route order.
abstract final class JourneyMoments {
  /// A stop is staying within this distance…
  static const stopRadiusMeters = 100.0;

  /// …for at least this long.
  static const stopMinimum = Duration(minutes: 10);

  /// A saved place counts as passed within this distance of the route.
  static const placeRadiusMeters = 300.0;

  /// A new county must hold for this many points in a row, so GPS jitter
  /// along a boundary doesn't read as crossings back and forth.
  static const countySettlePoints = 3;

  /// [countyAt] names the county code at a position (null outside
  /// Kenya); [countyName] turns a code into its name.
  static List<JourneyMoment> find(
    List<JourneyPoint> points, {
    int? Function(double latitude, double longitude)? countyAt,
    String? Function(int code)? countyName,
    List<JourneyPlaceMark> places = const [],
  }) {
    final moments = [
      ..._breaks(points),
      ..._stops(points),
      if (countyAt != null) ..._counties(points, countyAt, countyName),
      ..._places(points, places),
    ];
    // Stable by kind within an index, so the order is predictable.
    moments.sort(
      (a, b) => a.index != b.index
          ? a.index.compareTo(b.index)
          : a.kind.index.compareTo(b.kind.index),
    );
    return moments;
  }

  /// The first point index with a moment after [position], if any.
  static int? nextStopAfter(double position, List<JourneyMoment> moments) {
    for (final moment in moments) {
      if (moment.index > position + 1e-9) return moment.index;
    }
    return null;
  }

  /// Every moment at [index] (several can share a point).
  static List<JourneyMoment> at(int index, List<JourneyMoment> moments) => [
    for (final moment in moments)
      if (moment.index == index) moment,
  ];

  static Iterable<JourneyMoment> _breaks(List<JourneyPoint> points) sync* {
    for (var i = 0; i + 1 < points.length; i++) {
      if (points[i].segmentNumber != points[i + 1].segmentNumber) {
        yield JourneyMoment(
          kind: JourneyMomentKind.recordingBreak,
          index: i,
          duration: points[i + 1].recordedAt.difference(points[i].recordedAt),
        );
      }
    }
  }

  /// Runs of points within [stopRadiusMeters] of the run's first point,
  /// inside one segment, lasting [stopMinimum] or more.
  static Iterable<JourneyMoment> _stops(List<JourneyPoint> points) sync* {
    var i = 0;
    while (i < points.length) {
      final anchor = points[i];
      var j = i;
      while (j + 1 < points.length &&
          points[j + 1].segmentNumber == anchor.segmentNumber &&
          JourneyRoute.haversineMeters(anchor, points[j + 1]) <=
              stopRadiusMeters) {
        j++;
      }
      final stayed = points[j].recordedAt.difference(anchor.recordedAt);
      if (stayed >= stopMinimum) {
        yield JourneyMoment(
          kind: JourneyMomentKind.longStop,
          index: i,
          duration: stayed,
        );
        i = j + 1;
      } else {
        i++;
      }
    }
  }

  static Iterable<JourneyMoment> _counties(
    List<JourneyPoint> points,
    int? Function(double, double) countyAt,
    String? Function(int)? countyName,
  ) sync* {
    int? current;
    int? candidate;
    var candidateStart = 0;
    var held = 0;
    for (var i = 0; i < points.length; i++) {
      final code = countyAt(points[i].latitude, points[i].longitude);
      if (code == null) continue;
      if (current == null || code == current) {
        current = code;
        candidate = null;
        held = 0;
        continue;
      }
      if (code == candidate) {
        held++;
      } else {
        candidate = code;
        candidateStart = i;
        held = 1;
      }
      // A county the route ends in counts even with fewer points.
      if (held >= countySettlePoints || i == points.length - 1) {
        yield JourneyMoment(
          kind: JourneyMomentKind.countyCrossing,
          index: candidateStart,
          name: countyName?.call(code),
        );
        current = code;
        candidate = null;
        held = 0;
      }
    }
  }

  /// Each saved place once, at the route point closest to it.
  static Iterable<JourneyMoment> _places(
    List<JourneyPoint> points,
    List<JourneyPlaceMark> places,
  ) sync* {
    if (points.isEmpty) return;
    for (final place in places) {
      final mark = JourneyPoint(
        recordedAt: points.first.recordedAt,
        latitude: place.latitude,
        longitude: place.longitude,
        accuracyMeters: 0,
        segmentNumber: 0,
      );
      var best = -1;
      var bestMeters = placeRadiusMeters;
      for (var i = 0; i < points.length; i++) {
        final meters = JourneyRoute.haversineMeters(points[i], mark);
        if (meters <= bestMeters) {
          best = i;
          bestMeters = meters;
        }
      }
      if (best >= 0) {
        yield JourneyMoment(
          kind: JourneyMomentKind.savedPlace,
          index: best,
          name: place.name,
        );
      }
    }
  }
}
