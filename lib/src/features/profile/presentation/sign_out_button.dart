import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

/// The one Sign out button, shared by Profile and Settings so the two
/// screens always look the same.
class SignOutButton extends StatelessWidget {
  const SignOutButton({
    super.key,
    required this.signingOut,
    required this.onPressed,
  });

  final bool signingOut;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: signingOut ? null : onPressed,
      icon: const Icon(Icons.logout),
      label: Text(signingOut ? 'Signing out...' : 'Sign out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: Color(0xFFD5E7FA)),
      ),
    );
  }
}
