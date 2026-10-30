import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/create_plan_controller.dart';
import '../domain/new_plan_request.dart';
import '../domain/plan_failure.dart';
import '../domain/plan_limits.dart';
import '../domain/trip_plan.dart';
import 'create_plan_days_fields.dart';
import 'create_plan_fields.dart';
import 'create_plan_parts.dart';
import 'plan_pro_sheet.dart';

/// Picks a start for a plan (place search, or a pin on the map). Null when
/// the user backs out.
typedef ChoosePlanStart = Future<PlanStart?> Function(BuildContext context);

/// The create sheet over Trips (design 2a to 2d). Returns the new plan's id,
/// or null if the user closed it. Only the title is filled in for the user.
Future<String?> showCreatePlanSheet(
  BuildContext context, {
  required PlanLimits limits,
  VoidCallback? onSeePro,
  ChoosePlanStart? onChoosePlace,
  ChoosePlanStart? onPickOnMap,
  String? firstPlaceId,
}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: AppColors.sheetBackground,
  barrierColor: AppColors.sheetBarrier,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => CreatePlanSheet(
    limits: limits,
    onSeePro: onSeePro,
    onChoosePlace: onChoosePlace,
    onPickOnMap: onPickOnMap,
    firstPlaceId: firstPlaceId,
  ),
);

class CreatePlanSheet extends ConsumerStatefulWidget {
  const CreatePlanSheet({
    super.key,
    required this.limits,
    this.onSeePro,
    this.onChoosePlace,
    this.onPickOnMap,
    this.firstPlaceId,
  });

  final PlanLimits limits;
  final VoidCallback? onSeePro;
  final ChoosePlanStart? onChoosePlace;
  final ChoosePlanStart? onPickOnMap;
  final String? firstPlaceId;

  @override
  ConsumerState<CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends ConsumerState<CreatePlanSheet> {
  final _title = TextEditingController(text: 'Weekend trip');
  // Null once the user removes their choice: they must pick a start again.
  PlanStart? _start = PlanStart.currentLocation;
  DateTime? _date;
  int _days = 1;
  bool _showDayLimit = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  /// What is still missing before a plan can be made, or null.
  String? get _missing {
    if (_title.text.trim().isEmpty) return 'Give the plan a name.';
    if (_start == null) return 'Choose where this trip starts.';
    return null;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _chooseStart(PlanStartKind kind) async {
    if (kind == PlanStartKind.currentLocation) {
      setState(() => _start = PlanStart.currentLocation);
      return;
    }
    final pick = kind == PlanStartKind.place
        ? widget.onChoosePlace
        : widget.onPickOnMap;
    final chosen = await pick?.call(context);
    if (chosen != null && mounted) setState(() => _start = chosen);
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.accent,
            onPrimary: AppColors.accentForeground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _create() async {
    final title = _title.text.trim();
    final start = _start;
    if (_missing != null || start == null) return;
    setState(() => _error = null);
    final request = NewPlanRequest(
      title: title,
      days: _days,
      startKind: start.kind,
      startPlaceId: start.place?.id,
      startLabel: start.label ?? start.place?.name,
      startLat: start.lat ?? start.place?.lat,
      startLng: start.lng ?? start.place?.lng,
      startDate: _date,
      firstPlaceId: widget.firstPlaceId,
    );
    try {
      final id = await ref
          .read(createPlanControllerProvider.notifier)
          .create(request);
      if (mounted) Navigator.of(context).pop(id);
    } on PlanFailure catch (failure) {
      if (!mounted) return;
      if (failure.kind == PlanFailureKind.limitPlans) {
        // Over the sheet, so the form is kept if they come back.
        unawaited(
          showPlanProSheet(
            context,
            trigger: PlanProTrigger.upcomingPlans,
            onSeePro: widget.onSeePro,
          ),
        );
        return;
      }
      setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(createPlanControllerProvider);
    final limits = widget.limits;
    final atFreeLimit = !limits.pro && _days >= limits.maxDays;
    final missing = _missing;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + insets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CreatePlanHeader(),
            CreatePlanTitleField(controller: _title),
            const SizedBox(height: 16),
            CreatePlanStartField(
              start: _start,
              canChoosePlace: widget.onChoosePlace != null,
              canPickOnMap: widget.onPickOnMap != null,
              onChoose: _chooseStart,
              onClear: () => setState(() => _start = null),
            ),
            const SizedBox(height: 16),
            CreatePlanDateAndDays(
              date: _date,
              days: _days,
              maxDays: limits.maxDays,
              onPickDate: _pickDate,
              onClearDate: () => setState(() => _date = null),
              onDays: (days) => setState(() {
                _days = days;
                _showDayLimit = false;
              }),
              onBlockedIncrement: () => setState(() => _showDayLimit = true),
            ),
            const SizedBox(height: 8),
            CreatePlanDaysNote(
              limits: limits,
              days: _days,
              onSeePro: widget.onSeePro,
            ),
            if (_showDayLimit && !limits.pro) ...[
              const SizedBox(height: 12),
              CreatePlanNote(
                trailing: widget.onSeePro == null
                    ? null
                    : CreatePlanSeeProButton(onPressed: widget.onSeePro!),
                child: Text.rich(
                  TextSpan(
                    style: AppTypeScale.small.copyWith(
                      color: AppColors.foreground,
                    ),
                    children: [
                      TextSpan(
                        text: 'Free plans have up to ${limits.maxDays} days. ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text:
                            'Pro plans go up to '
                            '${PlanLimits.proTier.maxDays}.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTypeScale.small.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 16),
            if (missing != null) ...[
              Text(
                missing,
                textAlign: TextAlign.center,
                style: AppTypeScale.small,
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                  // Saving keeps the blue; a form that isn't complete greys.
                  disabledBackgroundColor: saving
                      ? AppColors.accent
                      : AppColors.segmentedTrack,
                  disabledForegroundColor: AppColors.faintForeground,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: saving || missing != null ? null : _create,
                child: saving
                    ? const AppProgressIndicator(color: Colors.white)
                    : Text(
                        atFreeLimit ? 'Create $_days-day plan' : 'Create plan',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
