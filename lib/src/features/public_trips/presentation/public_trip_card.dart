import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/public_trip_view.dart';
import 'public_trip_format.dart';
import 'public_trip_route_preview.dart';

/// A public trip as a card, in the look of the Share Card: the route behind,
/// a date pill with the transport icon on top, and the county count, names
/// and distance over a dark fade at the bottom.
class PublicTripCard extends StatelessWidget {
  const PublicTripCard({super.key, required this.trip, required this.onTap});

  final PublicTripView trip;
  final VoidCallback onTap;

  static const width = 236.0;
  static const height = 184.0;

  @override
  Widget build(BuildContext context) {
    final counties = publicTripCountyNames(trip);
    return Semantics(
      button: true,
      label: '${trip.title}, ${publicTripCountyCountLabel(trip)}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PublicTripRoutePreview(
                  lines: trip.routeLines,
                  moments: const [],
                  height: height,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC000000)],
                      stops: [0.35, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: PublicTripDatePill(trip: trip),
                ),
                if (trip.unclaimedCounties > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _NewPill(count: trip.unclaimedCounties),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        publicTripCountyCountLabel(trip),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      if (counties.isNotEmpty)
                        Text(
                          counties,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _small,
                        ),
                      Text(
                        '${publicTripDistanceLabel(trip.distanceMeters)}'
                        '  ·  ${trip.author.displayName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _small = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0xE6FFFFFF),
    height: 1.35,
  );
}

/// The translucent date pill with the transport icon.
class PublicTripDatePill extends StatelessWidget {
  const PublicTripDatePill({super.key, required this.trip});

  final PublicTripView trip;

  @override
  Widget build(BuildContext context) {
    final date = publicTripDateLabel(trip.tripDate);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(publicTripModeIcon(trip), size: 14, color: Colors.white),
            if (date.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewPill extends StatelessWidget {
  const _NewPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          count == 1 ? '1 new for you' : '$count new for you',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
