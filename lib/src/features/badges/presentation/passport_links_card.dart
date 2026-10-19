import 'package:flutter/material.dart';

import 'passport_palette.dart';
import 'passport_text.dart';

/// Where a county page leads next: the county itself, with its places,
/// safety and news. Context only; it never counts towards a stamp.
class PassportLinksCard extends StatelessWidget {
  const PassportLinksCard({
    super.key,
    required this.county,
    required this.onOpen,
  });

  final String county;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.explore_outlined, color: Color(0xFF0A84FF)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore $county',
                      style: passportText(14, weight: FontWeight.w600),
                    ),
                    Text(
                      'Places, safety and news',
                      style: passportText(12, color: PassportInk.tertiary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: PassportInk.disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
