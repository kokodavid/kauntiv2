import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/map_place.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/nearby_places.dart';
import 'trip_stop_dot.dart';

/// The expanded stops: a white card with where the trip starts, each stop
/// with up / down / remove buttons, and the place itself last. Long-press
/// and drag works too; the buttons are the way for everyone else.
class TripStopsRows extends StatelessWidget {
  const TripStopsRows({
    super.key,
    required this.stops,
    required this.destinationName,
    required this.destLat,
    required this.destLng,
    required this.onMove,
    required this.onRemove,
  });

  final List<MapPlace> stops;
  final String destinationName;
  final double destLat;
  final double destLng;

  /// Moves the stop at [from] to [to] (indices into the final list).
  final void Function(int from, int to) onMove;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          const _FixedRow(dot: TripStopDot.start(), title: 'Your location'),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: stops.length,
            onReorder: (oldIndex, newIndex) =>
                onMove(oldIndex, newIndex > oldIndex ? newIndex - 1 : newIndex),
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              child: child,
            ),
            itemBuilder: (context, i) {
              final stop = stops[i];
              final county = CountyPaths.byCode[stop.countyCode]?.name ?? '';
              final away = NearbyPlace(
                place: stop,
                distanceMeters: NearbyPlaces.metres(
                  destLat,
                  destLng,
                  stop.lat,
                  stop.lng,
                ),
              ).distanceLabel;
              return ReorderableDelayedDragStartListener(
                key: ValueKey(stop.id),
                index: i,
                child: _StopRow(
                  number: i + 1,
                  name: stop.name,
                  detail: '$county · $away from $destinationName',
                  canUp: i > 0,
                  canDown: i < stops.length - 1,
                  onUp: () => onMove(i, i - 1),
                  onDown: () => onMove(i, i + 1),
                  onRemove: () => onRemove(stop.id),
                ),
              );
            },
          ),
          _FixedRow(dot: const TripStopDot.end(), title: destinationName),
        ],
      ),
    );
  }
}

class _FixedRow extends StatelessWidget {
  const _FixedRow({required this.dot, required this.title});

  final Widget dot;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            dot,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypeScale.itemTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.number,
    required this.name,
    required this.detail,
    required this.canUp,
    required this.canDown,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
  });

  final int number;
  final String name;
  final String detail;
  final bool canUp;
  final bool canDown;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 4),
        child: Row(
          children: [
            TripStopDot.stop(number),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.itemTitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.small,
                  ),
                ],
              ),
            ),
            _IconAction(
              icon: Icons.arrow_upward,
              tooltip: 'Move $name up',
              onPressed: canUp ? onUp : null,
            ),
            _IconAction(
              icon: Icons.arrow_downward,
              tooltip: 'Move $name down',
              onPressed: canDown ? onDown : null,
            ),
            _IconAction(
              icon: Icons.close,
              tooltip: 'Remove $name',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.3 : 1,
      child: SizedBox(
        width: 40,
        height: 44,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 18, color: AppColors.foreground),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
