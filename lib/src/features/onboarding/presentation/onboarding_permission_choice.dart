import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/location_choice.dart';

/// The two answers to "how should Kaunti47 notice county lines?", as one
/// grouped list. "All the time" is first and marked recommended; each row
/// carries only a short line, so the choice reads at a glance. The chosen
/// row shows a filled check, the other an empty circle that can be tapped.
class PermissionChoiceCards extends StatelessWidget {
  const PermissionChoiceCards({
    super.key,
    required this.choice,
    required this.onChanged,
  });

  final LocationChoice choice;
  final ValueChanged<LocationChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    // The border sits outside; the rows are clipped to the radius just
    // inside it, so a tinted row never paints over the border at the corners.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.5),
        child: Column(
          children: [
            _ChoiceRow(
              icon: Icons.location_on_outlined,
              title: 'All the time',
              body:
                  'Counties unlock even when the app is closed and the phone '
                  'is in your pocket.',
              recommended: true,
              selected: choice == LocationChoice.allTheTime,
              onTap: () => onChanged(LocationChoice.allTheTime),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.listDivider,
            ),
            _ChoiceRow(
              icon: Icons.smartphone_outlined,
              title: 'Only while using',
              body:
                  'Counties are recorded when you open Kaunti47. If you '
                  "cross a line and don't open the app, we may miss it.",
              recommended: false,
              selected: choice == LocationChoice.whileUsing,
              onTap: () => onChanged(LocationChoice.whileUsing),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.recommended,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: recommended ? '$title, recommended. $body' : '$title. $body',
      excludeSemantics: true,
      child: Material(
        color: selected ? const Color(0xFFF2F8FF) : Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppTextStyles.listItemTitle.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Text(
                              'RECOMMENDED',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: const Color(0xFF0066CC),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          color: AppColors.headingText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _SelectMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A filled check when chosen, an empty ring when not: still a tap target
/// look, so the other row reads as an option rather than a disabled item.
class _SelectMark extends StatelessWidget {
  const _SelectMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.accent : Colors.transparent,
        border: selected
            ? null
            : Border.all(color: const Color(0xFFA1A1AA), width: 1.8),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }
}

/// "Next your phone asks. Choose …": sits right above the button and
/// follows the selected card.
class PermissionPromptNote extends StatelessWidget {
  const PermissionPromptNote({super.key, required this.choice});

  final LocationChoice choice;

  @override
  Widget build(BuildContext context) {
    final always = choice == LocationChoice.allTheTime;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Next your phone asks. Choose '),
          TextSpan(
            text: always ? 'Allow all the time' : 'While using the app',
            style: const TextStyle(
              color: AppColors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
