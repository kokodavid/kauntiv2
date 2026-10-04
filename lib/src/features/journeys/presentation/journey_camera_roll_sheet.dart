import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/camera_roll_matcher.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

part 'journey_camera_roll_sheet_tiles.dart';

/// Lets the user pick which of the camera-roll photos matched to this
/// Trip actually get added, rather than all-or-nothing via "Add to
/// timeline" (Claude-Design "2b" reference's "Choose" action).
///
/// Returns the chosen subset, or null if cancelled.
Future<List<CameraRollMatch>?> showCameraRollMatchPicker(
  BuildContext context,
  List<CameraRollMatch> matches,
) {
  return showModalBottomSheet<List<CameraRollMatch>>(
    context: context,
    // useRootNavigator: true - same fix as this app's other sheets - so
    // this sits above AppShell's floating bottom nav bar.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: AppColors.sheetBarrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _CameraRollMatchPicker(matches: matches),
  );
}

class _CameraRollMatchPicker extends StatefulWidget {
  const _CameraRollMatchPicker({required this.matches});

  final List<CameraRollMatch> matches;

  @override
  State<_CameraRollMatchPicker> createState() => _CameraRollMatchPickerState();
}

class _CameraRollMatchPickerState extends State<_CameraRollMatchPicker> {
  // The displayed list starts as the matches passed in, one entry per
  // cluster - but unlike that list, entries here can be swapped in place
  // when the user picks a different shot from a cluster's alternates, so
  // this needs its own mutable copy rather than reading widget.matches
  // directly.
  late final List<CameraRollMatch> _displayed = [...widget.matches];

  // Every match starts selected: "Choose" is for trimming down an
  // already-relevant set, not building one up from nothing.
  late final Set<CameraRollMatch> _selected = {..._displayed};

  void _toggle(CameraRollMatch match) {
    setState(() {
      if (!_selected.remove(match)) _selected.add(match);
    });
  }

  /// Opens the mini picker for the cluster at [index] and, if the user
  /// picks a different shot than the one currently showing, swaps it in -
  /// keeping the rest of that cluster (including the shot that was just
  /// replaced) as the new representative's alternates, and preserving
  /// whether that slot was selected.
  Future<void> _showAlternates(int index) async {
    final current = _displayed[index];
    final cluster = [current, ...current.alternates];
    final chosen = await showModalBottomSheet<CameraRollMatch>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      barrierColor: AppColors.sheetBarrier,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) =>
          _ClusterAlternativesSheet(cluster: cluster, current: current),
    );
    if (chosen == null || chosen.asset.id == current.asset.id || !mounted) {
      return;
    }
    setState(() {
      final wasSelected = _selected.remove(current);
      final replacement = CameraRollMatch(
        asset: chosen.asset,
        capturedAt: chosen.capturedAt,
        alternates: [
          for (final member in cluster)
            if (member.asset.id != chosen.asset.id) member,
        ],
      );
      _displayed[index] = replacement;
      if (wasSelected) _selected.add(replacement);
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final count = _selected.length;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.trackInactive,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const Text(
                'Choose photos',
                style: AppTextStyles.confirmSheetTitle,
              ),
              const SizedBox(height: 4),
              const Text(
                'Found in your camera roll during this Trip. Tap to '
                'leave one out.',
                style: AppTypeScale.body,
              ),
              const SizedBox(height: 14),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _displayed.length,
                  itemBuilder: (context, index) {
                    final match = _displayed[index];
                    return _MatchThumbnail(
                      match: match,
                      selected: _selected.contains(match),
                      onTap: () => _toggle(match),
                      onShowAlternates: match.alternates.isEmpty
                          ? null
                          : () => _showAlternates(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: count == 0
                      ? null
                      : () => Navigator.of(context).pop(_selected.toList()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.cardBorder,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    count == 0
                        ? 'Add photos'
                        : 'Add $count photo${count == 1 ? '' : 's'}',
                    style: AppTextStyles.confirmSheetButtonLabel,
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
