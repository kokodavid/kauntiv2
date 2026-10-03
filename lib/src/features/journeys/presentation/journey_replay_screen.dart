import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_glyph_icon.dart';
import '../../../design/app_colors.dart';
import '../application/journey_key_moments.dart';
import '../application/journey_views.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_point.dart';
import '../domain/journey_replay.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';
import 'journey_replay_controls.dart';
import 'journey_replay_playback_bar.dart';
import 'journey_replay_stat_bar.dart';
import 'journey_replay_timeline.dart';
import 'journey_route_map.dart';
import 'trip_share_sheet.dart';

part 'journey_replay_screen_shell.dart';
part 'journey_replay_screen_playback.dart';

abstract class _PlayerStateBase extends State<_Player>
    with TickerProviderStateMixin {
  late final JourneyReplayTrack _track = JourneyReplayTrack(widget.route);
  Duration _lastTick = Duration.zero;

  /// A one-shot fade/slide as the replay screen first appears, rather than
  /// the map and timeline just popping in.
  late final AnimationController _enterController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();
  late final CurvedAnimation _enterCurve = CurvedAnimation(
    parent: _enterController,
    curve: Curves.easeOut,
  );

  /// Position along the track in points, fractional between them. This
  /// changes up to 60 times a second during playback or scrubbing, so only
  /// the map marker and scrubber listen to this frame driver; the timeline
  /// rebuilds only for real state changes such as play/pause or key moments.
  late final AnimationController _positionController;
  double get _position => _positionController.value;
  set _position(double value) => _positionController.value = value;

  JourneyReplaySpeed _speed = JourneyReplaySpeed.x1;

  /// Replay has been started, scrubbed or jumped to; false shows the
  /// whole route.
  bool _active = false;

  /// The key moments replay is currently paused at, lighting up in the
  /// timeline; empty while it plays.
  List<JourneyMoment> _showing = const [];

  /// The played part, rebuilt only when the replay passes a point.
  JourneyRoute? _played;
  int _playedIndex = -1;
}

class _PlayerState extends _PlayerStateBase with _JourneyReplayPlayback {}
