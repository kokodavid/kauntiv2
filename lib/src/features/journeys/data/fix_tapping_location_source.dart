import '../domain/journey_fix.dart';
import '../domain/journey_transport_mode.dart';

/// Wraps a [JourneyLocationSource] and hands every fix it produces to
/// [onFix] as well. The fixes themselves pass through untouched, so the
/// recorder behaves exactly as before.
class FixTappingLocationSource implements JourneyLocationSource {
  FixTappingLocationSource(this._inner, this._onFix);

  final JourneyLocationSource _inner;
  final void Function(JourneyFix fix) _onFix;

  @override
  Stream<JourneyFix> get fixes => _inner.fixes.map((fix) {
    try {
      _onFix(fix);
    } on Object {
      // A listener's failure must never break the recording.
    }
    return fix;
  });

  @override
  Future<void> ensureAvailable() => _inner.ensureAvailable();

  @override
  Future<void> start({JourneyTransportMode? mode}) => _inner.start(mode: mode);

  @override
  Future<void> stop() => _inner.stop();
}
