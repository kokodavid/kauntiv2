import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_actions_menu.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/journey_route.dart' show JourneyFormat;
import '../domain/journey_summary.dart';
import 'journey_card.dart' show JourneyRoutePreview;
import 'journey_transport_mode_ui.dart';
import 'journey_trip_actions.dart';

/// One past Trip in the list: a full-width route-preview photo (the
/// leading county's code top-right, duration/distance pill bottom-left,
/// an "On this phone" badge top-left while waiting to upload), with the
/// title, start time and the counties crossed below it - styled like a
/// small stack of photos in a folder, peeking out behind the card.
class JourneyTripTile extends StatelessWidget {
  const JourneyTripTile({super.key, required this.journey, this.onOpen});

  final JourneySummary journey;
  final VoidCallback? onOpen;

  static const _photoHeight = 168.0;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static final _codeByName = {
    for (final county in CountyPaths.all) county.name: county.code,
  };

  @override
  Widget build(BuildContext context) {
    final started = journey.startedAt.toLocal();
    final date =
        '${_weekdays[started.weekday - 1]} ${started.day} '
        '${_months[started.month - 1]} · '
        '${TimeOfDay.fromDateTime(started).format(context)}';
    final facts = [
      JourneyFormat.duration(journey.duration),
      if (journey.isUploaded) JourneyFormat.distance(journey.distanceMeters),
    ].join(' · ');
    // The pill badges the route's destination county - the last one
    // crossed - matching the chain text read left to right below.
    final primaryCounty = journey.countyNames.isEmpty
        ? null
        : journey.countyNames.last;
    final primaryCode = primaryCounty == null
        ? null
        : _codeByName[primaryCounty];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The folder-stack depth: two tinted layers peeking from behind
        // the card's bottom edge, so a list of past Trips reads like a
        // stack of photos rather than a flat list.
        const Positioned(
          left: 22,
          right: 6,
          bottom: -6,
          child: _StackPeek(color: AppColors.trackInactive),
        ),
        const Positioned(
          left: 12,
          right: 2,
          bottom: -3,
          child: _StackPeek(color: AppColors.lockedFill),
        ),
        _Card(
          journey: journey,
          facts: facts,
          date: date,
          primaryCounty: primaryCounty,
          primaryCode: primaryCode,
          onOpen: onOpen,
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.journey,
    required this.facts,
    required this.date,
    required this.primaryCounty,
    required this.primaryCode,
    this.onOpen,
  });

  final JourneySummary journey;
  final String facts;
  final String date;
  final String? primaryCounty;
  final int? primaryCode;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final code = primaryCode;
    final county = primaryCounty;
    final mode = journey.transportMode;
    return Consumer(
      builder: (context, ref, _) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: JourneyTripTile._photoHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    JourneyRoutePreview(journeyId: journey.id),
                    if (code != null && county != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _CountyPill(code: code, name: county),
                      ),
                    if (!journey.isUploaded)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _OnThisPhoneBadge(
                          label: journey.blockedByTrialLimit
                              ? 'Free limit reached'
                              : 'On this phone',
                        ),
                      ),
                    Positioned(left: 10, bottom: 10, child: _FactsPill(facts: facts)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 6, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            journey.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypeScale.cardTitle,
                          ),
                        ),
                        AppActionsMenuButton(
                          tooltip: 'Trip options',
                          actions: [
                            AppMenuAction(
                              label: 'Rename',
                              icon: Icons.edit_outlined,
                              onTap: () =>
                                  renameJourneyTrip(context, ref, journey),
                            ),
                            AppMenuAction(
                              label: 'Delete',
                              icon: Icons.delete_outline,
                              isDestructive: true,
                              onTap: () =>
                                  deleteJourneyTrip(context, ref, journey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (mode != null) ...[
                          Icon(
                            journeyTransportModeIcon(mode),
                            size: 13,
                            color: AppColors.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypeScale.small,
                          ),
                        ),
                      ],
                    ),
                    if (journey.countyNames.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        journey.countyNames.join(' → '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.small.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin tinted layer peeking out behind the card's bottom edge,
/// suggesting another photo underneath it in the stack.
class _StackPeek extends StatelessWidget {
  const _StackPeek({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
    );
  }
}

/// The dark "047·NAIROBI" county-code pill, matching the one the Home
/// map uses for its own county label.
class _CountyPill extends StatelessWidget {
  const _CountyPill({required this.code, required this.name});

  final int code;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mapOverlayBackground,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          '${code.toString().padLeft(3, '0')}·${name.toUpperCase()}',
          style: AppTextStyles.mapCountyLabel,
        ),
      ),
    );
  }
}

/// Flags a Trip still waiting to upload (or blocked by the free-plan
/// limit) - the same warm, pending-state colours as elsewhere in the app.
class _OnThisPhoneBadge extends StatelessWidget {
  const _OnThisPhoneBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.explorePromotionFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.pendingFill,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypeScale.meta.copyWith(
              color: AppColors.explorePromotionText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactsPill extends StatelessWidget {
  const _FactsPill({required this.facts});

  final String facts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        facts,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypeScale.meta.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
