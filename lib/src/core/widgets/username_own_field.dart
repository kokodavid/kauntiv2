import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';

/// How the typed username stands, for the line under the field. The
/// background check shows nothing while it runs, so there is no "checking".
enum UsernameFieldStatus { idle, ok, problem }

/// The username text field with its status icon and the line under it.
class UsernameOwnField extends StatelessWidget {
  const UsernameOwnField({
    super.key,
    required this.controller,
    required this.status,
    required this.message,
    required this.onChanged,
    this.autofocus = true,
    this.hint,
    this.idleMessage,
  });

  final TextEditingController controller;
  final UsernameFieldStatus status;
  final String? message;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final String? hint;

  /// The line under the field before there is anything to say about it.
  final String? idleMessage;

  @override
  Widget build(BuildContext context) {
    final Widget? suffix = switch (status) {
      UsernameFieldStatus.ok => const Icon(
        Icons.check_circle_rounded,
        color: AppColors.legendHome,
      ),
      UsernameFieldStatus.problem => const Icon(
        Icons.error_outline_rounded,
        color: AppColors.danger,
      ),
      UsernameFieldStatus.idle => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLength: 30,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          keyboardType: TextInputType.visiblePassword,
          cursorColor: AppColors.accent,
          style: const TextStyle(fontSize: 14),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            prefixText: '@',
            hintText: hint,
            counterText: '',
            suffixIcon: suffix == null
                ? null
                : Padding(padding: const EdgeInsets.all(12), child: suffix),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message ??
              idleMessage ??
              '3 to 30 letters, numbers, hyphens or underscores. This is the '
                  'name other explorers see.',
          style: AppTextStyles.bodySmall.copyWith(
            color: status == UsernameFieldStatus.problem
                ? AppColors.danger
                : AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
