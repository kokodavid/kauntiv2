part of 'journey_card.dart';

/// Fades in the route's static map over a neutral fill when it loads.
/// Public (though this file is a `part of`) so other Trip-card styles -
/// the grouped carousel tiles - can reuse the same Mapbox static preview
/// instead of re-fetching the route themselves.
class JourneyRoutePreview extends ConsumerWidget {
  const JourneyRoutePreview({super.key, required this.journeyId});

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
