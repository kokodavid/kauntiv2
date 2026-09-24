import 'package:flutter/material.dart';

import '../domain/county_detail.dart';
import '../domain/place_category.dart';
import 'explore_pill.dart';

/// County Detail's place filters: "ALL · N" first, then one pill per
/// category the county's places actually have, in category order.
/// [selected] null means All.
class CountyPlaceFilters extends StatelessWidget {
  const CountyPlaceFilters({
    super.key,
    required this.places,
    required this.selected,
    required this.onSelected,
  });

  final List<CountyDetailPlace> places;
  final PlaceCategory? selected;
  final ValueChanged<PlaceCategory?> onSelected;

  /// The categories present in [places], in [PlaceCategory] order.
  static List<PlaceCategory> categoriesIn(List<CountyDetailPlace> places) => [
    for (final category in PlaceCategory.values)
      if (places.any((place) => place.category == category)) category,
  ];

  @override
  Widget build(BuildContext context) {
    int count(PlaceCategory c) => places.where((p) => p.category == c).length;
    final pills = <(String, PlaceCategory?)>[
      ('ALL · ${places.length}', null),
      for (final category in categoriesIn(places))
        ('${category.label.toUpperCase()} · ${count(category)}', category),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (label, category) in pills) ...[
            if (category != pills.first.$2) const SizedBox(width: 8),
            ExplorePill(
              label: label,
              selected: category == selected,
              horizontalPadding: 14,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}
