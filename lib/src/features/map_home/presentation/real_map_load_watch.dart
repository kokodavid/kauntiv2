import 'dart:async';

/// Decides, once, whether the real map loaded: [ready] when its style and
/// county layers are up, [fail] on a style error or after [timeout]. Only
/// that first outcome counts — later hiccups (a style switch offline)
/// never send Home back to the drawn map.
class RealMapLoadWatch {
  RealMapLoadWatch({
    required this.onReady,
    required this.onFailed,
    Duration timeout = const Duration(seconds: 12),
  }) {
    _timer = Timer(timeout, fail);
  }

  final void Function() onReady;
  final void Function() onFailed;
  late final Timer _timer;
  bool _settled = false;

  void ready() {
    if (_settled) return;
    _settled = true;
    _timer.cancel();
    onReady();
  }

  void fail() {
    if (_settled) return;
    _settled = true;
    _timer.cancel();
    onFailed();
  }

  void dispose() => _timer.cancel();
}
