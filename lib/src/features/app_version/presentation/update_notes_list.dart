import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

/// "What's new" lines with blue dots. When [collapsedHeight] is set the list
/// is clipped to it and fades out at the bottom so a long note reads as
/// "there is more" instead of cutting a line in half.
class UpdateNotesList extends StatelessWidget {
  const UpdateNotesList({
    super.key,
    required this.items,
    this.dot = 6,
    this.gap = 10,
    this.collapsedHeight,
  });

  final List<String> items;
  final double dot;
  final double gap;
  final double? collapsedHeight;

  @override
  Widget build(BuildContext context) {
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: dot,
                    height: dot,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    final height = collapsedHeight;
    if (height == null) return list;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black, Colors.black, Colors.transparent],
        stops: [0, 0.55, 1],
      ).createShader(rect),
      child: ClipRect(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: list,
          ),
        ),
      ),
    );
  }
}

/// "Show all ⌄" / "See less ⌃" text button, 44 high for tapping.
class UpdateNotesToggle extends StatelessWidget {
  const UpdateNotesToggle({
    super.key,
    required this.expanded,
    required this.moreLabel,
    required this.lessLabel,
    required this.onTap,
  });

  final bool expanded;
  final String moreLabel;
  final String lessLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        foregroundColor: AppColors.accentDark,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      iconAlignment: IconAlignment.end,
      icon: Icon(
        expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        size: 18,
      ),
      label: Text(expanded ? lessLabel : moreLabel),
    ),
  );
}
