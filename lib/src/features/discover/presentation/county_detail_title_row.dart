import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_county_shape.dart';
import '../domain/county_detail.dart';
import 'county_detail_facts.dart';

/// County title and stats paired with its county shape.
class CountyDetailTitleRow extends StatelessWidget {
  const CountyDetailTitleRow({super.key, required this.data});

  final CountyDetailData data;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.county.name, style: AppTextStyles.detailTitle),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.factCardBorder),
            const SizedBox(height: 10),
            CountyStatsRow(facts: data.quickFacts),
          ],
        ),
      ),
      const SizedBox(width: 19),
      Container(
        width: 100,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.countyShapeCardBorder),
          borderRadius: BorderRadius.circular(24),
        ),
        child: AppCountyShape(
          county: data.county,
          fill: data.isHeld ? AppColors.green : AppColors.lockedFill,
          stroke: data.isHeld ? null : AppColors.lockedStroke,
          strokeWidth: data.isHeld ? 0 : 1.2,
          dashed: !data.isHeld,
        ),
      ),
    ],
  );
}
