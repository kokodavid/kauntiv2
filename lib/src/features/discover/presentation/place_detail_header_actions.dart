import 'package:flutter/material.dart';

import '../../../core/domain/app_feature_flags.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';

/// Save and optional share actions that float over the Place Detail header.
class PlaceDetailHeaderActions extends StatelessWidget {
  const PlaceDetailHeaderActions({
    super.key,
    required this.saved,
    required this.onSavedChanged,
  });

  final bool saved;
  final Future<void> Function(bool saved) onSavedChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (AppFeatureFlags.placeShare) ...[
          _HeaderIconButton(
            icon: Icons.ios_share,
            tooltip: 'Share',
            color: AppColors.foreground,
            onPressed: () => showAppToast(
              context,
              variant: AppToastVariant.neutral,
              title: 'Sharing is coming soon.',
            ),
          ),
          const SizedBox(width: 8),
        ],
        _HeaderSaveButton(saved: saved, onChanged: onSavedChanged),
      ],
    );
  }
}

/// A back-button-shaped white square for the header controls.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 44,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.backButtonBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

/// Bookmark toggle that flips immediately and reverts if persistence fails.
class _HeaderSaveButton extends StatefulWidget {
  const _HeaderSaveButton({required this.saved, required this.onChanged});

  final bool saved;
  final Future<void> Function(bool saved) onChanged;

  @override
  State<_HeaderSaveButton> createState() => _HeaderSaveButtonState();
}

class _HeaderSaveButtonState extends State<_HeaderSaveButton> {
  late bool _saved = widget.saved;
  bool _busy = false;

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
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't update your saved places.",
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HeaderIconButton(
      icon: _saved ? Icons.bookmark : Icons.bookmark_border,
      tooltip: _saved ? 'Saved. Tap to remove' : 'Save place',
      color: _saved ? AppColors.accent : AppColors.foreground,
      onPressed: _busy ? null : _toggle,
    );
  }
}
