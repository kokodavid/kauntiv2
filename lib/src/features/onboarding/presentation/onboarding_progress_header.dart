import 'package:flutter/material.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../design/app_text_styles.dart';

/// The top of every setup step, drawn on the blue header: an optional
/// back button, "n of 4" and four segmented bars. [step] is 1 to 4, or
/// null to draw only the back button (no numbering).
class OnboardingProgressHeader extends StatelessWidget {
  const OnboardingProgressHeader({
    super.key,
    required this.step,
    this.total = 4,
    this.onBack,
  });

  final int? step;
  final int total;

  /// Null on step 1, which has nothing to go back to.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final step = this.step;
    return Semantics(
      label: step == null ? null : 'Step $step of $total',
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: onBack == null
                  ? null
                  : Center(
                      child: Semantics(
                        label: 'Back',
                        button: true,
                        excludeSemantics: true,
                        onTap: onBack,
                        child: AppBackButton(onPressed: onBack!),
                      ),
                    ),
            ),
            Expanded(
              child: step == null
                  ? const SizedBox.shrink()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$step of $total',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 1; i <= total; i++) ...[
                              if (i > 1) const SizedBox(width: 4),
                              Container(
                                width: 28,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i <= step
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}
