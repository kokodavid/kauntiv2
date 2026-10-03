part of 'trip_share_card.dart';

/// Distance/top speed on one row, average speed/peak elevation on the
/// next - fixed column widths so both rows line up regardless of how
/// wide each value happens to render (Claude-Design reference: "a 2x2
/// stat grid").
class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.distance,
    required this.topSpeed,
    required this.avgSpeed,
    required this.peak,
    required this.columnWidth,
    required this.columnGap,
    required this.rowGap,
    required this.distanceLabel,
    required this.topSpeedLabel,
    required this.avgSpeedLabel,
    required this.peakLabel,
    required this.valueStyle,
    required this.unitStyle,
    required this.labelStyle,
  });

  // Nullable: a Trip missing GPS speed samples, say, has no top speed
  // to show. Rather than a "— km/h" placeholder, that cell - and its
  // label - is left out of the grid entirely (see build()).
  final (String, String)? distance;
  final (String, String)? topSpeed;
  final (String, String)? avgSpeed;
  final (String, String)? peak;
  final double columnWidth;
  final double columnGap;
  final double rowGap;
  final String distanceLabel;
  final String topSpeedLabel;
  final String avgSpeedLabel;
  final String peakLabel;
  final TextStyle valueStyle;
  final TextStyle unitStyle;
  final TextStyle labelStyle;

  Widget _cell((String, String) stat, String label) => SizedBox(
    width: columnWidth,
    child: _StatCell(
      value: stat.$1,
      unit: stat.$2,
      label: label,
      valueStyle: valueStyle,
      unitStyle: unitStyle,
      labelStyle: labelStyle,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Only the present stats, still in distance/topSpeed/avgSpeed/peak
    // order - two per row, same as the original fixed 2x2 layout, but a
    // missing one just isn't in this list rather than rendering as an
    // empty placeholder cell.
    final entries = [
      if (distance != null) (distance!, distanceLabel),
      if (topSpeed != null) (topSpeed!, topSpeedLabel),
      if (avgSpeed != null) (avgSpeed!, avgSpeedLabel),
      if (peak != null) (peak!, peakLabel),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: rowGap));
      final rowCells = entries.skip(i).take(2).toList();
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < rowCells.length; j++) ...[
              if (j > 0) SizedBox(width: columnGap),
              _cell(rowCells[j].$1, rowCells[j].$2),
            ],
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}
