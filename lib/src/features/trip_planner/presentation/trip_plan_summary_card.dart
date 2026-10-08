import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/map_place.dart';
import '../../../core/widgets/county_badge_medallion.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/trip_plan.dart';
import 'trip_stop_dot.dart';
import 'trip_stops_chips.dart';

/// The full-screen map's card: distance and time, the stops as chips that
/// select a pin, the counties the road passes through, and Start trip.
/// Collapsed it is one line and a compact Start trip button.
class TripPlanSummaryCard extends StatelessWidget {
  const TripPlanSummaryCard({
    super.key,
    required this.plan,
    required this.destinationName,
    required this.claimed,
    required this.collapsed,
    required this.onToggle,
    required this.selected,
    required this.onSelect,
    required this.startButton,
  });

  final TripPlan plan;
  final String destinationName;
  final Set<int> claimed;
  final bool collapsed;
  final VoidCallback onToggle;

  /// Marker index selected on the map (0 you, 1..n stops, n+1 the place).
  final int? selected;
  final ValueChanged<int> onSelect;

  /// The Start trip button, built for this card's size.
  final Widget startButton;

  @override
  Widget build(BuildContext context) {
    final counties = [
      for (final code in plan.countyCodes)
        if (CountyPaths.byCode[code] != null) CountyPaths.byCode[code]!,
    ];
    final stops = plan.stops;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Grip(collapsed: collapsed, onToggle: onToggle),
          if (collapsed)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${plan.route.distanceLabel} · '
                        '${plan.route.durationLabel}',
                        style: AppTypeScale.sectionTitle,
                      ),
                      Text(
                        '${_stopsLabel(stops.length)} · '
                        '${counties.length} '
                        '${counties.length == 1 ? 'county' : 'counties'}',
                        style: AppTypeScale.small,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                startButton,
              ],
            )
          else ...[
            Row(
              children: [
                _Stat(value: plan.route.distanceLabel, label: 'DISTANCE'),
                _Stat(value: plan.route.durationLabel, label: 'BY ROAD'),
                _Stat(value: '${stops.length}', label: 'STOPS'),
              ],
            ),
            const SizedBox(height: 12),
            _Strip(
              stops: stops,
              destinationName: destinationName,
              selected: selected,
              onSelect: onSelect,
            ),
            if (counties.isNotEmpty) ...[
              const SizedBox(height: 14),
              _Counties(counties: counties, claimed: claimed),
            ],
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: startButton),
          ],
        ],
      ),
    );
  }

  static String _stopsLabel(int n) =>
      n == 0 ? 'No stops' : '$n ${n == 1 ? 'stop' : 'stops'}';
}

class _Grip extends StatelessWidget {
  const _Grip({required this.collapsed, required this.onToggle});

  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: collapsed ? 'Show trip details' : 'Hide trip details',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        onVerticalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if ((v > 0 && !collapsed) || (v < 0 && collapsed)) onToggle();
        },
        child: SizedBox(
          height: 28,
          width: double.infinity,
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lockedStroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypeScale.sectionTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: AppTypeScale.sectionLabel),
        ],
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({
    required this.stops,
    required this.destinationName,
    required this.selected,
    required this.onSelect,
  });

  final List<MapPlace> stops;
  final String destinationName;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          TripStopChip(
            dot: const TripStopDot.start(size: 24),
            label: 'You',
            selected: selected == 0,
            onTap: () => onSelect(0),
            maxWidth: 130,
          ),
          for (final (i, stop) in stops.indexed) ...[
            const SizedBox(width: 8),
            TripStopChip(
              dot: TripStopDot.stop(i + 1, size: 24),
              label: stop.name,
              selected: selected == i + 1,
              onTap: () => onSelect(i + 1),
              maxWidth: 130,
            ),
          ],
          const SizedBox(width: 8),
          TripStopChip(
            dot: const TripStopDot.end(size: 24),
            label: destinationName,
            selected: selected == stops.length + 1,
            onTap: () => onSelect(stops.length + 1),
            maxWidth: 130,
          ),
        ],
      ),
    );
  }
}

class _Counties extends StatelessWidget {
  const _Counties({required this.counties, required this.claimed});

  final List<CountyPath> counties;
  final Set<int> claimed;

  static const _shown = 6;
  static const _size = 30.0;
  static const _step = 22.0;

  @override
  Widget build(BuildContext context) {
    final unclaimed = counties.where((c) => !claimed.contains(c.code)).length;
    final shown = counties.take(_shown).toList();
    return Row(
      children: [
        SizedBox(
          width: _size + _step * (shown.length - 1),
          height: _size,
          child: Stack(
            children: [
              for (final (i, county) in shown.indexed)
                Positioned(
                  left: i * _step,
                  child: CountyBadgeMedallion(
                    county: county,
                    earned: claimed.contains(county.code),
                    size: _size,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Passes through ${counties.length} '
            '${counties.length == 1 ? 'county' : 'counties'}'
            '${unclaimed == 0 ? '' : ', $unclaimed not claimed yet'}. '
            'A county counts once your Trip records you in it.',
            style: AppTypeScale.small,
          ),
        ),
      ],
    );
  }
}
