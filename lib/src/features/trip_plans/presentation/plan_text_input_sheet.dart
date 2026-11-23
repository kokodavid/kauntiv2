import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import 'plan_sheet_frame.dart';

/// One line of text in a bottom sheet (rename plan, name a day), with a
/// small label, a live count, and Cancel and Save. Null when cancelled.
Future<String?> showPlanTextInput(
  BuildContext context, {
  required String title,
  String? label,
  String? initial,
  String? hint,
  int maxLength = 80,
  String action = 'Save',
  bool allowEmpty = false,
}) => showPlanSheet<String>(
  context,
  (_) => _TextInputBody(
    title: title,
    label: label,
    initial: initial,
    hint: hint,
    maxLength: maxLength,
    action: action,
    allowEmpty: allowEmpty,
  ),
);

class _TextInputBody extends StatefulWidget {
  const _TextInputBody({
    required this.title,
    required this.label,
    required this.initial,
    required this.hint,
    required this.maxLength,
    required this.action,
    required this.allowEmpty,
  });

  final String title;
  final String? label;
  final String? initial;
  final String? hint;
  final int maxLength;
  final String action;
  final bool allowEmpty;

  @override
  State<_TextInputBody> createState() => _TextInputBodyState();
}

class _TextInputBodyState extends State<_TextInputBody> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty && !widget.allowEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    return PlanSheetFrame(
      title: widget.title,
      children: [
        const SizedBox(height: 16),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(label.toUpperCase(), style: AppTypeScale.sectionLabel),
          ),
        TextField(
          controller: _controller,
          autofocus: true,
          maxLength: widget.maxLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          style: AppTypeScale.cardTitle.copyWith(fontWeight: FontWeight.w400),
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) => null,
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            filled: true,
            fillColor: AppColors.exploreSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            suffix: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => Text(
                '${value.text.length} / ${widget.maxLength}',
                style: AppTypeScale.small,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.inputFocusedBorder,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.secondaryFill,
                  foregroundColor: AppColors.foreground,
                  textStyle: AppTypeScale.action,
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                  textStyle: AppTypeScale.action,
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                onPressed: _save,
                child: Text(widget.action),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
