part of 'trip_share_card.dart';

/// A short fade behind the top chip/watermark row, so they stay legible
/// even over a bright sky (Claude-Design reference: "A 50% top gradient
/// sits behind the watermark and chip").
class _TopScrim extends StatelessWidget {
  const _TopScrim({required this.strength});

  final double strength;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.24],
          colors: [
            Colors.black.withValues(alpha: 0.5 * strength),
            Colors.black.withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}
