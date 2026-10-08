import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../application/journey_history.dart';
import '../domain/journey_grouping.dart';
import '../domain/journey_route.dart' show JourneyFormat;
import '../domain/journey_summary.dart';
import 'journey_card_skeleton.dart';
import 'journey_history_empty_states.dart';
import 'journey_history_filters.dart';
import 'journey_trip_group_section.dart';

/// Opens a past Journey; supplied by `app/` (the `/journey/:id` route).
typedef OpenJourney = void Function(BuildContext context, String id);

/// Past Journeys, newest first: those still on this phone (waiting to
/// upload) and the private cloud history, always grouped by month, with
/// one always-visible filter strip (county, date window, Trip length and
/// "on this phone") narrowing the whole list. Available with or without
/// Pro.
class JourneyHistorySection extends ConsumerStatefulWidget {
  const JourneyHistorySection({super.key, this.onOpen});

  final OpenJourney? onOpen;

  @override
  ConsumerState<JourneyHistorySection> createState() =>
      _JourneyHistorySectionState();
}

class _JourneyHistorySectionState extends ConsumerState<JourneyHistorySection> {
  String _query = '';
  final _queryController = TextEditingController();
  JourneyDateFilter _dateFilter = JourneyDateFilter.all;
  JourneyLengthBucket? _lengthFilter;
  Set<String> _countyFilter = const {};
  bool _onlyOnThisPhone = false;

  static final _codeByName = {
    for (final county in CountyPaths.all) county.name: county.code,
  };

  void _clearFilters() => setState(() {
    _queryController.clear();
    _query = '';
    _dateFilter = JourneyDateFilter.all;
    _lengthFilter = null;
    _countyFilter = const {};
    _onlyOnThisPhone = false;
  });

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  bool _matches(JourneySummary journey) {
    if (_onlyOnThisPhone && journey.isUploaded) return false;
    if (!_dateFilter.matches(journey.startedAt)) return false;
    if (_lengthFilter != null &&
        JourneyLengthBucket.of(journey.distanceMeters) != _lengthFilter) {
      return false;
    }
    if (_countyFilter.isNotEmpty &&
        !journey.countyNames.any(_countyFilter.contains)) {
      return false;
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    if (journey.title.toLowerCase().contains(query)) return true;
    final destination = journey.destination;
    if (destination != null &&
        [destination.name, for (final s in destination.viaStops) s.name]
            .any((name) => name.toLowerCase().contains(query))) {
      return true;
    }
    // Counties the route crossed (e.g. typing "kiambu" surfaces a Trip
    // that passed through it, even if it wasn't the destination). Empty
    // for a Trip still waiting to upload, so it just won't match here.
    return journey.countyNames.any(
      (name) => name.toLowerCase().contains(query),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(journeyHistoryListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Past Trips', style: AppTypeScale.sectionTitle),
        const SizedBox(height: 10),
        switch (history) {
          AsyncValue(:final value?) => _buildList(value),
          AsyncValue(hasError: true) => _Retry(
            onRetry: () => ref.invalidate(journeyHistoryListProvider),
          ),
          _ => const JourneyCardsLoading(),
        },
      ],
    );
  }

  /// Every county any (unfiltered) Trip crossed, with how many Trips
  /// crossed each one - most-visited first - for the county sheet. A
  /// county reached by several of the same Trip's segments still counts
  /// once per Trip, matching the "N trips" line the sheet shows for it.
  List<JourneyCountyOption> _countyOptions(List<JourneySummary> all) {
    final tripsByCounty = <String, int>{};
    for (final journey in all) {
      for (final name in journey.countyNames.toSet()) {
        tripsByCounty[name] = (tripsByCounty[name] ?? 0) + 1;
      }
    }
    final options = [
      for (final MapEntry(key: name, value: count) in tripsByCounty.entries)
        JourneyCountyOption(
          name: name,
          code: _codeByName[name] ?? 0,
          tripCount: count,
        ),
    ];
    options.sort((a, b) {
      final byCount = b.tripCount.compareTo(a.tripCount);
      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });
    return options;
  }

  /// How many of [all] crossed at least one of [counties] - the empty set
  /// means "every Trip" - used both for the always-visible count line and
  /// live on the county sheet's "Show N trips" button as rows are tapped.
  int _countyMatchCount(List<JourneySummary> all, Set<String> counties) {
    if (counties.isEmpty) return all.length;
    return all
        .where((journey) => journey.countyNames.any(counties.contains))
        .length;
  }

  Widget _buildList(JourneyHistory history) {
    final all = history.journeys;
    if (all.isEmpty) return const JourneyHistoryEmptyState();

    final hasLocal = all.any((journey) => !journey.isUploaded);
    final counties = _countyOptions(all);
    final journeys = [
      for (final journey in all)
        if (_matches(journey)) journey,
    ];
    final groups = JourneyGrouper.byMonth(journeys);
    final uploadedMeters = journeys.fold(
      0.0,
      (sum, journey) => sum + (journey.distanceMeters ?? 0),
    );
    final hasUploadedMatch = journeys.any((journey) => journey.isUploaded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JourneyHistorySearchField(
          controller: _queryController,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 10),
        JourneyHistoryFilterBar(
          counties: counties,
          countTripsFor: (selected) => _countyMatchCount(all, selected),
          selectedCounties: _countyFilter,
          onCountiesSelected: (selected) =>
              setState(() => _countyFilter = selected),
          dateFilter: _dateFilter,
          onDateSelected: (filter) => setState(() => _dateFilter = filter),
          lengthFilter: _lengthFilter,
          onLengthSelected: (bucket) => setState(() => _lengthFilter = bucket),
          onlyOnThisPhone: _onlyOnThisPhone,
          onToggleOnThisPhone: hasLocal
              ? () => setState(() => _onlyOnThisPhone = !_onlyOnThisPhone)
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          [
            journeys.length == 1 ? '1 trip' : '${journeys.length} trips',
            if (hasUploadedMatch) JourneyFormat.distance(uploadedMeters),
          ].join(' · '),
          style: AppTypeScale.small,
        ),
        const SizedBox(height: 16),
        if (history.cloudUnavailable)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              "You're offline: showing Trips on this phone only.",
              style: AppTypeScale.small,
            ),
          ),
        if (groups.isEmpty)
          JourneyHistoryNoMatches(query: _query, onClear: _clearFilters)
        else
          for (final group in groups) ...[
            if (group != groups.first) const SizedBox(height: 24),
            JourneyTripGroupSection(group: group, onOpen: widget.onOpen),
          ],
      ],
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
          child: Text("Couldn't load your Trips.", style: AppTypeScale.body),
        ),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
