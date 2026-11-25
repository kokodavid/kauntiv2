part of 'passport_share_sheet.dart';

abstract final class _Styles {
  static const heading = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.mutedForeground,
  );
  static const tileTitle = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.buttonForeground,
  );
  static const tileSubtitle = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12,
    height: 1.35,
    color: AppColors.mutedForeground,
  );
}

/// A share card drawn at its full logical size and scaled down to
/// [height]. The OverflowBox lets the card lay out at its real 360x640
/// (tight constraints would otherwise squash it); Transform.scale only
/// shrinks the painted result.
class _ScaledCard extends StatelessWidget {
  const _ScaledCard({
    required this.card,
    required this.height,
    required this.radius,
  });

  final PassportShareCard card;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scale = height / card.height;
    return SizedBox(
      width: card.width * scale,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: OverflowBox(
            minWidth: card.width,
            maxWidth: card.width,
            minHeight: card.height,
            maxHeight: card.height,
            alignment: Alignment.topLeft,
            child: card,
          ),
        ),
      ),
    );
  }
}

/// One style choice: a small preview, its name and a line about it.
class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.card,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final PassportShareCard card;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$title style',
    child: Material(
      color: selected ? const Color(0xFFF0F7FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.cardBorder,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ExcludeSemantics(
                child: _ScaledCard(card: card, height: 96, radius: 8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _Styles.tileTitle),
                    const SizedBox(height: 3),
                    Text(subtitle, style: _Styles.tileSubtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Close',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.lockedFill,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 16,
          color: AppColors.mutedForeground,
        ),
      ),
    ),
  );
}
