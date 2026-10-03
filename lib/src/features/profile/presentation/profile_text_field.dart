import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

/// A labeled text field for Profile/Settings forms ("Edit profile" today;
/// any future name/handle/bio-style field should reuse this rather than a
/// bare [TextField]). Border/focus colors come from the app's global
/// `inputDecorationTheme` (`app.dart`), so this widget only owns the
/// label-above-field layout and the optional helper caption underneath --
/// it never hardcodes a color itself.
class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLength,
    this.prefixText,
    this.suffixText,
    this.errorText,
    this.helperCaption,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
  });

  /// Shown above the field, e.g. "Display name".
  final String label;
  final TextEditingController controller;
  final int? maxLength;
  final String? prefixText;
  final String? suffixText;
  final String? errorText;

  /// Shown below the field in muted, small text (e.g. format guidance).
  /// Separate from [errorText], which the field itself renders.
  final String? helperCaption;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        enabled: enabled,
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          prefixText: prefixText,
          suffixText: suffixText,
          errorText: errorText,
        ),
      ),
      if (helperCaption != null) ...[
        const SizedBox(height: 2),
        Text(
          helperCaption!,
          style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
        ),
      ],
    ],
  );
}
