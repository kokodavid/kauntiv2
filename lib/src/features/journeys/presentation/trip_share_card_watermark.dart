part of 'trip_share_card.dart';

/// The app watermark: an icon badge plus the wordmark (Claude-Design
/// reference note: "The route mark and wordmark are placeholders; swap
/// in the real Kaunti47 logo at the same size" - [Icons.alt_route_rounded]
/// here is exactly that placeholder). [inverted] matches the reference's
/// no-photo note ("the watermark tile inverts to white").
/// The brand mark: a small version of the app's own icon ([AppIconBadge]
/// on the splash screen and Onboarding 02) - the gradient rounded-square
/// holding the white Kenya country outline ([AppCountryShape]), not a
/// generic icon. [inverted] swaps it to a white chip with the gradient's
/// own mid-blue shape instead, for the no-photo fallback, whose
/// background is already that same brand gradient - a white chip reads
/// there where a second copy of the gradient wouldn't.
class _Watermark extends StatelessWidget {
  const _Watermark({required this.textStyle, this.inverted = false});

  final TextStyle textStyle;
  final bool inverted;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 22,
        height: 22,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: inverted ? Colors.white : null,
          gradient: inverted
              ? null
              : const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.splashIconGradientStart,
                    AppColors.splashIconGradientMid,
                    AppColors.splashIconGradientEnd,
                  ],
                  stops: [0.04, 0.61, 0.94],
                ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: AppCountryShape(
          fill: inverted ? AppColors.splashIconGradientMid : Colors.white,
        ),
      ),
      const SizedBox(width: 7),
      Text('Kaunti47', style: textStyle),
    ],
  );
}
