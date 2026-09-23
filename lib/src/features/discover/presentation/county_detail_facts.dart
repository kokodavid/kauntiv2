import 'package:flutter/material.dart';

import '../domain/county_detail.dart';
import 'detail_widgets.dart';

/// Area / Elevation / Population beside the county shape. Missing values
/// read "Not on file yet", never a guess.
class CountyStatsRow extends StatelessWidget {
  const CountyStatsRow({super.key, required this.facts});

  final CountyQuickFacts facts;

  static const _missing = 'Not on file yet';

  @override
  Widget build(BuildContext context) {
    final area = facts.areaKm2;
    final elevation = facts.elevationM;
    final population = facts.population;
    return Row(
      children: [
        Expanded(
          child: DetailStatFact(
            label: 'Area',
            value: area == null ? _missing : '${withCommas(area)} KM²',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DetailStatFact(
            label: 'Elevation',
            value: elevation == null ? _missing : '${withCommas(elevation)}m',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DetailStatFact(
            label: 'Population',
            value: population == null ? _missing : compactCount(population),
          ),
        ),
      ],
    );
  }

  static String withCommas(num value) {
    final rounded = value.round();
    final digits = rounded.abs().toString();
    final buffer = StringBuffer(rounded < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String compactCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return '$value';
  }
}
