import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/journey_history.dart';
import '../application/journey_views.dart';
import '../domain/journey_point.dart';
import '../domain/journey_route.dart';
import 'journey_route_map.dart';

/// One past Journey: its route on the map with a replay, the summary, and
/// delete. Viewable with or without Pro.
class JourneyDetailScreen extends ConsumerWidget {
  const JourneyDetailScreen({super.key, required this.journeyId});

  final String journeyId;

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
        AsyncValue(:final value?) => _Body(detail: value),
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
  const _Body({required this.detail});

  final JourneyDetail detail;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  /// About 10 s to replay any route, drawn at 20 frames a second.
  static const _frame = Duration(milliseconds: 50);
  static const _frames = 200;

  late final List<JourneyPoint> _points = [
    for (final segment in widget.detail.route.segments) ...segment,
  ];
  Timer? _replay;
  int? _index;

  @override
  void dispose() {
    _replay?.cancel();
    super.dispose();
  }

  void _toggleReplay() {
    if (_replay != null) {
      _replay!.cancel();
      // Back to the whole route.
      setState(() {
        _replay = null;
        _index = null;
      });
      return;
    }
    final step = (_points.length / _frames).ceil().clamp(1, _points.length);
    var index = 0;
    setState(() => _index = 0);
    _replay = Timer.periodic(_frame, (timer) {
      index += step;
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index >= _points.length) {
        timer.cancel();
        setState(() {
          _replay = null;
          _index = null;
        });
        return;
      }
      setState(() => _index = index);
    });
  }

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
    final index = _index;
    JourneyLatLng at(JourneyPoint p) =>
        (latitude: p.latitude, longitude: p.longitude);
    // Replay draws the route from the start as it goes, with the camera
    // following the marker; otherwise the whole route with start and end.
    final shown = index == null
        ? route
        : JourneyRoute(_points.sublist(0, index + 1));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 320,
            child: route.isEmpty
                ? const ColoredBox(
                    color: AppColors.lockedFill,
                    child: Center(
                      child: Text(
                        'No route points were recorded.',
                        style: AppTypeScale.small,
                      ),
                    ),
                  )
                : JourneyRouteMap(
                    route: shown,
                    start: at(_points.first),
                    end: index == null ? at(_points.last) : null,
                    marker: index == null ? null : at(_points[index]),
                    follow: index != null,
                    animateFollow: false,
                  ),
          ),
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
        if (_points.length > 1)
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _toggleReplay,
              icon: Icon(_replay == null ? Icons.play_arrow : Icons.stop),
              label: Text(
                _replay == null ? 'Replay route' : 'Stop replay',
                style: AppTextStyles.buttonLabel,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
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
