part of 'trip_share_sheet.dart';

enum _ShareStat {
  distance('Distance', Icons.straighten_rounded),
  topSpeed('Top speed', Icons.speed_rounded),
  averageSpeed('Average speed', Icons.timer_outlined),
  elevation('Peak elevation', Icons.terrain_rounded);

  const _ShareStat(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// "Show on image" tiles under the preview, the same multi-select tile
/// grid the Interests picker uses. Only stats the Trip actually recorded
/// get a tile - there's nothing to hide otherwise.
class _StatSwitches extends StatelessWidget {
  const _StatSwitches({
    required this.summary,
    required this.visibility,
    required this.onChanged,
  });

  final JourneySummary summary;
  final TripShareStatVisibility visibility;
  final ValueChanged<TripShareStatVisibility> onChanged;

  bool _recorded(_ShareStat stat) => switch (stat) {
    _ShareStat.distance => summary.distanceMeters != null,
    _ShareStat.topSpeed => summary.topSpeedMps != null,
    _ShareStat.averageSpeed => summary.averageSpeedMps != null,
    _ShareStat.elevation => summary.highestElevationMeters != null,
  };

  bool _shown(_ShareStat stat) => switch (stat) {
    _ShareStat.distance => visibility.distance,
    _ShareStat.topSpeed => visibility.topSpeed,
    _ShareStat.averageSpeed => visibility.averageSpeed,
    _ShareStat.elevation => visibility.elevation,
  };

  void _toggle(_ShareStat stat) => onChanged(switch (stat) {
    _ShareStat.distance => visibility.copyWith(distance: !visibility.distance),
    _ShareStat.topSpeed => visibility.copyWith(topSpeed: !visibility.topSpeed),
    _ShareStat.averageSpeed => visibility.copyWith(
      averageSpeed: !visibility.averageSpeed,
    ),
    _ShareStat.elevation => visibility.copyWith(
      elevation: !visibility.elevation,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final stat in _ShareStat.values)
        if (_recorded(stat)) stat,
    ];
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Show on image', style: _Styles.stripHeading),
        const SizedBox(height: 10),
        ChoiceTileGrid<_ShareStat>(
          options: options,
          selected: [
            for (final stat in options)
              if (_shown(stat)) stat,
          ],
          labelOf: (stat) => stat.label,
          iconBuilder: (stat, color) => Icon(stat.icon, size: 18, color: color),
          onToggle: _toggle,
        ),
      ],
    );
  }
}
