import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/place_type.dart';
import '../../../core/widgets/place_type_style.dart';
import '../../../design/app_colors.dart';

/// Place Detail's "About": the description open on one card, in short
/// paragraphs, nothing to tap and nothing cut off. Replaces the old
/// collapsible tile (`PlaceDetailAboutTile`) -- that tile hid the place's
/// story behind a tap; this reads top to bottom with the rest of the
/// page. The category, moved off the header photo, sits on the card's
/// first line with the county.
class PlaceDetailAboutSection extends StatelessWidget {
  const PlaceDetailAboutSection({
    super.key,
    required this.description,
    required this.category,
    required this.countyName,
  });

  final String description;
  final PlaceType category;
  final String countyName;

  /// Experiment: skip the "About" heading -- the card reads fine
  /// without it since nothing else sits above it now. Flip back to
  /// `false` to bring the heading back.
  static const _hideTitle = true;

  @override
  Widget build(BuildContext context) {
    final paragraphs = _paragraphs(description);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_hideTitle) ...[
          Semantics(
            header: true,
            child: const Text('About', style: AppTypeScale.sectionTitle),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: category.dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${category.label} · $countyName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypeScale.family,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
              for (final paragraph in paragraphs) ...[
                const SizedBox(height: 12),
                Text(
                  paragraph,
                  style: const TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 16,
                    height: 26 / 16,
                    color: AppColors.detailBodyText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Splits on blank lines so an editor who already paragraphs the
  /// description gets real spacing between paragraphs; a description with
  /// no blank lines stays one block rather than being cut up mid-sentence.
  static List<String> _paragraphs(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const ['No description for this place yet.'];
    final parts = trimmed
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.isEmpty ? [trimmed] : parts;
  }
}
