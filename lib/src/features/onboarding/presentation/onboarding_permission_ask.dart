import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// "How a county is earned": cross a line, stay about two hours, it's
/// yours. The whole game in three icons, so the ask has a reason.
class PermissionHowEarned extends StatelessWidget {
  const PermissionHowEarned({super.key});

  static const _steps = [
    ('Cross a county line', Icons.place_outlined),
    ('Stay about two hours', Icons.schedule),
    ('The county is yours', Icons.workspace_premium_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'HOW A COUNTY IS EARNED',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                if (i > 0) const _Arrow(),
                Expanded(
                  child: _HowStep(
                    label: _steps[i].$1,
                    icon: _steps[i].$2,
                    isLast: i == _steps.length - 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 9),
      child: SizedBox(
        width: 14,
        child: Text(
          '→',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.detailStatLabel),
        ),
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({
    required this.label,
    required this.icon,
    required this.isLast,
  });

  final String label;
  final IconData icon;

  /// The final step ("yours") is filled blue; the others are white.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLast ? AppColors.accent : Colors.white,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isLast ? AppColors.accentForeground : AppColors.accent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }
}

/// A short reassurance in a bordered card: an icon, a title and one line.
/// Four of these sit in a 2x2 grid on step 3.
class PermissionReassurance extends StatelessWidget {
  const PermissionReassurance({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.listItemTitle.copyWith(
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
