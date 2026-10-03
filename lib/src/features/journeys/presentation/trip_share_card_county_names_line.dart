part of 'trip_share_card.dart';

/// County names in Trip order, truncated to fit [maxLines] at the
/// available width: as many full names as fit, then "+N more" for the
/// rest (Claude-Design reference: "Add names in trip order until the
/// next one won't fit, then show '+N more' in white"). Real text
/// measurement via [TextPainter], not a character-count guess - the
/// right cutoff depends on the actual rendered width of each name.
class _CountyNamesLine extends StatelessWidget {
  const _CountyNamesLine({
    required this.names,
    required this.maxLines,
    required this.style,
    required this.moreStyle,
  });

  final List<String> names;
  final int maxLines;
  final TextStyle style;
  final TextStyle moreStyle;

  bool _fits(String text, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }

  List<InlineSpan> _spansFor(double maxWidth) {
    final all = names.join(', ');
    if (_fits(all, maxWidth)) return [TextSpan(text: all, style: style)];
    for (var shown = names.length - 1; shown >= 0; shown--) {
      final prefix = names.sublist(0, shown).join(', ');
      final remaining = names.length - shown;
      final candidate = shown == 0
          ? '+$remaining more'
          : '$prefix, +$remaining more';
      if (!_fits(candidate, maxWidth)) continue;
      return shown == 0
          ? [TextSpan(text: '+$remaining more', style: moreStyle)]
          : [
              TextSpan(text: '$prefix, ', style: style),
              TextSpan(text: '+$remaining more', style: moreStyle),
            ];
    }
    // Absurdly narrow - shouldn't happen at any real card size, but
    // don't throw: show something rather than nothing.
    return [TextSpan(text: names.first, style: style)];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RichText(
        maxLines: maxLines,
        overflow: TextOverflow.clip,
        text: TextSpan(children: _spansFor(constraints.maxWidth)),
      ),
    );
  }
}
