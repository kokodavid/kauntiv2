part of 'journey_replay_controls.dart';

/// Reveal paused moments without shifting the sheet abruptly.
class _MomentsReveal extends StatelessWidget {
  const _MomentsReveal({
    required this.moments,
    required this.momentTime,
    this.onOpenPlace,
  });

  final List<JourneyMoment> moments;
  final DateTime? momentTime;
  final OpenJourneyPlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        reverseDuration: Duration.zero,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: moments.isEmpty
            ? const SizedBox(key: ValueKey('no-moments'))
            : Column(
                key: ValueKey(
                  'moments-${moments.map((m) => m.index).join('-')}',
                ),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 176),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final (index, moment) in moments.indexed)
                            _StaggeredReveal(
                              index: index,
                              child: JourneyMomentRow(
                                moment: moment,
                                time: momentTime,
                                onOpenPlace: onOpenPlace,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                ],
              ),
      ),
    );
  }
}

class _StaggeredReveal extends StatelessWidget {
  const _StaggeredReveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + index * 60),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Omits unknown speed/elevation stats, such as on a pending upload.
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.averageSpeedMps,
    required this.topSpeedMps,
    required this.highestElevationMeters,
  });

  final double? averageSpeedMps;
  final double? topSpeedMps;
  final double? highestElevationMeters;

  @override
  Widget build(BuildContext context) {
    final stats = [
      if (averageSpeedMps != null)
        (Icons.speed, 'Avg ${JourneyFormat.speed(averageSpeedMps)}'),
      if (topSpeedMps != null)
        (Icons.bolt, 'Top ${JourneyFormat.speed(topSpeedMps)}'),
      if (highestElevationMeters != null)
        (
          Icons.terrain,
          'Elev ${JourneyFormat.elevation(highestElevationMeters)}',
        ),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final (icon, label) in stats)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.trackInactive,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTypeScale.small.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
