import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import 'plan_day_colors.dart';

/// The worked example on the empty Planned page (design 1a): a sample Day 1
/// built from the same parts as a real day, tagged EXAMPLE.
class PlannedExampleDay extends StatelessWidget {
  const PlannedExampleDay({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.exploreSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.exploreBorder),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PlanDayPill(number: 1),
            SizedBox(width: 8),
            Expanded(
              child: Text('Rift Valley drive', style: AppTypeScale.itemTitle),
            ),
            Text('EXAMPLE', style: AppTypeScale.sectionLabel),
          ],
        ),
        SizedBox(height: 10),
        _ExampleStop(
          number: 1,
          name: 'Rift Valley Viewpoint',
          type: 'Viewpoint',
          county: 'Kiambu',
          countyColor: AppColors.legendVisited,
        ),
        Padding(
          padding: EdgeInsets.only(left: 32, top: 4, bottom: 4),
          child: Text('about 1 h 10 min · 62 km', style: AppTypeScale.meta),
        ),
        _ExampleStop(
          number: 2,
          name: "Hell's Gate National Park",
          type: 'Park',
          county: 'Nakuru',
          countyColor: AppColors.lockedStroke,
          isNew: true,
        ),
        Divider(height: 20, color: AppColors.softDivider),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('PASSES', style: AppTypeScale.sectionLabel),
            _CountyDot(name: 'Nairobi', color: AppColors.legendHome),
            _CountyDot(name: 'Kiambu', color: AppColors.legendVisited),
            _CountyDot(
              name: 'Nakuru',
              color: AppColors.lockedStroke,
              isNew: true,
            ),
          ],
        ),
      ],
    ),
  );
}

/// The "DAY 1" pill in the day's colour.
class PlanDayPill extends StatelessWidget {
  const PlanDayPill({super.key, required this.number, this.muted = false});

  final int number;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    height: 20,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: muted ? AppColors.lockedStroke : PlanDayColors.of(number),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      'DAY $number',
      style: const TextStyle(
        fontFamily: AppTypeScale.family,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Colors.white,
      ),
    ),
  );
}

class _ExampleStop extends StatelessWidget {
  const _ExampleStop({
    required this.number,
    required this.name,
    required this.type,
    required this.county,
    required this.countyColor,
    this.isNew = false,
  });

  final int number;
  final String name;
  final String type;
  final String county;
  final Color countyColor;
  final bool isNew;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 11,
        backgroundColor: PlanDayColors.of(1),
        child: Text(
          '$number',
          style: const TextStyle(
            fontFamily: AppTypeScale.family,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTypeScale.itemTitle),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.exploreCategoryFill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    type,
                    style: AppTypeScale.meta.copyWith(
                      color: AppColors.exploreCategoryText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CountyDot(name: county, color: countyColor, isNew: isNew),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class _CountyDot extends StatelessWidget {
  const _CountyDot({
    required this.name,
    required this.color,
    this.isNew = false,
  });

  final String name;
  final Color color;
  final bool isNew;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(name, style: AppTypeScale.meta),
      if (isNew) ...[
        const SizedBox(width: 4),
        Text(
          'new',
          style: AppTypeScale.meta.copyWith(color: AppColors.newCountyText),
        ),
      ],
    ],
  );
}
