import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/journey_history.dart';
import '../application/journey_views.dart';
import '../domain/journey_route.dart';
import 'journey_route_map.dart';

/// One past Journey: its whole route on the map with Replay (full screen),
/// the summary, and delete. Viewable with or without Pro.
class JourneyDetailScreen extends ConsumerWidget {
  const JourneyDetailScreen({
    super.key,
    required this.journeyId,
    this.onReplay,
  });

  final String journeyId;

  /// Opens the full-screen replay; null hides Replay.
  final void Function(BuildContext context)? onReplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(journeyDetailProvider(journeyId));
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: switch (detail) {
        AsyncValue(:final value?) => _Body(detail: value, onReplay: onReplay),
        AsyncValue(:final error?) => _Message(
          text: error is JourneyNotFound
              ? 'This Journey was deleted.'
              : "Couldn't load this Journey. Check your connection.",
          onRetry: error is JourneyNotFound
              ? null
              : () => ref.invalidate(journeyDetailProvider(journeyId)),
        ),
        _ => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      },
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.detail, required this.onReplay});

  final JourneyDetail detail;
  final void Function(BuildContext context)? onReplay;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this Journey?'),
        content: const Text(
          'The route is removed from your account and this phone. This '
          "can't be undone.",
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
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(journeyHistoryListProvider.notifier)
          .delete(widget.detail.summary);
      if (mounted) Navigator.of(context).maybePop();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't delete it. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.detail.summary;
    final route = widget.detail.route;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (route.isEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: const SizedBox(
              height: 320,
              child: ColoredBox(
                color: AppColors.lockedFill,
                child: Center(
                  child: Text(
                    'No route points were recorded.',
                    style: AppTypeScale.small,
                  ),
                ),
              ),
            ),
          )
        else
          _RoutePreview(
            route: route,
            onReplay: route.pointCount > 1 ? widget.onReplay : null,
          ),
        const SizedBox(height: 16),
        Text(summary.title, style: AppTextStyles.headingForeground),
        if (!summary.isUploaded)
          Text(
            'On this phone, waiting to upload to your account.',
            style: AppTypeScale.small.copyWith(color: AppColors.pendingFill),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Fact(
              label: 'Distance',
              value: JourneyFormat.distance(
                summary.distanceMeters ?? route.distanceMeters,
              ),
            ),
            _Fact(
              label: 'Duration',
              value: JourneyFormat.duration(summary.duration),
            ),
            _Fact(
              label: 'Started',
              value: TimeOfDay.fromDateTime(
                summary.startedAt.toLocal(),
              ).format(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _delete,
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Delete Journey'),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypeScale.statValue),
          Text(label, style: AppTypeScale.statLabel),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: AppTypeScale.body),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// The whole route, start and end pinned, with Replay over its corner.
class _RoutePreview extends StatelessWidget {
  const _RoutePreview({required this.route, required this.onReplay});

  final JourneyRoute route;
  final void Function(BuildContext context)? onReplay;

  @override
  Widget build(BuildContext context) {
    final first = route.segments.first.first;
    final last = route.segments.last.last;
    final replay = onReplay;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 360,
        child: Stack(
          children: [
            Positioned.fill(
              child: JourneyRouteMap(
                route: route,
                start: (latitude: first.latitude, longitude: first.longitude),
                end: (latitude: last.latitude, longitude: last.longitude),
              ),
            ),
            if (replay != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: FilledButton.icon(
                  onPressed: () => replay(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentForeground,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Replay'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
