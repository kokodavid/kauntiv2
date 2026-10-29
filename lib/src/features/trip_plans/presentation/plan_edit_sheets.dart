import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../domain/plan_failure.dart';
import 'plan_pro_sheet.dart';

/// Says why a change didn't happen: a Free limit opens the Pro sheet, any
/// other refusal is one line in a toast.
void reportPlanFailure(BuildContext context, PlanFailure failure) {
  final trigger = switch (failure.kind) {
    PlanFailureKind.limitDays => PlanProTrigger.days,
    PlanFailureKind.limitStops => PlanProTrigger.stops,
    PlanFailureKind.limitPlaces => PlanProTrigger.places,
    PlanFailureKind.limitPlans => PlanProTrigger.upcomingPlans,
    _ => null,
  };
  if (trigger != null) {
    unawaited(showPlanProSheet(context, trigger: trigger));
    return;
  }
  showAppToast(
    context,
    variant: AppToastVariant.error,
    title: failure.message,
  );
}

/// One line of text in a dialog (rename, note). Null when cancelled.
Future<String?> showPlanTextInput(
  BuildContext context, {
  required String title,
  String? initial,
  String? hint,
  int maxLength = 80,
  String action = 'Save',
  bool allowEmpty = false,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextInput(
    title: title,
    initial: initial,
    hint: hint,
    maxLength: maxLength,
    action: action,
    allowEmpty: allowEmpty,
  ),
);

class _TextInput extends StatefulWidget {
  const _TextInput({
    required this.title,
    required this.initial,
    required this.hint,
    required this.maxLength,
    required this.action,
    required this.allowEmpty,
  });

  final String title;
  final String? initial;
  final String? hint;
  final int maxLength;
  final String action;
  final bool allowEmpty;

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: widget.maxLength,
      decoration: InputDecoration(hintText: widget.hint),
      textCapitalization: TextCapitalization.sentences,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          final text = _controller.text.trim();
          if (text.isEmpty && !widget.allowEmpty) return;
          Navigator.of(context).pop(text);
        },
        child: Text(widget.action),
      ),
    ],
  );
}

/// A yes or no. True only when confirmed.
Future<bool> showPlanConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
