import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_media_picker.dart';
import '../../../design/app_colors.dart';
import '../application/photo_encoder.dart';
import '../application/place_photos_providers.dart';
import '../domain/encoded_photo.dart';
import '../domain/photo_submission.dart';
import 'place_photo_sheet_parts.dart';

/// What the submit sheet ended with.
enum PhotoSheetResult { sent, chooseUsername }

/// Opens the submit sheet. [needsUsername] opens it on the "choose a
/// username first" step instead of the picker.
Future<PhotoSheetResult?> showPlacePhotoSubmitSheet(
  BuildContext context, {
  required String placeId,
  bool needsUsername = false,
}) => showModalBottomSheet<PhotoSheetResult>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.white,
  barrierColor: AppColors.scrim,
  showDragHandle: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) =>
      PlacePhotoSubmitSheet(placeId: placeId, needsUsername: needsUsername),
);

enum _Step { need, choose, preview, sent }

class PlacePhotoSubmitSheet extends ConsumerStatefulWidget {
  const PlacePhotoSubmitSheet({
    super.key,
    required this.placeId,
    this.needsUsername = false,
  });

  final String placeId;
  final bool needsUsername;

  static const consent =
      'I took this photo and allow Kaunti47 to show it in the app, '
      'credited to my username.';

  @override
  ConsumerState<PlacePhotoSubmitSheet> createState() => _SheetState();
}

class _SheetState extends ConsumerState<PlacePhotoSubmitSheet> {
  final _caption = TextEditingController();
  late _Step _step = widget.needsUsername ? _Step.need : _Step.choose;
  EncodedPhoto? _photo;
  bool _agreed = false;
  bool _busy = false;
  PhotoSubmitFailure? _refusal;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _close([PhotoSheetResult? result]) => Navigator.of(context).pop(result);

  Future<void> _pick(AppImageSource source) async {
    setState(() {
      _busy = true;
      _refusal = null;
    });
    try {
      final picked = await AppMediaPicker.pickImage(source: source);
      if (picked == null) return;
      final encoded = await encodePhoto(await picked.readAsBytes());
      if (!mounted) return;
      final tooSmall = encoded.width < 800 && encoded.height < 800;
      setState(() {
        _photo = encoded;
        _step = _Step.preview;
        _refusal = tooSmall
            ? PhotoSubmitFailure.fromServer('image_too_small')
            : null;
      });
    } on UnreadablePhoto {
      _fail("Couldn't read that photo.");
    } on Object {
      _fail("Couldn't open that photo.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _refusal = PhotoSubmitFailure('local', message));
  }

  Future<void> _send() async {
    final photo = _photo;
    final repository = ref.read(placePhotosRepositoryProvider);
    if (photo == null || repository == null || !_agreed || _busy) return;
    setState(() {
      _busy = true;
      _refusal = null;
    });
    try {
      await repository.submit(
        placeId: widget.placeId,
        photo: photo,
        caption: _caption.text,
      );
      if (mounted) setState(() => _step = _Step.sent);
    } on PhotoSubmitFailure catch (e) {
      if (mounted) setState(() => _refusal = e);
    } on Object {
      _fail("Couldn't send your photo. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _chooseAnother() => setState(() {
    _photo = null;
    _refusal = null;
    _step = _Step.choose;
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 18,
          children: switch (_step) {
            _Step.need => _need(),
            _Step.choose => _choose(),
            _Step.preview => _preview(),
            _Step.sent => _sent(),
          },
        ),
      ),
    );
  }

  List<Widget> _need() => [
    const SheetHeading(
      'Choose a username first',
      'Your photo is credited to your username, never your real name.',
    ),
    SheetPillButton(
      label: 'Choose a username',
      onPressed: () => _close(PhotoSheetResult.chooseUsername),
    ),
    TextButton(
      onPressed: _close,
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      child: const Text('Not now'),
    ),
  ];

  List<Widget> _choose() {
    final handle = ref.watch(myPhotoHandleProvider).value;
    final credit = handle == null ? '' : ' "Photo by @$handle".';
    return [
      SheetHeading(
        'Add a photo',
        "We check every photo before it appears. Once it's live, it shows "
            'as$credit',
      ),
      Row(
        spacing: 10,
        children: [
          Expanded(
            child: SheetSourceButton(
              icon: Icons.photo_camera_outlined,
              label: 'Camera',
              enabled: !_busy,
              onPressed: () => _pick(AppImageSource.camera),
            ),
          ),
          Expanded(
            child: SheetSourceButton(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              enabled: !_busy,
              onPressed: () => _pick(AppImageSource.gallery),
            ),
          ),
        ],
      ),
      if (_refusal != null) SheetRefusal(_refusal!.message),
      const Text(
        'At least 800 px on the long side. Up to 2 waiting per place.',
        style: TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: 12,
          height: 1.45,
          color: AppColors.mutedForeground,
        ),
      ),
    ];
  }

  List<Widget> _preview() {
    final photo = _photo!;
    final refusal = _refusal;
    final another = refusal?.needsAnotherPhoto ?? false;
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Add a photo', style: AppTypeScale.sectionTitle),
          TextButton(
            onPressed: _busy ? null : _chooseAnother,
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Change'),
          ),
        ],
      ),
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          photo.thumb,
          height: 176,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      TextField(
        controller: _caption,
        maxLength: 140,
        enabled: !_busy,
        decoration: const InputDecoration(
          labelText: 'Caption (optional)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      SheetConsentRow(
        checked: _agreed,
        text: PlacePhotoSubmitSheet.consent,
        onChanged: _busy ? null : (v) => setState(() => _agreed = v),
      ),
      if (refusal != null) SheetRefusal(refusal.message),
      if (_busy)
        const SheetSendingBar()
      else if (refusal != null)
        SheetPillButton(
          label: refusal.actionLabel,
          soft: another,
          onPressed: another
              ? _chooseAnother
              : refusal.code == PhotoSubmitFailure.needsUsername
              ? () => _close(PhotoSheetResult.chooseUsername)
              : _close,
        )
      else
        SheetPillButton(
          label: 'Send for review',
          enabled: _agreed,
          onPressed: _send,
        ),
    ];
  }

  List<Widget> _sent() => [
    const SheetSentBody(),
    SheetPillButton(
      label: 'Done',
      onPressed: () => _close(PhotoSheetResult.sent),
    ),
  ];
}
