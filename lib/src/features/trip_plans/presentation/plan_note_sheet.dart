import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/place_type.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_counties.dart';
import '../domain/plan_day.dart';
import 'plan_sheet_frame.dart';
import 'plan_stop_row.dart';

const _maxLength = 200;

/// The note on a stop (design 3e), in a sheet: which stop it is for, a
/// multi-line field with a count, and Save note (plus Remove when there is
/// one already). Returns the text; an empty string removes the note; null
/// when cancelled.
Future<String?> showPlanNoteSheet(
  BuildContext context, {
  required PlanStop stop,
  required int number,
  required Color color,
  required String dayLabel,
  PlanCountyStatus? countyStatus,
}) => showPlanSheet<String>(
  context,
  (_) => _NoteSheet(
    stop: stop,
    number: number,
    color: color,
    dayLabel: dayLabel,
    countyStatus: countyStatus,
  ),
);

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({
    required this.stop,
    required this.number,
    required this.color,
    required this.dayLabel,
    required this.countyStatus,
  });

  final PlanStop stop;
  final int number;
  final Color color;
  final String dayLabel;
  final PlanCountyStatus? countyStatus;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _controller = TextEditingController(text: widget.stop.note);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hadNote => widget.stop.note != null;

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
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text('Note', style: AppTypeScale.sectionTitle),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.mutedForeground,
                  textStyle: AppTypeScale.itemTitle,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _StopCard(
            stop: widget.stop,
            number: widget.number,
            color: widget.color,
            dayLabel: widget.dayLabel,
            status: widget.countyStatus,
          ),
          const SizedBox(height: 12),
          _Field(controller: _controller),
          const SizedBox(height: 14),
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, _) {
              final text = value.text.trim();
              return Row(
                children: [
                  if (_hadNote) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.exploreBorder),
                        textStyle: AppTypeScale.action.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        minimumSize: const Size(96, 44),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.of(context).pop(''),
                      child: const Text('Remove'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.accentForeground,
                        textStyle: AppTypeScale.action.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        minimumSize: const Size.fromHeight(44),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: text.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(text),
                      child: const Text('Save note'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// The stop the note is for: its number, name, type, county and day.
class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.stop,
    required this.number,
    required this.color,
    required this.dayLabel,
    required this.status,
  });

  final PlanStop stop;
  final int number;
  final Color color;
  final String dayLabel;
  final PlanCountyStatus? status;

  @override
  Widget build(BuildContext context) {
    final place = stop.place;
    final kind = place.type.isEmpty ? null : PlaceType.of(place.type).label;
    final county = CountyPaths.byCode[place.countyCode]?.name;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: AppTypeScale.action.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: AppTypeScale.itemTitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (kind != null) PlanTypeChip(kind),
                    if (county != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlanCountyDot(status),
                          const SizedBox(width: 5),
                          Text(county, style: AppTypeScale.small),
                        ],
                      ),
                    ],
                    Text('· $dayLabel', style: AppTypeScale.meta),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The note field: an accent border while typing, and "79 / 200" inside.
class _Field extends StatelessWidget {
  const _Field({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: true,
    minLines: 4,
    maxLines: 6,
    maxLength: _maxLength,
    textCapitalization: TextCapitalization.sentences,
    style: AppTypeScale.itemTitle.copyWith(fontWeight: FontWeight.w400),
    decoration: InputDecoration(
      hintText: 'Book ahead, bring a jacket…',
      hintStyle: AppTypeScale.itemTitle.copyWith(
        fontWeight: FontWeight.w400,
        color: AppColors.faintForeground,
      ),
      counterStyle: AppTypeScale.small,
      contentPadding: const EdgeInsets.all(14),
      border: _border(AppColors.inputBorder),
      enabledBorder: _border(AppColors.inputBorder),
      focusedBorder: _border(AppColors.accent, width: 1.5),
    ),
  );

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
}
