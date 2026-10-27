import 'package:flutter/material.dart';

import 'passport_palette.dart';
import 'passport_text.dart';

/// Passed Through's way to Explored: three parts that fill in turn as the
/// longest single visit approaches the stay that earns Explored.
class PassportVisitMeter extends StatelessWidget {
  const PassportVisitMeter({super.key, required this.fraction});

  final double fraction;

  static const _parts = [
    (label: 'Brief Pass', from: 0.0, to: 0.33),
    (label: 'Linger', from: 0.33, to: 0.75),
    (label: 'Almost There', from: 0.75, to: 1.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _parts.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            flex: ((_parts[i].to - _parts[i].from) * 100).round(),
            child: _Part(
              label: _parts[i].label,
              fill:
                  ((fraction - _parts[i].from) /
                          (_parts[i].to - _parts[i].from))
                      .clamp(0.0, 1.0),
              isCurrent: fraction >= _parts[i].from && fraction < _parts[i].to,
              isDone: fraction >= _parts[i].to,
            ),
          ),
        ],
      ],
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({
    required this.label,
    required this.fill,
    required this.isCurrent,
    required this.isDone,
  });

  final String label;
  final double fill;
  final bool isCurrent;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 6,
            backgroundColor: PassportInk.segmentOff,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF0A84FF)),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: passportText(
            10.5,
            weight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isDone
                ? PassportInk.secondary
                : isCurrent
                ? PassportInk.primary
                : PassportInk.disabled,
          ),
        ),
      ],
    );
  }
}
