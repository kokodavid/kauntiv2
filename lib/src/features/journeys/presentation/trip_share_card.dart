import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_shape.dart';
import '../domain/journey_transport_mode.dart';
import 'journey_transport_mode_ui.dart';

/// Where a [TripShareCard] is used: the wide in-app history-card
/// thumbnail, or one of the taller share-out sizes (Instagram feed 4:5,
/// Stories 9:16). Both tall sizes use this one "share" arrangement,
/// differing only in outer padding (see [TripShareCard._contentPadding])
/// - only the label verbosity and whether the Trip title shows differ
/// between [thumbnail] and [share] themselves.
enum TripShareCardVariant { thumbnail, share }

/// The generated Trip image used both as the history card's background
/// (replacing the old Mapbox route-preview fetch) and as the file handed
/// to the OS share sheet (Claude-Design "Trip Share Card" reference).
///
/// Pure layout: this widget only draws, from already-resolved data. It
/// doesn't decide which photo to use, fetch it, or rasterize itself to a
/// PNG - that's the renderer built on top of it next.
class TripShareCard extends StatelessWidget {
  const TripShareCard({
    super.key,
    required this.variant,
    required this.width,
    required this.height,
    required this.title,
    required this.startedAt,
    required this.endedAt,
    this.transportMode,
    this.distanceMeters,
    this.topSpeedMps,
    this.averageSpeedMps,
    this.highestElevationMeters,
    this.countyNames = const [],
    this.photo,
    this.routePoints = const [],
  });

  final TripShareCardVariant variant;

  /// The card's exact logical size - 342x171 for the history-card
  /// thumbnail, 360x450 for a 4:5 feed share, 360x640 for a 9:16 Story
  /// share (Claude-Design "Trip Share Card" reference). Exporting to a
  /// higher-resolution PNG (the design calls for 3x) is the renderer's
  /// job, not this widget's - it only ever lays out at its logical size.
  final double width;
  final double height;

  /// Shown only in the [TripShareCardVariant.share] layout - the
  /// thumbnail has no room for it alongside the stat grid.
  final String title;

  final DateTime startedAt;
  final DateTime endedAt;
  final JourneyTransportMode? transportMode;
  final double? distanceMeters;
  final double? topSpeedMps;
  final double? averageSpeedMps;
  final double? highestElevationMeters;

  /// Counties the Trip crossed, in trip order. The count shown ("5
  /// counties") is just this list's length - there's no separate count
  /// field to keep in sync.
  final List<String> countyNames;

  /// The Trip's cover photo, already resolved - null shows the no-photo
  /// brand gradient instead. Resolving *which* photo (the user's chosen
  /// cover, falling back to the Trip's earliest) and fetching it is the
  /// caller's job.
  final ImageProvider? photo;

  /// The route's points, already normalized to a unit square - see
  /// [normalizeRoute] - for the no-photo fallback's route line. Ignored
  /// whenever [photo] is set.
  final List<Offset> routePoints;

  /// Normalizes a route's (lat, lng) points to a unit square: (0,0) is
  /// the top-left of its own bounding box, (1,1) the bottom-right,
  /// aspect-ratio preserved (the shorter axis is centered rather than
  /// stretched to fill the square). Lets the no-photo painter place a
  /// route anywhere at any size without knowing real coordinates.
  /// Returns an empty list for a route with no real span - nothing
  /// meaningful to draw.
  static List<Offset> normalizeRoute(List<(double lat, double lng)> points) {
    if (points.length < 2) return const [];
    var minLat = points.first.$1, maxLat = points.first.$1;
    var minLng = points.first.$2, maxLng = points.first.$2;
    for (final (lat, lng) in points) {
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    final span = math.max(latSpan, lngSpan);
    if (span == 0) return const [];
    final latPad = (span - latSpan) / 2;
    final lngPad = (span - lngSpan) / 2;
    return [
      for (final (lat, lng) in points)
        Offset(
          (lng - minLng + lngPad) / span,
          // Screen y grows downward; latitude grows northward, so flip.
          1 - (lat - minLat + latPad) / span,
        ),
    ];
  }

  bool get _isShare => variant == TripShareCardVariant.share;

  /// True for the taller, narrower Stories shape (9:16) rather than the
  /// Feed shape (4:5) - both are [TripShareCardVariant.share], told
  /// apart only by how tall they are relative to their width, since
  /// nothing else about this widget's inputs differs between them.
  bool get _isStory => height / width > 1.5;

  EdgeInsets get _contentPadding {
    if (!_isShare) return const EdgeInsets.all(14);
    // Stories safe zone (Claude-Design reference): keep clear of the
    // top/bottom strips where Instagram and WhatsApp draw their own UI.
    return _isStory
        ? const EdgeInsets.fromLTRB(20, 72, 20, 104)
        : const EdgeInsets.all(22);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null;
    final dateLabel = _TripShareDate.format(
      startedAt,
      endedAt,
      includeYear: _isShare,
    );
    final icon = transportMode == null
        ? null
        : journeyTransportModeIcon(transportMode!);
    final distance = _TripShareStats.distance(distanceMeters);
    final topSpeed = _TripShareStats.speed(topSpeedMps);
    final avgSpeed = _TripShareStats.speed(averageSpeedMps);
    final peak = _TripShareStats.elevation(highestElevationMeters);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              Image(image: photo!, fit: BoxFit.cover)
            else
              _NoPhotoBackground(routePoints: routePoints, isShare: _isShare),
            // Always present; lighter over the brand gradient than over
            // a real photo, which can be far busier or brighter.
            _BottomScrim(strength: hasPhoto ? 1 : 0.6),
            _TopScrim(strength: hasPhoto ? 1 : 0.6),
            Padding(
              padding: _contentPadding,
              child: _isShare
                  ? _ShareContent(
                      title: title,
                      dateLabel: dateLabel,
                      icon: icon,
                      watermarkInverted: !hasPhoto,
                      countyNames: countyNames,
                      distance: distance,
                      topSpeed: topSpeed,
                      avgSpeed: avgSpeed,
                      peak: peak,
                    )
                  : _ThumbnailContent(
                      dateLabel: dateLabel,
                      icon: icon,
                      watermarkInverted: !hasPhoto,
                      countyNames: countyNames,
                      distance: distance,
                      topSpeed: topSpeed,
                      avgSpeed: avgSpeed,
                      peak: peak,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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

/// The date pill, top-anchored: a transport-mode icon (when known) plus
/// a short date or date range, on a translucent dark pill so it reads
/// over any photo.
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.icon,
    required this.textStyle,
  });

  final String label;
  final IconData? icon;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(label, style: textStyle),
        ],
      ),
    ),
  );
}

/// The app watermark: an icon badge plus the wordmark (Claude-Design
/// reference note: "The route mark and wordmark are placeholders; swap
/// in the real Kaunti47 logo at the same size" - [Icons.alt_route_rounded]
/// here is exactly that placeholder). [inverted] matches the reference's
/// no-photo note ("the watermark tile inverts to white").
/// The brand mark: a small version of the app's own icon ([AppIconBadge]
/// on the splash screen and Onboarding 02) - the gradient rounded-square
/// holding the white Kenya country outline ([AppCountryShape]), not a
/// generic icon. [inverted] swaps it to a white chip with the gradient's
/// own mid-blue shape instead, for the no-photo fallback, whose
/// background is already that same brand gradient - a white chip reads
/// there where a second copy of the gradient wouldn't.
class _Watermark extends StatelessWidget {
  const _Watermark({required this.textStyle, this.inverted = false});

  final TextStyle textStyle;
  final bool inverted;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 22,
        height: 22,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: inverted ? Colors.white : null,
          gradient: inverted
              ? null
              : const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.splashIconGradientStart,
                    AppColors.splashIconGradientMid,
                    AppColors.splashIconGradientEnd,
                  ],
                  stops: [0.04, 0.61, 0.94],
                ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: AppCountryShape(
          fill: inverted ? AppColors.splashIconGradientMid : Colors.white,
        ),
      ),
      const SizedBox(width: 7),
      Text('Kaunti47', style: textStyle),
    ],
  );
}

/// Bottom-up darkening behind the text block - always present, but
/// lighter ([strength] < 1) over the no-photo brand gradient, which
/// already reads darker toward the bottom on its own (Claude-Design
/// reference: "Bottom gradient: 88% ink at the base, 66-70% at a third
/// of the height, clear by 66%. ... The photo is never dimmed all
/// over.").
class _BottomScrim extends StatelessWidget {
  const _BottomScrim({required this.strength});

  final double strength;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          // Extended further up the card (was 0.34/0.66) - Claude-Design
          // "Share Sheet 3a" reference flagged the Trip title sitting on
          // the bright part of a photo in the old build, since the
          // scrim faded out before reaching it on a taller photo.
          stops: const [0, 0.42, 0.70],
          colors: [
            Colors.black.withValues(alpha: 0.90 * strength),
            Colors.black.withValues(alpha: 0.72 * strength),
            Colors.black.withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}

/// A short fade behind the top chip/watermark row, so they stay legible
/// even over a bright sky (Claude-Design reference: "A 50% top gradient
/// sits behind the watermark and chip").
class _TopScrim extends StatelessWidget {
  const _TopScrim({required this.strength});

  final double strength;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.24],
          colors: [
            Colors.black.withValues(alpha: 0.5 * strength),
            Colors.black.withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}

/// The no-photo fallback: a cyan -> accent blue -> violet brand gradient
/// with the Trip's own route drawn faintly over it, so every photo-less
/// Trip still looks like its own Trip rather than a generic placeholder
/// (Claude-Design reference: "A cyan -> blue -> violet brand gradient
/// with the trip's route at 40% white, so each fallback is still
/// unique."). The cyan/violet hex values are placeholders pending real
/// brand colours; [AppColors.accent] anchors the middle of the gradient
/// since it's already the app's primary blue.
class _NoPhotoBackground extends StatelessWidget {
  const _NoPhotoBackground({required this.routePoints, required this.isShare});

  final List<Offset> routePoints;
  final bool isShare;

  static const _cyan = Color(0xFF3FD8F0);
  static const _violet = Color(0xFF6B4CF0);

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_cyan, AppColors.accent, _violet],
      ),
    ),
    child: routePoints.length < 2
        ? null
        : CustomPaint(
            painter: _RouteLinePainter(
              points: routePoints,
              // Thumbnail: a small squiggle tucked behind where the
              // stats sit. Share: "the route drawn large as the hero"
              // (Claude-Design reference) - most of the card.
              area: isShare
                  ? const Rect.fromLTWH(0.08, 0.06, 0.84, 0.56)
                  : const Rect.fromLTWH(0.55, 0.16, 0.38, 0.34),
            ),
          ),
  );
}

class _RouteLinePainter extends CustomPainter {
  _RouteLinePainter({required this.points, required this.area});

  /// Unit-square normalized (see [TripShareCard.normalizeRoute]).
  final List<Offset> points;

  /// The unit-square sub-rect to draw the route within.
  final Rect area;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      area.left * size.width,
      area.top * size.height,
      area.width * size.width,
      area.height * size.height,
    );
    Offset at(int i) => Offset(
      rect.left + points[i].dx * rect.width,
      rect.top + points[i].dy * rect.height,
    );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final p = at(i);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // A solid dot at the end, like the finish of a route - the
    // reference's own route-line sketches end this way.
    canvas.drawCircle(
      at(points.length - 1),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.area != area;
}

/// "Thu 1 Oct" / "Thu 1 Oct 2026" for a single-day Trip; "12-14 Sep" /
/// "12-14 Sep 2026" for one spanning several calendar days locally, or
/// "30 Sep - 2 Oct" across a month boundary.
abstract final class _TripShareDate {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String format(
    DateTime startedAt,
    DateTime endedAt, {
    required bool includeYear,
  }) {
    final start = startedAt.toLocal();
    final end = endedAt.toLocal();
    final year = includeYear ? ' ${end.year}' : '';
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return '${_weekdays[start.weekday - 1]} ${start.day} '
          '${_months[start.month - 1]}$year';
    }
    if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day} ${_months[start.month - 1]}$year';
    }
    return '${start.day} ${_months[start.month - 1]} - '
        '${end.day} ${_months[end.month - 1]}$year';
  }
}

/// Formatting specific to this card: more decimal precision than the
/// compact history-card facts pill uses, since these numbers are the
/// whole point of a share image. Returns (value, unit) separately so the
/// layout can style them differently, rather than one combined string.
abstract final class _TripShareStats {
  /// Always rendered in km, even for a short Trip - a fixed unit keeps
  /// the stat grid's layout predictable. 1 decimal under 100 km, none
  /// at or above it (matches the reference's own examples: "42.3 km",
  /// "612 km").
  ///
  /// Null, not a "—" placeholder, when the underlying value is missing -
  /// [_StatGrid] drops a null cell from the grid entirely instead of
  /// showing an empty dash for a stat the Trip never recorded.
  static (String, String)? distance(double? meters) {
    if (meters == null) return null;
    final km = meters / 1000;
    final value = km < 100 ? km.toStringAsFixed(1) : km.round().toString();
    return (value, 'km');
  }

  static (String, String)? speed(double? metersPerSecond) {
    if (metersPerSecond == null) return null;
    return ('${(metersPerSecond * 3.6).round()}', 'km/h');
  }

  /// Thousands-separated ("1,240 m") - the one stat large enough to need
  /// it. No `intl` dependency for just this: a few lines beats a whole
  /// package for one comma rule.
  static (String, String)? elevation(double? meters) {
    if (meters == null) return null;
    final value = meters.round();
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return ('${value < 0 ? '-' : ''}$buffer', 'm');
  }
}

/// Text styles for both variants, sized from the Claude-Design reference
/// ("Inter throughout. Numbers are 700, units 500 at 75% white, labels
/// 600 caps with +0.07em tracking, county names 500 at 80% white. The
/// county count is the only display-size element."). Kept local to this
/// file rather than added to [AppTypeScale]: these sizes are specific to
/// this one card, not the shared content scale.
abstract final class _Styles {
  static const _white80 = Color(0xCCFFFFFF); // 80% white
  static const _white75 = Color(0xBFFFFFFF); // 75% white
  static const _white70 = Color(0xB3FFFFFF); // 70% white

  // Thumbnail.
  static const thumbChipText = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const thumbWatermarkText = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const thumbCountyCount = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1,
  );
  static const thumbCountyLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const thumbCountyNames = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: _white80,
  );
  static const thumbCountyMore = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const thumbStatValue = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1,
  );
  static const thumbStatUnit = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: _white75,
  );
  static const thumbStatLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: _white70,
    letterSpacing: 0.5,
  );

  // Share (4:5 / 9:16).
  static const shareChipText = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const shareWatermarkText = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const shareTitle = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: _white80,
  );
  static const shareCountyCount = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1,
  );
  static const shareCountyLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const shareCountyNames = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _white80,
  );
  static const shareCountyMore = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const shareStatValue = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 23,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1,
  );
  static const shareStatUnit = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: _white75,
  );
  static const shareStatLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: _white70,
    letterSpacing: 0.6,
  );
}
