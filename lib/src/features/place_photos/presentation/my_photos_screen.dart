import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../design/app_colors.dart';
import '../application/place_photos_providers.dart';
import '../domain/photo_submission.dart';
import 'my_photos_empty.dart';
import 'my_photos_parts.dart';

enum _Filter { all, pending, approved, rejected }

/// Profile › My photos: every photo the user has sent, across all places,
/// grouped by where it stands. Opening it marks the reviewed ones as seen;
/// the blue dots on the rows that were new stay for this visit.
class MyPhotosScreen extends ConsumerStatefulWidget {
  const MyPhotosScreen({super.key, required this.onOpenPlace});

  final void Function(String placeId) onOpenPlace;

  @override
  ConsumerState<MyPhotosScreen> createState() => _MyPhotosScreenState();
}

class _MyPhotosScreenState extends ConsumerState<MyPhotosScreen> {
  _Filter _filter = _Filter.all;
  Set<String>? _unseen;

  Future<void> _markSeen() async {
    final repository = ref.read(placePhotosRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.markResultsSeen();
      if (!mounted) return;
      ref
        ..invalidate(unseenPhotoCountProvider)
        ..invalidate(myPlacePhotosProvider);
    } on Object {
      // The dot stays until the next successful visit.
    }
  }

  void _capture(List<PhotoSubmission> all) {
    if (_unseen != null) return;
    _unseen = {for (final s in all) if (s.unseen) s.id};
    if (_unseen!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_markSeen()));
    }
  }

  void _refresh() => ref
    ..invalidate(myPhotosProvider)
    ..invalidate(myPlacePhotosProvider)
    ..invalidate(unseenPhotoCountProvider);

  Future<void> _run(Future<void> Function() action, String failure) async {
    try {
      await action();
      _refresh();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  Future<void> _remove(PhotoSubmission s) async {
    final repository = ref.read(placePhotosRepositoryProvider);
    if (repository == null) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this photo?'),
        content: const Text(
          "It won't be reviewed. You can send it again later.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    await _run(
      () => repository.withdraw(s.id),
      "Couldn't remove that photo. It may already have been reviewed.",
    );
  }

  Future<void> _dismiss(PhotoSubmission s) async {
    final repository = ref.read(placePhotosRepositoryProvider);
    if (repository == null) return;
    await _run(() => repository.dismiss(s.id), "Couldn't clear that photo.");
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myPhotosProvider);
    final all = async.value;
    if (all != null) _capture(all);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  AppBackButton(
                    size: 44,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  const Text('My photos', style: AppTypeScale.sectionTitle),
                ],
              ),
            ),
            Expanded(
              child: all == null
                  ? Center(
                      child: async.hasError
                          ? TextButton(
                              onPressed: () => ref.invalidate(myPhotosProvider),
                              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                              child: const Text(
                                "Couldn't load your photos. Try again.",
                              ),
                            )
                          : const CircularProgressIndicator(),
                    )
                  : all.isEmpty
                  ? const MyPhotosEmpty()
                  : _body(all),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(List<PhotoSubmission> all) {
    final handle = ref.watch(myPhotoHandleProvider).value;
    int count(PhotoSubmissionStatus? s) =>
        s == null ? all.length : all.where((x) => x.status == s).length;
    final filters = [
      (_Filter.all, 'All', count(null)),
      (_Filter.pending, 'Awaiting review', count(PhotoSubmissionStatus.pending)),
      (_Filter.approved, 'Published', count(PhotoSubmissionStatus.approved)),
      (_Filter.rejected, 'Not published', count(PhotoSubmissionStatus.rejected)),
    ];
    const groups = [
      (PhotoSubmissionStatus.pending, _Filter.pending, 'Awaiting review',
          'Waiting for the team', null),
      (PhotoSubmissionStatus.approved, _Filter.approved, 'Published',
          'Shown in the app', null),
      (PhotoSubmissionStatus.rejected, _Filter.rejected, 'Not published',
          'Only you can see these',
          'Not published photos leave this list after 30 days. You can send '
              'another any time.'),
    ];
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            children: [
              for (final (value, label, n) in filters)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: MyPhotosFilterPill(
                    label: label,
                    count: n,
                    selected: _filter == value,
                    onTap: () => setState(() => _filter = value),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              for (final (status, key, title, note, foot) in groups)
                if ((_filter == _Filter.all || _filter == key) &&
                    all.any((s) => s.status == status))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: MyPhotosGroup(
                      title: title,
                      note: note,
                      foot: foot,
                      rows: [for (final s in all) if (s.status == status) s],
                      handle: handle,
                      unseen: _unseen ?? const {},
                      onOpenPlace: widget.onOpenPlace,
                      onRemove: _remove,
                      onDismiss: _dismiss,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
