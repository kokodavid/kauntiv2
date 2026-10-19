import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bottom_nav_hidden_provider.dart';
import '../../../core/widgets/offline_screen.dart';
import '../../../design/app_colors.dart';
import '../../profile/application/public_profile_providers.dart';
import '../application/badges_providers.dart';
import '../domain/passport_book.dart';
import 'passport_book_open.dart';
import 'passport_callbacks.dart';
import 'passport_county_screen.dart';
import 'passport_cover.dart';
import 'passport_landing.dart';
import 'passport_skeleton.dart';

/// The Passport tab: a cover the first time it opens in an app session, then
/// the landing of 47 counties by region. Tapping a county opens its page.
///
/// The screen stays alive while the user switches tabs, so the cover shows
/// once per session and the landing keeps its filter, search and scroll
/// when a county page is closed.
class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key, this.onOpenCounty});

  /// Opens a county's own page (places, safety, news).
  final PassportOpenCounty? onOpenCounty;

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

/// The cover is built but switched off for now: the tab opens straight on
/// the landing. Set to true to bring it (and the book opening) back.
const showCover = false;

class _PassportScreenState extends ConsumerState<PassportScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );
  final ScrollController _scroll = ScrollController();

  /// True once the cover has opened, or after the user has opened it.
  bool _coverDone = !showCover;
  PassportFilter _filter = PassportFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _open.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _coverDone = true);
      }
    });
  }

  @override
  void dispose() {
    _open.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _openCover(bool reduceMotion) {
    _open.duration = Duration(milliseconds: reduceMotion ? 200 : 1050);
    _open.forward(from: 0);
  }

  /// The floating tab bar steps aside while the cover is up, so the cover
  /// has the whole screen.
  void _syncNav({required bool hidden}) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(bottomNavHiddenProvider.notifier).set(hidden: hidden);
      });

  @override
  Widget build(BuildContext context) {
    final collection = ref.watch(badgeCollectionProvider);
    _syncNav(hidden: collection.hasValue && !_coverDone);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: switch (collection) {
        AsyncValue(:final value?) => _content(
          context,
          PassportBook.fromCollection(value),
        ),
        // Nothing saved yet and no connection: the whole tab says so.
        AsyncValue(hasError: true) => SafeArea(
          child: OfflineScreen(
            message:
                'Your passport loads from the internet the first time. '
                'Check your data or Wi‑Fi, then try again.',
            onRetry: () => ref.invalidate(badgeCollectionProvider),
          ),
        ),
        _ => const SafeArea(bottom: false, child: PassportSkeleton()),
      },
    );
  }

  Widget _content(BuildContext context, PassportBook book) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final holderName = ref.watch(
      myPublicProfileProvider.select((p) => p.value?.displayName),
    );
    final landing = SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(badgeCollectionProvider.future),
        child: PassportLanding(
          book: book,
          filter: _filter,
          query: _query,
          controller: _scroll,
          onFilter: (value) => setState(() => _filter = value),
          onQuery: (value) => setState(() => _query = value),
          onOpenCounty: (code) => PassportCountyScreen.open(
            context,
            code: code,
            onOpenCounty: widget.onOpenCounty,
          ),
          holderName: holderName,
        ),
      ),
    );
    if (_coverDone) return landing;
    return PassportBookOpen(
      animation: _open,
      reduceMotion: reduceMotion,
      page: landing,
      cover: PassportCover(
        book: book,
        holderName: holderName,
        onOpen: () => _openCover(reduceMotion),
      ),
    );
  }
}
