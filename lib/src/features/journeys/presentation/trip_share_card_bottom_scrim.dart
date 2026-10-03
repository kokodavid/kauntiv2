part of 'trip_share_card.dart';

/// Bottom-up darkening behind the text block - always present, but
/// lighter ([strength] < 1) over the no-photo brand gradient, which
/// already reads darker toward the bottom on its own (Claude-Design
/// reference: "Bottom gradient: 88% ink at the base, 66-70% at a third
/// of the height, clear by 66%. ... The photo is never dimmed all
/// over.").
class _BottomScrim extends StatelessWidget {
  const _BottomScrim({required this.strength});

  final double strength;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          // Extended further up the card (was 0.34/0.66) - Claude-Design
          // "Share Sheet 3a" reference flagged the Trip title sitting on
          // the bright part of a photo in the old build, since the
          // scrim faded out before reaching it on a taller photo.
          stops: const [0, 0.42, 0.70],
          colors: [
            Colors.black.withValues(alpha: 0.90 * strength),
            Colors.black.withValues(alpha: 0.72 * strength),
            Colors.black.withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}
