/// Lets one sheet at a time open from the map. A county tap waits for the
/// camera flight before its sheet appears, so without this a quick second
/// tap (a county or a pin) would start a second sheet on top of the first.
class RealMapSheetGuard {
  bool _busy = false;

  /// Whether a sheet is opening or showing.
  bool get isBusy => _busy;

  /// Runs [open] unless a sheet is already opening or showing; the guard
  /// stays closed until [open] finishes, which is when the sheet is gone.
  Future<void> run(Future<void> Function() open) async {
    if (_busy) return;
    _busy = true;
    try {
      await open();
    } finally {
      _busy = false;
    }
  }
}
