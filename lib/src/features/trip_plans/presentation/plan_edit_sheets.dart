import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_failure.dart';
import 'plan_pro_sheet.dart';
import 'plan_sheet_frame.dart';

/// Says why a change didn't happen: a Free limit opens the Pro sheet, any
/// other refusal is one line in a toast.
void reportPlanFailure(BuildContext context, PlanFailure failure) {
  final trigger = switch (failure.kind) {
    PlanFailureKind.limitDays => PlanProTrigger.days,
    PlanFailureKind.limitStops => PlanProTrigger.stops,
    PlanFailureKind.limitPlaces => PlanProTrigger.places,
    PlanFailureKind.limitPlans => PlanProTrigger.upcomingPlans,
    PlanFailureKind.limitBestOrder => PlanProTrigger.bestOrder,
    PlanFailureKind.limitMembers ||
    PlanFailureKind.limitRoles => PlanProTrigger.invitee,
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

/// A yes or no as a bottom sheet (design 3g): an icon, what happens, then
/// Cancel and the action. True only when confirmed.
Future<bool> showPlanConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  IconData icon = Icons.delete_outline,
  bool destructive = true,
}) async =>
    await showPlanSheet<bool>(
      context,
      (sheet) => _ConfirmBody(
        title: title,
        message: message,
        action: action,
        icon: icon,
        destructive: destructive,
      ),
    ) ??
    false;

class _ConfirmBody extends StatelessWidget {
  const _ConfirmBody({
    required this.title,
    required this.message,
    required this.action,
    required this.icon,
    required this.destructive,
  });

  final String title;
  final String message;
  final String action;
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.accent;
    final foreground = destructive
        ? AppColors.dangerForeground
        : AppColors.accentForeground;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sheetGrabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: destructive ? AppColors.dangerTint : AppColors.accentTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTypeScale.sectionTitle),
          const SizedBox(height: 6),
          Text(message, style: AppTypeScale.body),
          const SizedBox(height: 20),
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
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: foreground,
                    textStyle: AppTypeScale.action,
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(action),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
