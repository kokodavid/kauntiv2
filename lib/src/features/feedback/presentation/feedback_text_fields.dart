import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

class FeedbackSectionLabel extends StatelessWidget {
  const FeedbackSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 8),
    child: Text(
      text,
      style: AppTextStyles.listItemTitle.copyWith(fontSize: 14),
    ),
  );
}

class FeedbackTextField extends StatelessWidget {
  const FeedbackTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String> onChanged;

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.mutedForeground,
        ),
        counterStyle: const TextStyle(
          fontSize: 11,
          color: AppColors.mutedForeground,
        ),
        filled: true,
        fillColor: AppColors.pageBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: _border(AppColors.cardBorder),
        disabledBorder: _border(AppColors.cardBorder),
        focusedBorder: _border(AppColors.accent, 1.5),
      ),
    );
  }
}

/// "May we contact you?": off unless the tester turns it on.
class FeedbackContactSwitch extends StatelessWidget {
  const FeedbackContactSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'May we contact you about this?',
                style: AppTextStyles.listItemTitle.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                'Only if we need more detail, on the email you signed in with.',
                style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeTrackColor: AppColors.accent,
        ),
      ],
    );
  }
}

/// What the app adds to the report by itself.
class FeedbackContextNote extends StatelessWidget {
  const FeedbackContextNote({super.key, required this.screen});

  final String? screen;

  @override
  Widget build(BuildContext context) {
    final where = screen == null ? 'the screen you were on' : screen!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.noteBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.noteMutedText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sent with $where, the app version and your phone model, '
              'so you do not have to describe them.',
              style: AppTextStyles.noteText.copyWith(
                fontSize: 12,
                color: AppColors.noteMutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
