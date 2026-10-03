part of 'trip_share_card.dart';

/// The wide arrangement (Claude-Design "Trip Share Card" reference,
/// "CARD THUMBNAIL"): the date chip top-left, the watermark top-right,
/// the county block and a compact 2x2 stat grid bottom-anchored side by
/// side. No Trip title - there's no room for it at this size.
class _ThumbnailContent extends StatelessWidget {
  const _ThumbnailContent({
    required this.dateLabel,
    required this.icon,
    required this.watermarkInverted,
    required this.countyNames,
    required this.distance,
    required this.topSpeed,
    required this.avgSpeed,
    required this.peak,
  });

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
          _DateChip(
            label: dateLabel,
            icon: icon,
            textStyle: _Styles.thumbChipText,
          ),
          const Spacer(),
          _Watermark(
            textStyle: _Styles.thumbWatermarkText,
            inverted: watermarkInverted,
          ),
        ],
      ),
      const Spacer(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _CountyBlock(
              names: countyNames,
              maxNameLines: 1,
              countStyle: _Styles.thumbCountyCount,
              labelStyle: _Styles.thumbCountyLabel,
              nameStyle: _Styles.thumbCountyNames,
              moreStyle: _Styles.thumbCountyMore,
            ),
          ),
          const SizedBox(width: 10),
          _StatGrid(
            distance: distance,
            topSpeed: topSpeed,
            avgSpeed: avgSpeed,
            peak: peak,
            columnWidth: 64,
            columnGap: 10,
            rowGap: 4,
            distanceLabel: 'DISTANCE',
            topSpeedLabel: 'TOP',
            avgSpeedLabel: 'AVG',
            peakLabel: 'PEAK',
            valueStyle: _Styles.thumbStatValue,
            unitStyle: _Styles.thumbStatUnit,
            labelStyle: _Styles.thumbStatLabel,
          ),
        ],
      ),
    ],
  );
}
