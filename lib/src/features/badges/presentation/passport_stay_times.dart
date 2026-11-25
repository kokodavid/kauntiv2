import 'package:flutter/material.dart';

import '../domain/county_badge_detail.dart';
import 'passport_dates.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// How long the traveller has stayed in a county, added up across visits.
/// Display only: the 2 hours that earns a county is still one stay.
/// Visits are not listed one by one. Nothing shows until a stay with a
/// recorded length exists.
class PassportStayTimes extends StatelessWidget {
  const PassportStayTimes({super.key, required this.detail});

  final CountyBadgeDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.timedVisits == 0 && detail.longVisits == 0) {
      return const SizedBox.shrink();
    }
    final n = detail.timedVisits;
    final summary = n == 0
        ? 'Stays here were longer than a day'
        : 'About ${passportDuration(detail.totalStay)} across '
              '$n timed visit${n == 1 ? '' : 's'}';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary, style: passportText(13, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Time adds up across visits, but Explored needs a single stay '
            'of 2 hours or more.',
            style: passportText(12, color: PassportInk.secondary),
          ),
          if (detail.longVisits > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Stays over a day are left out of the total.',
              style: passportText(11, color: PassportInk.tertiary),
            ),
          ],
        ],
      ),
    );
  }
}
