import 'journey_point.dart';
import 'journey_route.dart';

/// A route thinned for a small preview image: each segment kept (gaps
/// stay gaps), at most [maxPoints] points overall, first and last of
/// every segment always in.
abstract final class JourneyPreview {
  static const maxPoints = 240;

  /// Most segments drawn; later short ones are dropped.
  static const maxSegments = 12;

  static List<List<JourneyPoint>> thin(JourneyRoute route) {
    final segments = route.segments.take(maxSegments).toList();
    final total = segments.fold<int>(0, (sum, s) => sum + s.length);
    if (total <= maxPoints) return segments;
    return [
      for (final segment in segments)
        _sample(segment, (segment.length * maxPoints / total).floor()),
    ];
  }

  static List<JourneyPoint> _sample(List<JourneyPoint> segment, int keep) {
    if (keep < 2 || segment.length <= 2) {
      return [segment.first, if (segment.length > 1) segment.last];
    }
    if (segment.length <= keep) return segment;
    final step = (segment.length - 1) / (keep - 1);
    return [for (var i = 0; i < keep; i++) segment[(i * step).round()]];
  }

  /// Google's encoded polyline format (precision 5), as Mapbox's static
  /// path overlay reads it.
  static String encode(List<JourneyPoint> points) {
    final out = StringBuffer();
    var lastLat = 0;
    var lastLng = 0;
    for (final point in points) {
      final lat = (point.latitude * 1e5).round();
      final lng = (point.longitude * 1e5).round();
      _value(lat - lastLat, out);
      _value(lng - lastLng, out);
      lastLat = lat;
      lastLng = lng;
    }
    return out.toString();
  }

  static void _value(int value, StringBuffer out) {
    var v = value < 0 ? ~(value << 1) : value << 1;
    while (v >= 0x20) {
      out.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    out.writeCharCode(v + 63);
  }
}
