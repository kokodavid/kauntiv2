import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/place_type.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';

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

/// The 47 counties by name. Returns the county code, 0 for "All counties",
/// or null when closed without choosing.
Future<int?> showCountyFilterSheet(
  BuildContext context, {
  int? selected,
  Set<int>? only,
}) {
  final counties = [
    for (final c in CountyPaths.all)
      if (only == null || only.contains(c.code)) c,
  ]
    ..sort((a, b) => a.name.compareTo(b.name));
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Browse by county', style: AppTypeScale.sectionTitle),
            ),
            ListTile(
              minTileHeight: 52,
              title: const Text('All counties'),
              selected: selected == null,
              onTap: () => Navigator.of(sheet).pop(0),
            ),
            for (final county in counties)
              ListTile(
                minTileHeight: 52,
                title: Text(county.name),
                selected: selected == county.code,
                onTap: () => Navigator.of(sheet).pop(county.code),
              ),
          ],
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
