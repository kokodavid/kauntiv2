/// Whether the phone is travelling, from the speed of its location fixes.
enum MotionState { unknown, still, moving }

/// Decides [MotionState] from a stream of fixes. Pure: feed it fixes with
/// [addFix] and call [tick] now and then, since a phone that is not moving
/// stops sending fixes.
///
/// The thresholds sit between GPS noise (a phone on a table reads under
/// ~0.5 m/s) and the slowest Trip mode (a walk is ~1.2-1.7 m/s), so one rule
/// covers walking, cycling and driving. Both directions need the speed to
/// hold for a while, so a red light or a slow patch does not flip the state.
class MotionTracker {
  /// At or above this a fix counts as travelling (4.3 km/h).
  static const movingSpeed = 1.2;

  /// Below this a fix counts as standing still (2.2 km/h).
  static const stillSpeed = 0.6;

  /// How long travelling speed must hold before the state is [moving].
  static const movingFor = Duration(seconds: 15);

  /// How long standing still must hold before the state is [still].
  static const stillFor = Duration(seconds: 90);

  /// A longer gap between fixes breaks the run of travelling fixes.
  static const maxFixGap = Duration(seconds: 30);

  MotionState _state = MotionState.unknown;
  DateTime? _fastSince;
  DateTime? _slowSince;
  DateTime? _lastFixAt;

  MotionState get state => _state;

  /// Takes one fix. A null [speed] carries no information and is ignored.
  MotionState addFix({required double? speed, required DateTime at}) {
    final last = _lastFixAt;
    if (last != null && at.difference(last) > maxFixGap) _fastSince = null;
    _lastFixAt = at;
    if (speed == null || !speed.isFinite || speed < 0) return _state;

    if (speed >= movingSpeed) {
      _slowSince = null;
      _fastSince ??= at;
      if (at.difference(_fastSince!) >= movingFor) {
        _state = MotionState.moving;
      }
    } else if (speed < stillSpeed) {
      _fastSince = null;
      _slowSince ??= at;
      // The first reading of a session settles straight to still: the
      // default is the calm state, not "maybe moving".
      if (_state == MotionState.unknown ||
          at.difference(_slowSince!) >= stillFor) {
        _state = MotionState.still;
      }
    } else {
      _fastSince = null;
      _slowSince = null;
    }
    return _state;
  }

  /// No fix for [stillFor] means the phone has stopped sending them (the
  /// distance filter holds them back while it is still).
  MotionState tick(DateTime now) {
    final last = _lastFixAt;
    if (last != null && now.difference(last) >= stillFor) {
      _fastSince = null;
      _state = MotionState.still;
    }
    return _state;
  }
}
