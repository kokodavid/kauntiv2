import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/map_place.dart';
import '../../../design/app_colors.dart';
import '../domain/trip_stop_order.dart';
import 'trip_stops_chips.dart';
import 'trip_stops_rows.dart';

/// "Stops": the trip's stops on one line, or, with "Edit order", as a list
/// to reorder and remove from. The order is the planner's shortest one
/// until the user changes it; a much longer one is called out.
class TripStopsList extends StatefulWidget {
  const TripStopsList({
    super.key,
    required this.stops,
    required this.destinationName,
    required this.destLat,
    required this.destLng,
    required this.custom,
    required this.extraMeters,
    required this.onRemove,
    required this.onReorder,
    required this.onAutoOrder,
  });

  final List<MapPlace> stops;
  final String destinationName;
  final double destLat;
  final double destLng;

  /// The user has set the order; false while the planner picks it.
  final bool custom;

  /// How much longer a custom order is than the shortest, when worth a
  /// warning; 0 otherwise.
  final double extraMeters;
  final ValueChanged<String> onRemove;
  final ValueChanged<List<MapPlace>> onReorder;
  final VoidCallback onAutoOrder;

  @override
  State<TripStopsList> createState() => _TripStopsListState();
}

class _TripStopsListState extends State<TripStopsList> {
  bool _editing = false;

  void _move(int from, int to) {
    final next = List.of(widget.stops);
    next.insert(to, next.removeAt(from));
    widget.onReorder(next);
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.stops;
    final editing = _editing && stops.isNotEmpty;
    final canReorder = stops.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Stops', style: AppTypeScale.sectionTitle),
            const SizedBox(width: 8),
            Text(
              '${stops.length} of ${TripStopOrder.maxStops}',
              style: AppTypeScale.small,
            ),
            const Spacer(),
            if (stops.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _editing = !_editing),
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, 44),
                  foregroundColor: AppColors.accent,
                ),
                child: Text(
                  editing ? 'Done' : 'Edit order',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        if (stops.isEmpty)
          Text(
            'Straight to ${widget.destinationName}. Add a place below to '
            'turn it into a bigger trip.',
            style: AppTypeScale.body,
          )
        else if (editing)
          TripStopsRows(
            stops: stops,
            destinationName: widget.destinationName,
            destLat: widget.destLat,
            destLng: widget.destLng,
            onMove: _move,
            onRemove: widget.onRemove,
          )
        else
          TripStopsChips(stops: stops, destinationName: widget.destinationName),
        if (editing && !widget.custom && canReorder)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Auto order (shortest). Use the arrows to change it.',
              style: AppTypeScale.small,
            ),
          ),
        if (widget.custom && canReorder && widget.extraMeters > 0)
          _LongerNote(
            extraMeters: widget.extraMeters,
            onUseShortest: widget.onAutoOrder,
          ),
      ],
    );
  }
}

/// "Your order is about 40 km longer than the shortest one", with the way
/// back to the shortest.
class _LongerNote extends StatelessWidget {
  const _LongerNote({required this.extraMeters, required this.onUseShortest});

  final double extraMeters;
  final VoidCallback onUseShortest;

  @override
  Widget build(BuildContext context) {
    final km = (extraMeters / 1000).round();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Your order is about '),
                TextSpan(
                  text: '$km km',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' longer than the shortest one.'),
              ],
            ),
            style: AppTypeScale.body.copyWith(color: AppColors.warningText),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onUseShortest,
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 44),
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.accent,
              ),
              child: const Text(
                'Use shortest',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
