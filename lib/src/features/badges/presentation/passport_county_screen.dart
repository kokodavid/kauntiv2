import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/badges_providers.dart';
import '../domain/passport_book.dart';
import '../domain/passport_rules.dart';
import 'passport_callbacks.dart';
import 'passport_county_view.dart';
import 'passport_pager.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// The county pages, 001 Mombasa to 047 Nairobi by official code. Swipe
/// sideways or use the pager to turn pages; back returns to the landing.
class PassportCountyScreen extends ConsumerStatefulWidget {
  const PassportCountyScreen({
    super.key,
    required this.initialCode,
    this.onOpenCounty,
  });

  final int initialCode;
  final PassportOpenCounty? onOpenCounty;

  /// Pushes the pages over everything, tab bar included, so the pager has
  /// the bottom of the screen to itself.
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

  void _go(int index) => _pages.animateToPage(
    index,
    duration: _turn,
    curve: Curves.easeOutCubic,
  );

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
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Column(
                    children: [
                      _TopBar(code: _index + 1, total: book.total),
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
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 26 + MediaQuery.viewPaddingOf(context).bottom,
                    child: PassportPager(
                      previous: _index > 0 ? book.counties[_index - 1] : null,
                      next: _index < book.total - 1
                          ? book.counties[_index + 1]
                          : null,
                      code: _index + 1,
                      total: book.total,
                      onPrevious: () => _go(_index - 1),
                      onNext: () => _go(_index + 1),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.code, required this.total});

  final int code;
  final int total;

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
              'PAGE $page / ${total.toString().padLeft(3, '0')}',
              textAlign: TextAlign.center,
              style: passportText(
                12,
                weight: FontWeight.w600,
                color: PassportInk.tertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          // Keeps the title centred against the back pill.
          const SizedBox(width: 96),
        ],
      ),
    );
  }
}
