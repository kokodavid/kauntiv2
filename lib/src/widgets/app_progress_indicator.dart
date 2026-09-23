import 'package:flutter/cupertino.dart';

import '../design/app_colors.dart';

/// Small activity spinner shown while an async action (sign-in, saving,
/// requesting a permission) is in flight. Uses Cupertino's spinner on both
/// platforms for a lighter, more neutral look than Material's circular
/// progress indicator, matching the rest of the design system's restrained
/// style.
class AppProgressIndicator extends StatelessWidget {
  const AppProgressIndicator({super.key, this.color, this.radius = 10});

  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CupertinoActivityIndicator(
      color: color ?? AppColors.ink,
      radius: radius,
    );
  }
}
