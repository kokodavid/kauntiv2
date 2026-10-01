part of 'journey_card.dart';

/// Duration/distance on the photo, in a small translucent pill.
class _FactsPill extends StatelessWidget {
  const _FactsPill({required this.facts});

  final String facts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.route_rounded,
            size: 13,
            color: AppColors.heroSubheadingText,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              facts,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypeScale.photoCaption,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades in the route's static map over a neutral fill when it loads.
class _RoutePreview extends ConsumerWidget {
  const _RoutePreview({required this.journeyId});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const fill = ColoredBox(
      color: AppColors.lockedFill,
      child: Center(
        child: Icon(
          Icons.route_rounded,
          size: 40,
          color: AppColors.lockedStroke,
        ),
      ),
    );
    final token = ref.watch(appConfigProvider).mapboxAccessToken;
    if (token.isEmpty) return fill;
    final route = ref.watch(journeyDetailProvider(journeyId)).value?.route;
    if (route == null || route.isEmpty) return fill;
    return LayoutBuilder(
      builder: (context, constraints) {
        final url = JourneyStaticMap.url(
          route,
          token: token,
          width: (constraints.maxWidth / 40).ceil() * 40,
          height: constraints.maxHeight.round(),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            fill,
            Image.network(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
