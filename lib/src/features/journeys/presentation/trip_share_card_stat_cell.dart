part of 'trip_share_card.dart';

/// One "value unit / LABEL" tile, e.g. "42.3 km" over "DISTANCE".
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.unit,
    required this.label,
    required this.valueStyle,
    required this.unitStyle,
    required this.labelStyle,
  });

  final String value;
  final String unit;
  final String label;
  final TextStyle valueStyle;
  final TextStyle unitStyle;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      // The parent _StatGrid cell is a fixed-width SizedBox (64px on the
      // thumbnail), tight enough that a longer value - a 2-digit top
      // speed, say - can outgrow it and overflow the Row by a couple of
      // pixels. FittedBox scales the whole value+unit pair down just
      // enough to fit instead, rather than this needing to be re-tuned
      // per stat/value length.
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: valueStyle),
            const SizedBox(width: 3),
            Text(unit, style: unitStyle),
          ],
        ),
      ),
      Text(label, style: labelStyle),
    ],
  );
}
