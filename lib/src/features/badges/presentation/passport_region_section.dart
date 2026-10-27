import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/passport_county.dart';
import '../domain/passport_regions.dart';
import 'passport_palette.dart';
import 'passport_stamp_cell.dart';
import 'passport_text.dart';

/// A region: its name, "x of y stamped", and a four-column grid.
class PassportRegionSection extends StatelessWidget {
  const PassportRegionSection({
    super.key,
    required this.region,
    required this.counties,
    required this.stamped,
    required this.total,
    required this.onOpen,
  });

  final PassportRegion region;
  final List<PassportCounty> counties;
  final int stamped;
  final int total;
  final void Function(int countyCode) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                region.label,
                style: passportText(15, weight: FontWeight.w700),
              ),
            ),
            Text(
              '$stamped of $total explored',
              style: passportText(
                12,
                weight: FontWeight.w600,
                color: PassportInk.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
        const SizedBox(height: 14),
        // Rows of four, so cells keep their natural height.
        for (var start = 0; start < counties.length; start += 4) ...[
          if (start > 0) const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: start + i < counties.length
                      ? PassportStampCell(
                          county: counties[start + i],
                          onTap: () => onOpen(counties[start + i].code),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
