import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// A tall-enough bottom sheet that lifts above the keyboard.
Future<T?> showPlanSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.sheetBackground,
      barrierColor: AppColors.sheetBarrier,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: builder,
    );

/// Grabber, title and a scrolling body for the sharing sheets.
class PlanSheetFrame extends StatelessWidget {
  const PlanSheetFrame({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.closeButton = false,
    this.onBack,
  });

  final String title;

  /// A quiet line under the title.
  final String? subtitle;

  /// A round "×" at the right of the title.
  final bool closeButton;

  /// A round "‹" before the title, to go back a step.
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sheetGrabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onBack != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Semantics(
                    button: true,
                    label: 'Back',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onBack,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryFill,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypeScale.sectionTitle),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: AppTypeScale.small),
                      ),
                  ],
                ),
              ),
              if (closeButton)
                Semantics(
                  button: true,
                  label: 'Close',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

/// A person's round avatar: their photo, or their first letter.
class PlanPersonAvatar extends StatelessWidget {
  const PlanPersonAvatar({
    super.key,
    required this.initial,
    this.url,
    this.size = 36,
  });

  final String initial;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: AppColors.secondaryFill,
    foregroundImage: url == null ? null : NetworkImage(url!),
    child: Text(initial, style: AppTypeScale.small),
  );
}
