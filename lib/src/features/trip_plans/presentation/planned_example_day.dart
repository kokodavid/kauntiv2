import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import 'plan_day_colors.dart';

/// One county on an example day: claimed (blue) or new (grey, "new").
class ExampleCounty {
  const ExampleCounty(this.name, {this.isNew = false});

  final String name;
  final bool isNew;
}

/// A sample day for the empty Planned page. Fixed copy, so the page stays
/// static and works offline.
class ExampleDay {
  const ExampleDay({
    required this.number,
    required this.date,
    required this.title,
    required this.meta,
    required this.stops,
    required this.counties,
  });

  final int number;
  final String date;
  final String title;
  final String meta;
  final List<String> stops;
  final List<ExampleCounty> counties;
}

/// The three days the empty state cycles through (a coast trip).
const exampleDays = [
  ExampleDay(
    number: 1,
    date: 'Fri 11 Dec',
    title: 'Mombasa day',
    meta: '3 stops · about 55 min drive · 24 km',
    stops: ['Fort Jesus', 'Haller Park', 'Nyali Beach'],
    counties: [ExampleCounty('Mombasa')],
  ),
  ExampleDay(
    number: 2,
    date: 'Sat 12 Dec',
    title: 'Coast drive north',
    meta: '3 stops · about 2 h 30 min drive · 118 km',
    stops: ['Kilifi Creek', 'Gede Ruins', 'Watamu Marine Park'],
    counties: [ExampleCounty('Mombasa'), ExampleCounty('Kilifi', isNew: true)],
  ),
  ExampleDay(
    number: 3,
    date: 'Sun 13 Dec',
    title: 'To Lamu',
    meta: '2 stops · about 4 h 10 min drive · 236 km',
    stops: ['Malindi Marine Park', 'Lamu Old Town'],
    counties: [
      ExampleCounty('Kilifi', isNew: true),
      ExampleCounty('Tana River', isNew: true),
      ExampleCounty('Lamu', isNew: true),
    ],
  ),
];

/// A collapsed example day: the card the real plan screen shows for a day,
/// at a fixed height so the loop never jumps.
class ExampleDayCard extends StatelessWidget {
  const ExampleDayCard({super.key, required this.day});

  final ExampleDay day;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.exploreSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.exploreBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlanDayPill(number: day.number),
                const SizedBox(width: 8),
                Text(day.date, style: AppTypeScale.meta),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              day.title,
              style: AppTypeScale.cardTitle.copyWith(height: 22 / 16),
            ),
            const SizedBox(height: 4),
            Text(
              day.meta,
              style: AppTypeScale.small.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.detailStatValue,
              ),
            ),
            Text(
              day.stops.join(' → '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypeScale.small,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                for (final county in day.counties) _CountyDot(county: county),
              ],
            ),
          ],
        ),
      ),
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

class _CountyDot extends StatelessWidget {
  const _CountyDot({required this.county});

  final ExampleCounty county;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: AppTypeScale.family,
      fontSize: 11,
      height: 16 / 11,
      color: AppColors.bodyText,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: county.isNew
                ? AppColors.lockedStroke
                : AppColors.legendVisited,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(county.name, style: style),
        if (county.isNew) ...[
          const SizedBox(width: 4),
          Text(
            'new',
            style: style.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.newCountyText,
            ),
          ),
        ],
      ],
    );
  }
}
