import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/place_type.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_place_facets.dart';
import '../domain/plan_place_query.dart';

/// A filter chip: county or type, 34 high.
class PlaceFilterChip extends StatelessWidget {
  const PlaceFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.accent : AppColors.exploreSurface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.exploreBorder,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: selected ? Colors.white : AppColors.ink,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: AppTypeScale.small.copyWith(
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The type chips' keys and labels, in display order. With [only], just the
/// types that have places.
List<({String key, String label})> placeTypeChoices({Set<String>? only}) => [
  for (final type in PlaceType.all)
    if (only == null || only.contains(type.key))
      (key: type.key, label: type.pluralLabel),
];

/// The row of filters under the search box: All, County and one chip per
/// type that has places. Until [facets] is known every type is offered.
class AddPlacesFilterBar extends StatelessWidget {
  const AddPlacesFilterBar({
    super.key,
    required this.query,
    required this.facets,
    required this.onAll,
    required this.onCounty,
    required this.onType,
  });

  final PlanPlaceQuery query;
  final PlanPlaceFacets? facets;
  final VoidCallback onAll;
  final VoidCallback onCounty;
  final ValueChanged<String> onType;

  @override
  Widget build(BuildContext context) {
    final countyName = query.countyCode == null
        ? 'County'
        : CountyPaths.byCode[query.countyCode]?.name ?? 'County';
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          PlaceFilterChip(
            label: 'All',
            selected: query.countyCode == null && query.type == null,
            onTap: onAll,
          ),
          if (facets == null ||
              facets!.counties.isNotEmpty ||
              query.countyCode != null)
            PlaceFilterChip(
              label: countyName,
              icon: Icons.map_outlined,
              selected: query.countyCode != null,
              onTap: onCounty,
            ),
          for (final choice in placeTypeChoices(only: facets?.types))
            PlaceFilterChip(
              label: choice.label,
              selected: query.type == choice.key,
              onTap: () => onType(choice.key),
            ),
        ],
      ),
    );
  }
}
