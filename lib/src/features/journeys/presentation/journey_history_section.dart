import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/journey_history.dart';
import '../domain/journey_summary.dart';
import 'journey_card.dart';
import 'journey_card_skeleton.dart';
import 'journey_history_empty_states.dart';
import 'journey_history_filters.dart';
import 'journey_rename_dialog.dart';

/// Opens a past Journey; supplied by `app/` (the `/journey/:id` route).
typedef OpenJourney = void Function(BuildContext context, String id);

/// Past Journeys, newest first: those still on this phone (waiting to
/// upload) and the private cloud history, grouped by month so the list
/// reads like a travelogue rather than a flat log. Tap one to replay it;
/// delete it here. Available with or without Pro.
class JourneyHistorySection extends ConsumerStatefulWidget {
  const JourneyHistorySection({super.key, this.onOpen});

  final OpenJourney? onOpen;

  @override
  ConsumerState<JourneyHistorySection> createState() =>
      _JourneyHistorySectionState();
}

class _JourneyHistorySectionState extends ConsumerState<JourneyHistorySection> {
  static const _searchThreshold = 8;

  String _query = '';
  final _queryController = TextEditingController();
  JourneyDateFilter _dateFilter = JourneyDateFilter.all;

  void _clearFilters() => setState(() {
    _queryController.clear();
    _query = '';
    _dateFilter = JourneyDateFilter.all;
  });

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  bool _matches(JourneySummary journey) {
    if (_dateFilter != JourneyDateFilter.all) {
      final label = JourneyTitles.monthLabel(journey.startedAt);
      final wanted = _dateFilter == JourneyDateFilter.thisMonth
          ? 'This month'
          : 'Last month';
      if (label != wanted) return false;
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    if (journey.title.toLowerCase().contains(query)) return true;
    final destination = journey.destination?.name;
    if (destination != null && destination.toLowerCase().contains(query)) {
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
        const SizedBox(height: 8),
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

  Widget _buildList(JourneyHistory history) {
    final all = history.journeys;
    final showSearch = all.length > _searchThreshold;
    final journeys = showSearch
        ? [
            for (final journey in all)
              if (_matches(journey)) journey,
          ]
        : all;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSearch) ...[
          JourneyHistorySearchField(
            controller: _queryController,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          JourneyHistoryDateFilters(
            selected: _dateFilter,
            onSelected: (filter) => setState(() => _dateFilter = filter),
          ),
          const SizedBox(height: 12),
        ],
        if (all.isNotEmpty && journeys.isEmpty)
          JourneyHistoryNoMatches(query: _query, onClear: _clearFilters)
        else
          _List(
            journeys: journeys,
            cloudUnavailable: history.cloudUnavailable,
            onOpen: widget.onOpen,
          ),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.journeys,
    required this.cloudUnavailable,
    this.onOpen,
  });

  final List<JourneySummary> journeys;
  final bool cloudUnavailable;
  final OpenJourney? onOpen;

  @override
  Widget build(BuildContext context) {
    final open = onOpen;
    final children = <Widget>[
      if (cloudUnavailable)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            "You're offline: showing Trips on this phone only.",
            style: AppTypeScale.small,
          ),
        ),
      if (journeys.isEmpty) const JourneyHistoryEmptyState(),
    ];

    String? lastLabel;
    for (final journey in journeys) {
      final label = JourneyTitles.monthLabel(journey.startedAt);
      if (label != lastLabel) {
        if (lastLabel != null) children.add(const SizedBox(height: 28));
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(label.toUpperCase(), style: AppTypeScale.sectionLabel),
          ),
        );
        lastLabel = label;
      } else {
        children.add(const SizedBox(height: 22));
      }
      children.add(
        _Row(
          journey: journey,
          onTap: open == null ? null : () => open(context, journey.id),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.journey, this.onTap});

  final JourneySummary journey;
  final VoidCallback? onTap;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final title = await showJourneyRenameDialog(context, journey.title);
    if (title == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(journeyHistoryListProvider.notifier)
          .rename(journey, title);
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't rename it. Try again.")),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this Trip?'),
        content: Text(
          journey.isUploaded
              ? "'${journey.title}' is removed from your account and this "
                    "phone. This can't be undone."
              : "'${journey.title}' hasn't uploaded yet, so it's removed "
                    "from this phone for good. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(journeyHistoryListProvider.notifier).delete(journey);
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't delete it. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => JourneyCard(
    journey: journey,
    onOpen: onTap,
    onRename: () => _rename(context, ref),
    onDelete: () => _delete(context, ref),
  );
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
