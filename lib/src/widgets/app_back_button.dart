import 'package:flutter/material.dart';

import '../design/app_colors.dart';

/// The app's one back button: a white rounded-square with an
/// `arrow_back` glyph. Originally County/Place Detail's floated photo
/// control (`DetailBackButton`); now shared so any screen that needs a
/// back affordance -- Detail, Profile, Settings -- uses the same shape
/// and colors instead of a one-off per screen.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed, this.size = 40});

  final VoidCallback onPressed;

  /// Overall square side. Every call site uses the default 40 so the
  /// button is identical wherever it appears (Detail's floated photo
  /// control, Profile's header, Settings' app bar); override only for a
  /// deliberately different context. The icon and corner radius scale
  /// with it.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.backButtonBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size * 0.35),
          ),
          padding: EdgeInsets.zero,
          minimumSize: Size.square(size),
          // Material's default tap-target padding pads the button's hit
          // area (and, inside some ambient themes, its visible box) out
          // to 48dp regardless of the requested size -- shrinkWrap turns
          // that off so this renders at exactly [size] everywhere it's
          // used (a bare Row, an AppBar's leading slot, a floated photo
          // control), instead of looking bigger in one context than
          // another.
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Icon(
          Icons.arrow_back,
          size: size * 0.5,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}
