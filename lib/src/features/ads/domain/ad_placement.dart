/// Where ads go inside a long list. Kept pure so the rule is tested without
/// a widget.
abstract final class AdPlacement {
  /// One ad after every this many rows.
  static const everyRows = 4;

  /// Whether an ad follows the row at [index] (0-based) in a list of
  /// [total] rows. Never after the last row, so a list never ends on an ad,
  /// and never in a short list. [every] overrides the spacing for screens
  /// whose rows are large (grids, grouped cards).
  static bool afterRow({
    required int index,
    required int total,
    int every = everyRows,
  }) {
    final shown = index + 1;
    return shown % every == 0 && shown < total;
  }
}
