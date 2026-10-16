import 'package:flutter/material.dart';

import '../../design/app_colors.dart';

/// A plain bookmark toggle for list rows (v1 `AppSaveIcon`), shared by
/// Explore and the arrival sheet. Flips
/// immediately, then reverts with a note if [onChanged] throws.
class AppSaveIcon extends StatefulWidget {
  const AppSaveIcon({
    super.key,
    required this.saved,
    required this.onChanged,
    this.dimension = 28,
    this.iconSize = 18,
    this.unsavedColor = AppColors.exploreMutedText,
  });

  final bool saved;

  /// Tap target edge and glyph size. Lists with larger rows pass 44 / 22.
  final double dimension;
  final double iconSize;
  final Color unsavedColor;
  final Future<void> Function(bool saved) onChanged;

  @override
  State<AppSaveIcon> createState() => _AppSaveIconState();
}

class _AppSaveIconState extends State<AppSaveIcon> {
  late bool _saved = widget.saved;
  bool _busy = false;

  @override
  void didUpdateWidget(AppSaveIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_busy && oldWidget.saved != widget.saved) _saved = widget.saved;
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final next = !_saved;
    setState(() {
      _saved = next;
      _busy = true;
    });
    try {
      await widget.onChanged(next);
    } on Object {
      if (!mounted) return;
      setState(() => _saved = !next);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update your saved places.")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.dimension,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: widget.iconSize,
        tooltip: _saved ? 'Remove from saved' : 'Save',
        onPressed: _toggle,
        icon: Icon(
          _saved ? Icons.bookmark : Icons.bookmark_border,
          color: _saved ? AppColors.accent : widget.unsavedColor,
        ),
      ),
    );
  }
}
