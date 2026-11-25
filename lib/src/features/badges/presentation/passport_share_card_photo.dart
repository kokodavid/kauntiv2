part of 'passport_share_card.dart';

/// Photo style: the map and count over the traveller's own photo, with the
/// same top and bottom darkening as the Trip share card so the text reads
/// on any picture. The photo itself is never dimmed all over.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.book,
    required this.username,
    required this.name,
    required this.photo,
  });

  final PassportBook book;

  /// Null when the traveller turned it off.
  final String? username;
  final String? name;
  final ImageProvider? photo;

  static const _white80 = Color(0xCCFFFFFF);

  @override
  Widget build(BuildContext context) {
    final white = passportText(
      15,
      weight: FontWeight.w700,
      color: Colors.white,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF4A5853)),
        if (photo != null)
          Image(
            image: photo!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 190,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x73000000), Color(0x00000000)],
              ),
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xE6000000), Color(0xB8000000), Color(0x00000000)],
              stops: [0, 0.42, 0.70],
            ),
          ),
        ),
        Padding(
          padding: PassportShareCard.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppShareWatermark(textStyle: white),
                  const Spacer(),
                  const _Pill(onPhoto: true),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 155,
                    height: 196,
                    child: PassportKenyaMap(
                      levels: _levels(book),
                      onPhoto: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _Legend(book: book, onPhoto: true),
                    ),
                  ),
                ],
              ),
              if (name != null) ...[
                const SizedBox(height: 18),
                Text(
                  name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: passportText(
                    15,
                    weight: FontWeight.w600,
                    color: _white80,
                  ),
                ),
                const SizedBox(height: 6),
              ] else
                const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${book.claimedCount}',
                    style: passportText(
                      44,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'of ${book.total} counties explored',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: passportText(
                        20,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PassportLevelBar(
                levels: book.barLevels,
                height: 18,
                offHeight: 11,
                onPhoto: true,
              ),
              const SizedBox(height: 14),
              _Footer(username: username, onPhoto: true),
            ],
          ),
        ),
      ],
    );
  }
}
