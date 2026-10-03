import 'journey_media_capture.dart';
import 'journey_point.dart';
import 'journey_route.dart';

/// What happened at a key moment of a Journey.
enum JourneyMomentKind {
  recordingBreak,
  longStop,
  countyCrossing,
  photo,
  elevationPeak,
}

/// A key moment the replay pauses at: where along the route ([index], a
/// point in recording order) and what happened there.
class JourneyMoment {
  const JourneyMoment({
    required this.kind,
    required this.index,
    this.name,
    this.countyCode,
    this.duration,
    this.photo,
    this.elevationMeters,
  });

  final JourneyMomentKind kind;
  final int index;

  /// The county entered (null when unknown).
  final String? name;

  /// The entered county's numeric code, for a [countyCrossing] moment
  /// (null when unknown) - looking up richer county data and deep-linking
  /// to County Detail both need this, not just the display [name].
  final int? countyCode;

  /// How long the recording was paused, or the stop lasted.
  final Duration? duration;

  /// The photo, for photo moments.
  final JourneyMediaItem? photo;

  /// The altitude in metres, for the elevation-peak moment.
  final double? elevationMeters;

  bool get isPhoto => photo != null;
}

/// Finds a Journey's key moments: recording breaks, long stops and county
/// crossings, in route order.
abstract final class JourneyMoments {
  /// The peak must stand at least this far above the route's lowest
  /// point, so GPS altitude noise on an essentially flat Trip doesn't
  /// produce a pointless "highest point" pause.
  static const elevationPeakMinimumGainMeters = 30.0;

  /// A stop is staying within this distance…
  static const stopRadiusMeters = 100.0;

  /// …for at least this long.
  static const stopMinimum = Duration(minutes: 10);

  /// A new county must hold for this many points in a row, so GPS jitter
  /// along a boundary doesn't read as crossings back and forth.
  static const countySettlePoints = 3;

  /// [countyAt] names the county code at a position (null outside
  /// Kenya); [countyName] turns a code into its name.
  static List<JourneyMoment> find(
    List<JourneyPoint> points, {
    int? Function(double latitude, double longitude)? countyAt,
    String? Function(int code)? countyName,
    List<JourneyMediaItem> photos = const [],
  }) {
    final moments = [
      ..._breaks(points),
      ..._stops(points),
      if (countyAt != null) ..._counties(points, countyAt, countyName),
      ..._photos(points, photos),
      ..._elevationPeak(points),
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
    var held = 0;
    for (var i = 0; i < points.length; i++) {
      if (i > 0 && points[i].segmentNumber != points[i - 1].segmentNumber) {
        candidate = null;
        held = 0;
      }
      final code = countyAt(points[i].latitude, points[i].longitude);
      if (code == null) {
        candidate = null;
        held = 0;
        continue;
      }
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
        held = 1;
      }
      if (held >= countySettlePoints) {
        yield JourneyMoment(
          kind: JourneyMomentKind.countyCrossing,
          index: i,
          name: countyName?.call(code),
          countyCode: code,
        );
        current = code;
        candidate = null;
        held = 0;
      }
    }
  }

  /// Each photo at the route point closest to when it was taken - time,
  /// not distance: a phone can sit at one GPS fix for minutes while
  /// several photos are taken, and `recordedAt` is what actually orders
  /// the route the marker walks along.
  static Iterable<JourneyMoment> _photos(
    List<JourneyPoint> points,
    List<JourneyMediaItem> photos,
  ) sync* {
    if (points.isEmpty) return;
    for (final photo in photos) {
      var best = 0;
      var bestDiff = points.first.recordedAt.difference(photo.capturedAt).abs();
      for (var i = 1; i < points.length; i++) {
        final diff = points[i].recordedAt.difference(photo.capturedAt).abs();
        if (diff < bestDiff) {
          best = i;
          bestDiff = diff;
        }
      }
      yield JourneyMoment(
        kind: JourneyMomentKind.photo,
        index: best,
        photo: photo,
      );
    }
  }

  /// The single highest point of the route, if any point has altitude
  /// data and it clears [elevationPeakMinimumGainMeters] above the
  /// route's lowest known altitude.
  static Iterable<JourneyMoment> _elevationPeak(
    List<JourneyPoint> points,
  ) sync* {
    int? peakIndex;
    double? peak;
    double? lowest;
    for (var i = 0; i < points.length; i++) {
      final altitude = points[i].altitudeMeters;
      if (altitude == null) continue;
      if (lowest == null || altitude < lowest) lowest = altitude;
      if (peak == null || altitude > peak) {
        peak = altitude;
        peakIndex = i;
      }
    }
    if (peakIndex == null || peak == null || lowest == null) return;
    if (peak - lowest < elevationPeakMinimumGainMeters) return;
    yield JourneyMoment(
      kind: JourneyMomentKind.elevationPeak,
      index: peakIndex,
      elevationMeters: peak,
    );
  }
}
