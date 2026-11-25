import 'package:flutter/material.dart';

import '../domain/county_badge_detail.dart';
import 'passport_dates.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// How long the traveller has stayed in a county, add up and stay by stay.
/// Display only: the 2 hours that earns a county is still one stay.
/// Nothing shows until a stay with a recorded length exists.
class PassportStayTimes extends StatelessWidget {
  const PassportStayTimes({super.key, required this.detail});

  final CountyBadgeDetail detail;

  static const _listed = 3;

  @override
  Widget build(BuildContext context) {
    final stays = [
      for (final s in detail.recentStays)
        if (s.stay != null) s,
    ].take(_listed).toList();
    if (detail.timedVisits == 0 && stays.isEmpty) {
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
          for (final s in stays) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${passportDay(s.enteredAt)} · '
                    '${s.explored ? 'Explored' : 'Passed through'}',
                    style: passportText(12, color: PassportInk.secondary),
                  ),
                ),
                Text(
                  s.isLong ? 'Over a day' : passportDuration(s.stay!),
                  style: passportText(12, weight: FontWeight.w600),
                ),
              ],
            ),
          ],
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
