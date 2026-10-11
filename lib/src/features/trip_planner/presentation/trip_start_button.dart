import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/map_place.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/trip_plan_view.dart';
import '../application/trip_planner_providers.dart';

/// The Start trip pill of Place Detail's bottom bar, and of the full-screen
/// map: "Start trip" over a line saying what the trip is ("2 stops ·
/// 279 km · 8 h 22 min"). It hands the stops, in driving order, to
/// [onStart]. With [compact] it is a one-line button for a collapsed card.
class TripStartButton extends ConsumerStatefulWidget {
  const TripStartButton({
    super.key,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.onStart,
    this.compact = false,
  });

  final String placeId;
  final double latitude;
  final double longitude;
  final Future<void> Function(BuildContext context, List<MapPlace> stops)
  onStart;
  final bool compact;

  @override
  ConsumerState<TripStartButton> createState() => _TripStartButtonState();
}

class _TripStartButtonState extends ConsumerState<TripStartButton> {
  bool _busy = false;

  /// The stops in driving order. Falls back to the order they were picked
  /// in when the route cannot be planned: the trip can still start.
  Future<List<MapPlace>> _orderedStops() async {
    final picked = ref.read(tripStopsProvider(widget.placeId));
    if (picked.isEmpty) return picked;
    try {
      final plan = await ref.read(
        tripPlanProvider(
          widget.latitude,
          widget.longitude,
          tripStopKey(
            picked,
            custom: ref.read(tripCustomOrderProvider(widget.placeId)),
          ),
        ).future,
      );
      return plan.stops;
    } on Object {
      return picked;
    }
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final stops = await _orderedStops();
      if (!mounted) return;
      await widget.onStart(context, stops);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't start the trip.")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref
        .watch(
          tripPlanViewProvider(
            widget.placeId,
            widget.latitude,
            widget.longitude,
          ),
        )
        .barSummary;
    return Semantics(
      button: true,
      label: 'Start trip. $summary',
      child: Material(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(widget.compact ? 22 : 28),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.compact ? 22 : 28),
          onTap: _busy ? null : () => unawaited(_start()),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.compact ? 44 : 56),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 18 : 22,
                vertical: 6,
              ),
              child: _busy
                  ? const Center(
                      child: AppProgressIndicator(
                        color: AppColors.accentForeground,
                        radius: 9,
                      ),
                    )
                  : widget.compact
                  ? const Align(widthFactor: 1, child: _Title())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Title(),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
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
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Start trip',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.accentForeground,
      ),
    );
  }
}
