import 'package:flutter/material.dart';

import '../domain/passport_level.dart';
import '../domain/passport_rules.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// "To earn Silver": what the next stamp asks for, in plain words. Metal
/// targets are the same in every county.
class PassportRequirements extends StatelessWidget {
  const PassportRequirements({
    super.key,
    required this.next,
    required this.county,
    required this.rules,
  });

  final PassportLevel next;
  final String county;
  final PassportRules rules;

  List<String> get _lines {
    switch (next) {
      case PassportLevel.passedThrough:
        return [
          'Cross into $county with Kaunti47 allowed to use your location, '
              'even when the app is closed. The stamp is pressed for you.',
        ];
      case PassportLevel.explored:
        final hours = rules.exploredStay.inHours;
        return ['Spend $hours hours or more in $county on a single visit.'];
      default:
        final t = rules.milestoneFor(next);
        if (t == null) return const [];
        String n(int v, String one, String many) => '$v ${v == 1 ? one : many}';
        final days = t.visitDays == 1
            ? 'on 1 day'
            : 'across ${t.visitDays} days';
        return [
          'Check in at ${n(t.places, 'place', 'places')} in '
              '${n(t.categories, 'category', 'categories')}, $days.',
          "Tap I'm here on a place's page while you're there.",
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TO EARN ${next.label.toUpperCase()}',
            style: passportText(
              10,
              weight: FontWeight.w600,
              color: PassportInk.tertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lines.first,
            style: passportText(12.5, weight: FontWeight.w500, height: 1.4),
          ),
          for (final extra in lines.skip(1)) ...[
            const SizedBox(height: 4),
            Text(
              extra,
              style: passportText(
                11.5,
                color: PassportInk.secondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
