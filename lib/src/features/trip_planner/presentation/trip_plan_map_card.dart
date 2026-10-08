import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../domain/trip_plan.dart';
import '../domain/trip_plan_snapshot.dart';
import '../domain/trip_route.dart';
import 'trip_plan_map.dart';

/// The Plan trip route map, its map states, and the full-screen control.
class TripPlanMapCard extends StatefulWidget {
  const TripPlanMapCard({
    super.key,
    required this.snapshot,
    required this.destination,
    required this.onExpand,
    required this.onTurnOnLocation,
    required this.onRetry,
  });

  final TripPlanSnapshot snapshot;
  final TripRoutePoint destination;
  final Future<void> Function() onExpand;
  final VoidCallback onTurnOnLocation;
  final VoidCallback onRetry;

  @override
  State<TripPlanMapCard> createState() => _TripPlanMapCardState();
}

class _TripPlanMapCardState extends State<TripPlanMapCard> {
  var _releasingMap = false;

  Future<void> _openExpandedMap() async {
    if (_releasingMap) return;
    setState(() => _releasingMap = true);

    // Remove the inline platform view before creating the route page's map.
    // Two frames give Android's platform-view controller time to release it.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    try {
      await widget.onExpand();
    } finally {
      // The route page also needs a brief disposal window before this card
      // restores its own Mapbox view after the user presses Back.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (mounted) setState(() => _releasingMap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final destination = widget.destination;
    final status = snapshot.status;
    final plan = snapshot.plan;
    final origin = snapshot.origin;
    final List<TripRoutePoint> points;
    var dashed = false;
    switch (status) {
      case TripPlanStatus.ready:
        points = plan!.route.points;
      case TripPlanStatus.noRoute when origin != null:
        points = [origin, destination];
        dashed = true;
      case TripPlanStatus.planning:
      case TripPlanStatus.noLocation:
      case TripPlanStatus.noRoute:
        points = [destination];
    }
    final stops = plan == null || status != TripPlanStatus.ready
        ? const <TripRoutePoint>[]
        : [for (final s in plan.stops) TripRoutePoint(s.lat, s.lng)];
    final ready = status == TripPlanStatus.ready && points.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: TripPlanMap.defaultHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (status == TripPlanStatus.planning)
                const ColoredBox(
                  color: AppColors.lockedFill,
                  child: Center(
                    child: AppProgressIndicator(
                      color: AppColors.accent,
                      radius: 12,
                    ),
                  ),
                )
              else if (_releasingMap)
                const ColoredBox(
                  color: AppColors.lockedFill,
                  child: Center(
                    child: AppProgressIndicator(
                      color: AppColors.accent,
                      radius: 12,
                    ),
                  ),
                )
              else
                TripPlanMap(
                  points: points,
                  stops: stops,
                  dashed: dashed,
                  rounded: false,
                  height: null,
                ),
              if (snapshot.updating)
                const ColoredBox(color: Color(0x99FFFFFF)),
              if (snapshot.updating)
                const Positioned(left: 10, top: 10, child: _UpdatingPill()),
              if (ready)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: SizedBox.square(
                      dimension: 44,
                      child: IconButton(
                        tooltip: 'Open the map full screen',
                        icon: const Icon(Icons.open_in_full, size: 20),
                        onPressed: _releasingMap ? null : _openExpandedMap,
                      ),
                    ),
                  ),
                ),
              if (ready)
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: _StatsPill(plan: plan!),
                ),
            ],
          ),
        ),
        if (status == TripPlanStatus.noLocation)
          _Note(
            title: 'Location is off',
            body: 'Turn it on to plan the road from where you are.',
            action: 'Turn on',
            onAction: widget.onTurnOnLocation,
          ),
        if (status == TripPlanStatus.noRoute)
          _Note(
            title: "Can't load the road",
            body: snapshot.straightLabel == null
                ? 'You can still start the trip or open directions.'
                : 'About ${snapshot.straightLabel} in a straight line.',
            action: 'Try again',
            onAction: widget.onRetry,
          ),
      ],
    );
  }
}

class _UpdatingPill extends StatelessWidget {
  const _UpdatingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppProgressIndicator(color: AppColors.accent, radius: 7),
          SizedBox(width: 8),
          Text('Updating route…', style: AppTypeScale.small),
        ],
      ),
    );
  }
}

class _StatsPill extends StatelessWidget {
  const _StatsPill({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Stat(value: plan.route.distanceLabel, label: 'DISTANCE'),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.cardBorder,
          ),
          _Stat(value: plan.route.durationLabel, label: 'BY ROAD'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypeScale.sectionTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        Text(label, style: AppTypeScale.sectionLabel),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypeScale.itemTitle),
                Text(body, style: AppTypeScale.small),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(64, 44),
              foregroundColor: AppColors.accent,
            ),
            child: Text(
              action,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
