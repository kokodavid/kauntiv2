import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

/// The pale blue card the top of the Passport landing uses (the one the
/// Collection tab had): a white rim around a blue-to-clear wash.
class PassportCardShell extends StatelessWidget {
  const PassportCardShell({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.lockedFill),
        gradient: const RadialGradient(
          radius: 1.2,
          colors: [Colors.white, Colors.white, Color(0x99FFFFFF)],
          stops: [0, 0.68, 1],
        ),
      ),
      child: Container(
        padding: padding,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6F3FF), Color(0x14DBEEFF)],
          ),
        ),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}
