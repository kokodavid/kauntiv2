import 'package:flutter/material.dart';

import '../domain/passport_rules.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// Why the next stamp is locked in this county: what it asks for against
/// what the county has so far. Sits in the Next stamp card.
class PassportLockNote extends StatelessWidget {
  const PassportLockNote({super.key, required this.county, required this.lock});

  final String county;
  final PassportLock lock;

  String get _message {
    String n(int v, String one, String many) => '$v ${v == 1 ? one : many}';
    final asks = <String>[
      if (lock.needsPlaces)
        '${n(lock.placesNeeded, 'place', 'places')} '
            '(it has ${lock.placesHave})',
      if (lock.needsCategories)
        '${n(lock.categoriesNeeded, 'category', 'categories')} among them '
            '(it covers ${lock.categoriesHave})',
    ];
    return '${lock.level.label} needs ${asks.join(' and ')}. '
        "We're adding places to $county. Your earned stamps stay as they are.";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: PassportInk.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _message,
              style: passportText(
                12.5,
                color: PassportInk.secondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
