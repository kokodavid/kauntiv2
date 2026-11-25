part of 'passport_share_sheet.dart';

mixin _PassportShareSheetContent
    on _PassportShareSheetStateBase, _PassportShareSheetActions {
  @override
  Widget build(BuildContext context) {
    final paper = _style == PassportShareStyle.passport;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Share your Passport',
                      style: AppTextStyles.confirmSheetTitle,
                    ),
                  ),
                  _CloseButton(onTap: () => Navigator.of(context).maybePop()),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: _ScaledCard(
                  card: _card(),
                  height: _PassportShareSheetStateBase._previewHeight,
                  radius: 20,
                ),
              ),
              const SizedBox(height: 18),
              const Text('Style', style: _Styles.heading),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StyleTile(
                      card: _card(style: PassportShareStyle.passport),
                      title: 'Passport',
                      subtitle: 'Paper look, like your Passport card',
                      selected: paper,
                      onTap: () => _pickStyle(PassportShareStyle.passport),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StyleTile(
                      card: _card(style: PassportShareStyle.photo),
                      title: 'Photo',
                      subtitle: _photo == null
                          ? 'Add a photo from your phone'
                          : 'Your map over your photo',
                      selected: !paper,
                      onTap: () => _pickStyle(PassportShareStyle.photo),
                    ),
                  ),
                ],
              ),
              if (!paper) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Change photo'),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Text('Show on image', style: _Styles.heading),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_hasName)
                    AppChoicePill(
                      label: 'Name',
                      icon: Icons.person_outline_rounded,
                      selected: _showName,
                      onTap: () => setState(() => _showName = !_showName),
                    ),
                  AppChoicePill(
                    label: '@${widget.username}',
                    icon: Icons.alternate_email_rounded,
                    selected: _showUsername,
                    onTap: () => setState(() => _showUsername = !_showUsername),
                  ),
                  if (paper)
                    AppChoicePill(
                      label: 'Background art',
                      icon: Icons.landscape_outlined,
                      selected: _showArt,
                      onTap: () => setState(() => _showArt = !_showArt),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              AppShareActionRow(
                buttonKey: _shareButtonKey,
                saving: _saving,
                sharing: _sharing,
                sharingInstagram: _sharingInstagram,
                instagramAvailable: _instagramAvailable,
                onSave: _saveToPhotos,
                onShareInstagram: _shareToInstagram,
                onShare: _share,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
