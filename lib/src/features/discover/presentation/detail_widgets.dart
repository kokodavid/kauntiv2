import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// White rounded-square back button floated on detail photos.
class DetailBackButton extends StatelessWidget {
  const DetailBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.backButtonBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 20,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}

/// Small label over a bold value ("AREA / 9,462 KM²").
class DetailStatFact extends StatelessWidget {
  const DetailStatFact({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.detailStatLabel),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.detailStatValue,
        ),
      ],
    );
  }
}

/// Bordered card of facts side by side; null values are left out.
class DetailFactCard extends StatelessWidget {
  const DetailFactCard({super.key, required this.facts});

  final List<(String, String?)> facts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.factCardBorder),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          for (final (label, value) in facts)
            if (value != null)
              Expanded(
                child: DetailStatFact(label: label, value: value),
              ),
        ],
      ),
    );
  }
}

/// Frosted dark pill with white text (county status on the photo).
class DetailStatusChip extends StatelessWidget {
  const DetailStatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: AppColors.countyStatusChipBackground,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.detailStatusChip,
          ),
        ),
      ),
    );
  }
}

/// Round frosted-glass button (share, save) beside Place Detail's CTA.
class DetailGlassButton extends StatelessWidget {
  const DetailGlassButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.foreground,
    this.size = 40,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.tabBarShell,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.detailGlassShadow,
                offset: Offset(0, 2),
                blurRadius: 17,
              ),
            ],
          ),
          child: IconButton(
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            icon: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

/// Bookmark toggle that flips immediately and reverts if [onChanged]
/// fails, so saving feels instant but never lies about the result.
class DetailSaveButton extends StatefulWidget {
  const DetailSaveButton({
    super.key,
    required this.saved,
    required this.onChanged,
    this.size = 40,
    this.unsavedColor = AppColors.foreground,
  });

  final bool saved;
  final Future<void> Function(bool saved) onChanged;
  final double size;
  final Color unsavedColor;

  @override
  State<DetailSaveButton> createState() => _DetailSaveButtonState();
}

class _DetailSaveButtonState extends State<DetailSaveButton> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update your saved places.")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailGlassButton(
      size: widget.size,
      tooltip: _saved ? 'Remove from saved' : 'Save',
      icon: _saved ? Icons.bookmark : Icons.bookmark_border,
      color: _saved ? AppColors.accent : widget.unsavedColor,
      onPressed: _toggle,
    );
  }
}
