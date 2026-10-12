import 'package:flutter/material.dart';

import '../../../core/domain/map_place.dart';
import '../../../core/widgets/app_photo_parts.dart' show AppOpenDirections;
import '../../../core/widgets/app_place_sheet.dart';
import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import 'county_peek_sheet.dart';
import 'real_map_sheet_guard.dart';

/// The sheets Home's real map opens. A county peek is an overlay with no
/// backdrop, so the map stays tappable behind it: tapping another county
/// swaps the open peek for that county's instead of stacking a second one,
/// and a swipe down closes it. A place sheet is a normal modal sheet, one
/// at a time.
class RealMapSheets {
  RealMapSheets({required this.onPeekClosed});

  /// Runs when the peek closes by itself (swipe, Open County, a pin tap),
  /// not when it is replaced by another county's.
  final VoidCallback onPeekClosed;

  final _places = RealMapSheetGuard();
  final _host = GlobalKey<_PeekHostState>();
  _Peek? _latest;
  OverlayEntry? _entry;

  bool get isPeekOpen => _entry != null;

  /// Shows [badge]'s peek, or swaps it in when one is already open.
  void showCounty(
    BuildContext context,
    MapHomeCountyBadge badge, {
    required bool isHome,
    VoidCallback? onOpen,
  }) {
    final peek = _Peek(badge, isHome, onOpen);
    _latest = peek;
    if (_entry != null) {
      _host.currentState?.show(peek);
      return;
    }
    final entry = OverlayEntry(
      builder: (_) => _PeekHost(
        key: _host,
        initial: _latest,
        onDismissed: _remove,
        onClosed: onPeekClosed,
      ),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  /// Closes the county peek with its slide-out; does nothing when none is open.
  void closePeek() => _host.currentState?.dismiss();

  /// Opens a place sheet, closing any county peek first. Ignored while one
  /// is already opening or showing.
  Future<void> showPlace(
    BuildContext context,
    MapPlace place, {
    AppOpenPlace? onOpenPlace,
    AppOpenDirections? onRoute,
    AppOpenPlaceRoute? onPlaceRoute,
  }) {
    closePeek();
    return _places.run(
      () => AppPlaceSheet.show(
        context,
        place,
        onOpenPlace: onOpenPlace,
        onRoute: onRoute,
        onPlaceRoute: onPlaceRoute,
      ),
    );
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
    _latest = null;
  }

  /// Takes the peek away at once, without the slide-out or the callback
  /// (the map is leaving the screen).
  void dispose() {
    _remove();
  }
}

class _Peek {
  const _Peek(this.badge, this.isHome, this.onOpen);

  final MapHomeCountyBadge badge;
  final bool isHome;
  final VoidCallback? onOpen;
}

class _PeekHost extends StatefulWidget {
  const _PeekHost({
    super.key,
    required this.initial,
    required this.onDismissed,
    required this.onClosed,
  });

  final _Peek? initial;
  final VoidCallback onDismissed;
  final VoidCallback onClosed;

  @override
  State<_PeekHost> createState() => _PeekHostState();
}

class _PeekHostState extends State<_PeekHost> {
  static const _slide = Duration(milliseconds: 250);
  bool _visible = false;
  late _Peek? _peek = widget.initial;

  /// Swaps in another county's peek while this one is open.
  void show(_Peek peek) => setState(() => _peek = peek);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  void dismiss() {
    if (!_visible) return;
    setState(() => _visible = false);
    widget.onClosed();
    Future<void>.delayed(_slide, widget.onDismissed);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Dims the map like the modal sheet did, but only visually: taps
          // still reach the map, so another county can be picked.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: _slide,
                child: ColoredBox(
                  color: AppColors.foreground.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _sheet()),
        ],
      ),
    );
  }

  Widget _sheet() {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 1),
        duration: _slide,
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 250) dismiss();
          },
          child: _sheetBody(),
        ),
      ),
    );
  }

  Widget _sheetBody() {
    final peek = _peek;
    if (peek == null) return const SizedBox.shrink();
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.bottomCenter,
      child: CountyPeekSheet(
        key: ValueKey(peek.badge.county.code),
        badge: peek.badge,
        isHome: peek.isHome,
        onOpen: peek.onOpen,
        onClose: dismiss,
      ),
    );
  }
}
