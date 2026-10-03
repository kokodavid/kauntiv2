part of 'trip_share_card.dart';

/// The tall arrangement (Claude-Design "Trip Share Card" reference,
/// "SOCIAL SHARE"): watermark top-left, date chip top-right, everything
/// else stacked - Trip title, county block, a divider rule, then the
/// full 2x2 stat grid with un-abbreviated labels since there's room.
class _ShareContent extends StatelessWidget {
  const _ShareContent({
    required this.title,
    required this.dateLabel,
    required this.icon,
    required this.watermarkInverted,
    required this.countyNames,
    required this.distance,
    required this.topSpeed,
    required this.avgSpeed,
    required this.peak,
  });

  final String title;
  final String dateLabel;
  final IconData? icon;
  final bool watermarkInverted;
  final List<String> countyNames;
  final (String, String)? distance;
  final (String, String)? topSpeed;
  final (String, String)? avgSpeed;
  final (String, String)? peak;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          _Watermark(
            textStyle: _Styles.shareWatermarkText,
            inverted: watermarkInverted,
          ),
          const Spacer(),
          _DateChip(
            label: dateLabel,
            icon: icon,
            textStyle: _Styles.shareChipText,
          ),
        ],
      ),
      const Spacer(),
      Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _Styles.shareTitle,
      ),
      const SizedBox(height: 8),
      _CountyBlock(
        names: countyNames,
        maxNameLines: 2,
        countStyle: _Styles.shareCountyCount,
        labelStyle: _Styles.shareCountyLabel,
        nameStyle: _Styles.shareCountyNames,
        moreStyle: _Styles.shareCountyMore,
      ),
      const SizedBox(height: 14),
      Container(height: 1, color: Colors.white.withValues(alpha: 0.22)),
      const SizedBox(height: 14),
      _StatGrid(
        distance: distance,
        topSpeed: topSpeed,
        avgSpeed: avgSpeed,
        peak: peak,
        columnWidth: 140,
        columnGap: 16,
        rowGap: 10,
        distanceLabel: 'DISTANCE',
        topSpeedLabel: 'TOP SPEED',
        avgSpeedLabel: 'AVG SPEED',
        peakLabel: 'PEAK ELEVATION',
        valueStyle: _Styles.shareStatValue,
        unitStyle: _Styles.shareStatUnit,
        labelStyle: _Styles.shareStatLabel,
      ),
    ],
  );
}
