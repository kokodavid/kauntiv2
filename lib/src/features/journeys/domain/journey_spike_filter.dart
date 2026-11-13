import 'journey_fix.dart';
import 'journey_route.dart';

/// What to do with one location fix: the fixes to add to the route now (none,
/// one, or two when a held fix is confirmed), and what was thrown away.
class JourneySpikeVerdict {
  const JourneySpikeVerdict({
    this.accepted = const [],
    this.startsNewSegment = false,
    this.spikesDropped = 0,
    this.held = false,
  });

  /// Fixes to append, in time order.
  final List<JourneyFix> accepted;

  /// The first accepted fix is a confirmed jump: start a new route segment
  /// there instead of drawing a line across it.
  final bool startsNewSegment;

  /// Fixes thrown away as spikes by this call.
  final int spikesDropped;

  /// The fix was held back to be judged by the next one.
  final bool held;
}

/// Tells a GPS spike from a real jump, so one bad fix cannot corrupt the
/// route or invent a county crossing.
///
/// A fix that implies a speed above the limit for the Trip's mode is not
/// thrown away or accepted straight away. It is held, and the next fix
/// decides: if that one agrees with the route before the held fix, the held
/// fix was a spike and is dropped; if it agrees with the held fix, the jump
/// is real (a tunnel, a ferry, long signal loss) and a new segment starts
/// there. Pure: feed it fixes in time order with [judge].
class JourneySpikeFilter {
  /// [maxSpeedMetersPerSecond] is the fastest believable speed for the
  /// Trip's mode; null (a Trip with no mode) accepts every fix.
  JourneySpikeFilter({required this.maxSpeedMetersPerSecond});

  final double? maxSpeedMetersPerSecond;

  JourneyFix? _last;
  JourneyFix? _held;

  /// A fix is being held, waiting for the next one.
  bool get isHolding => _held != null;

  /// Forget the route so far, for example after a new segment starts.
  void reset() {
    _last = null;
    _held = null;
  }

  JourneySpikeVerdict judge(JourneyFix fix) {
    final limit = maxSpeedMetersPerSecond;
    final last = _last;
    if (limit == null || last == null) {
      _last = fix;
      _held = null;
      return JourneySpikeVerdict(accepted: [fix]);
    }
    if (!fix.recordedAt.isAfter(last.recordedAt)) {
      // Not newer than what is already in the route: nothing to add.
      return const JourneySpikeVerdict();
    }
    final held = _held;
    if (_plausible(last, fix, limit)) {
      _last = fix;
      _held = null;
      // The held fix disagreed with the route and this one agrees with the
      // route: the held fix was a spike.
      return JourneySpikeVerdict(
        accepted: [fix],
        spikesDropped: held == null ? 0 : 1,
      );
    }
    if (held == null) {
      _held = fix;
      return const JourneySpikeVerdict(held: true);
    }
    if (fix.recordedAt.isAfter(held.recordedAt) &&
        _plausible(held, fix, limit)) {
      // Two fixes agree with each other and not with the old route.
      _last = fix;
      _held = null;
      return JourneySpikeVerdict(
        accepted: [held, fix],
        startsNewSegment: true,
      );
    }
    // The new fix agrees with neither: the held one was a spike, and this one
    // is now the suspect.
    _held = fix;
    return const JourneySpikeVerdict(spikesDropped: 1, held: true);
  }

  static bool _plausible(JourneyFix from, JourneyFix to, double limit) {
    final seconds =
        to.recordedAt.difference(from.recordedAt).inMilliseconds / 1000;
    if (seconds <= 0) return false;
    final metres = JourneyRoute.haversineMeters(
      from.inSegment(0),
      to.inSegment(0),
    );
    return metres / seconds <= limit;
  }
}
