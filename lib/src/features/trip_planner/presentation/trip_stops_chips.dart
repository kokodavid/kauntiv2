import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/map_place.dart';
import '../../../design/app_colors.dart';
import 'trip_stop_dot.dart';

/// The stops on one line: "You, 1, 2, the place", joined by short
/// connectors. The calm view of the trip; "Edit order" opens the list.
class TripStopsChips extends StatelessWidget {
  const TripStopsChips({
    super.key,
    required this.stops,
    required this.destinationName,
    this.selected,
    this.onSelect,
  });

  final List<MapPlace> stops;
  final String destinationName;

  /// Marker index highlighted (0 you, 1..n stops, n+1 the place).
  final int? selected;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      TripStopChip(
        dot: const TripStopDot.start(size: 24),
        label: 'You',
        selected: selected == 0,
        onTap: onSelect == null ? null : () => onSelect!(0),
      ),
      for (final (i, stop) in stops.indexed)
        TripStopChip(
          dot: TripStopDot.stop(i + 1, size: 24),
          label: stop.name,
          selected: selected == i + 1,
          onTap: onSelect == null ? null : () => onSelect!(i + 1),
        ),
      TripStopChip(
        dot: const TripStopDot.end(size: 24),
        label: destinationName,
        selected: selected == stops.length + 1,
        onTap: onSelect == null ? null : () => onSelect!(stops.length + 1),
      ),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: chips.length,
        separatorBuilder: (context, index) => Center(
          child: Container(
            width: 10,
            height: 2,
            color: AppColors.trackInactive,
          ),
        ),
        itemBuilder: (context, index) => Center(child: chips[index]),
      ),
    );
  }
}

/// One pill of [TripStopsChips] (also the full-screen map's stop strip).
class TripStopChip extends StatelessWidget {
  const TripStopChip({
    super.key,
    required this.dot,
    required this.label,
    this.selected = false,
    this.onTap,
    this.maxWidth = 160,
  });

  final Widget dot;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.foreground : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.foreground : AppColors.cardBorder,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 40, maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                dot,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.itemTitle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
