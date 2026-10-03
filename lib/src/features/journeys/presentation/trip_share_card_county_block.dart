part of 'trip_share_card.dart';

/// "5 counties" (the count is just `names.length`) plus the names
/// themselves beneath, truncated to fit - see [_CountyNamesLine].
class _CountyBlock extends StatelessWidget {
  const _CountyBlock({
    required this.names,
    required this.maxNameLines,
    required this.countStyle,
    required this.labelStyle,
    required this.nameStyle,
    required this.moreStyle,
  });

  final List<String> names;
  final int maxNameLines;
  final TextStyle countStyle;
  final TextStyle labelStyle;
  final TextStyle nameStyle;
  final TextStyle moreStyle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${names.length}', style: countStyle),
          const SizedBox(width: 6),
          // "1 county uses the singular" (Claude-Design reference).
          Text(names.length == 1 ? 'county' : 'counties', style: labelStyle),
        ],
      ),
      if (names.isNotEmpty) ...[
        const SizedBox(height: 4),
        _CountyNamesLine(
          names: names,
          maxLines: maxNameLines,
          style: nameStyle,
          moreStyle: moreStyle,
        ),
      ],
    ],
  );
}
