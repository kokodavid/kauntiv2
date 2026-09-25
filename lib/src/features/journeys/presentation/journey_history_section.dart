import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/journey_history.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';

/// Opens a past Journey; supplied by `app/` (the `/journey/:id` route).
typedef OpenJourney = void Function(BuildContext context, String id);

/// Past Journeys, newest first: those still on this phone (waiting to
/// upload) and the private cloud history. Available with or without Pro.
class JourneyHistorySection extends ConsumerWidget {
  const JourneyHistorySection({super.key, this.onOpen});

  final OpenJourney? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(journeyHistoryListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Past Journeys', style: AppTypeScale.sectionTitle),
        const SizedBox(height: 8),
        switch (history) {
          AsyncValue(:final value?) => _List(history: value, onOpen: onOpen),
          AsyncValue(hasError: true) => _Retry(
            onRetry: () => ref.invalidate(journeyHistoryListProvider),
          ),
          _ => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        },
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.history, this.onOpen});

  final JourneyHistory history;
  final OpenJourney? onOpen;

  @override
  Widget build(BuildContext context) {
    final open = onOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (history.cloudUnavailable)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              "You're offline: showing Journeys on this phone only.",
              style: AppTypeScale.small,
            ),
          ),
        if (history.journeys.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No Journeys yet. Start one to see your route here.',
              style: AppTypeScale.body,
            ),
          ),
        for (final (i, journey) in history.journeys.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.listDivider),
          _Row(
            journey: journey,
            onTap: open == null ? null : () => open(context, journey.id),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.journey, this.onTap});

  final JourneySummary journey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final local = journey.startedAt.toLocal();
    final date = JourneyTitles.defaultFor(
      local,
    ).replaceFirst('Journey on ', '');
    final details = [
      date,
      JourneyFormat.duration(journey.duration),
      if (journey.isUploaded) JourneyFormat.distance(journey.distanceMeters),
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.route_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journey.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.itemTitle,
                  ),
                  Text(details, style: AppTypeScale.small),
                  if (!journey.isUploaded)
                    Text(
                      'Waiting to upload',
                      style: AppTypeScale.meta.copyWith(
                        color: AppColors.pendingFill,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text("Couldn't load your Journeys.", style: AppTypeScale.body),
        ),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
