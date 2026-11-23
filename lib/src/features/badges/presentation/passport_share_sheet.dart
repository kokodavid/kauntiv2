import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_instagram_stories.dart';
import '../../../core/services/app_media_picker.dart';
import '../../../core/services/app_share.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../core/widgets/app_share_action_row.dart';
import '../../../core/widgets/share_card_renderer.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../services/app_logger.dart';
import '../domain/passport_book.dart';
import 'passport_share_card.dart';
import 'passport_stamp_art.dart';
import 'passport_traveller_card.dart';

part 'passport_share_sheet_actions.dart';
part 'passport_share_sheet_content.dart';
part 'passport_share_sheet_parts.dart';

/// "Share your Passport" (Claude-Design "Passport Share Card", share
/// sheet): a live preview, the two styles, the name and background-art
/// switches, and Save / Stories / Share. The @username is always on the
/// image; only the display name can be hidden.
void showPassportShareSheet(
  BuildContext context, {
  required PassportBook book,
  required String username,
  String? holderName,
}) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: AppColors.sheetBarrier,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _PassportShareSheet(
        book: book,
        username: username,
        holderName: holderName,
      ),
    ),
  );
}

class _PassportShareSheet extends StatefulWidget {
  const _PassportShareSheet({
    required this.book,
    required this.username,
    this.holderName,
  });

  final PassportBook book;
  final String username;
  final String? holderName;

  @override
  State<_PassportShareSheet> createState() => _PassportShareSheetState();
}

abstract class _PassportShareSheetStateBase extends State<_PassportShareSheet> {
  static const _logger = AppLogger.badges();

  /// The preview's fixed height; its width follows the 9:16 card.
  static const _previewHeight = 370.0;

  var _style = PassportShareStyle.passport;
  late var _showName = _hasName;
  var _showArt = true;

  /// The photo picked from the phone, for the Photo style.
  ImageProvider? _photo;

  var _sharing = false;
  var _saving = false;
  var _sharingInstagram = false;

  /// Shown only once Instagram is confirmed to accept a Stories handoff.
  var _instagramAvailable = false;

  /// Anchors the iOS share popover to the Share button.
  final _shareButtonKey = GlobalKey();

  bool get _hasName => widget.holderName?.trim().isNotEmpty ?? false;

  PassportShareCard _card({PassportShareStyle? style}) => PassportShareCard(
    style: style ?? _style,
    book: widget.book,
    username: widget.username,
    holderName: widget.holderName,
    showName: _showName,
    showArt: _showArt,
    photo: _photo,
  );
}

class _PassportShareSheetState extends _PassportShareSheetStateBase
    with _PassportShareSheetActions, _PassportShareSheetContent {}
