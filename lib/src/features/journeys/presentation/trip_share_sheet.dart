import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_instagram_stories.dart';
import '../../../core/services/app_media_picker.dart';
import '../../../core/services/app_share.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../core/widgets/app_glyph_icon.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../services/app_logger.dart';
import '../../auth/application/auth_providers.dart';
import '../application/journey_cloud_providers.dart';
import '../application/journey_views.dart';
import '../application/trip_share_card_cache_provider.dart';
import '../domain/journey_media_capture.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';
import 'trip_share_card.dart';
import 'trip_share_card_renderer.dart';

part 'trip_share_sheet_shell.dart';
part 'trip_share_sheet_actions.dart';
part 'trip_share_sheet_content.dart';
part 'trip_share_sheet_close_button.dart';
part 'trip_share_sheet_shape_toggle.dart';
part 'trip_share_sheet_shape_chip.dart';
part 'trip_share_sheet_photo_strip.dart';
part 'trip_share_sheet_photo_thumb.dart';
part 'trip_share_sheet_from_phone_tile.dart';
part 'trip_share_sheet_styles.dart';

abstract class _TripShareSheetStateBase extends ConsumerState<_TripShareSheet> {
  static const _logger = AppLogger.journeys();

  /// Fixed regardless of [_shape] - Feed's preview is 296x370 (its own
  /// 4:5 ratio at this height), Story's is narrower at the same height
  /// (9:16 is taller/narrower, not shorter) - rather than the old
  /// full-width preview, which left no room below it for the photo
  /// strip and Share button on the taller Story shape.
  static const _previewHeight = 370.0;

  _ShareShape _shape = _ShareShape.feed;

  /// The Trip's own synced photo the user tapped in the strip, if any -
  /// cleared by picking one from the phone instead. Null with
  /// [_localPhoto] also null means "no explicit choice yet", which
  /// falls back to the Trip's resolved cover photo (its chosen cover,
  /// or earliest synced photo).
  String? _selectedMediaId;

  /// Picked via "From phone"; overrides [_selectedMediaId] when set -
  /// only one of the two is ever the active choice.
  Uint8List? _localPhoto;

  var _sharing = false;
  var _saving = false;
  var _sharingInstagram = false;

  /// Whether to show the Instagram Stories button at all - only once
  /// we've confirmed Instagram is actually installed and the device can
  /// open its Stories scheme ([AppInstagramStories.isAvailable]); a
  /// button that opens nothing is worse than no button.
  var _instagramAvailable = false;

  /// Anchors the iOS share popover to the Share button itself. iOS
  /// requires `sharePositionOrigin` to be a real, non-zero rect in the
  /// presenting view's coordinate space - passing nothing (as this used
  /// to) throws a PlatformException ("sharePositionOrigin: argument must
  /// be set") rather than falling back to some default position, which
  /// is what was behind every real-device Share tap failing with
  /// "Couldn't prepare that image." Android and iPhone both ignore this
  /// rect outside of an iPad popover, so it's harmless there.
  final _shareButtonKey = GlobalKey();
}

class _TripShareSheetState extends _TripShareSheetStateBase
    with _TripShareSheetActions, _TripShareSheetContent {}
