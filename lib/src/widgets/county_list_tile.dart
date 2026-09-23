import 'package:flutter/material.dart';

import '../counties/county_paths.dart';
import '../design/app_colors.dart';
import '../design/app_text_styles.dart';
import 'app_county_shape.dart';

/// One row in a county picker: the county's outline, its name, "County
/// No. N", and a checkmark when it's the current selection. Used inside
/// [CountyPickerSheet]'s list -- factored out on its own so any other
/// "pick a county" surface can reuse the exact same row instead of
/// re-deriving it (v1 had two near-duplicate versions of this row, one
/// inline on the map screen and one in its bottom sheet).
class CountyListTile extends StatelessWidget {
  const CountyListTile({
    super.key,
    required this.county,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final CountyPath county;
  final bool selected;
  final VoidCallback onTap;

  /// Draws a bottom divider matching the Figma list (every row except
  /// the last has one). The caller decides per-row since only the list
  /// knows which row is last.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.listDivider),
                ),
              )
            : null,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: AppCountyShape(
                county: county,
                fill: Colors.transparent,
                stroke: AppColors.mutedForeground,
                strokeWidth: 1.2,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(county.name, style: AppTextStyles.listItemTitle),
                  Text(
                    'County No. ${county.code}',
                    style: AppTextStyles.listItemSubtitle,
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 18, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
