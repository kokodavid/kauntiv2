import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';

/// A bottom-sheet text prompt, matching the Claude-Design "Rename Trip"
/// reference: a title, one accent-bordered text field prefilled with the
/// current value, and a filled primary ("Save") button over an outlined
/// Cancel button. Reusable for any single-line rename/edit prompt in the
/// app, not just a Trip's title.
///
/// Returns the trimmed, non-empty text if confirmed, or null if
/// cancelled (Cancel, a back gesture, or tapping outside the sheet).
Future<String?> showAppTextInputSheet(
  BuildContext context, {
  required String title,
  required String initialValue,
  String saveLabel = 'Save',
  String cancelLabel = 'Cancel',
  String? hintText,
  int maxLength = 120,
}) {
  return showModalBottomSheet<String>(
    context: context,
    // useRootNavigator: true - same fix as this app's other sheets - so
    // this sits above AppShell's floating bottom nav bar.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: AppColors.sheetBarrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _AppTextInputSheet(
      title: title,
      initialValue: initialValue,
      saveLabel: saveLabel,
      cancelLabel: cancelLabel,
      hintText: hintText,
      maxLength: maxLength,
    ),
  );
}

class _AppTextInputSheet extends StatefulWidget {
  const _AppTextInputSheet({
    required this.title,
    required this.initialValue,
    required this.saveLabel,
    required this.cancelLabel,
    required this.hintText,
    required this.maxLength,
  });

  final String title;
  final String initialValue;
  final String saveLabel;
  final String cancelLabel;
  final String? hintText;
  final int maxLength;

  @override
  State<_AppTextInputSheet> createState() => _AppTextInputSheetState();
}

class _AppTextInputSheetState extends State<_AppTextInputSheet> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final accentBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.trackInactive,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(widget.title, style: AppTextStyles.confirmSheetTitle),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: widget.maxLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: AppTextStyles.menuItemLabel,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  counterText: '',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: accentBorder,
                  enabledBorder: accentBorder,
                  focusedBorder: accentBorder,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    widget.saveLabel,
                    style: AppTextStyles.confirmSheetButtonLabel,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.buttonForeground,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    widget.cancelLabel,
                    style: AppTextStyles.confirmSheetButtonLabel.copyWith(
                      color: AppColors.buttonForeground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
