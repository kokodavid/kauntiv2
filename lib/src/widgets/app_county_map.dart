import 'package:flutter/material.dart';

import '../counties/county_paths.dart';
import '../design/app_colors.dart';
import 'app_svg_path.dart';

/// The whole-of-Kenya map, drawn from [CountyPaths] (the same vector data
/// [AppCountyShape]/[AppCountryShape] use elsewhere), with the selected
/// county highlighted.
///
/// [onCountySelected] gives real tap-to-select on the actual county
/// shapes (Figma's "Tap your county on the map" caption), not just a
/// single whole-widget tap target -- a tap is hit-tested against every
/// county's real polygon by inverting the same scale/translate the
/// painter uses, then finding which path contains that point.
class AppCountyMap extends StatelessWidget {
  const AppCountyMap({
    super.key,
    required this.selectedCounty,
    this.onCountySelected,
  });

  final CountyPath? selectedCounty;
  final ValueChanged<CountyPath>? onCountySelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Map of Kenya counties',
      button: onCountySelected != null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onCountySelected == null
                ? null
                : (details) {
                    final county = _countyAt(details.localPosition, size);
                    if (county != null) onCountySelected!(county);
                  },
            child: CustomPaint(
              painter: _CountyMapPainter(selectedCounty: selectedCounty),
              size: size,
            ),
          );
        },
      ),
    );
  }

  /// Inverts the painter's fit-to-box transform (see
  /// [_CountyMapPainter.paint]) to turn a tap's local offset into
  /// viewBox-space, then returns whichever county's real path contains
  /// that point, if any.
  CountyPath? _countyAt(Offset localPosition, Size size) {
    if (size.isEmpty) return null;

    final scale = [
      size.width / CountyPaths.viewBoxWidth,
      size.height / CountyPaths.viewBoxHeight,
    ].reduce((a, b) => a < b ? a : b);
    if (scale <= 0) return null;

    final dx = (size.width - CountyPaths.viewBoxWidth * scale) / 2;
    final dy = (size.height - CountyPaths.viewBoxHeight * scale) / 2;
    final pathPoint = Offset(
      (localPosition.dx - dx) / scale,
      (localPosition.dy - dy) / scale,
    );

    for (final county in CountyPaths.all) {
      if (AppSvgPath.parse(county.pathData).contains(pathPoint)) {
        return county;
      }
    }
    return null;
  }
}

class _CountyMapPainter extends CustomPainter {
  const _CountyMapPainter({required this.selectedCounty});

  final CountyPath? selectedCounty;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = [
      size.width / CountyPaths.viewBoxWidth,
      size.height / CountyPaths.viewBoxHeight,
    ].reduce((a, b) => a < b ? a : b);
    final dx = (size.width - CountyPaths.viewBoxWidth * scale) / 2;
    final dy = (size.height - CountyPaths.viewBoxHeight * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    for (final county in CountyPaths.all) {
      final path = AppSvgPath.parse(county.pathData);
      // Selected fill is legendHome, not AppColors.green (v1's olive) --
      // this map's "home county" highlight is the same green the app's
      // stat-card legend already uses for "Home" elsewhere.
      //
      // Unselected fill/stroke: the Figma "Karibu" node (235:4745) embeds
      // the map as a flattened image rather than per-county vector paths,
      // so there's no fill/stroke token attached to the shapes directly.
      // A closer look at the actual screenshot (not just the variable-defs
      // list, which mixes in colors from sibling buttons/chips) shows the
      // county fill is a crisp white ("White theme" / #ffffff in that same
      // list) standing out against the #f5f5f5 page background -- an
      // earlier pass wrongly used `cardBorder` (#f1f5f9, only a hair off
      // #f5f5f5) for the fill, which made the whole map nearly disappear
      // into the page instead of reading as a distinct white shape. The
      // internal county-boundary lines are the pale `trackInactive`
      // (#e2e8f0, matches `colors/slate/200` from the same node) -- that
      // part was already right.
      final selected = county == selectedCounty;
      canvas.drawPath(
        path,
        Paint()..color = selected ? AppColors.legendHome : Colors.white,
      );
      if (!selected) {
        canvas.drawPath(
          path,
          Paint()
            ..color = AppColors.trackInactive
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CountyMapPainter oldDelegate) {
    return oldDelegate.selectedCounty != selectedCounty;
  }
}
