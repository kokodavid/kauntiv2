part of 'passport_share_card.dart';

/// Passport style: the Traveller card's paper look, stretched to a Story.
class _PaperCard extends StatelessWidget {
  const _PaperCard({
    required this.book,
    required this.username,
    required this.name,
    required this.showArt,
  });

  final PassportBook book;
  final String username;
  final String? name;
  final bool showArt;

  @override
  Widget build(BuildContext context) {
    final latest = book.latestStamp;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEAF3FC), Color(0xFFF4F8FC), Color(0xFFF8F1EA)],
            ),
          ),
        ),
        if (showArt)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 340,
            // Fades in from nothing at the top so the art never cuts off
            // in a hard line behind the map.
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xFF000000)],
                stops: [0, 0.38],
              ).createShader(bounds),
              child: Image.asset(
                PassportTravellerCard.artAsset,
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.44),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        // A soft wash keeps the text readable over the fine line work.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB3FFFFFF), Color(0x4DFFFFFF), Color(0x00FFFFFF)],
              stops: [0, 0.55, 1],
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
                  AppShareWatermark(
                    textStyle: passportText(15, weight: FontWeight.w700),
                  ),
                  const Spacer(),
                  const _Pill(label: 'MY PASSPORT', onPhoto: false),
                ],
              ),
              const SizedBox(height: 26),
              _Holder(
                username: username,
                name: name,
                firstStampAt: book.firstStampAt,
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Count(book: book),
                          const SizedBox(height: 10),
                          _Legend(book: book),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 167,
                    height: 212,
                    child: PassportKenyaMap(levels: _levels(book)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PassportLevelBar(levels: book.barLevels),
              const Spacer(),
              Row(
                children: [
                  if (latest != null)
                    Flexible(child: _LatestStamp(county: latest))
                  else
                    const Spacer(),
                  const SizedBox(width: 10),
                  Text(
                    'kaunti47.com',
                    style: passportText(
                      12,
                      weight: FontWeight.w600,
                      color: PassportInk.blueDeep,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Map<int, PassportLevel> _levels(PassportBook book) => {
  for (final county in book.counties) county.code: county.level,
};

/// TRAVELLER, then the name and @username. With the name hidden the
/// @username takes its place, smaller than the name would be.
class _Holder extends StatelessWidget {
  const _Holder({
    required this.username,
    required this.name,
    required this.firstStampAt,
  });

  final String username;
  final String? name;
  final DateTime? firstStampAt;

  @override
  Widget build(BuildContext context) {
    final first = firstStampAt == null
        ? null
        : 'First stamp ${passportDate(firstStampAt!)}';
    final secondary = passportText(13, color: PassportInk.secondary);
    final handle = passportText(
      name == null ? 18 : 13,
      weight: FontWeight.w700,
      color: PassportInk.blueDeep,
      height: name == null ? 1.2 : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRAVELLER',
          style: passportText(
            10.5,
            weight: FontWeight.w600,
            color: PassportInk.tertiary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 5),
        if (name != null) ...[
          Text(
            name!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: passportText(
              25,
              weight: FontWeight.w700,
              height: 1.12,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              text: '@$username',
              style: handle,
              children: [
                if (first != null) TextSpan(text: ' · $first', style: secondary),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ] else ...[
          Text(
            '@$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: handle,
          ),
          if (first != null) ...[
            const SizedBox(height: 5),
            Text(first, style: secondary),
          ],
        ],
      ],
    );
  }
}

/// "11 / 47" and COUNTIES EXPLORED.
class _Count extends StatelessWidget {
  const _Count({required this.book});

  final PassportBook book;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          text: '${book.claimedCount}',
          style: passportText(
            60,
            weight: FontWeight.w800,
            color: AppColors.accent,
            height: 1,
            letterSpacing: -1.5,
          ),
          children: [
            TextSpan(
              text: ' / ${book.total}',
              style: passportText(
                24,
                weight: FontWeight.w500,
                color: PassportInk.tertiary,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'COUNTIES EXPLORED',
        style: passportText(
          10,
          weight: FontWeight.w600,
          color: PassportInk.tertiary,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}
