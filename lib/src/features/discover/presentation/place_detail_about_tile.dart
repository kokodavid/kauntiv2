import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// "About this place": a tile that shows the first lines of the
/// description and opens to all of it when tapped.
class PlaceDetailAboutTile extends StatefulWidget {
  const PlaceDetailAboutTile({super.key, required this.description});

  final String description;

  @override
  State<PlaceDetailAboutTile> createState() => _PlaceDetailAboutTileState();
}

class _PlaceDetailAboutTileState extends State<PlaceDetailAboutTile> {
  static const _previewLines = 2;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.description.trim();
    final style = AppTypeScale.body.copyWith(fontSize: 14, height: 22 / 14);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: text.isEmpty ? null : () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ABOUT THIS PLACE',
                      style: AppTypeScale.sectionLabel.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  if (text.isNotEmpty)
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    text.isEmpty ? 'No description for this place yet.' : text,
                    maxLines: _open ? null : _previewLines,
                    overflow: _open ? null : TextOverflow.ellipsis,
                    style: style,
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
