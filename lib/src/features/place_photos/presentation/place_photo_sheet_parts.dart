import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// The full-width rounded button the submit sheet ends with.
class SheetPillButton extends StatelessWidget {
  const SheetPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.soft = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The pale-blue version ("Choose another photo").
  final bool soft;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;
    final background = soft
        ? AppColors.accentTint
        : active
        ? AppColors.accent
        : AppColors.segmentedTrack;
    final foreground = soft
        ? AppColors.accent
        : active
        ? Colors.white
        : AppColors.disabledText;
    return Semantics(
      button: true,
      enabled: active,
      child: GestureDetector(
        onTap: active ? onPressed : null,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// The button turned into a bar while the photo is on its way.
class SheetSendingBar extends StatelessWidget {
  const SheetSendingBar({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: AppColors.accentTint,
      borderRadius: BorderRadius.circular(26),
    ),
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    child: const Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: LinearProgressIndicator(
            backgroundColor: AppColors.accentTint,
            color: AppColors.photoSendingFill,
          ),
        ),
        Text(
          'Sending…',
          style: TextStyle(
            fontFamily: AppTypeScale.family,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ],
    ),
  );
}

/// One plain sentence in danger text, above the button.
class SheetRefusal extends StatelessWidget {
  const SheetRefusal(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: AppColors.dangerTint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline,
          size: 18,
          color: AppColors.dangerSoftForeground,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 13,
              height: 1.45,
              color: AppColors.dangerSoftForeground,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The consent row: the whole row is the 44 pt target.
class SheetConsentRow extends StatelessWidget {
  const SheetConsentRow({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.text,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: checked,
    child: InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!checked),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: checked ? AppColors.accent : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: checked
                    ? null
                    : Border.all(color: AppColors.lockedStroke, width: 2),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.headingText,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A bold title with a calm line under it.
class SheetHeading extends StatelessWidget {
  const SheetHeading(this.title, this.body, {super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTypeScale.sectionTitle),
      const SizedBox(height: 6),
      Text(
        body,
        style: const TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: 13,
          height: 1.5,
          color: AppColors.offlineBody,
        ),
      ),
    ],
  );
}

/// Camera or Gallery: a big target with an icon over a label.
class SheetSourceButton extends StatelessWidget {
  const SheetSourceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onPressed : null,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 104,
      decoration: BoxDecoration(
        color: AppColors.lockedFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: AppColors.foreground),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The calm "thanks" after a photo is on its way.
class SheetSentBody extends StatelessWidget {
  const SheetSentBody({super.key});

  @override
  Widget build(BuildContext context) => Column(
    spacing: 10,
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.successTint,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 28,
          color: AppColors.newCountyText,
        ),
      ),
      const Text('Sent for review', style: AppTypeScale.sectionTitle),
      const Text(
        "Thanks. We'll check it soon. You can see how it's going in "
        'Profile › My photos.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: 13,
          height: 1.5,
          color: AppColors.offlineBody,
        ),
      ),
    ],
  );
}
