import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../data/camera_roll_matcher.dart';

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
  // Every match starts selected: "Choose" is for trimming down an
  // already-relevant set, not building one up from nothing.
  late final Set<CameraRollMatch> _selected = {...widget.matches};

  void _toggle(CameraRollMatch match) {
    setState(() {
      if (!_selected.remove(match)) _selected.add(match);
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
              Text('Choose photos', style: AppTextStyles.confirmSheetTitle),
              const SizedBox(height: 4),
              Text(
                'Found in your camera roll during this Trip. Tap to '
                'leave one out.',
                style: AppTypeScale.body,
              ),
              const SizedBox(height: 14),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                  itemCount: widget.matches.length,
                  itemBuilder: (context, index) {
                    final match = widget.matches[index];
                    return _MatchThumbnail(
                      match: match,
                      selected: _selected.contains(match),
                      onTap: () => _toggle(match),
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

class _MatchThumbnail extends StatelessWidget {
  const _MatchThumbnail({
    required this.match,
    required this.selected,
    required this.onTap,
  });

  final CameraRollMatch match;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FutureBuilder<Uint8List?>(
              future: match.asset.thumbnailDataWithSize(
                const ThumbnailSize.square(200),
              ),
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null) {
                  return const ColoredBox(color: AppColors.lockedFill);
                }
                return Image.memory(bytes, fit: BoxFit.cover);
              },
            ),
          ),
          if (!selected)
            ColoredBox(color: Colors.white.withValues(alpha: 0.55)),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.accent : Colors.white,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.cardBorder,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
