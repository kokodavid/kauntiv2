import 'package:flutter/material.dart';

import '../../../core/domain/place_type.dart';
import '../domain/county_detail.dart';
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
  final PlaceType? selected;
  final ValueChanged<PlaceType?> onSelected;

  /// The types present in [places], in list order ([PlaceType.all]);
  /// unlisted types come last.
  static List<PlaceType> categoriesIn(List<CountyDetailPlace> places) {
    int rank(PlaceType type) {
      final index = PlaceType.all.indexOf(type);
      return index < 0 ? PlaceType.all.length : index;
    }

    return {for (final place in places) place.category}.toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  @override
  Widget build(BuildContext context) {
    int count(PlaceType c) => places.where((p) => p.category == c).length;
    final pills = <(String, PlaceType?)>[
      ('All · ${places.length}', null),
      for (final category in categoriesIn(places))
        ('${category.pluralLabel} · ${count(category)}', category),
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
