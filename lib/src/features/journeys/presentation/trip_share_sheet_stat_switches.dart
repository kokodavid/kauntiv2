part of 'trip_share_sheet.dart';

/// "Show on image" switches under the preview. Only stats the Trip
/// actually recorded get a switch - there's nothing to hide otherwise.
class _StatSwitches extends StatelessWidget {
  const _StatSwitches({
    required this.summary,
    required this.visibility,
    required this.onChanged,
  });

  final JourneySummary summary;
  final TripShareStatVisibility visibility;
  final ValueChanged<TripShareStatVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (summary.distanceMeters != null)
        _row(
          'Distance',
          visibility.distance,
          (v) => onChanged(visibility.copyWith(distance: v)),
        ),
      if (summary.topSpeedMps != null)
        _row(
          'Top speed',
          visibility.topSpeed,
          (v) => onChanged(visibility.copyWith(topSpeed: v)),
        ),
      if (summary.averageSpeedMps != null)
        _row(
          'Average speed',
          visibility.averageSpeed,
          (v) => onChanged(visibility.copyWith(averageSpeed: v)),
        ),
      if (summary.highestElevationMeters != null)
        _row(
          'Peak elevation',
          visibility.elevation,
          (v) => onChanged(visibility.copyWith(elevation: v)),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Show on image', style: _Styles.stripHeading),
        const SizedBox(height: 4),
        ...rows,
      ],
    );
  }

  Widget _row(String label, bool value, ValueChanged<bool> onChanged) =>
      SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(child: Text(label, style: _Styles.shapeLabel)),
            Switch.adaptive(
              value: value,
              activeTrackColor: AppColors.accent,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}
