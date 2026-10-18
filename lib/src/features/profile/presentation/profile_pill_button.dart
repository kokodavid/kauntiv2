import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

/// White pill used in the Profile header (Settings). [showDot] adds the blue
/// "update available" dot with a white ring.
class ProfilePillButton extends StatelessWidget {
  const ProfilePillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) => Semantics(
    label: showDot ? 'Settings, update available' : null,
    excludeSemantics: showDot,
    child: Stack(
      clipBehavior: Clip.none,
      children: [_pill(), if (showDot) _dot()],
    ),
  );

  Widget _dot() => Positioned(
    top: -3,
    right: -3,
    child: Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    ),
  );

  Widget _pill() => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
