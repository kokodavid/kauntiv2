import 'package:flutter/material.dart';

import '../domain/passport_county.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// The floating pager under a county page: the neighbours by code and a
/// position bar. Each end hides its own button.
class PassportPager extends StatelessWidget {
  const PassportPager({
    super.key,
    required this.previous,
    required this.next,
    required this.code,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final PassportCounty? previous;
  final PassportCounty? next;
  final int code;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: previous == null
                ? const SizedBox.shrink()
                : _Side(county: previous!, leading: true, onTap: onPrevious),
          ),
          Container(
            width: 44,
            height: 4,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: PassportInk.track,
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44 * code / total,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: next == null
                ? const SizedBox.shrink()
                : _Side(county: next!, leading: false, onTap: onNext),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.county,
    required this.leading,
    required this.onTap,
  });

  final PassportCounty county;
  final bool leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: leading
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          county.number,
          style: passportText(
            10,
            weight: FontWeight.w600,
            color: PassportInk.tertiary,
          ),
        ),
        Text(
          county.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: passportText(13, weight: FontWeight.w600),
        ),
      ],
    );
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: leading
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (leading) const Icon(Icons.chevron_left_rounded, size: 20),
            Flexible(child: label),
            if (!leading) const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
