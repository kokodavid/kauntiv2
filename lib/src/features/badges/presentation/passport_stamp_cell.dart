import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/passport_county.dart';
import '../domain/passport_level.dart';
import 'passport_medallion.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// One county on the landing grid: medallion in its ring, name, and a
/// line of standing. Metal levels carry a B / S / G tag.
class PassportStampCell extends StatelessWidget {
  const PassportStampCell({super.key, required this.county, required this.onTap});

  final PassportCounty county;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = county.level;
    final mark = level.mark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              PassportMedallion(
                county: county.county,
                level: level,
                size: 56,
                gap: 2,
              ),
              if (mark != null)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: level.ring,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.pageBackground,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      mark,
                      style: passportText(
                        8.5,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            county.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: passportText(11.5, weight: FontWeight.w600),
          ),
          const SizedBox(height: 1),
          SizedBox(
            height: 12,
            child: Text(
              county.subLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: passportText(
                10,
                weight: FontWeight.w500,
                color: level == PassportLevel.gold
                    ? level.text
                    : PassportInk.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
