import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../application/badges_providers.dart';
import '../domain/passport_book.dart';
import '../domain/passport_rules.dart';
import 'passport_callbacks.dart';
import 'passport_county_skeleton.dart';
import 'passport_county_view.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// The county pages, 001 Mombasa to 047 Nairobi by official code. Swipe
/// sideways or use the arrows to turn pages; back returns to the landing.
class PassportCountyScreen extends ConsumerStatefulWidget {
  const PassportCountyScreen({
    super.key,
    required this.initialCode,
    this.onOpenCounty,
  });

  final int initialCode;
  final PassportOpenCounty? onOpenCounty;

  /// Pushes the pages over everything, tab bar included, so the page has
  /// the whole screen to itself.
  static Future<void> open(
    BuildContext context, {
    required int code,
    PassportOpenCounty? onOpenCounty,
  }) => Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PassportCountyScreen(initialCode: code, onOpenCounty: onOpenCounty),
    ),
  );

  @override
  ConsumerState<PassportCountyScreen> createState() =>
      _PassportCountyScreenState();
}

class _PassportCountyScreenState extends ConsumerState<PassportCountyScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialCode - 1,
  );
  late int _index = widget.initialCode - 1;

  static const _turn = Duration(milliseconds: 330);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) =>
      _pages.animateToPage(index, duration: _turn, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final collection = ref.watch(badgeCollectionProvider).value;
    final book = collection == null
        ? null
        : PassportBook.fromCollection(collection);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: book == null
            ? Column(
                children: [
                  _TopBar(
                    code: widget.initialCode,
                    total: CountyPaths.all.length,
                    onPrevious: null,
                    onNext: null,
                  ),
                  const Expanded(child: PassportCountyPageSkeleton()),
                ],
              )
            : Column(
                children: [
                  _TopBar(
                    code: _index + 1,
                    total: book.total,
                    onPrevious: _index > 0 ? () => _go(_index - 1) : null,
                    onNext: _index < book.total - 1
                        ? () => _go(_index + 1)
                        : null,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: book.total,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => PassportCountyView(
                        county: book.counties[i],
                        rules: PassportRules.standard.withVerification(
                          live: book.checkInsLive,
                        ),
                        onOpenCounty: widget.onOpenCounty,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.code,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int code;
  final int total;

  /// Null at the first and last page, which greys that arrow.
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final page = code.toString().padLeft(3, '0');
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const StadiumBorder(
              side: BorderSide(color: AppColors.cardBorder),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_left_rounded),
                      Text(
                        'Passport',
                        style: passportText(14, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$page / ${total.toString().padLeft(3, '0')}',
              textAlign: TextAlign.center,
              style: passportText(
                12,
                weight: FontWeight.w600,
                color: PassportInk.tertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          _ArrowButton(
            icon: Icons.chevron_left_rounded,
            label: 'Previous county',
            onTap: onPrevious,
          ),
          const SizedBox(width: 8),
          _ArrowButton(
            icon: Icons.chevron_right_rounded,
            label: 'Next county',
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.cardBorder),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 40,
            child: Icon(
              icon,
              size: 22,
              color: onTap == null ? PassportInk.disabled : PassportInk.primary,
            ),
          ),
        ),
      ),
    );
  }
}
