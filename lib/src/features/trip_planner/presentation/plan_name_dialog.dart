import 'package:flutter/material.dart';

import '../domain/saved_trip.dart';

/// Asks for a saved plan's name. Null when cancelled.
Future<String?> showPlanNameDialog(
  BuildContext context, {
  required String title,
  required String initial,
  String confirmLabel = 'Save',
}) => showDialog<String>(
  context: context,
  builder: (_) => _PlanNameDialog(
    title: title,
    initial: initial,
    confirmLabel: confirmLabel,
  ),
);

class _PlanNameDialog extends StatefulWidget {
  const _PlanNameDialog({
    required this.title,
    required this.initial,
    required this.confirmLabel,
  });

  final String title;
  final String initial;
  final String confirmLabel;

  @override
  State<_PlanNameDialog> createState() => _PlanNameDialogState();
}

class _PlanNameDialogState extends State<_PlanNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: SavedTrip.maxNameLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Name this plan'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
