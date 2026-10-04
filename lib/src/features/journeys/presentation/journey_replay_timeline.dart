import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/design/app_type_scale.dart';
import '../../../core/services/camera_roll_matcher.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/journey_key_moments.dart';
import '../domain/journey_county_moment_facts.dart';
import '../domain/journey_media_capture.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_point.dart';
import '../domain/journey_summary.dart';
import 'journey_camera_roll_sheet.dart';
import 'journey_moment_row.dart';
import 'journey_trip_media_actions.dart';

part 'journey_replay_timeline_empty_timeline_body.dart';
part 'journey_replay_timeline_add_moments_card.dart';
part 'journey_replay_timeline_inline_camera_roll_suggestion.dart';
part 'journey_replay_timeline_camera_roll_match_card.dart';
part 'journey_replay_timeline_thumbnail_tile.dart';
part 'journey_replay_timeline_actions.dart';
part 'journey_replay_timeline_state.dart';

/// The scrollable story below the map: the Trip's date and title, then
/// every key moment in order. Replay drives which one is "current"; the
/// timeline brings it into view instead of popping a separate card.
class JourneyReplayTimeline extends ConsumerStatefulWidget {
  const JourneyReplayTimeline({
    super.key,
    required this.summary,
    required this.points,
    required this.moments,
    required this.currentMoments,
    required this.onJumpTo,
    this.onOpenCounty,
    this.momentsLoading = false,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  final JourneySummary summary;
  final List<JourneyPoint> points;
  final List<JourneyMoment> moments;

  /// True while `journeyMomentsProvider` is still resolving its first
  /// value - shows a spinner instead of the empty-timeline card, so a
  /// Trip that simply hasn't finished computing its moments isn't
  /// briefly mistaken for one with none.
  final bool momentsLoading;

  /// The moment(s) replay is currently paused at, if any ("lit up").
  final List<JourneyMoment> currentMoments;

  /// Jumps the replay to a moment's point in the route.
  final ValueChanged<int> onJumpTo;
  final ValueChanged<int>? onOpenCounty;

  final double topPadding;
  final double bottomPadding;

  @override
  ConsumerState<JourneyReplayTimeline> createState() =>
      _JourneyReplayTimelineState();
}

/// How the camera-roll auto-match (Claude-Design "2b" reference) stands
/// for this Trip. [idle] only until the first post-frame check runs;
/// [noAccess] covers both "never asked" and "denied" - the empty-timeline
/// card treats them the same (offer to ask), and [CameraRollMatcher]
/// itself is what actually distinguishes them when asked to request.
enum _CameraRollStatus { idle, noAccess, noMatches, matchesFound }

class _CameraRollScan {
  const _CameraRollScan(this.status, [this.matches = const []]);

  final _CameraRollStatus status;
  final List<CameraRollMatch> matches;
}

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// "THU 1 OCT · 7:40 – 8:16 AM" (or "...7:40 AM – 1:16 PM" across noon).
String _dateRange(DateTime startedAt, DateTime endedAt) {
  final start = startedAt.toLocal();
  final end = endedAt.toLocal();
  final date =
      '${_weekdays[start.weekday - 1]} ${start.day} ${_months[start.month - 1]}';
  final startPeriod = start.hour < 12 ? 'AM' : 'PM';
  final endPeriod = end.hour < 12 ? 'AM' : 'PM';
  final endTime = '${_hhmm(end)} $endPeriod';
  final range = startPeriod == endPeriod
      ? '${_hhmm(start)} – $endTime'
      : '${_hhmm(start)} $startPeriod – $endTime';
  return '$date · $range';
}

String _hhmm(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
