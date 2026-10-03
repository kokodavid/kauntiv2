part of 'journey_recording_controls.dart';

/// Resolves the latest route point with bundled boundaries, including offline.
String? journeyCountyNameForRoute(JourneyRoute route) {
  final last = route.lastPoint;
  if (last == null) return null;
  final code = CountyBoundaryResolver.countyCodeFor(
    latitude: last.latitude,
    longitude: last.longitude,
  );
  if (code == null) return null;
  for (final county in CountyPaths.all) {
    if (county.code == code) return county.name;
  }
  return null;
}

/// A small tinted circle button for Photo, Pause/Resume or Stop.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 52,
    child: IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground.withValues(alpha: 0.4),
      ),
      icon: Icon(icon, size: 24),
    ),
  );
}

class _TripDetailsToggle extends StatelessWidget {
  const _TripDetailsToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const StadiumBorder(side: BorderSide(color: AppColors.cardBorder)),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trip details',
              style: AppTypeScale.itemTitle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.foreground,
            ),
          ],
        ),
      ),
    ),
  );
}

class _TripDetailsPanel extends StatelessWidget {
  const _TripDetailsPanel({required this.startedAt, required this.route});

  final DateTime? startedAt;
  final JourneyRoute route;

  @override
  Widget build(BuildContext context) {
    final started = startedAt;
    final title = started == null
        ? 'This Trip'
        : JourneyTitles.defaultFor(started.toLocal());
    final counties = _countiesSoFar(route);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypeScale.cardTitle),
          const SizedBox(height: 14),
          const Text('COUNTIES SO FAR', style: AppTypeScale.sectionLabel),
          const SizedBox(height: 8),
          if (counties.isEmpty)
            const Text('Waiting for your location…', style: AppTypeScale.small)
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: [
                for (var i = 0; i < counties.length; i++) ...[
                  if (i != 0)
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColors.mutedForeground,
                    ),
                  _CountyChip(
                    name: counties[i],
                    isLatest: i == counties.length - 1,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  static List<String> _countiesSoFar(JourneyRoute route) {
    if (route.isEmpty) return const [];
    final names = {
      for (final county in CountyPaths.all) county.code: county.name,
    };
    final result = <String>[];
    int? last;
    for (final segment in JourneyPreview.thin(route)) {
      for (final point in segment) {
        final previous = last;
        final priorCode = previous == null
            ? null
            : CountyBoundaryResolver.countyCodeFor(
                latitude: point.latitude,
                longitude: point.longitude,
                countyCodes: [previous],
                minimumInsideDistanceMeters:
                    CountyBoundaryResolver.boundaryHysteresisMeters,
              );
        final code = priorCode == previous
            ? previous
            : CountyBoundaryResolver.countyCodeFor(
                latitude: point.latitude,
                longitude: point.longitude,
                minimumInsideDistanceMeters:
                    CountyBoundaryResolver.boundaryHysteresisMeters,
              );
        if (code == null) continue;
        last = code;
        final name = names[code];
        if (name != null && (result.isEmpty || result.last != name)) {
          result.add(name);
        }
      }
    }
    return result;
  }
}

class _CountyChip extends StatelessWidget {
  const _CountyChip({required this.name, required this.isLatest});

  final String name;
  final bool isLatest;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: isLatest ? AppColors.accent : AppColors.lockedFill,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      name,
      style: AppTypeScale.meta.copyWith(
        color: isLatest ? Colors.white : AppColors.foreground,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
