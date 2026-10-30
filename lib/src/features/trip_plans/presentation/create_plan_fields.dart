import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/create_plan_controller.dart';
import '../domain/trip_plan.dart';
import 'create_plan_parts.dart';

/// "New plan" with the close button.
class CreatePlanHeader extends StatelessWidget {
  const CreatePlanHeader({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.sheetGrabber,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Expanded(
            child: Text('New plan', style: AppTypeScale.sectionTitle),
          ),
          IconButton(
            tooltip: 'Close',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.iconButtonBackground,
              foregroundColor: AppColors.foreground,
              minimumSize: const Size(44, 44),
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ],
  );
}

class CreatePlanTitleField extends StatelessWidget {
  const CreatePlanTitleField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const CreatePlanLabel('Title'),
      TextField(
        controller: controller,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        style: AppTypeScale.cardTitle.copyWith(fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.exploreSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.inputFocusedBorder),
          ),
        ),
      ),
    ],
  );
}

/// Start from: three chips, the chosen place under them, and the amber note
/// when the phone's location can't be read (design 2c).
class CreatePlanStartField extends ConsumerWidget {
  const CreatePlanStartField({
    super.key,
    required this.start,
    required this.canChoosePlace,
    required this.canPickOnMap,
    required this.onChoose,
  });

  final PlanStart start;
  final bool canChoosePlace;
  final bool canPickOnMap;
  final ValueChanged<PlanStartKind> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usesLocation = start.kind == PlanStartKind.currentLocation;
    final location = usesLocation
        ? ref.watch(planCurrentLocationProvider)
        : null;
    final noFix =
        location != null && !location.isLoading && location.value == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CreatePlanLabel('Start from'),
        // One row of equal chips; the text shrinks rather than wrapping.
        Row(
          spacing: 6,
          children: [
            Expanded(
              child: CreatePlanChip(
                label: 'Current location',
                selected: usesLocation,
                onTap: () => onChoose(PlanStartKind.currentLocation),
              ),
            ),
            if (canChoosePlace)
              Expanded(
                child: CreatePlanChip(
                  label: 'Choose a place',
                  selected: start.kind == PlanStartKind.place,
                  onTap: () => onChoose(PlanStartKind.place),
                ),
              ),
            if (canPickOnMap)
              Expanded(
                child: CreatePlanChip(
                  label: 'Pick on map',
                  selected: start.kind == PlanStartKind.point,
                  onTap: () => onChoose(PlanStartKind.point),
                ),
              ),
          ],
        ),
        if (!usesLocation) ...[
          const SizedBox(height: 8),
          _StartLine(label: start.displayLabel),
        ],
        if (noFix) ...[
          const SizedBox(height: 10),
          CreatePlanNote(
            warning: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "We can't find your location right now. Turn on location, "
                  'or choose a place to start from.',
                  style: AppTypeScale.small.copyWith(
                    color: AppColors.warningText,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  children: [
                    TextButton(
                      style: _linkStyle,
                      onPressed: () =>
                          ref.invalidate(planCurrentLocationProvider),
                      child: const Text('Try again'),
                    ),
                    if (canChoosePlace)
                      TextButton(
                        style: _linkStyle,
                        onPressed: () => onChoose(PlanStartKind.place),
                        child: const Text('Choose a place'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static final _linkStyle = TextButton.styleFrom(
    foregroundColor: AppColors.accent,
    padding: EdgeInsets.zero,
    minimumSize: const Size(44, 36),
    textStyle: AppTypeScale.action,
  );
}

class _StartLine extends StatelessWidget {
  const _StartLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypeScale.small.copyWith(color: AppColors.foreground),
        ),
      ),
    ],
  );
}
