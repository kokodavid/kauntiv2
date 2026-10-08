import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// The sheet's one primary action: a 50 pt accent pill.
class MapHomePrimaryButton extends StatelessWidget {
  const MapHomePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  static const height = 50.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: Text(label, style: AppTextStyles.buttonLabel),
      ),
    );
  }
}
